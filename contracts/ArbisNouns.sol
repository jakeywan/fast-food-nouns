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
import { INounsDescriptor } from './interfaces/INounsDescriptor.sol';
import { INounsToken } from './interfaces/INounsToken.sol';
import { INounsSeeder } from './interfaces/INounsSeeder.sol';
import { IOpenWearables } from './interfaces/IOpenWearables.sol';
import { Base64 } from 'base64-sol/base64.sol';
import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { ERC721Enumerable } from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "./external/arbitrum/AddressAliasHelper.sol";
import 'hardhat/console.sol';

contract ArbisNouns is Ownable, ERC721Enumerable {
    using Strings for uint256;

    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    // Determines where in the stack the head is inserted per tokenId
    uint256[1000] public headPositions;

    // Will be used to verify messages coming from L1 oracle
    address public oracleAddress;

    // Given a seed, return a head SVG. Note that this won't be full, there aren't
    // 1000 different heads. TODO: make this number closer to the actual number we
    // need.
    string[1000] public headSVGs;

    // Background hex colors
    string[2] public backgrounds;

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
     * @notice Update seed for an Arbis Noun
     */
    function updateSeed(INounsSeeder.Seed memory seed, uint256 tokenId) public onlyOwner {
        seeds[tokenId] = seed;
    }

    /**
     * @notice Update the head svg for a given seed number
     */
    function updateHeadSVG(uint256 seed, string memory svg) public onlyOwner {
        headSVGs[seed] = svg;
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
            
            // TODO: Also support ER721
            // bool isOwner;
            // Conditionally check interface support for ERC721 or ERC1155
            // if (wContract.supportsInterface(bytes4(keccak256('ownerOf(uint256)')))) {
            //     require(msg.sender == wContract.ownerOf(wRefs[i].tokenId), "Not your wearable.");
            //     isOwner = true;
            // }
            // TODO: Why isn't this evaluating to true?
            // if (wContract.supportsInterface(bytes4(keccak256('balanceOf(address,uint256)')))) {
                require(wContract.balanceOf(msg.sender, tokenId) > 0, "Not your wearable.");
                // isOwner = true;
            // }

            // Set WearableRef to state
            // require(isOwner, "Not your wearable.");
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
    function generateSVGImage(uint256 tokenId) external returns (string memory) {

        // Generate each rect individually, and then compose the SVG
        IOpenWearables.WearableRef[] memory wearableRefs = wearableRefsByTokenId[tokenId];
        // Final string of all our rects
        string memory rects;
        
        // Loop over wearables. Add one to make sure we get to the head and glasses.
        for (uint256 i = 0; i < wearableRefs.length + 1; i++) {
            // At index of the head position, insert rect and increment `_rectIndex`
            if (i == headPositions[tokenId]) {
                // Head
                rects = string(abi.encodePacked(rects, headSVGs[seed.head]));
            }
            
            // If we have a wearable here, combine it in
            if (wearableRefs.length > i) {
                // Confirm FFN ownership of WearableRef token
                IOpenWearables wContract = IOpenWearables(wearableRefs[i].contractAddress);
                // If user doesn't own wearable, delete it from state and skip it
                address owner = ownerOf(tokenId);

                // TODO: Support `ownerOf` as well for ERC721?
                if (wContract.balanceOf(owner, wearableRefs[i].tokenId) == 0) {
                    delete wearableRefs[i].tokenId;
                    continue;
                }

                // Ownership confirmed, fetch WearableData from contract and insert rect
                IOpenWearables.WearableData memory _wearableData = wContract.getWearable(wearableRefs[i].tokenId, owner);
                rects = string(abi.encodePacked(rects, _wearableData.innerSVG));
            }
            
        }

        return _composeSVGParts(rects, backgrounds[seed.background]);
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
     * @notice Transfers an Arbis Noun to its rightful L1 owner (and if it doesn't
     * exist, mints it to the rightful owner).
     */
    function updateOwner(string calldata data) public {
        // Verify that the sender is L1 oracle contract
        require(msg.sender == AddressAliasHelper.applyL1ToL2Alias(oracleAddress), "Not oracle");

        // Transfer Arbis Noun from current owner to new owner
        (uint256 tokenId, address owner) = abi.decode(data, (uint256, address));

        // If tokenId exists, transfer it. If not, mint it to the new owner.
        if (_exists(tokenId)) {
            // NOTE: do i need the data param even though i don't need to send data?
            _safeTransfer(ownerOf(tokenId), owner, tokenId);
        } else {
            _mint(owner, tokenId);
        }
    }

}
