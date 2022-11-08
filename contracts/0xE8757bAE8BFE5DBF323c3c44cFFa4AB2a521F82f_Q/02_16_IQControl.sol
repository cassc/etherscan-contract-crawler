// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IQControl {

    function maxSupply() external returns (uint);

    function maxMintsPerWallet() external returns (uint);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function setEmoji(uint tokenId, string memory emoji) external;

    function setName(uint tokenId, string memory name) external;

    function canMint(uint256 totalSupply, uint8 numToMint) external;

    function getNumReserved() external returns (uint8 numReserved);

    function setReserved(uint8 remainder) external;

    function minted(address _receiver, uint tokenId) external;

    function setStarted(bool state) external;

    function controlBeforeTokenTransfer(address from, address to, uint256 tokenId) external;

}