// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

import {StrategyVaultSettings} from "./BalancerVaultTypes.sol";
import {IERC20} from "../../../interfaces/IERC20.sol";

library BalancerEvents {
    event RewardReinvested(address token, uint256 primaryAmount, uint256 secondaryAmount, uint256 bptAmount);
    event VaultSettlement(
        uint256 maturity,
        uint256 bptToSettle,
        uint256 strategyTokensRedeemed
    );

    event EmergencyVaultSettlement(
        uint256 maturity,
        uint256 bptToSettle,
        uint256 redeemStrategyTokenAmount
    );

    event StrategyVaultSettingsUpdated(StrategyVaultSettings settings);

    event ClaimedRewardTokens(IERC20[] rewardTokens, uint256[] claimedBalances);
}