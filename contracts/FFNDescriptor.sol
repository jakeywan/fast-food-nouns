// SPDX-License-Identifier: GPL-3.0

/// @title Fast Food Nouns Descriptor Contract

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
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import { INounsDescriptor } from './interfaces/INounsDescriptor.sol';
import { INounsToken } from './interfaces/INounsToken.sol';
import { INounsSeeder } from './interfaces/INounsSeeder.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { Base64 } from 'base64-sol/base64.sol';
import 'hardhat/console.sol';

contract FFNDescriptor is Ownable {
    using Strings for uint256;

    // Concatenated, then hashed, seed values to use as tokenId lookup table
    mapping(bytes32 => uint256) public tokenIdsBySeed;

    // Used to fetch base parts (head, background) and render non-opted-in FFNs
    INounsDescriptor public nounDescriptor = INounsDescriptor(0x0Cfdb3Ba1694c2bb2CFACB0339ad7b1Ae5932B63);

    // Used to check tokenId ownership before wearing clothes
    INounsToken public fastFoodNouns = INounsToken(0xFbA74f771FCEE22f2FFEC7A66EC14207C7075a32);

    // prettier-ignore
    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    // Nouns color palette (just storing the one array, not a mapping)
    string[] public nounsPalette;

    // Track whether a given tokenId has opted into the new wearables system
    bool[1000] public hasUpgraded;

    // Descriptive data for wearable to inform rendering engine
    struct WearableData {
        bytes rleData;
        string[] palette;
        uint256 gridSize;
    }

    // A reference to a WearableData on another contract
    struct WearableRef {
        address contractAddress;
        uint256 tokenId;
    }

    // Determines where in the stack the head is inserted per tokenId
    uint256[] public headPosition;

    // The state of what a given tokenId is wearing (tokenId => list of items worn)
    mapping(uint256 => WearableRef[]) public wearableRefsByTokenId;

    /**
     * @notice Update an individual bytes32 => tokenId mapping.
     * @dev While this structure makes it possible to accidentally add many seeds
     * for the same tokenId, we can still only have one of each seed. Not worth
     * adding a delete function.
     */
    function updateTokenIdBySeed(INounsSeeder.Seed memory seed, uint256 tokenId) public onlyOwner {
        bytes32 seedHash = keccak256(abi.encodePacked(
            seed.background,
            seed.body,
            seed.accessory,
            seed.head,
            seed.glasses
        ));
        tokenIdsBySeed[seedHash] = tokenId;
    }

    // TODO: This fails from a too-large input size. Let's make it possible to
    // break this into chunks (doing 1-by-1 is also too much gas). add a
    // `uint256 startingIndex` and make i = `startingIndex` so we can upload
    // in chunks.
    /**
     * @notice Batch upload all bytes32 => tokenId mappings.
     */
    function updateAllTokenIdsBySeed(INounsSeeder.Seed[] memory seedsArray) external onlyOwner {
      for (uint256 i = 0; i < seedsArray.length; i++) {
        updateTokenIdBySeed(seedsArray[i], i);
      }
    }

    /**
     * @notice Convert a Seed struct into a bytes32 hash and return corresponding tokenId. 
     */
    function getTokenIdFromSeed(INounsSeeder.Seed memory _seed) view public returns (uint256) {
        bytes32 seedHash = keccak256(abi.encodePacked(
          _seed.background,
          _seed.body,
          _seed.accessory,
          _seed.head,
          _seed.glasses
        ));
        return tokenIdsBySeed[seedHash];
    }

    /**
     * @notice Wear wearables.
     * TODO: I think we also need to include and update head position here.
     */
    function wearWearables(uint256 tokenId, WearableRef[] calldata wRefs) external {
        // Verify ownership of FFN NFT
        require(msg.sender == fastFoodNouns.ownerOf(tokenId), "Not your Fast Food Noun.");
        // Empty out existing wearablesRefs for this tokenId
        delete wearableRefsByTokenId[tokenId];
        // Loop, verify ownership, save to state
        for (uint256 i = 0; i < wRefs.length; i++) {
            IERC721 wContract = IERC721(wRefs[i].contractAddress);
            require(msg.sender == wContract.ownerOf(wRefs[i].tokenId), "Not your wearable.");
            wearableRefsByTokenId[tokenId].push(wRefs[i]);
        }
        // TODO: We should emit an event here for clients
    }


    /**
     * @notice Return the list of wearables selected for a given tokenId.
     * TODO: Do we need this? Or is it already available?
     */
    function getWearableRefsForTokenId(uint256 tokenId)
        public
        view
        returns (WearableRef[] memory)
    {
        return wearableRefsByTokenId[tokenId];
    }

    /**
     * @notice Update the official Noun descriptor in case it's moved or updated.
     * @dev For legacy FFNs, and to render heads.
     */
    function setNounDescriptor(INounsDescriptor _descriptor) external onlyOwner {
        nounDescriptor = _descriptor;
    }

    /**
     * @notice Add colors to nounsPalette.
     * @dev For legacy FFNs, and to render heads.
     */
    function addManyColorsToNounsPalette(string[] calldata newColors) external onlyOwner {
        for (uint256 i = 0; i < newColors.length; i++) {
            addColorToPalette(newColors[i]);
        }
    }

    /**
     * @notice Add a single color to a color palette.
     */
    function addColorToPalette(string calldata _color) public onlyOwner {
        nounsPalette.push(_color);
    }

    /**
     * @notice Given a seed, find the corresponding tokenId, then assemble.
     * @dev The FFNs token contract doesn't send us the tokenId, so we're inferring
     * it from the seed passed. This is the only function called by the FFN contract.
     */
    function generateSVGImage(INounsSeeder.Seed memory seed) external view returns (string memory) {
        uint256 tokenId = getTokenIdFromSeed(seed);

        // If tokenId hasn't opted into new system, fetch legacy parts. Replicates
        // NounsDescriptor.sol.
        if (hasUpgraded[tokenId] == false) {
            bytes[] memory _parts = new bytes[](4);
            _parts[0] = nounDescriptor.bodies(seed.body);
            _parts[1] = nounDescriptor.accessories(seed.accessory);
            _parts[2] = nounDescriptor.heads(seed.head);
            _parts[3] = nounDescriptor.glasses(seed.glasses);

            MultiPartRLEToSVG.SVGParams memory params = MultiPartRLEToSVG.SVGParams({
                parts: _parts,
                background: nounDescriptor.backgrounds(seed.background)
            });
            
            return NFTDescriptor.generateSVGImage(params, nounsPalette);
        }

        // If token has opted in to new system, render new parts. We need to gen
        // each rect individually, and then compose the SVG.
        // WearableRef[] memory wearableRefs = wearablesByTokenId[tokenId];

        // _parts[0] = WearableData({
        //     rleData: '',
        //     palette: [],
        //     gridSize: 32
        // })
    }

    /**
     * @notice Assemble parts for this tokenId.
     * @dev We need to render each rect separately, compose an array, and sandwich
     * them with the final SVG tag. This differs from Nouns because we don't have
     * a universal palette. Each NFT has it's own palette.
     */
    function _getPartsForSeed(INounsSeeder.Seed memory seed, uint256 tokenId)
        internal
        view
        returns (bytes[] memory)
    {
        
        // If tokenId has opted into new system, assemble parts.

        /**
        // List of WearableRefs for this user
        WearableRef[] memory wearableRefs = wearablesByTokenId[tokenId];
        // List of WearableData we're building
        WearableData[] memory wearableData;
        // Base Fast Food shirt is always inserted as fallback
        _parts[0] = WearableData({
            rleData: '',
            palette: [],
            gridSize: 32
        })
        // For each WearableRef, generate an SVG rect
        for (uint256 i = 0; i < wearableRefs.length; i++) {
            
            // At index of the head position, insert it w/ fallback glasses
            if (i == headPosition[tokenId]) {
                _parts[5] = nounDescriptor.heads(seed.head);
                _parts[6] = WearableData({
                    rleData: '',
                    palette: [],
                    gridSize: 32
                })
            }
            // If user doesn't own wearable, delete it from state and skip it
            IERC721 memory wContract = IERC721(wearableRefs[i].contractAddress);
            if (msg.sender !== wContract.ownerOf(wearableRefs[i].tokenId)) {
                delete wearableRefs[i].tokenId;
                continue;
            }
            // Fetch WearableData from contract and insert it
            _parts[7] = wContract.openWearable(wearableRefs[i].tokenId);

        }
        */

        // TODO: Just putting these here so it'll compile.
        bytes[] memory _parts = new bytes[](10);
        return _parts;
    }

}

