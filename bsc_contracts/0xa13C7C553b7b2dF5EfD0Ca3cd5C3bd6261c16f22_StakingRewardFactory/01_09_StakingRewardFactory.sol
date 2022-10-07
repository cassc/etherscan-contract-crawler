//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./StakingReward.sol";

contract StakingRewardFactory is Ownable {
    event PoolCreation(
        uint256 indexed timestamp,
        StakingReward indexed poolAddress,
        address indexed projectOwner
    );

    /**
     * @dev Create a pool.
     *
     * emits a {PoolCreation} event
     */

    function launchPool(
        string memory name,
        address stakingToken,
        address rewardToken,
        uint256 lockPeriod
    ) public onlyOwner {
        StakingReward pool;

        pool = new StakingReward(
            owner(),
            name,
            stakingToken,
            rewardToken,
            lockPeriod
        );

        emit PoolCreation(block.timestamp, pool, msg.sender);
    }
}