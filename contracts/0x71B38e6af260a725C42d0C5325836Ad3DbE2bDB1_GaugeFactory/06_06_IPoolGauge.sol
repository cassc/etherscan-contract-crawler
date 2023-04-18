// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface IPoolGauge {
    function initialize(address _lpAddr, address _minter, address _permit2Address, address _owner) external;
}