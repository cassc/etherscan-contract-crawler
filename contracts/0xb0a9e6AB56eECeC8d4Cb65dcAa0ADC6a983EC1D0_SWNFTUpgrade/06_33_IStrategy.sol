//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

/// @title Interface for swETH
interface IStrategy {
    function enter(uint256 tokenId, uint256 amount, bytes memory params)
        external
        returns (uint256 shares);

    function exit(uint256 tokenId, uint256 shares, bytes memory params)
        external
        returns (uint256 amount);

    // ============ Events ============

    event LogEnter(uint256 indexed tokenId, uint256 amount, uint256 shares, bytes params);

    event LogExit(uint256 indexed tokenId, uint256 amount, uint256 shares, bytes params);
}