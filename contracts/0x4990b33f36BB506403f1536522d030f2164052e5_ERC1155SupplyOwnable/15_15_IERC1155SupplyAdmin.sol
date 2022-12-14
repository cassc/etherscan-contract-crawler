// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC1155SupplyAdmin {
    error ErrMaxSupplyFrozen();

    function setMaxSupply(uint256 tokenId, uint256 newValue) external;

    function setMaxSupplyBatch(uint256[] calldata tokenIds, uint256[] calldata newValues) external;

    function freezeMaxSupply(uint256 tokenId) external;

    function freezeMaxSupplyBatch(uint256[] calldata tokenIds) external;
}