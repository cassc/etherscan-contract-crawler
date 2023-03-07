// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Base64.sol";
import "./ICheckDescriptor.sol";

contract CheckDescriptor is ICheckDescriptor {
    uint base = 1000000;
    uint layers = 5;
    function tokenURI(string memory tokenId, string memory seed) external pure returns (string memory) {
        bytes memory svg = abi.encodePacked(
            '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg">',
            '<rect width="100%" height="100%" fill="#121212"/>',
            '<text x="160" y="130" font-family="Courier,monospace" font-weight="700" font-size="20" text-anchor="middle" letter-spacing="1">',
            '<tspan fill="#', substring(seed, 60, 65),'">-------</tspan>',
            '<tspan dy="20" x="160" fill="#', substring(seed, 54, 59),'">/...../.\\</tspan>',
            '<tspan dy="25" x="160" fill="#', substring(seed, 48, 53),'">|...../...|</tspan>',
            '<tspan dy="25" x="160" fill="#', substring(seed, 42, 47),'">\\..\\/.../</tspan>',
            '<tspan dy="22" x="160" fill="#', substring(seed, 36, 41),'">-------</tspan>',
            '</text></svg>'
        );
        string memory img = string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(svg)
            )    
        );
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "Checkscii #', tokenId, '",',
                '"description": "Randomly generated on-chain Checks!",',
                '"image": "', img, '"',
                ', "attributes": [',
                '{"trait_type" : "Layer #1", "value": "', substring(seed, 60, 65),'"}, {"trait_type" : "Layer #2", "value": "', substring(seed, 54, 59),'"}, '
                '{"trait_type" : "Layer #3", "value": "', substring(seed, 48, 53),'"}, {"trait_type" : "Layer #4", "value": "', substring(seed, 42, 47),'"}, {"trait_type" : "Layer #5", "value": "', substring(seed, 36, 41),'"}]'
            '}'
        );
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    function substring(string memory str, uint startIndex, uint endIndex) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(startIndex < strBytes.length && endIndex < strBytes.length, "Index out of range");
        require(endIndex >= startIndex, "Invalid index range");
        bytes memory result = new bytes(endIndex - startIndex + 1);
        for (uint i = startIndex; i <= endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }      
}