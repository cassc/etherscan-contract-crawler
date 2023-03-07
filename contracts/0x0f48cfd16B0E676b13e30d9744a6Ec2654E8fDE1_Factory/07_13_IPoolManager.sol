// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

interface IPoolManager {
    function addPool(address _gauge) external returns (bool);
}