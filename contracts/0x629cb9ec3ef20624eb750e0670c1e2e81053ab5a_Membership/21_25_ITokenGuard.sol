// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITokenGuard {
    // erc20 & erc721
    function isAllowed(address operator, address from, address to, uint256 value) external returns (bool);
    // erc1155
    function isAllowed(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts)
        external
        returns (bool);
}