/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity ^0.8.16;

interface IDODOLiquidator {
    function liquidate(
        address sender,
        address[] calldata tokens,
        uint256[] calldata balances,
        uint256[] calldata debts
    ) external;
}