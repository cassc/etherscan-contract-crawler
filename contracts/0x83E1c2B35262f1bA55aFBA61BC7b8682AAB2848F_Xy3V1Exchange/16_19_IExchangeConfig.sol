// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IExchangeConfig {
    event UpdateTarget(address indexed target);
    event UpdateDelegate(address indexed delegate);
    function updateTarget(address _target) external;
    function updateDelegate(address _delegate) external;
}