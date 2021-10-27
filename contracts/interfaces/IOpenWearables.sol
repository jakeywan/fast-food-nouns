// SPDX-License-Identifier: GPL-3.0

/// @title Interface for OpenWearables

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

/**
 * @dev Any contract impelementing this interface must also be an ERC721 or ERC115,
 * but we're agnostic to which one.
 */
interface IOpenWearables {

    struct WearableData {
        string name;
        bytes rleData;
        string[] palette;
        uint256 gridSize;
    }

    struct WearableRef {
        address contractAddress;
        uint256 tokenId;
    }

    function openWearable(uint256 tokenId) external returns (WearableData memory);

    function ownerOf(uint256) external returns (address owner);
    
    // TODO: Add support for ERC1155 balanceOf

}
