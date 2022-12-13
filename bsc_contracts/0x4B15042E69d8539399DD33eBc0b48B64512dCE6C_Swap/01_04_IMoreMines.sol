//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IMoreMines {
    function isReferrer(uint256) external view returns (uint256);

    function getAllOwned(address owner) external view returns(uint32[] memory);
    function ownerOf(uint256 tokenID) external view returns(address);
}