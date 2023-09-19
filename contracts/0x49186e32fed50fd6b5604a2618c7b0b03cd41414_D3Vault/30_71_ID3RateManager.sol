/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface ID3RateManager {
    function getBorrowRate(address token, uint256 utilizationRatio) external view returns (uint256);
}