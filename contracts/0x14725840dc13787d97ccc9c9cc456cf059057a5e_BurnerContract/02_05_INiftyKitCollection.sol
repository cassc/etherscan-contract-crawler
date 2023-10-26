// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
interface INiftyKitCollection {
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
}