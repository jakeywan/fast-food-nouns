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
        string innerSVG;
        uint256 size;
    }

    struct WearableRef {
        address contractAddress;
        uint256 tokenId;
    }

    function getWearable(uint256 tokenId, address owner) external returns (WearableData memory);

    function ownerOf(uint256) external returns (address owner);

    function balanceOf(address,uint256) external returns (uint256);

    function supportsInterface(bytes4) external returns (bool);
    
}
