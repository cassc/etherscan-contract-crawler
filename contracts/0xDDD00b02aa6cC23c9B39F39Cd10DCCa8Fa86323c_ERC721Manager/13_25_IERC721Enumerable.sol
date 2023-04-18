// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import './IERC165.sol';

/**
 * @dev Required interface of an ERC721Enumerable compliant contract.
 */
interface IERC721Enumerable is IERC165 {
    function totalSupply() external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}