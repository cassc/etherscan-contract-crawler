// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface CurveGEARETHPool {
    function balances(uint256 i) external view returns (uint256 balance);
}

address constant curvePool = 0x0E9B5B092caD6F1c5E6bc7f89Ffe1abb5c95F1C2;
address constant curveGauge = 0x37Efc3f05D659B30A83cf0B07522C9d08513Ca9d;
address constant curveLP = 0x5Be6C45e2d074fAa20700C49aDA3E88a1cc0025d;
address constant convexRewardPool = 0x502Cc0d946e79CeA4DaafCf21F374C6bce763067;
address constant convexGear = 0x989AEb4d175e16225E39E87d0D97A3360524AD80;

contract CurveSnapshotVoting {
    /// @dev Returns voting power of Curve LP + Curve Gauge + Convex Staking
    /// @param holder address to get voting
    function balanceOf(address holder) external view returns (uint256) {
        uint256 tokens = CurveGEARETHPool(curvePool).balances(0);
        uint256 totalSupply = IERC20(curveLP).totalSupply();

        uint256 balance = holder == convexGear
            ? 0
            : IERC20(curveGauge).balanceOf(holder) + IERC20(curveLP).balanceOf(holder)
                + IERC20(convexRewardPool).balanceOf(holder);

        return balance * tokens / totalSupply;
    }
}