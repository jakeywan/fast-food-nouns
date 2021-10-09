// SPDX-License-Identifier: GPL-3.0

/// @title The Nouns ERC-721 token

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { INounsDescriptor } from './interfaces/INounsDescriptor.sol';
import { INounsSeeder } from './interfaces/INounsSeeder.sol';
import { INounsToken } from './interfaces/INounsToken.sol';
import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { ERC721Enumerable } from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IProxyRegistry } from './external/opensea/IProxyRegistry.sol';
import { Strings } from './Strings.sol';
import 'hardhat/console.sol';

contract NounsToken is INounsToken, Ownable, ERC721Enumerable {
    using Strings for uint256;

    // Price and maximum number of Fast Food Nouns
    uint256 public price = 30000000000000000;
    uint256 public max_tokens = 1000;
    uint256 public mint_limit= 20;

    // Hat svg
    string public hatSvg = 'PHBhdGggZD0iTTIxMCA3MEg1MFY4MEgyMTBWNzBaIiBmaWxsPSIjRTExODMzIi8+CjxwYXRoIGQ9Ik0xODAgNTBINjBWNjBIMTgwVjUwWiIgZmlsbD0iI0UxMTgzMyIvPgo8cGF0aCBkPSJNMTcwIDQwSDcwVjUwSDE3MFY0MFoiIGZpbGw9IiNFMTE4MzMiLz4KPHBhdGggZD0iTTE3MCAzMEg3MFY0MEgxNzBWMzBaIiBmaWxsPSIjRTExODMzIi8+CjxyZWN0IHdpZHRoPSIxMzAiIGhlaWdodD0iMTAiIHRyYW5zZm9ybT0ibWF0cml4KC0xIDAgMCAxIDE4MCA2MCkiIGZpbGw9IiNCRDJEMjQiLz4KPHBhdGggZD0iTTEyMCA3MEgxMTBWODBIMTIwVjcwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTIwIDcwSDExMFY4MEgxMjBWNzBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xMjAgNzBIMTEwVjgwSDEyMFY3MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTEyMCA3MEgxMTBWODBIMTIwVjcwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTIwIDcwSDExMFY4MEgxMjBWNzBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xMjAgNzBIMTEwVjgwSDEyMFY3MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTEyMCA3MEgxMTBWODBIMTIwVjcwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTIwIDcwSDExMFY4MEgxMjBWNzBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xMjAgNzBIMTEwVjgwSDEyMFY3MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTEyMCA3MEgxMTBWODBIMTIwVjcwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTIwIDYwSDExMFY3MEgxMjBWNjBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xMjAgNjBIMTEwVjcwSDEyMFY2MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTEyMCA2MEgxMTBWNzBIMTIwVjYwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTIwIDYwSDExMFY3MEgxMjBWNjBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xMjAgNjBIMTEwVjcwSDEyMFY2MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTEyMCA2MEgxMTBWNzBIMTIwVjYwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTIwIDYwSDExMFY3MEgxMjBWNjBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xMjAgNjBIMTEwVjcwSDEyMFY2MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTEyMCA2MEgxMTBWNzBIMTIwVjYwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTIwIDYwSDExMFY3MEgxMjBWNjBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xMzAgNTBIMTIwVjYwSDEzMFY1MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTEzMCA1MEgxMjBWNjBIMTMwVjUwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTMwIDUwSDEyMFY2MEgxMzBWNTBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xMzAgNTBIMTIwVjYwSDEzMFY1MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTEzMCA1MEgxMjBWNjBIMTMwVjUwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTMwIDUwSDEyMFY2MEgxMzBWNTBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xMzAgNTBIMTIwVjYwSDEzMFY1MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTEzMCA1MEgxMjBWNjBIMTMwVjUwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTMwIDUwSDEyMFY2MEgxMzBWNTBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xMzAgNTBIMTIwVjYwSDEzMFY1MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE1MCA1MEgxNDBWNjBIMTUwVjUwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTUwIDUwSDE0MFY2MEgxNTBWNTBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNTAgNTBIMTQwVjYwSDE1MFY1MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE1MCA1MEgxNDBWNjBIMTUwVjUwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTUwIDUwSDE0MFY2MEgxNTBWNTBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNTAgNTBIMTQwVjYwSDE1MFY1MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE1MCA1MEgxNDBWNjBIMTUwVjUwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTUwIDUwSDE0MFY2MEgxNTBWNTBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNTAgNTBIMTQwVjYwSDE1MFY1MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE1MCA1MEgxNDBWNjBIMTUwVjUwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTYwIDYwSDE1MFY3MEgxNjBWNjBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNjAgNjBIMTUwVjcwSDE2MFY2MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE2MCA2MEgxNTBWNzBIMTYwVjYwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTYwIDYwSDE1MFY3MEgxNjBWNjBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNjAgNjBIMTUwVjcwSDE2MFY2MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE2MCA2MEgxNTBWNzBIMTYwVjYwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTYwIDYwSDE1MFY3MEgxNjBWNjBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNjAgNjBIMTUwVjcwSDE2MFY2MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE2MCA2MEgxNTBWNzBIMTYwVjYwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTYwIDYwSDE1MFY3MEgxNjBWNjBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNjAgNzBIMTUwVjgwSDE2MFY3MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE2MCA3MEgxNTBWODBIMTYwVjcwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTYwIDcwSDE1MFY4MEgxNjBWNzBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNjAgNzBIMTUwVjgwSDE2MFY3MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE2MCA3MEgxNTBWODBIMTYwVjcwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTYwIDcwSDE1MFY4MEgxNjBWNzBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNjAgNzBIMTUwVjgwSDE2MFY3MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE2MCA3MEgxNTBWODBIMTYwVjcwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTYwIDcwSDE1MFY4MEgxNjBWNzBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNjAgNzBIMTUwVjgwSDE2MFY3MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE1MCA3MEgxNDBWODBIMTUwVjcwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTUwIDcwSDE0MFY4MEgxNTBWNzBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNTAgNzBIMTQwVjgwSDE1MFY3MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE1MCA3MEgxNDBWODBIMTUwVjcwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTUwIDcwSDE0MFY4MEgxNTBWNzBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNTAgNzBIMTQwVjgwSDE1MFY3MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE1MCA3MEgxNDBWODBIMTUwVjcwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTUwIDcwSDE0MFY4MEgxNTBWNzBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNTAgNzBIMTQwVjgwSDE1MFY3MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE1MCA3MEgxNDBWODBIMTUwVjcwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTQwIDcwSDEzMFY4MEgxNDBWNzBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNDAgNzBIMTMwVjgwSDE0MFY3MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE0MCA3MEgxMzBWODBIMTQwVjcwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTQwIDcwSDEzMFY4MEgxNDBWNzBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNDAgNzBIMTMwVjgwSDE0MFY3MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE0MCA3MEgxMzBWODBIMTQwVjcwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTQwIDcwSDEzMFY4MEgxNDBWNzBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNDAgNzBIMTMwVjgwSDE0MFY3MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE0MCA3MEgxMzBWODBIMTQwVjcwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTQwIDcwSDEzMFY4MEgxNDBWNzBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xMzAgNzBIMTIwVjgwSDEzMFY3MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTEzMCA3MEgxMjBWODBIMTMwVjcwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTMwIDcwSDEyMFY4MEgxMzBWNzBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xMzAgNzBIMTIwVjgwSDEzMFY3MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTEzMCA3MEgxMjBWODBIMTMwVjcwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTMwIDcwSDEyMFY4MEgxMzBWNzBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xMzAgNzBIMTIwVjgwSDEzMFY3MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTEzMCA3MEgxMjBWODBIMTMwVjcwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTMwIDcwSDEyMFY4MEgxMzBWNzBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xMzAgNzBIMTIwVjgwSDEzMFY3MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE0MCA2MEgxMzBWNzBIMTQwVjYwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTQwIDYwSDEzMFY3MEgxNDBWNjBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNDAgNjBIMTMwVjcwSDE0MFY2MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE0MCA2MEgxMzBWNzBIMTQwVjYwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTQwIDYwSDEzMFY3MEgxNDBWNjBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNDAgNjBIMTMwVjcwSDE0MFY2MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE0MCA2MEgxMzBWNzBIMTQwVjYwWiIgZmlsbD0iI0VFRDgxMSIvPgo8cGF0aCBkPSJNMTQwIDYwSDEzMFY3MEgxNDBWNjBaIiBmaWxsPSIjRUVEODExIi8+CjxwYXRoIGQ9Ik0xNDAgNjBIMTMwVjcwSDE0MFY2MFoiIGZpbGw9IiNFRUQ4MTEiLz4KPHBhdGggZD0iTTE0MCA2MEgxMzBWNzBIMTQwVjYwWiIgZmlsbD0iI0VFRDgxMSIvPg';

    // Store custom descriptions for GOOPs
    mapping (uint => string) public customDescription;

    // The Nouns token URI descriptor
    INounsDescriptor public descriptor;

    // The Nouns token seeder
    INounsSeeder public seeder;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;

    // Whether the seeder can be updated
    bool public isSeederLocked;

    // The noun seeds
    mapping(uint256 => INounsSeeder.Seed) public seeds;

    // The internal noun ID tracker
    uint256 private _currentNounId;

    // IPFS content hash of contract-level metadata
    string private _contractURIHash = '';

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    // TODO: add withdraw addresses

    // Sale Status
    // TODO: set this to default false
    bool public sale_active = true;

    /**
     * @notice Require that the descriptor has not been locked.
     */
    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, 'Descriptor is locked');
        _;
    }

    /**
     * @notice Require that the seeder has not been locked.
     */
    modifier whenSeederNotLocked() {
        require(!isSeederLocked, 'Seeder is locked');
        _;
    }

    /**
     * @notice Set a custom description for a Noun token on-chain that will display on OpenSea and other sites.
     * Takes the format of "Noun [tokenId] is a [....]"
     * May be modified at any time
     * Send empty string to revert to default.
     * @dev Only callable by the holder of the token.
     */
    function setCustomDescription (uint256 tokenId, string calldata _description) external returns (string memory){
        require (msg.sender == ownerOf(tokenId), "not your Noun");
        customDescription[tokenId] = _description;
        string memory returnMessage = string(abi.encodePacked("Description set to: " , viewDescription(tokenId)));
        return returnMessage;
    }

    function viewDescription (uint256 tokenId) public view returns (string memory){
        string memory description = "";
        string memory NounID = tokenId.toString();

        if (bytes(customDescription[tokenId]).length != 0)
        {
            description = string(abi.encodePacked(description,'Noun ', NounID, ' is a ', customDescription[tokenId]));
        }
        else
        {
            description = string(abi.encodePacked(description,'Noun ', NounID, ' is a fast food worker.'));
        }
        return description;
    }

    constructor(address _descriptor) ERC721('Fast Food Nouns', 'FFN') {
        // We're using our own descriptor. That contract is deployed, then the
        // address is passed here as a param.
        descriptor = INounsDescriptor(_descriptor);

        // MAINNET
        seeder = INounsSeeder(0xCC8a0FB5ab3C7132c1b2A0109142Fb112c4Ce515);
        // RINKEBY
        // seeder = INounsSeeder(0xA98A1b1Cc4f5746A753167BAf8e0C26AcBe42F2E);

        proxyRegistry = IProxyRegistry(0xa5409ec958C83C3f309868babACA7c86DCB077c1);
    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }

    function toggleSale() external onlyOwner {
        sale_active=!sale_active;
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice Mint Nouns to sender
     */
    function mint(uint256 num_tokens) external override payable {

        require (sale_active,"sale not active");

        require (num_tokens<=mint_limit,"minted too many");

        require(num_tokens+totalSupply()<=max_tokens,"exceeds maximum tokens");

        require(msg.value>=num_tokens*price,"not enough ethers sent");

        for (uint256 x=0;x<num_tokens;x++)
        {
            _mintTo(msg.sender, _currentNounId++);
        }
    }

    /**
     * @notice Burn a noun.
     */
    function burn(uint256 nounId) public override onlyOwner {
        _burn(nounId);
        emit NounBurned(nounId);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'NounsToken: URI query for nonexistent token');
        string memory NounID = tokenId.toString();
        string memory name = string(abi.encodePacked('Fast Food Noun ', NounID)); 
        string memory description = viewDescription(tokenId);
        return descriptor.genericDataURI(name, description, seeds[tokenId]);
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(INounsDescriptor _descriptor) external override onlyOwner whenDescriptorNotLocked {
        descriptor = _descriptor;

        emit DescriptorUpdated(_descriptor);
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor() external override onlyOwner whenDescriptorNotLocked {
        isDescriptorLocked = true;

        emit DescriptorLocked();
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(INounsSeeder _seeder) external override onlyOwner whenSeederNotLocked {
        seeder = _seeder;

        emit SeederUpdated(_seeder);
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external override onlyOwner whenSeederNotLocked {
        isSeederLocked = true;

        emit SeederLocked();
    }

    /**
     * @notice Mint a Noun with `nounId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 nounId) internal returns (uint256) {
        // IMPORTANT: Must be the Nouns descriptor, not the Fast Food
        // descriptor, because the `generateSeed` function counts the available
        // body part types before determining random seeds for them.
        // MAINNET
        INounsDescriptor nounsDescriptor = INounsDescriptor(0x0Cfdb3Ba1694c2bb2CFACB0339ad7b1Ae5932B63);
        // RINKEBY
        // INounsDescriptor nounsDescriptor = INounsDescriptor(0x53cB482c73655D2287AE3282AD1395F82e6a402F);

        INounsSeeder.Seed memory seed = seeds[nounId] = seeder.generateSeed(nounId, nounsDescriptor);
        _mint(to, nounId);
        emit NounCreated(nounId, seed);

        return nounId;
    }

}
