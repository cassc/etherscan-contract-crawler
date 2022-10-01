// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface IPresaled {

    function mint(address to, uint amount, uint package) external;

    function burn(uint256[] memory tokenIdList) external;

    function getPresaledOwner(address owner) external view returns (uint[] memory);

    function getMintedTimestamp(uint tokenId) external view returns (uint);

    function getPresaledPackage(uint tokenId) external view returns (uint);

    function transferOwnership(address owner) external;

    function setBaseURI(string memory baseURI_) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);

}