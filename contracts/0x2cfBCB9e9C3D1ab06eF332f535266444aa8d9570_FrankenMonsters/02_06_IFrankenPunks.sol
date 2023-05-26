// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IFrankenPunks {
    function ownerOf(uint256 tokenId) external view returns(address);
    function balanceOf(address owner) external view returns(uint256);
}