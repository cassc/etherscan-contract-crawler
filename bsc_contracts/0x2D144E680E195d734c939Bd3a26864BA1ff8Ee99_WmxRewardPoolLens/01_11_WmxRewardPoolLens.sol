// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./WmxRewardPoolFactory.sol";

/**
 * @title   WmxRewardPoolLens
 */
contract WmxRewardPoolLens {
    WmxRewardPoolFactory public immutable wmxRewardPoolFactory;
    address public rewardToken;
    address public stakingToken;

    struct Pool {
        uint256 rewardRate;
        uint256 startTime;
        uint256 duration;
        uint256 rewardsAvailable;
        uint256 rewardsRemained;
        uint256 maxCap;
        uint256 curCap;
    }

    /**
     * @param _wmxRewardPoolFactory  Pool factory
     */
    constructor(WmxRewardPoolFactory _wmxRewardPoolFactory) public {
        wmxRewardPoolFactory = _wmxRewardPoolFactory;
        rewardToken = wmxRewardPoolFactory.rewardToken();
        stakingToken = wmxRewardPoolFactory.stakingToken();
    }

    function getCreatedPools() external view returns (Pool[] memory pools) {
        address[] memory poolsAddresses = wmxRewardPoolFactory.getCreatedPools();
        uint256 len = poolsAddresses.length;
        pools = new Pool[](len);
        for (uint256 i = 0; i < len; i++) {
            WmxRewardPoolV2 p = WmxRewardPoolV2(poolsAddresses[i]);
            uint256 duration = p.duration();
            uint256 rewardRate = p.rewardRate();
            pools[i] = Pool(
                rewardRate,
                p.startTime(),
                duration,
                rewardRate * duration,
                IERC20(rewardToken).balanceOf(poolsAddresses[i]),
                p.maxCap(),
                IERC20(stakingToken).balanceOf(poolsAddresses[i])
            );
        }
        return pools;
    }
}