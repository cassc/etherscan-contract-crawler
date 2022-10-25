// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

import "./IOnChainStakingPool.sol";
import "./OnChainStakingPool.sol";
import "./OnChainStaking.Library.sol";
import "../common/OnChOwnableWithWhitelist.sol";

contract OnChainStakingPoolWithReward is OnChainStakingPool {

    address public rewardTokenAddress;
    OnChainStakingLib.OnChainStakingRewardState public rewardState;

    constructor (string memory name_,
        address tokenAddress_,
        address rewardTokenAddress_,
        uint stakingStarts_,
        uint stakingEnds_,
        uint withdrawStarts_,
        uint withdrawEnds_,
        uint256 stakingCap_
    ) OnChainStakingPool (
        name_,
        tokenAddress_,
        stakingStarts_,
        stakingEnds_,
        withdrawStarts_,
        withdrawEnds_,
        stakingCap_
    ) {
        require(rewardTokenAddress_ != address(0), "OnChainStakingPool: 0 reward address");
        rewardTokenAddress = rewardTokenAddress_;
    }

    function changeTimelineConfiguration(uint stakingStarts_, uint stakingEnds_, uint withdrawStarts_, uint withdrawEnds_)
    external whitelistedOnly {

        stakingStarts = stakingStarts_;
        super.setStakingStarts(stakingStarts_);

        stakingEnds = stakingEnds_;
        super.setStakingEnds(stakingEnds_);

        withdrawStarts = withdrawStarts_;
        super.setWithdrawStarts(withdrawStarts_);

        withdrawEnds = withdrawEnds_;
        super.setWithdrawEnds(withdrawEnds_);
    }

    function changeStakingCap(uint stakingCap_)
    external whitelistedOnly {
        stakingCap = stakingCap_;
        super.setStakingCap(stakingCap_);
    }

    function rewardsTotal() external view returns (uint256) {
        return rewardState.rewardsTotal;
    }

    function earlyWithdrawReward() external view returns (uint256) {
        return rewardState.earlyWithdrawReward;
    }

    function rewardBalance() external view returns (uint256) {
        return rewardState.rewardBalance;
    }

    function addReward(uint256 rewardAmount, uint256 withdrawableAmount)
    external whitelistedOnly returns (bool) {
        return OnChainStakingLib.addReward(rewardAmount, withdrawableAmount,
            rewardTokenAddress, rewardState);
    }

    function addMarginalReward(uint256 withdrawableAmount)
    external whitelistedOnly {
        rewardState.earlyWithdrawReward = withdrawableAmount;
        OnChainStakingLib.addMarginalReward(rewardTokenAddress, tokenAddress,
            address(this), stakedBalance(), rewardState);
    }

    function withdraw(uint256 amount) virtual
    public
    returns (bool) {
        return OnChainStakingLib.withdraw(
            msg.sender,
            tokenAddress,
            rewardTokenAddress,
            amount,
            withdrawStarts,
            withdrawEnds,
            stakingEnds,
            stakeState,
            rewardState
        );
    }
}