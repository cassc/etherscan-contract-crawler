// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IGoodGuys {
    function balanceOf(address) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}