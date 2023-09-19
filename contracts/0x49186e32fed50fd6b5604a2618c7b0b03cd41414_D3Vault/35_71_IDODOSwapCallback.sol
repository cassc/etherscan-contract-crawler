/*
    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

interface IDODOSwapCallback {
    function d3MMSwapCallBack(address token, uint256 value, bytes calldata data) external;
}