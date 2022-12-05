// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

struct MetadataAttribute {
    bytes trait;
    bytes value;
}

interface IMetadataStore {
    function addAttribute(bytes32 key, bytes memory trait, bytes memory value) external;
    function readAttribute(bytes32 key) external view returns (MetadataAttribute memory);
    function addImage(bytes32 key, bytes memory image, bytes memory animation) external;
    function readImage(bytes32 key) external view returns (bytes memory, bytes memory);
}