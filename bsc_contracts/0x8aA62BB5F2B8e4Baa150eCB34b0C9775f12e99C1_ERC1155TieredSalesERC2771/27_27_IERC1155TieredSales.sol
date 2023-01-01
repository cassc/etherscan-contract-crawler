// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC1155TieredSales {
    function tierToTokenId(uint256 tierId) external view returns (uint256);

    function tierToTokenId(uint256[] calldata tierIds) external view returns (uint256[] memory);
}