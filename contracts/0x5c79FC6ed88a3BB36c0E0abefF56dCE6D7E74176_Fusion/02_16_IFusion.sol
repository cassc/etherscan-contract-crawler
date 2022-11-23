// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IFusion {
    function setBaseURI(string memory baseURI_) external;

    function mint(address recipient, uint256 tokenId) external;

    function setOperators(address[] calldata users, bool remove) external;

    function burn(uint256 tokenId) external;
}