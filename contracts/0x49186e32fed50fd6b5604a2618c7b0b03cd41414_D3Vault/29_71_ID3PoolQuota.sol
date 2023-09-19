/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface ID3PoolQuota {
    function getPoolQuota(address pool, address token) external view returns (uint256);
}