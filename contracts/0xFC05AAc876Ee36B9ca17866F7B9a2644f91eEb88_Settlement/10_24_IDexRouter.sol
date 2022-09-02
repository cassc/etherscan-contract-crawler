//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Types.sol";

/**
 * Abstraction of DEX integration with simple fill function.
 */
interface IDexRouter {

    /**
     * Fill an order using the given call data details.
     */
    function fill(Types.Order memory order, bytes calldata swapData) external returns (bool status, string memory failReason);
}