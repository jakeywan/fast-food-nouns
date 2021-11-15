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
import { IOpenWearables } from './interfaces/IOpenWearables.sol';
import { Base64 } from 'base64-sol/base64.sol';
import 'hardhat/console.sol';

contract ArbisNouns is Ownable {
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

    // Track whether a given tokenId has opted into the new wearables system
    bool[1000] public hasUpgraded;

    // Determines where in the stack the head is inserted per tokenId
    uint256[1000] public headPositions;

    // The state of what a given tokenId is wearing (tokenId => list of items worn)
    mapping(uint256 => IOpenWearables.WearableRef[]) public wearableRefsByTokenId;

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
     */
    function wearWearables(
        uint256 tokenId,
        uint256 headPosition,
        IOpenWearables.WearableRef[] calldata wRefs
    )
        external 
    {
        // Verify ownership of FFN NFT
        require(msg.sender == fastFoodNouns.ownerOf(tokenId), "Not your Fast Food Noun.");
        // Empty out existing wearablesRefs for this tokenId
        delete wearableRefsByTokenId[tokenId];
        // Update head position
        headPositions[tokenId] = headPosition;
        // Loop, verify ownership, save to state
        for (uint256 i = 0; i < wRefs.length; i++) {
            // TODO: We must also support IERC1155
            IOpenWearables wContract = IOpenWearables(wRefs[i].contractAddress);

            bool isOwner;
            // Conditionally check interface support for ERC721 or ERC1155
            if (wContract.supportsInterface(bytes4(keccak256('ownerOf(uint256)')))) {
                require(msg.sender == wContract.ownerOf(wRefs[i].tokenId), "Not your wearable.");
                isOwner = true;
            }
            // TODO: Why isn't this evaluating to true?
            // if (wContract.supportsInterface(bytes4(keccak256('balanceOf(address,uint256)')))) {
                require(wContract.balanceOf(msg.sender, tokenId) > 0, "Not your wearable.");
                isOwner = true;
            // }

            // Set WearableRef to state
            require(isOwner, "Not your wearable.");
            wearableRefsByTokenId[tokenId].push(wRefs[i]);

        }
        // TODO: We should emit an event here for clients
    }

    /**
     * @notice Update FFN contract.
     */
    function updateFFNContract(address _contract) external onlyOwner {
        fastFoodNouns = INounsToken(_contract);
    }

    /**
     * @notice Return the list of wearables selected for a given tokenId.
     */
    function getWearableRefsForTokenId(uint256 tokenId)
        public
        view
        returns (IOpenWearables.WearableRef[] memory)
    {
        return wearableRefsByTokenId[tokenId];
    }

    /**
     * @notice Update the official Noun descriptor in case it's moved or updated.
     * @dev For legacy FFNs, and to render heads and backgrounds.
     */
    function setNounDescriptor(INounsDescriptor _descriptor) external onlyOwner {
        nounDescriptor = _descriptor;
    }

    /**
     * @notice Given a seed, find the corresponding tokenId, then assemble.
     * @dev The FFNs token contract doesn't send us the tokenId, so we're inferring
     * it from the seed passed. This is the only function called by the FFN contract.
     */
    function generateSVGImage(INounsSeeder.Seed memory seed) external returns (string memory) {
        uint256 tokenId = getTokenIdFromSeed(seed);

        // If tokenId hasn't opted into new system, fetch legacy parts.
        if (hasUpgraded[tokenId] == false) {
            return generateLegacySVG(seed);
        }

        // If token has opted in to new system, render new parts. We need to gen
        // each rect individually, and then compose the SVG.
        IOpenWearables.WearableRef[] memory wearableRefs = wearableRefsByTokenId[tokenId];
        // Final string of all our rects
        string memory rects;
        
        // Loop over wearables. Add one to make sure we get to the head and glasses.
        for (uint256 i = 0; i < wearableRefs.length + 1; i++) {
            // At index of the head position, insert rect and increment `_rectIndex`
            if (i == headPositions[tokenId]) {
                // Head
                // TODO: We can optimize this by not forcing it into an array,
                // we'd just need to adjust _generateSVGRects to take single param
                bytes[] memory rleHead = new bytes[](1);
                rleHead[0] = nounDescriptor.heads(seed.head);
                rects = string(abi.encodePacked(rects, RenderingEngine._generateSVGRects(
                    rleHead
                )));
            }
            
            // If we have a wearable here, combine it in
            if (wearableRefs.length > i) {
                // Confirm FFN ownership of WearableRef token
                IOpenWearables wContract = IOpenWearables(wearableRefs[i].contractAddress);
                // If user doesn't own wearable, delete it from state and skip it
                address owner = fastFoodNouns.ownerOf(tokenId);
                // TODO: Support `ownerOf` as well
                if (wContract.balanceOf(owner, wearableRefs[i].tokenId) == 0) {
                    delete wearableRefs[i].tokenId;
                    continue;
                }

                // TODO: confirm it's a supported size?

                // Ownership confirmed, fetch WearableData from contract and insert rect
                IOpenWearables.WearableData memory _wearableData = wContract.getWearable(wearableRefs[i].tokenId, owner);
                rects = string(abi.encodePacked(rects, _wearableData.innerSVG));
            }
            
        }

        return RenderingEngine._composeSVGParts(rects, nounDescriptor.backgrounds(seed.background));
    }

    /**
     * @notice Render original SVG in case FFN hasn't opted in to new system.
     * @dev This should just replicate the existing NounsDescriptor.sol.
     */
    function generateLegacySVG(INounsSeeder.Seed memory seed)
        public
        returns (string memory)
    {
        bytes[] memory _parts = new bytes[](4);
        _parts[0] = nounDescriptor.bodies(seed.body);
        _parts[1] = nounDescriptor.accessories(seed.accessory);
        _parts[2] = nounDescriptor.heads(seed.head);
        _parts[3] = nounDescriptor.glasses(seed.glasses);

        string memory rects = RenderingEngine._generateSVGRects(_parts);
        
        return RenderingEngine._composeSVGParts(rects, nounDescriptor.backgrounds(seed.background));
    }

    /**
     * @notice Indicate that a FFN should use the new wearables system.
     */
    function upgradeToken(uint256 tokenId) external {
        hasUpgraded[tokenId] = true;
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