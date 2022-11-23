// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract RewardRateConfigurable is Initializable {
    struct RewardsConfiguration {
        uint256 rewardPerBlock;
        uint256 lastUpdateBlockNum;
        uint256 updateBlocksInterval;
    }

    uint256 public constant REWARD_PER_BLOCK_MULTIPLIER = 967742;
    uint256 public constant DIVIDER = 1e6;

    RewardsConfiguration private rewardsConfiguration;

    event RewardPerBlockUpdated(uint256 oldValue, uint256 newValue);

    function __RewardRateConfigurable_init(
        uint256 _rewardPerBlock,
        uint256 _rewardUpdateBlocksInterval
    ) internal onlyInitializing {
        __RewardRateConfigurable_init_unchained(_rewardPerBlock, _rewardUpdateBlocksInterval);
    }

    function __RewardRateConfigurable_init_unchained(
        uint256 _rewardPerBlock,
        uint256 _rewardUpdateBlocksInterval
    ) internal onlyInitializing {
        rewardsConfiguration.rewardPerBlock = _rewardPerBlock;
        rewardsConfiguration.lastUpdateBlockNum = block.number;
        rewardsConfiguration.updateBlocksInterval = _rewardUpdateBlocksInterval;
    }

    function getRewardsConfiguration() public view returns (RewardsConfiguration memory) {
        return rewardsConfiguration;
    }

    function getRewardPerBlock() public view returns (uint256) {
        return rewardsConfiguration.rewardPerBlock;
    }

    function _setRewardConfiguration(uint256 rewardPerBlock, uint256 updateBlocksInterval)
        internal
    {
        uint256 oldRewardValue = rewardsConfiguration.rewardPerBlock;

        rewardsConfiguration.rewardPerBlock = rewardPerBlock;
        rewardsConfiguration.lastUpdateBlockNum = block.number;
        rewardsConfiguration.updateBlocksInterval = updateBlocksInterval;

        emit RewardPerBlockUpdated(oldRewardValue, rewardPerBlock);
    }

    function _updateRewardPerBlock() internal {
        if (
            (block.number - rewardsConfiguration.lastUpdateBlockNum) <
            rewardsConfiguration.updateBlocksInterval
        ) {
            return;
        }

        uint256 rewardPerBlockOldValue = rewardsConfiguration.rewardPerBlock;

        rewardsConfiguration.rewardPerBlock =
            (rewardPerBlockOldValue * REWARD_PER_BLOCK_MULTIPLIER) / DIVIDER;

        rewardsConfiguration.lastUpdateBlockNum = block.number;

        emit RewardPerBlockUpdated(rewardPerBlockOldValue, rewardsConfiguration.rewardPerBlock);
    }
}