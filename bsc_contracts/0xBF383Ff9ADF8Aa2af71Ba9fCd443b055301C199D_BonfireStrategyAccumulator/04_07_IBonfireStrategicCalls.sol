// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

interface IBonfireStrategicCalls {
    function token() external view returns (address token);

    function quote() external view returns (uint256 expectedGains);

    function execute(uint256 threshold, address to)
        external
        returns (uint256 gains);
}