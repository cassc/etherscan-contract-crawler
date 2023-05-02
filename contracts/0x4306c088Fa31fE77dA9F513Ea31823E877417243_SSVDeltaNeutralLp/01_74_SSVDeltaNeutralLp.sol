// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {StrategyVault} from "src/vaults/locked/StrategyVault.sol";
import {AffineVault} from "src/vaults/AffineVault.sol";
import {DeltaNeutralLp, LpInfo, LendingInfo} from "src/strategies/DeltaNeutralLp.sol";

contract SSVDeltaNeutralLp is DeltaNeutralLp {
    StrategyVault public immutable strategyVault;

    constructor(
        StrategyVault _vault,
        LendingInfo memory lendingInfo,
        LpInfo memory lpInfo,
        address[] memory strategists
    ) DeltaNeutralLp(AffineVault(address(_vault)), lendingInfo, lpInfo, strategists) {
        strategyVault = _vault;
    }

    function startPosition(uint256 assets, uint256 slippageToleranceBps) external override onlyRole(STRATEGIST_ROLE) {
        _startPosition(assets, slippageToleranceBps);
        strategyVault.beginEpoch();
    }

    function endPosition(uint256 slippageToleranceBps) external override onlyRole(STRATEGIST_ROLE) {
        _endPosition(slippageToleranceBps);
        strategyVault.endEpoch();
    }
}