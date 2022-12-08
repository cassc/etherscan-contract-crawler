// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title MapleLiquidityPositionLibBase1 Contract
/// @author Enzyme Council <[email protected]>
/// @notice A persistent contract containing all required storage variables and
/// required functions for a MapleLiquidityPositionLib implementation
/// @dev DO NOT EDIT CONTRACT. If new events or storage are necessary, they should be added to
/// a numbered MapleLiquidityPositionLibBaseXXX that inherits the previous base.
/// e.g., `MapleLiquidityPositionLibBase2 is MapleLiquidityPositionLibBase1`
abstract contract MapleLiquidityPositionLibBase1 {
    event UsedLendingPoolAdded(address indexed lendingPool);

    event UsedLendingPoolRemoved(address indexed lendingPool);

    address[] internal usedLendingPoolsV1;
}