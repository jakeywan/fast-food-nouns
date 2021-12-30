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

    // Reference to Polygon FFNs contract, using to check ownership
    INounsToken public fastFoodNouns = INounsToken(0x514715Fc7F687Ed94E585CaB2bB3009d70C2Cc40);

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
        
        return wearableDataByTokenId[tokenId];
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
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        
        string memory base64SVG = _composeSVGParts(
            wearableDataByTokenId[tokenId].innerSVG,
            "e1d7d5"
        );

        string memory name = wearableDataByTokenId[tokenId].name;
        string memory description = 'Fast Food Nouns wearable.';

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name":"', name, '", "description":"', description, '", "image":"data:image/svg+xml;base64,', base64SVG, '"}'))));
        
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    /**
     * @notice Burn/ban tokens with a specific tokenId held by a specific address.
     * The DAO reserves right to ban offensive designs.
     */
    function burn(address account, uint256 tokenId, uint256 amount) external onlyOwner {
        _burn(account, tokenId, amount);
        delete wearableDataByTokenId[tokenId];
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
        require(!hasMintedBaseWearables[tokenId], "Already minted basics.");

        address owner = fastFoodNouns.ownerOf(tokenId);

        // Get seeds for this FFN
        (
            uint48 background,
            uint48 body,
            uint48 accessory,
            uint48 head,
            uint48 glasses
        ) = fastFoodNouns.seeds(tokenId);

        // Capture that this FFN has minted base wearables
        hasMintedBaseWearables[tokenId] = true;

         // Mint additional existing tokens
        _mint(owner, mintedBodySeeds[body], 1, "");
        emit WearableMinted(tokenId, owner);

        _mint(owner, mintedAccessorySeeds[accessory], 1, "");
        emit WearableMinted(tokenId, owner);

        _mint(owner, mintedGlassesSeeds[glasses], 1, "");
        emit WearableMinted(tokenId, owner);

    }

    /**
     * @notice Admin mint one of each base wearable. This must be populated after deploy.
     */
    function adminMintBaseWearable(
        uint256 seed,
        uint256 seedType, // 0 body, 1 glasses, 2 accessories
        string memory innerSVG,
        string memory name
    ) external onlyOwner {
        
        // Save data to state
        wearableDataByTokenId.push(IOpenWearables.WearableData({
            name: name,
            innerSVG: innerSVG
        }));

        // Save a reference for this item (seed # => wearable tokenId)
        if (seedType == 0) {
            mintedBodySeeds[seed] = _currentId;
        }
        if (seedType == 1) {
            mintedGlassesSeeds[seed] = _currentId;
        }
        if (seedType == 2) {
            mintedAccessorySeeds[seed] = _currentId;
        }

        console.logUint(_currentId);

        // Mint
        _mint(msg.sender, _currentId++, 1, "");
    }

    /**
     * @dev Admin mint tokens (only works for existing tokens)
     */
    function adminMintExisting(address to, uint256 tokenId, uint256 amount)
        external
        onlyOwner
    {
        // Mint and save data
        _mint(to, tokenId, amount, "");

        emit WearableMinted(_currentId++, msg.sender);
    }

    /**
     * @dev Admint mint new tokens    
     */
    function adminMintNew(
        address to,
        uint256 amount,
        IOpenWearables.WearableData memory _wearableData
    ) external onlyOwner {
        // Mint and save data
        _mint(to, _currentId, amount, "");
        wearableDataByTokenId.push(_wearableData);

        emit WearableMinted(_currentId++, msg.sender);
    }

    /**
     * @notice Update FFN contract.
     */
    function updateFFNContract(address _contract) external onlyOwner {
        fastFoodNouns = INounsToken(_contract);
    }

    /**
     * @notice Given a string of interior SVG parts and a background, compose
     * and encode the final SVG.
     */
    function _composeSVGParts(string memory rects, string memory background)
        internal
        pure
        returns(string memory)
    {
        return Base64.encode(abi.encodePacked(
            '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
            '<rect width="100%" height="100%" fill="#', background, '" />',
            rects,
            '</svg>'
        ));
    }

}
