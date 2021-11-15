// SPDX-License-Identifier: GPL-3.0

/// @title The Fast Food Nouns Wearables Tokens

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░████████████░░░░░░░░░░░ *
 * ░░░░░░██████░█░███░░░░░░░░░░░ *
 * ░░░░███████░█░█░██████░░░░░░░ *
 * ░░░████████░░░░░██████░░░░░░░ *
 * ░░░████████████████████████░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import { Base64 } from 'base64-sol/base64.sol';
import { INounsToken } from './interfaces/INounsToken.sol';
import { IOpenWearables } from './interfaces/IOpenWearables.sol';
import { INounsDescriptor } from './interfaces/INounsDescriptor.sol';
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import 'hardhat/console.sol';

contract FFNWearables is ERC1155, Ownable {
    using Strings for uint256;

    // The internal tokenId tracker
    uint256 private _currentId;

    // Minting whitelist (only used when mintingStatus == WhiteListOnly)
    mapping(address => bool) public whitelist;

    enum Status { Paused, FFNsOnly, WhitelistOnly, Open }
    Status public mintingStatus;

    // Holds WearableData per tokenId
    IOpenWearables.WearableData[] public wearableDataByTokenId;

    // tokenId => reference of how to retrieve Noun part information. Holds
    // alternative wearable data that references the Nouns contract. We do
    // this so we don't have to save the SVG rects to storage (expensive).
    // 0 = body, 1 = accessory, 2 = glasses
    struct NounsPartRef {
        uint256 partType;
        uint256 seed;
    }
    mapping(uint256 => NounsPartRef) public nounsPartRefsByTokenId;

    // Specifies which tokenIds which are open to mint. tokenId => isOpenToMint
    mapping(uint256 => bool) public openMintWearables;

    // Tracks which base seed items have already been created as tokens in
    // our system. seed number => our tokenId. tokenId 0 is going to be a custom
    // item, so we can expect it to be non-zero
    mapping(uint256 => uint256) public mintedBodySeeds;
    mapping(uint256 => uint256) public mintedAccessorySeeds;
    mapping(uint256 => uint256) public mintedGlassesSeeds;

    // True if FFN has already minted base wearables
    bool[1000] public hasMintedBaseWearables;

    // Reference to Nouns contract, using to check ownership
    INounsToken public fastFoodNouns = INounsToken(0xFbA74f771FCEE22f2FFEC7A66EC14207C7075a32);

    // Used to fetch base parts and render non-opted-in FFNs
    INounsDescriptor public nounDescriptor = INounsDescriptor(0x0Cfdb3Ba1694c2bb2CFACB0339ad7b1Ae5932B63);

    event WearableMinted(uint256 indexed tokenId, address indexed creator);

    constructor() ERC1155('Fast Food Wearables') {}

    /**
     * @notice Verify ownership and return WearableData for token requested.
     * @dev This is soft validation, easily bypassed. It's on contract writers
     * not to bypass ownership checks. Doing otherwise is tantamount to bypassing
     * royalties or copyminting.
     */
    function getWearable(uint256 tokenId, address owner)
        external
        view
        returns (IOpenWearables.WearableData memory)
    {
        require(balanceOf(owner, tokenId) > 0, "Wearable not owned.");

        // If we don't have innerSVG for this tokenId, fallback to NounsPartRef
        if (bytes(wearableDataByTokenId[tokenId].innerSVG).length == 0) {
            return IOpenWearables.WearableData({
                name: wearableDataByTokenId[tokenId].name,
                innerSVG: renderNounsPartForTokenId(tokenId),
                size: wearableDataByTokenId[tokenId].size
            });
        } else {
            return wearableDataByTokenId[tokenId];
        }

    }

    /**
     * @notice Mint an `amount` of tokens to sender and save WearableData to state.
     * @dev Can only be called by a whitelisted creator address.
     */
    function mint(uint256 amount, IOpenWearables.WearableData memory _wearableData) external {

        if (mintingStatus == Status.Paused) {
            revert("Minting paused.");
        }
        
        if (mintingStatus == Status.WhitelistOnly) {
            require(whitelist[msg.sender], "Not whitelisted.");
        }

        if (mintingStatus == Status.FFNsOnly) {
            require(fastFoodNouns.balanceOf(msg.sender) > 0, "Not an FFN holder.");
        }

        // Mint and save data
        _mint(msg.sender, _currentId, amount, "");
        wearableDataByTokenId.push(_wearableData);

        emit WearableMinted(_currentId++, msg.sender);
    }

    /**
     * @notice Let anyone mint from our available open mints.
     */
    function mintOpenWearable(uint256 tokenId) external {
        require(openMintWearables[tokenId], "Wearable not free.");
        require(bytes(wearableDataByTokenId[tokenId].name).length > 0, "No token data.");
        // TODO: require they own at least one FFN

        _mint(msg.sender, tokenId, 1, "");
        emit WearableMinted(tokenId, msg.sender);
    }

    /**
     * @notice Toggle whether a specific wearable should be open mint.
     */
    function toggleOpenMintWearable(uint256 tokenId) external onlyOwner {
        openMintWearables[tokenId] = !openMintWearables[tokenId];
    }

    /**
     * @notice Compose image and return tokenURI.
     */
    function tokenURI(uint256 tokenId) external returns (string memory) {
        
        // If `_wearableData.innerSVG` is empty, fallback to NounsPartRef
        string memory innerSVG;
        if (bytes(wearableDataByTokenId[tokenId].innerSVG).length == 0) {
            innerSVG = renderNounsPartForTokenId(tokenId);
        } else {
            innerSVG = wearableDataByTokenId[tokenId].innerSVG;
        }
        string memory base64SVG = RenderingEngine._composeSVGParts(innerSVG, "e1d7d5");

        string memory name = wearableDataByTokenId[tokenId].name;
        string memory description = 'TODO';

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name":"', name, '", "description":"', description, '", "image":"data:image/svg+xml;base64,', base64SVG, '"}'))));
        
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    /**
     * @notice This contract may become open for all to mint, but the DAO keeps
     * the right to ban offensive designs. We're not burning these because it's
     * not as cost-effective. Use the burn mechanism if you want to do that.
     */
    function banToken(uint256 tokenId) external onlyOwner {
        delete wearableDataByTokenId[tokenId];
    }

    /**
     * @notice Burn tokens with a specific tokenId held by a specific address.
     */
    function burn(address account, uint256 tokenId, uint256 amount) external onlyOwner {
        _burn(account, tokenId, amount);
    }

    /**
     * @notice Sets minting status, takes uint that refers to Status enum (0 indexed).
     */
    function setMintingStatus(Status _status) external onlyOwner {
        mintingStatus = _status;
    }

    /**
     * @notice Let each FFN mint their current clothes, one time.
     */
    function mintBaseWearables(uint256 tokenId) external {
        require(fastFoodNouns.ownerOf(tokenId) == msg.sender, "Not your FFN.");
        require(!hasMintedBaseWearables[tokenId], "Already minted basics.");

        // Get seeds for this FFN
        (
            uint48 background,
            uint48 body,
            uint48 accessory,
            uint48 head,
            uint48 glasses
        ) = fastFoodNouns.seeds(tokenId);

        // BODY
        if (mintedBodySeeds[body] == 0) {
            // Mint new item
            _mint(msg.sender, _currentId, 1, "");
            // Save wearable data for this tokenId (using NounsPartRef)
            wearableDataByTokenId.push(IOpenWearables.WearableData({
                name: string(abi.encodePacked('Nouns Shirt ', _currentId.toString())),
                innerSVG: '', // empty fill force us to fallback to NounsPartRef
                size: 320
            }));
            // Save nounsPartRefsByTokenId for this tokenId
            nounsPartRefsByTokenId[_currentId] = NounsPartRef({
                partType: 0,
                seed: body
            });
            emit WearableMinted(_currentId++, msg.sender);
        } else {
            // Increment existing item
            _mint(msg.sender, mintedBodySeeds[body], 1, "");
            emit WearableMinted(tokenId, msg.sender);
        }

        // ACCESSORY
        if (mintedAccessorySeeds[accessory] == 0) {
            // Mint new item
            _mint(msg.sender, _currentId, 1, "");
            // Save wearable data for this tokenId (using NounsPartRef)
            wearableDataByTokenId.push(IOpenWearables.WearableData({
                name: string(abi.encodePacked('Nouns Accessory ', _currentId.toString())),
                innerSVG: '', // empty fill force us to fallback to NounsPartRef
                size: 320
            }));
            // Save nounsPartRefsByTokenId for this tokenId
            nounsPartRefsByTokenId[_currentId] = NounsPartRef({
                partType: 1,
                seed: accessory
            });
            emit WearableMinted(_currentId++, msg.sender);
        } else {
            // Increment existing item
            _mint(msg.sender, mintedAccessorySeeds[accessory], 1, "");
            emit WearableMinted(tokenId, msg.sender);
        }

        // GLASSES
        if (mintedGlassesSeeds[glasses] == 0) {
            // Mint new item
            _mint(msg.sender, _currentId, 1, "");
            // Save wearable data for this tokenId (using NounsPartRef)
            wearableDataByTokenId.push(IOpenWearables.WearableData({
                name: string(abi.encodePacked('Nouns Glasses ', _currentId.toString())),
                innerSVG: '', // empty fill force us to fallback to NounsPartRef
                size: 320
            }));
            // Save nounsPartRefsByTokenId for this tokenId
            nounsPartRefsByTokenId[_currentId] = NounsPartRef({
                partType: 2,
                seed: glasses
            });
            emit WearableMinted(_currentId++, msg.sender);
        } else {
            // Increment existing item
            _mint(msg.sender, mintedGlassesSeeds[glasses], 1, "");
            emit WearableMinted(tokenId, msg.sender);
        }

        hasMintedBaseWearables[tokenId] = true;
    }

    /**
     * @notice Renders an innerSVG part from a `NounsPartReference`. We're relying
     * on this mechanism so we don't have to store extra innerSVGs in state.
     */
    function renderNounsPartForTokenId(uint256 tokenId) public view returns (string memory innerSVG) {
        NounsPartRef storage ref = nounsPartRefsByTokenId[tokenId];
        
        // Render and save wearable data for this tokenId
        bytes[] memory _parts = new bytes[](1);
        
        // Body
        if (ref.partType == 0) {
            _parts[0] = nounDescriptor.bodies(ref.seed);
        }
        // Accessory
        if (ref.partType == 1) {
            _parts[0] = nounDescriptor.accessories(ref.seed);
        }
        // Glasses
        if (ref.partType == 2) {
            _parts[0] = nounDescriptor.glasses(ref.seed);
        }

        return RenderingEngine._generateSVGRects(_parts);
    }

    /**
     * @notice Update FFN contract.
     */
    function updateFFNContract(address _contract) external onlyOwner {
        fastFoodNouns = INounsToken(_contract);
    }

}

library RenderingEngine {

    struct ContentBounds {
        uint8 top;
        uint8 right;
        uint8 bottom;
        uint8 left;
    }

    struct Rect {
        uint8 length;
        uint8 colorIndex;
    }

    struct DecodedImage {
        uint8 paletteIndex;
        ContentBounds bounds;
        Rect[] rects;
    }

    /**
     * @notice Given a string of interior SVG parts and a background, compose
     * and encode the final SVG.
     */
    function _composeSVGParts(string memory rects, string memory background)
        internal
        view
        returns(string memory)
    {
        return Base64.encode(abi.encodePacked(
            '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
            '<rect width="100%" height="100%" fill="#', background, '" />',
            rects,
            '</svg>'
        ));
    }

    /**
     * @notice Given RLE image parts and color palettes, generate SVG rects.
     * @dev This function will fallback to using the Nouns contract as palette
     * if an empty palette is supplied to it.
     * TODO: we should pass the Nouns descriptor contract address in explicitly,
     * in case they move it and we want to keep it updated.
     */
    function _generateSVGRects(bytes[] memory parts)
        internal
        view
        returns (string memory svg)
    {
        // TODO: will we ever want to update this?
        INounsDescriptor nounDescriptor = INounsDescriptor(0x0Cfdb3Ba1694c2bb2CFACB0339ad7b1Ae5932B63);
        string[33] memory lookup = [
            '0', '10', '20', '30', '40', '50', '60', '70', 
            '80', '90', '100', '110', '120', '130', '140', '150', 
            '160', '170', '180', '190', '200', '210', '220', '230', 
            '240', '250', '260', '270', '280', '290', '300', '310',
            '320' 
        ];
        string memory rects;
        for (uint8 p = 0; p < parts.length; p++) {
            DecodedImage memory image = _decodeRLEImage(parts[p]);
            uint256 currentX = image.bounds.left;
            uint256 currentY = image.bounds.top;
            uint256 cursor;
            string[16] memory buffer;

            string memory part;
            for (uint256 i = 0; i < image.rects.length; i++) {
                Rect memory rect = image.rects[i];
                if (rect.colorIndex != 0) {
                    buffer[cursor] = lookup[rect.length];          // width
                    buffer[cursor + 1] = lookup[currentX];         // x
                    buffer[cursor + 2] = lookup[currentY];         // y
                    // Use the default Nouns palette
                    buffer[cursor + 3] = nounDescriptor.palettes(0, rect.colorIndex);
                   
                    cursor += 4;

                    if (cursor >= 16) {
                        part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
                        cursor = 0;
                    }
                }

                currentX += rect.length;
                if (currentX == image.bounds.right) {
                    currentX = image.bounds.left;
                    currentY++;
                }
            }

            if (cursor != 0) {
                part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
            }
            rects = string(abi.encodePacked(rects, part));
        }
        return rects;
    }

    /**
     * @notice Return a string that consists of all rects in the provided `buffer`.
     */
    // prettier-ignore
    function _getChunk(uint256 cursor, string[16] memory buffer) private pure returns (string memory) {
        string memory chunk;
        for (uint256 i = 0; i < cursor; i += 4) {
            chunk = string(
                abi.encodePacked(
                    chunk,
                    '<rect width="', buffer[i], '" height="10" x="', buffer[i + 1], '" y="', buffer[i + 2], '" fill="#', buffer[i + 3], '" />'
                )
            );
        }
        return chunk;
    }

    /**
     * @notice Decode a single RLE compressed image into a `DecodedImage`.
     */
    function _decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
        uint8 paletteIndex = uint8(image[0]);
        ContentBounds memory bounds = ContentBounds({
            top: uint8(image[1]),
            right: uint8(image[2]),
            bottom: uint8(image[3]),
            left: uint8(image[4])
        });

        uint256 cursor;
        Rect[] memory rects = new Rect[]((image.length - 5) / 2);
        for (uint256 i = 5; i < image.length; i += 2) {
            rects[cursor] = Rect({ length: uint8(image[i]), colorIndex: uint8(image[i + 1]) });
            cursor++;
        }
        return DecodedImage({ paletteIndex: paletteIndex, bounds: bounds, rects: rects });
    }
}