// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IRewarderFactory {
    function newRewarder(
        address _operator,
        address _currency,
        address _pool
    ) external returns (address);
}