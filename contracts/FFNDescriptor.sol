// SPDX-License-Identifier: GPL-3.0

/// @title A custom Fast Food Nouns version of the Nouns descriptor

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
import { INounsSeeder } from './interfaces/INounsSeeder.sol';
import { Base64 } from 'base64-sol/base64.sol';
import 'hardhat/console.sol';

contract FFNDescriptor is Ownable {
    using Strings for uint256;

    // modified. the NounsDescriptor contract. For the main Nouns SVG parts, we're going
    // to fetch them directly from the live contract. Then we're going to insert
    // our hat, and assemble into the base64 encoded tokenURI.
    // MAINNET
    INounsDescriptor public nounDescriptor = INounsDescriptor(0x0Cfdb3Ba1694c2bb2CFACB0339ad7b1Ae5932B63);

    // prettier-ignore
    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    // Noun Color Palettes (Index => Hex Colors)
    mapping(uint8 => string[]) public palettes;

    // Custom Backgrounds (RLE)
    bytes[] public customBackgrounds;

    // Custom Bodies (RLE)
    bytes[] public customBodies;

    // Custom Accessories (RLE)
    bytes[] public customAccessories;

    // Custom Hats (RLE)
    bytes[] public customHats;

    // Custom Glasses (RLE)
    bytes[] public customGlasses;

    // Custom Overlay (RLE)
    bytes[] public customOverlays;

    /**
     * @notice Update the underlying Noun descriptor (in case they change it).
     */
    event NounDescriptorUpdated(INounsDescriptor descriptor);
    function setNounDescriptor(INounsDescriptor _descriptor) external onlyOwner {
        nounDescriptor = _descriptor;
        emit NounDescriptorUpdated(_descriptor);
    }

    /**
     * @notice Get the number of available `customBackgrounds`.
     */
    function customBackgroundCount() external view returns (uint256) {
        return customBackgrounds.length;
    }

    /**
     * @notice Get the number of available `customBodies`.
     */
    function customBodyCount() external view returns (uint256) {
        return customBodies.length;
    }

    /**
     * @notice Get the number of available `customAccessories`.
     */
    function customAccessoryCount() external view returns (uint256) {
        return customAccessories.length;
    }

    /**
     * @notice Get the number of available `customHats`.
     */
    function customHatCount() external view returns (uint256) {
        return customHats.length;
    }

    /**
     * @notice Get the number of available `customGlasses`.
     */
    function customGlassesCount() external view returns (uint256) {
        return customGlasses.length;
    }

    /**
     * @notice Get the number of available `customOverlays`.
     */
    function customOverlayCount() external view returns (uint256) {
        return customOverlays.length;
    }

    /**
     * @notice Add colors to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external onlyOwner {
        require(palettes[paletteIndex].length + newColors.length <= 256, 'Palettes can only hold 256 colors');
        for (uint256 i = 0; i < newColors.length; i++) {
            _addColorToPalette(paletteIndex, newColors[i]);
        }
    }

    /**
     * @notice Batch add custom backgrounds.
     */
    function addManyCustomBackgrounds(bytes[] calldata _backgrounds) external onlyOwner {
        for (uint256 i = 0; i < _backgrounds.length; i++) {
            _addCustomBackground(_backgrounds[i]);
        }
    }

    /**
     * @notice Batch add custom bodies.
     */
    function addManyCustomBodies(bytes[] calldata _bodies) external onlyOwner {
        for (uint256 i = 0; i < _bodies.length; i++) {
            _addCustomBody(_bodies[i]);
        }
    }

    /**
     * @notice Batch add custom accessories.
     */
    function addManyCustomAccessories(bytes[] calldata _accessories) external onlyOwner {
        for (uint256 i = 0; i < _accessories.length; i++) {
            _addCustomAccessory(_accessories[i]);
        }
    }

    /**
     * @notice Batch add custom hats.
     */
    function addManyCustomHats(bytes[] calldata _hats) external onlyOwner {
        for (uint256 i = 0; i < _hats.length; i++) {
            _addCustomHat(_hats[i]);
        }
    }

    /**
     * @notice Batch add custom glasses.
     */
    function addManyCustomGlasses(bytes[] calldata _glasses) external onlyOwner {
        for (uint256 i = 0; i < _glasses.length; i++) {
            _addCustomGlasses(_glasses[i]);
        }
    }

    /**
     * @notice Batch add custom overlays.
     */
    function addManyCustomOverlays(bytes[] calldata _overlays) external onlyOwner {
        for (uint256 i = 0; i < _overlays.length; i++) {
            _addCustomOverlay(_overlays[i]);
        }
    }

    /**
     * @notice Add a single color to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addColorToPalette(uint8 _paletteIndex, string calldata _color) external onlyOwner {
        require(palettes[_paletteIndex].length <= 255, 'Palettes can only hold 256 colors');
        _addColorToPalette(_paletteIndex, _color);
    }

    /**
     * @notice Add custom background.
     */
    function addCustomBackground(bytes calldata _background) external onlyOwner {
        _addCustomBackground(_background);
    }

    /**
     * @notice Add custom body.
     */
    function addCustomBody(bytes calldata _body) external onlyOwner {
        _addCustomBody(_body);
    }

    /**
     * @notice Add custom accessory.
     */
    function addCustomAccessory(bytes calldata _accessory) external onlyOwner {
        _addCustomAccessory(_accessory);
    }

    /**
     * @notice Add custom hat.
     */
    function addCustomHat(bytes calldata _hat) external onlyOwner {
        _addCustomHat(_hat);
    }

    /**
     * @notice Add custom hat.
     */
    function addCustomGlasses(bytes calldata _glasses) external onlyOwner {
        _addCustomGlasses(_glasses);
    }

    /**
     * @notice Add custom hat.
     */
    function addCustomOverlay(bytes calldata _overlay) external onlyOwner {
        _addCustomOverlay(_overlay);
    }

    /**
     * @notice Given a token ID and seed, construct a token URI for an official Nouns DAO noun.
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory) {
        return dataURI(tokenId, seed);
    }

    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI for an official Nouns DAO noun.
     */
    function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed) public view returns (string memory) {
        string memory nounId = tokenId.toString();
        string memory name = string(abi.encodePacked('Noun ', nounId));
        string memory description = string(abi.encodePacked('Noun ', nounId, ' is a member of the Nouns DAO'));

        return genericDataURI(name, description, seed);
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(
        string memory name,
        string memory description,
        INounsSeeder.Seed memory seed
    ) public view returns (string memory) {
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
            name: name,
            description: description,
            parts: _getPartsForSeed(seed),
            // modified: point at live Nouns descriptor
            background: nounDescriptor.backgrounds(seed.background)
        });
        return NFTDescriptor.constructTokenURI(params, palettes);
    }

    /**
     * @notice Given a seed, construct a base64 encoded SVG image.
     */
    function generateSVGImage(INounsSeeder.Seed memory seed) external view returns (string memory) {
        MultiPartRLEToSVG.SVGParams memory params = MultiPartRLEToSVG.SVGParams({
            parts: _getPartsForSeed(seed),
            // modified
            background: nounDescriptor.backgrounds(seed.background)
        });
        return NFTDescriptor.generateSVGImage(params, palettes);
    }

    /**
     * @notice Add a single color to a color palette.
     */
    function _addColorToPalette(uint8 _paletteIndex, string calldata _color) internal {
        palettes[_paletteIndex].push(_color);
    }

    /**
     * @notice Add custom background.
     */
    function _addCustomBackground(bytes calldata _background) internal {
        customBackgrounds.push(_background);
    }

    /**
     * @notice Add custom body.
     */
    function _addCustomBody(bytes calldata _body) internal {
        customBodies.push(_body);
    }

    /**
     * @notice Add custom accessory.
     */
    function _addCustomAccessory(bytes calldata _accessory) internal {
        customAccessories.push(_accessory);
    }

    /**
     * @notice Add custom hat.
     */
    function _addCustomHat(bytes calldata _hat) internal {
        customHats.push(_hat);
    }

    /**
     * @notice Add custom glasses.
     */
    function _addCustomGlasses(bytes calldata _glasses) internal {
        customGlasses.push(_glasses);
    }

    /**
     * @notice Add custom overlay (miscellaneous, goes on top of everything).
     */
    function _addCustomOverlay(bytes calldata _overlay) internal {
        customOverlays.push(_overlay);
    }

    /**
     * @notice Get all Noun parts for the passed `seed` plus customizations.
     */
    function _getPartsForSeed(INounsSeeder.Seed memory seed) internal view returns (bytes[] memory) {
        bytes[] memory _parts = new bytes[](4);
        // modified to fetch from nouns descriptor (not internal state)
        _parts[0] = nounDescriptor.bodies(seed.body);
        _parts[1] = nounDescriptor.accessories(seed.accessory);
        _parts[2] = nounDescriptor.heads(seed.head);
        _parts[3] = nounDescriptor.glasses(seed.glasses);
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
    function generateSVG(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        internal
        view
        returns (string memory svg)
    {
        // prettier-ignore
        return string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
                '<rect width="100%" height="100%" fill="#', params.background, '" />',
                _generateSVGRects(params, palettes),
                '</svg>'
            )
        );
    }

    /**
     * @notice Given RLE image parts and color palettes, generate SVG rects.
     */
    // prettier-ignore
    function _generateSVGRects(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
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
        for (uint8 p = 0; p < params.parts.length; p++) {
            DecodedImage memory image = _decodeRLEImage(params.parts[p]);
            string[] storage palette = palettes[image.paletteIndex];
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
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(TokenURIParams memory params, mapping(uint8 => string[]) storage palettes)
        internal
        view
        returns (string memory)
    {
        string memory image = generateSVGImage(
            MultiPartRLEToSVG.SVGParams({ parts: params.parts, background: params.background }),
            // IMPORTANT: you must populate these before you can fetch token URIs
            palettes
        );

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', params.name, '", "description":"', params.description, '", "image": "', 'data:image/svg+xml;base64,', image, '"}')
                    )
                )
            )
        );
    }

    /**
     * @notice Generate an SVG image for use in the ERC721 token URI.
     */
    function generateSVGImage(MultiPartRLEToSVG.SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        internal
        view
        returns (string memory svg)
    {
        return Base64.encode(bytes(MultiPartRLEToSVG.generateSVG(params, palettes)));
    }
}