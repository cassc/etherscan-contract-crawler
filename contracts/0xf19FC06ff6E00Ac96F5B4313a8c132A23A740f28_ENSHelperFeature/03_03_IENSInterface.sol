// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IENSToken {
    function baseNode() external view returns (bytes32);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function available(uint256 id) external view returns (bool);
}

interface IENS {
    function resolver(bytes32 node) external view returns (address);
}

interface IENSResolver {
    function addr(bytes32 node) external view returns (address);

    function name(bytes32 node) external view returns (bytes memory);
}