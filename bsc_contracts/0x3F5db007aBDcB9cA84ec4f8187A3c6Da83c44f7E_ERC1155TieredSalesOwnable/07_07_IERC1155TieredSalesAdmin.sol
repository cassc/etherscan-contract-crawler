// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC1155TieredSalesAdmin {
    function configureTierTokenId(uint256 tierId, uint256 tokenId) external;

    function configureTierTokenId(uint256[] calldata tierIds, uint256[] calldata tokenIds) external;
}