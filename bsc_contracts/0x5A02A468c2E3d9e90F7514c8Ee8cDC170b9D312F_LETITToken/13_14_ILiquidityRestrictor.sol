// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ILiquidityRestrictor {
    function assureByAgent(
        address token,
        address from,
        address to
    ) external returns (bool allow, string memory message);

    function assureLiquidityRestrictions(
        address from,
        address to
    ) external returns (bool allow, string memory message);
}