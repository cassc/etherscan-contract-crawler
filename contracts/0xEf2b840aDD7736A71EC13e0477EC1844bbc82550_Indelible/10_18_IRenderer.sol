// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
    
struct Trait {
    string name;
    string mimetype;
    bool hide;
}

interface IRenderer {
    function hashToMetadata(string memory _hash) external view returns (string memory);
    function hashToSVG(string memory _hash) external view returns (string memory);
    function traitDetails(uint layerIndex, uint traitIndex) external view returns (Trait memory);
    function traitData(uint layerIndex, uint traitIndex) external view returns (bytes memory);
}