library MultiPartRLEToSVG {
    struct SVGParams {
        bytes[] parts;
        string background;
    }

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
     * @notice Given RLE image parts and color palettes, merge to generate a single SVG image.
     */
    function generateSVG(SVGParams memory params, string[] storage palette)
        internal
        view
        returns (string memory svg)
    {
        // prettier-ignore
        return string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
                '<rect width="100%" height="100%" fill="#', params.background, '" />',
                _generateSVGRects(params.parts, palette),
                '</svg>'
            )
        );
    }

    /**
     * @notice Given RLE image parts and color palettes, generate SVG rects.
     */
    // prettier-ignore
    function _generateSVGRects(bytes[] memory parts, string[] storage palette)
        private
        view
        returns (string memory svg)
    {
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
                    buffer[cursor + 3] = palette[rect.colorIndex]; // color

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

library NFTDescriptor {
    struct TokenURIParams {
        string name;
        string description;
        bytes[] parts;
        string background;
    }

    /**
     * @notice Generate an SVG image for use in the ERC721 token URI.
     */
    function generateSVGImage(MultiPartRLEToSVG.SVGParams memory params, string[] storage palette)
        internal
        view
        returns (string memory svg)
    {
        return Base64.encode(bytes(MultiPartRLEToSVG.generateSVG(params, palette)));
    }
}