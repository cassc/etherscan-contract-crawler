// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

abstract contract Token {
    function burn(uint256 tokenId) external virtual;

    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool);
}