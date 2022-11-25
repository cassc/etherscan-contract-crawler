pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library UserInfo {
    using SafeMath for uint256;
    struct Data {
        uint256 amount;
        // packing slot
        uint128 rewards;
        uint128 latestHarvestBlockNumber;
        uint128 pendingRewardPerTokenPaid;
        uint128 pendingRewards;
    }

    function deposit(
        UserInfo.Data storage data,
        uint256 amount
    ) internal {
        if(data.amount == 0){
            // mean no deposit token yet
            data.latestHarvestBlockNumber = uint128(block.number);
        }
        data.amount = data.amount.add(amount);
    }

    function withdraw(
        UserInfo.Data storage data,
        uint256 amount
    ) internal {
        data.amount = data.amount.sub(amount);
    }

    function updateEarnedRewards(
        UserInfo.Data storage data,
        uint256 amount
    ) internal {
        data.rewards = uint128(amount);
    }

    function harvest(
        UserInfo.Data storage data,
        uint256 blockNumber
    ) internal {
        data.rewards = 0;
        data.latestHarvestBlockNumber = uint128(blockNumber);
    }

    function updatePendingReward(
        UserInfo.Data storage data,
        uint256 rewards,
        uint256 rewardPerTokenPaid
    ) internal {
        data.pendingRewards = uint128(rewards);
        data.pendingRewardPerTokenPaid = uint128(rewardPerTokenPaid);
    }

}