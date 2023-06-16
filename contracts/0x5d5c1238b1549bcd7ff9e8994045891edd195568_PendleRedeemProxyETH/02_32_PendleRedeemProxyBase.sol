// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;
pragma abicoder v2;

import "../interfaces/IPendleRouter.sol";
import "../interfaces/IPendleForge.sol";
import "../core/abstract/PendleLiquidityMiningBase.sol";
import "../interfaces/IPendleLiquidityMiningV2.sol";
import "../interfaces/IPendleYieldToken.sol";
import "../interfaces/IPendleRewardManager.sol";
import "../interfaces/IPendleRewardManagerV2.sol";
import "hardhat/console.sol";

struct OtRewards {
    uint256 amountRewardOne;
    uint256 amountRewardTwo;
}

struct Args {
    address[] xyts;
    address[] ots;
    address[] markets;
    address[] lmContractsForRewards;
    uint256[] expiriesForRewards;
    address[] lmContractsForInterests;
    uint256[] expiriesForInterests;
    address[] lmV2ContractsForRewards;
    address[] lmV2ContractsForInterests;
}

abstract contract PendleRedeemProxyBase {
    IPendleRouter public immutable router;

    constructor(address _router) {
        require(_router != address(0), "ZERO_ADDRESS");
        router = IPendleRouter(_router);
    }

    function redeem(Args calldata args, address user)
        external
        returns (
            uint256[] memory xytInterests,
            OtRewards[] memory otRewards,
            uint256[] memory marketInterests,
            uint256[] memory lmRewards,
            string[] memory lmRewardsFailureReasons,
            uint256[] memory lmInterests,
            string[] memory lmInterestsFailureReasons,
            uint256[] memory lmV2Rewards,
            uint256[] memory lmV2Interests
        )
    {
        xytInterests = redeemXyts(args.xyts);
        otRewards = redeemOts(args.ots);
        marketInterests = redeemMarkets(args.markets);

        (lmRewards, lmRewardsFailureReasons) = redeemLmRewards(
            args.lmContractsForRewards,
            args.expiriesForRewards,
            user
        );

        (lmInterests, lmInterestsFailureReasons) = redeemLmInterests(
            args.lmContractsForInterests,
            args.expiriesForInterests,
            user
        );

        lmV2Rewards = redeemLmV2Rewards(args.lmV2ContractsForRewards, user);

        lmV2Interests = redeemLmV2Interests(args.lmV2ContractsForInterests, user);
    }

    function redeemXyts(address[] calldata xyts) public returns (uint256[] memory xytInterests) {
        xytInterests = new uint256[](xyts.length);
        for (uint256 i = 0; i < xyts.length; i++) {
            IPendleYieldToken xyt = IPendleYieldToken(xyts[i]);
            bytes32 forgeId = IPendleForge(xyt.forge()).forgeId();
            address underlyingAsset = xyt.underlyingAsset();
            uint256 expiry = xyt.expiry();
            xytInterests[i] = router.redeemDueInterests(
                forgeId,
                underlyingAsset,
                expiry,
                msg.sender
            );
        }
    }

    function redeemOts(address[] calldata ots) public returns (OtRewards[] memory otRewards) {
        otRewards = new OtRewards[](ots.length);
        for (uint256 i = 0; i < ots.length; i++) {
            IPendleYieldToken ot = IPendleYieldToken(ots[i]);
            IPendleForge forge = IPendleForge(ot.forge());
            address rewardManager = address(forge.rewardManager());
            address underlyingAsset = ot.underlyingAsset();
            uint256 expiry = ot.expiry();
            otRewards[i] = _redeemFromRewardManager(
                rewardManager,
                underlyingAsset,
                expiry,
                msg.sender
            );
        }
    }

    function redeemMarkets(address[] calldata markets)
        public
        returns (uint256[] memory marketInterests)
    {
        uint256 marketCount = markets.length;
        marketInterests = new uint256[](marketCount);
        for (uint256 i = 0; i < marketCount; i++) {
            marketInterests[i] = router.redeemLpInterests(markets[i], msg.sender);
        }
    }

    function redeemLmRewards(
        address[] calldata lmContractsForRewards,
        uint256[] calldata expiriesForRewards,
        address user
    ) public returns (uint256[] memory lmRewards, string[] memory failureReasons) {
        uint256 count = expiriesForRewards.length;
        require(count == lmContractsForRewards.length, "ARRAY_LENGTH_MISMATCH");

        lmRewards = new uint256[](count);
        failureReasons = new string[](count);
        for (uint256 i = 0; i < count; i++) {
            try
                PendleLiquidityMiningBase(lmContractsForRewards[i]).redeemRewards(
                    expiriesForRewards[i],
                    user
                )
            returns (uint256 lmReward) {
                lmRewards[i] = lmReward;
                failureReasons[i] = "";
            } catch Error(string memory reason) {
                lmRewards[i] = 0;
                failureReasons[i] = reason;
            }
        }
    }

    function redeemLmInterests(
        address[] calldata lmContractsForInterests,
        uint256[] calldata expiriesForInterests,
        address user
    ) public returns (uint256[] memory lmInterests, string[] memory failureReasons) {
        uint256 count = expiriesForInterests.length;
        require(count == lmContractsForInterests.length, "ARRAY_LENGTH_MISMATCH");

        lmInterests = new uint256[](count);
        failureReasons = new string[](count);
        for (uint256 i = 0; i < count; i++) {
            try
                IPendleLiquidityMining(lmContractsForInterests[i]).redeemLpInterests(
                    expiriesForInterests[i],
                    user
                )
            returns (uint256 lmInterest) {
                lmInterests[i] = lmInterest;
                failureReasons[i] = "";
            } catch Error(string memory reason) {
                lmInterests[i] = 0;
                failureReasons[i] = reason;
            }
        }
    }

    function redeemLmV2Rewards(address[] calldata lmV2ContractsForRewards, address user)
        public
        returns (uint256[] memory lmV2Rewards)
    {
        uint256 count = lmV2ContractsForRewards.length;

        lmV2Rewards = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            lmV2Rewards[i] = IPendleLiquidityMiningV2(lmV2ContractsForRewards[i]).redeemRewards(
                user
            );
        }
    }

    function redeemLmV2Interests(address[] calldata lmV2ContractsForInterests, address user)
        public
        returns (uint256[] memory lmV2Interests)
    {
        uint256 count = lmV2ContractsForInterests.length;

        lmV2Interests = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            lmV2Interests[i] = IPendleLiquidityMiningV2(lmV2ContractsForInterests[i])
                .redeemDueInterests(user);
        }
    }

    function _redeemFromRewardManager(
        address rewardManager,
        address underlyingAsset,
        uint256 expiry,
        address to
    ) internal virtual returns (OtRewards memory);
}