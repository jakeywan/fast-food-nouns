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

    // Hat & opening SVG tag
    string public hatSVG = '<rect width="160" height="10" transform="matrix(-1 0 0 1 240 80)" fill="#E11833"/><rect width="120" height="10" transform="matrix(-1 0 0 1 210 60)" fill="#E11833"/><rect width="100" height="10" transform="matrix(-1 0 0 1 200 50)" fill="#E11833"/><rect width="100" height="10" transform="matrix(-1 0 0 1 200 40)" fill="#E11833"/><rect width="130" height="10" transform="matrix(-1 0 0 1 210 70)" fill="#BD2D24"/><rect width="50" height="10" transform="matrix(-1 0 0 1 190 70)" fill="#EED811"/><rect width="10" height="10" transform="matrix(-1 0 0 1 150 60)" fill="#EED811"/><rect width="10" height="10" transform="matrix(-1 0 0 1 160 50)" fill="#EED811"/><rect width="10" height="10" transform="matrix(-1 0 0 1 170 60)" fill="#EED811"/><rect width="10" height="10" transform="matrix(-1 0 0 1 180 50)" fill="#EED811"/><rect width="10" height="10" transform="matrix(-1 0 0 1 190 60)" fill="#EED811"/>';

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

    constructor() ERC721('Fast Food Nouns', 'FFN') {
        // MAINNET
        descriptor = INounsDescriptor(0x0Cfdb3Ba1694c2bb2CFACB0339ad7b1Ae5932B63);
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
        // MODIFY THE SVG
        string memory SVG = descriptor.generateSVGImage(seeds[tokenId]);
        // decode base64 SVG into bytes
        bytes memory decodedSVG = Base64.decode(SVG);
        // remove the SVG closing tag `</svg>`
        string memory substring = removeLastSVGTag(decodedSVG);
        // concatenate existing SVG (minus closing tag), hat, and closing tag
        string memory finalSVG = string(abi.encodePacked(substring, hatSVG, '</svg>'));
        // rencode 
        string memory encodedFinalSVG = Base64.encode(bytes(finalSVG));
        // compose json
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', name, '", "description": "', description, '", "image": "data:image/svg+xml;base64,', encodedFinalSVG, '"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
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
        INounsSeeder.Seed memory seed = seeds[nounId] = seeder.generateSeed(nounId, descriptor);
        _mint(to, nounId);
        emit NounCreated(nounId, seed);

        return nounId;
    }

    // Returns SVG string without the closing tag so we can insert more elements
    function removeLastSVGTag(bytes memory svgBytes) internal pure returns (string memory) {
        bytes memory result = svgBytes;        
        // NOTE: `result` remains the same length as `svgBytes`, but abi.encode
        // seems to ignore the empty bytes at the end of result. so choosing this
        // route over a for loop bc it seems more gas efficient.
        delete result[result.length - 1];
        delete result[result.length - 2];
        delete result[result.length - 3];
        delete result[result.length - 4];
        delete result[result.length - 5];
        delete result[result.length - 6];
        return string(result);
    }

}

/// @title Base64
/// @author Brecht Devos - <brecht@loopring.org>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}