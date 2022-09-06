//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

// Polygon ERC20Predicate contract that handles Plasma exits (only used for Matic).
interface IPolygonERC20Predicate {
    function startExitWithBurntTokens(bytes calldata data) external;
}