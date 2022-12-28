// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IREWardSplitter.sol";
import "./Base/ISelfStakingERC20.sol";
import "./Base/UpgradeableBase.sol";

/**
    When we dump USDC rewards into the system, it needs to be split
    between REYIELD holders.  But we don't want people to have to
    repeatedly claim REYIELD from the curve gauge in order to not
    miss out on rewards.

    So, this will split the USDC proportionally

    Curve gauges distribute rewards over 1 week, so we match that.

    Wild fluctuations in curve liquidity may result in either
    curve or REYIELD being slightly more profitable to participate
    in, but it should be minor, and average itself out.  If it's
    genuinely a problem, we can mitigate it by adding rewards
    more frequently
 */
contract REWardSplitter is UpgradeableBase(1), IREWardSplitter
{
    bool public constant isREWardSplitter = true;

    function approve(IERC20 rewardToken, address[] memory targets)
        public
        onlyOwner
    {
        for (uint256 x = targets.length; x > 0;)
        {
            rewardToken.approve(targets[--x], type(uint256).max);
        }
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREWardSplitter(newImplementation).isREWardSplitter());
    }

    function splitRewards(uint256 amount, ISelfStakingERC20 selfStakingERC20, ICurveGauge[] calldata gauges)
        public
        view 
        returns (uint256 selfStakingERC20Amount, uint256[] memory gaugeAmounts)
    {
        /*
            Goal:  Split REYIELD rewards between REYIELD holders and the gauge

            Total effective staked = totalStakingSupply + balanceOf(gauges)

            Quirk:  We want to calculate how much REYIELD is in a gauge which
            is eligible for staking.  This is the amount being distributed by
            the gauge, including funds waiting for users to claim via
            claim_rewards, plus the amount yet to be distributed over the next
            week.  We're using balanceOf(gauge) to get that number.  However,
            if someone simply transfers REYIELD to the gauge (ie, without
            calling deposit_reward_token), then the gauge will not distribute
            those tokens and our reward estimation is forevermore increased
            (although there are ways to mitigate).  ...But, let's just say
            "that's okay", and call it a feature "how to donate your REYIELD
            to boost curve rewards for everyone else".  No problem.
        */
        uint256 totalEffectiveSupply = selfStakingERC20.totalStakingSupply();
        gaugeAmounts = new uint256[](gauges.length);
        selfStakingERC20Amount = amount;
        for (uint256 x = gauges.length; x > 0;)
        {
            ICurveGauge gauge = gauges[--x];
            if (!selfStakingERC20.isExcluded(address(gauge))) { revert GaugeNotExcluded(); }
            uint256 gaugeAmount = selfStakingERC20.balanceOf(address(gauge));
            gaugeAmounts[x] = gaugeAmount;
            totalEffectiveSupply += gaugeAmount;            
        }
        if (totalEffectiveSupply != 0)
        {
            for (uint256 x = gauges.length; x > 0;)
            {
                uint256 gaugeAmount = amount * gaugeAmounts[--x] / totalEffectiveSupply;
                gaugeAmounts[x] = gaugeAmount;
                selfStakingERC20Amount -= gaugeAmount;
            }
        }
    }

    function addReward(uint256 amount, ISelfStakingERC20 selfStakingERC20, ICurveGauge[] calldata gauges)
        public
        onlyOwner
    {
        (uint256 selfStakingERC20Amount, uint256[] memory gaugeAmounts) = splitRewards(amount, selfStakingERC20, gauges);
        IERC20 rewardToken = selfStakingERC20.rewardToken();
        rewardToken.transferFrom(msg.sender, address(this), amount);
        if (selfStakingERC20Amount > 0)
        {
            selfStakingERC20.addReward(selfStakingERC20Amount, block.timestamp, block.timestamp + 60 * 60 * 24 * 7); 
        }
        for (uint256 x = gauges.length; x > 0;)
        {
            uint256 gaugeAmount = gaugeAmounts[--x];
            if (gaugeAmount > 0)
            {
                gauges[x].deposit_reward_token(address(rewardToken), gaugeAmount);
            }
        }
    }

    function addRewardPermit(uint256 amount, ISelfStakingERC20 selfStakingERC20, ICurveGauge[] calldata gauges, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
    {
        IERC20Permit(address(selfStakingERC20.rewardToken())).permit(msg.sender, address(this), permitAmount, deadline, v, r, s);
        addReward(amount, selfStakingERC20, gauges);
    }
}