// SPDX-License-Identifier: UNLICENCED
// Copyright 2021; All rights reserved
// Author: @divergenceharri (@divergence_art)

pragma solidity >=0.8.9 <0.9.0;

/// @title Every Icon Contract (Repository Interface)
/// @notice A common interface for the 4 Every Icon repositories.
interface IEveryIconRepository {
    function icon(uint256) external view returns (uint256[4] memory);
}