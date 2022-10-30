// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {AuraStakingContext} from "../../BalancerVaultTypes.sol";

library AuraStakingUtils {
    function _isValidRewardToken(AuraStakingContext memory context, address token)
        internal pure returns (bool) {
        uint256 len = context.rewardTokens.length;
        for (uint256 i; i < len; i++) {
            if (address(context.rewardTokens[i]) == token) return true;
        }
        return false;
    }
}