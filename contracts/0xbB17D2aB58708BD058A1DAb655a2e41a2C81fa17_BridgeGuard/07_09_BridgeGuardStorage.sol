// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { IBridgeGuardTypes } from "./interfaces/IBridgeGuardTypes.sol";

/**
 * @title BridgeGuard contract storage
 * @author CloudWalk Inc.
 */
abstract contract BridgeGuardStorage is IBridgeGuardTypes {
    /// @dev The address of the bride contract.
    address internal _bridge;

    /// @dev The mapping of guard details for a given chain id and token.
    mapping(uint256 => mapping(address => Guard)) internal _accommodationGuards;
}