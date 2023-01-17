/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

import "./02_17_SafeMathUpgradeable.sol";
import {Constant} from "./06_17_Constant.sol";
import {ICoverConfig} from "./07_17_ICoverConfig.sol";
import {ICoverData} from "./08_17_ICoverData.sol";
import {Math} from "./05_17_Math.sol";

library CoverLib {
    using SafeMathUpgradeable for uint256;

    function getRewardPctg(address coverCfg, uint256 overwrittenRewardPctg) internal view returns (uint256) {
        return overwrittenRewardPctg > 0 ? overwrittenRewardPctg : ICoverConfig(coverCfg).getInsurTokenRewardPercentX10000();
    }

    function getRewardAmount(uint256 premiumAmount2Insur, uint256 rewardPctg) internal pure returns (uint256) {
        return rewardPctg <= 10000 ? premiumAmount2Insur.mul(rewardPctg).div(10**4) : 0;
    }

    function processCoverOwnerReward(
        address coverData,
        address owner,
        uint256 premiumAmount2Insur,
        uint256 rewardPctg
    ) internal returns (uint256) {
        require(rewardPctg <= 10000, "PCORWD: 1");
        uint256 rewardAmount = getRewardAmount(premiumAmount2Insur, rewardPctg);
        if (rewardAmount > 0) {
            ICoverData(coverData).increaseTotalInsurTokenRewardAmount(rewardAmount);
            ICoverData(coverData).increaseBuyCoverInsurTokenEarned(owner, rewardAmount);
        }
        return rewardAmount;
    }

    function getEarnedPremiumAmount(
        address coverData,
        address owner,
        uint256 coverId,
        uint256 premiumAmount
    ) internal view returns (uint256) {
        return premiumAmount.sub(getUnearnedPremiumAmount(coverData, owner, coverId, premiumAmount));
    }

    function getUnearnedPremiumAmount(
        address coverData,
        address owner,
        uint256 coverId,
        uint256 premiumAmount
    ) internal view returns (uint256) {
        uint256 unearnedPremAmt = premiumAmount;
        uint256 cvAmt = ICoverData(coverData).getCoverAmount(owner, coverId);
        uint256 begin = ICoverData(coverData).getCoverBeginTimestamp(owner, coverId);
        uint256 end = ICoverData(coverData).getCoverEndTimestamp(owner, coverId);
        uint256 claimed = ICoverData(coverData).getCoverClaimedAmount(owner, coverId);
        if (claimed > 0) {
            unearnedPremAmt = unearnedPremAmt.mul(cvAmt.sub(claimed)).div(cvAmt);
        }
        uint256 totalRewardPctg = getTotalRewardPctg(coverData, owner, coverId);
        if (totalRewardPctg > 0) {
            unearnedPremAmt = unearnedPremAmt.mul(uint256(10000).sub(totalRewardPctg)).div(10000);
        }
        uint256 adjustedNowTimestamp = Math.max(block.timestamp, begin); // solhint-disable-line not-rely-on-time
        return unearnedPremAmt.mul(end.sub(adjustedNowTimestamp)).div(end.sub(begin));
    }

    function getTotalRewardPctg(
        address coverData,
        address owner,
        uint256 coverId
    ) internal view returns (uint256) {
        return ICoverData(coverData).getCoverRewardPctg(owner, coverId).add(ICoverData(coverData).getCoverReferralRewardPctg(owner, coverId));
    }
}