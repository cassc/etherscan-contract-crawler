pragma solidity >=0.6.0 <0.8.0;

import "./IFestaked.sol";
import "./FestakedOptimized.sol";

abstract contract RewardAdder is IFestaked {
    address  public rewardTokenAddress;
    FestakedLib.FestakeRewardState public rewardState;
    address public rewardSetter; // Not using Ownable to save on deployment gas

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
    external returns (bool) {
        return FestakedLib.addReward(rewardAmount, withdrawableAmount,
            rewardTokenAddress, rewardState);
    }
}

contract FestakedWithReward is FestakedOptimized, RewardAdder {
    constructor (string memory name_,
        address tokenAddress_,
        address rewardTokenAddress_,
        uint stakingStarts_,
        uint stakingEnds_,
        uint withdrawStarts_,
        uint withdrawEnds_,
        uint256 stakingCap_) FestakedOptimized (
            name_,
            tokenAddress_,
            stakingStarts_,
            stakingEnds_,
            withdrawStarts_,
            withdrawEnds_,
            stakingCap_
        ) public {
        require(rewardTokenAddress_ != address(0), "Festaking: 0 reward address");
        rewardTokenAddress = rewardTokenAddress_;
        rewardSetter = msg.sender;
    }

    function addMarginalReward(uint256 withdrawableAmount)
    external {
        require(msg.sender == rewardSetter, "Festaking: Not allowed");
        rewardState.earlyWithdrawReward = withdrawableAmount;
        FestakedLib.addMarginalReward(rewardTokenAddress, tokenAddress,
            address(this), stakedBalance(), rewardState);
    }

    function withdraw(uint256 amount) virtual
    public
    returns (bool) {
        return FestakedLib.withdraw(
            msg.sender,
            tokenAddress,
            rewardTokenAddress,
            amount,
            withdrawStarts,
            withdrawEnds,
            stakingEnds,
            stakeState,
            rewardState);
    }
}