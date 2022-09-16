// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./POAPLibrary.sol";

interface IAnonymiceBadges {
    function totalSupply() external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function getAllPOAPs(address wallet) external view returns (uint256[] memory);

    function getBoardPOAPs(address wallet) external view returns (uint256[] memory);

    function currentBoard(address wallet) external view returns (uint256);

    function boardNames(address wallet) external view returns (string memory);

    function getBoard(uint256 boardId) external view returns (POAPLibrary.Board memory);

    function externalClaimPOAP(uint256 id, address to) external;
}