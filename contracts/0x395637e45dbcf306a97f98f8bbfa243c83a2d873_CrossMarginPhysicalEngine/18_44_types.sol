// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../config/types.sol";
import {Balance} from "pomace/config/types.sol";

/**
 * @dev base unit of cross margin account. This is the data stored in the state
 *      storage packing is utilized to save gas.
 * @param shorts an array of short positions
 * @param longs an array of long positions
 * @param collaterals an array of collateral balances
 */
struct CrossMarginAccount {
    Position[] shorts;
    Position[] longs;
    Balance[] collaterals;
}