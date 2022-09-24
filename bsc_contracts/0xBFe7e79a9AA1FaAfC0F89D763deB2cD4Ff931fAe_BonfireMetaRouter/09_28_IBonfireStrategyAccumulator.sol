// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

interface IBonfireStrategyAccumulator {
    function tokenRegistered(address token)
        external
        view
        returns (bool registered);

    function quote(address token, uint256 threshold)
        external
        view
        returns (uint256 expectedGains);

    function execute(
        address token,
        uint256 threshold,
        uint256 deadline,
        address to
    ) external returns (uint256 gains);
}