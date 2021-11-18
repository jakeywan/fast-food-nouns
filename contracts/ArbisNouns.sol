// SPDX-License-Identifier: GPL-3.0

/// @title Arbis Nouns ERC721

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
import { INounsSeeder } from './interfaces/INounsSeeder.sol';
import { IOpenWearables } from './interfaces/IOpenWearables.sol';
import { Base64 } from 'base64-sol/base64.sol';
import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { ERC721Enumerable } from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import 'hardhat/console.sol';

contract ArbisNouns is Ownable, ERC721Enumerable {
    using Strings for uint256;

    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    // Determines where in the stack the head is inserted per tokenId
    uint256[1000] public headPositions;

    // Given a seed, return a head SVG. Note that this won't be full, there aren't
    // 1000 different heads. TODO: make this number closer to the actual number we
    // need.
    string[1000] public headSVGs;

    // Background hex colors
    string[2] public backgrounds;

    // List of owners who can mint their nouns, per tokenId
    address[1000] public snapshot;

    string public tokenDescription = 'Can I take your order? Arbis Nouns are an NFT wearables project by the Fast Food DAO. Buy a Fast Food Noun on Ethereum to claim your Arbis Noun.';

    // The state of what a given tokenId is wearing (tokenId => list of items worn)
    mapping(uint256 => IOpenWearables.WearableRef[]) public wearableRefsByTokenId;

    // Exact copy of the seeds from L1 for a given tokenId
    INounsSeeder.Seed[1000] public seeds;

    constructor() ERC721('Arbis Nouns', 'ARBN') {
        // Initialize background colors
        backgrounds[0] = 'd5d7e1';
        backgrounds[1] = 'e1d7d5';
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
        require(msg.sender == ownerOf(tokenId), "Not your Fast Food Noun.");
        // Empty out existing wearablesRefs for this tokenId
        delete wearableRefsByTokenId[tokenId];
        // Update head position
        headPositions[tokenId] = headPosition;
        // Loop, verify ownership, save to state
        for (uint256 i = 0; i < wRefs.length; i++) {
            IOpenWearables wContract = IOpenWearables(wRefs[i].contractAddress);
            
            require(wContract.balanceOf(msg.sender, tokenId) > 0, "Not your wearable.");

            // Set WearableRef to state
            wearableRefsByTokenId[tokenId].push(wRefs[i]);

        }
        // TODO: We should emit an event here for clients
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
     * @notice Generate SVG for tokenId
     */
    function generateSVGImage(uint256 tokenId) public view returns (string memory) {

        // Generate each rect individually, and then compose the SVG
        IOpenWearables.WearableRef[] memory wearableRefs = wearableRefsByTokenId[tokenId];
        // Final string of all our rects
        string memory rects;
        
        // Loop over wearables. Add one to make sure we get to the head and glasses.
        for (uint256 i = 0; i < wearableRefs.length + 1; i++) {
            // At index of the head position, insert rect and increment `_rectIndex`
            if (i == headPositions[tokenId]) {
                // Head
                rects = string(abi.encodePacked(rects, headSVGs[seeds[tokenId].head]));
            }
            
            // If we have a wearable here, combine it in
            if (wearableRefs.length > i) {
                // Confirm FFN ownership of WearableRef token
                IOpenWearables wContract = IOpenWearables(wearableRefs[i].contractAddress);
                // If user doesn't own wearable, skip it
                address owner = ownerOf(tokenId);

                if (wContract.balanceOf(owner, wearableRefs[i].tokenId) == 0) {
                    continue;
                }

                // Ownership confirmed, fetch WearableData from contract and insert rect
                IOpenWearables.WearableData memory _wearableData = wContract.getWearable(wearableRefs[i].tokenId, owner);
                rects = string(abi.encodePacked(rects, _wearableData.innerSVG));
            }
            
        }

        return _composeSVGParts(rects, backgrounds[seeds[tokenId].background]);
    }

    /**
     * @notice Compose tokenURI for Arbis Noun.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'Nonexistent token.');
        string memory NounID = tokenId.toString();
        string memory name = string(abi.encodePacked('Arbis Noun ', NounID));
        string memory description = tokenDescription;

        // Build svg
        string memory svg = generateSVGImage(tokenId);
    
        // Compose json string
        string memory json = Base64.encode(abi.encodePacked('{"name":"', name, '", "description":"', description, '", "image":"data:image/svg+xml;base64,', svg, '"}'));
        return string(abi.encodePacked('data:application/json;base64,', json));
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

    /**
     * @notice Transfers an Arbis Noun to its rightful L1 owner (and if it doesn't
     * exist, mints it to the rightful owner).
     */
    function mint(uint256 tokenId) external {
        // Mint token to snapshot address
        _mint(snapshot[tokenId], tokenId);
    }

    /**
     * @notice Let user batch mint all their available Arbis Nouns at once
     */
    function mintAll() external {
        for (uint256 i = 0; i < snapshot.length; i++) {
            if (snapshot[i] == msg.sender) {
                _mint(snapshot[i], i);
            }
        }
    }

    /**
     * @notice Check available mints
     */
    function checkNumberOfMintsAvailable(address owner) external returns (uint256) {
        uint256 counter = 0;
        for (uint256 i = 0; i < snapshot.length; i++) {
            if (snapshot[i] == owner) {
                counter++;
            }
        }
        return counter;
    }

    /**
     * @notice Update seed for an Arbis Noun
     */
    function updateSeed(INounsSeeder.Seed memory seed, uint256 tokenId) external onlyOwner {
        seeds[tokenId] = seed;
    }

    /**
     * @notice Update the head svg for a given seed number
     */
    function updateHeadSVG(uint256 seed, string memory svg) external onlyOwner {
        headSVGs[seed] = svg;
    }

    /**
     * @notice Update address to which the given tokenId will be minted
     */
    function updateSnapshot(uint256 tokenId, address owner) external onlyOwner {
        snapshot[tokenId] = owner;
    }

}
