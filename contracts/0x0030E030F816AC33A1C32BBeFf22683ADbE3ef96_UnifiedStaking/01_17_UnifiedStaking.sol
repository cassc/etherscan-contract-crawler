// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IMintableERC20.sol";
import "./libraries/NftStakingPool.sol";
import "./libraries/MinterAccess.sol";

/**
 * @title Samurai Saga Collections Staking
 * https://samuraisaga.com
 */
contract UnifiedStaking is NftStakingPool, MinterAccess {
    constructor(IMintableERC20 _rewardToken) NftStakingPool(_rewardToken) {}

    function _sendRewards(address destination, uint256 amount) internal override {
        uint256 b = rewardToken.balanceOf(address(this));
        if (b >= amount) super._sendRewards(destination, amount);
        else IMintableERC20(address(rewardToken)).mint(destination, amount);
    }

    function stakeFrom(
        address from,
        uint256 poolId,
        uint256 tokenId
    ) external onlyMinters whenPoolOpened(poolId) {
        require(from != address(0), "Stake: address(0)");
        Pool memory pool = getPool(poolId);
        _stake(from, pool.collection, tokenId, poolId);
        emit Stake(from, poolId, pool.collection, tokenId);
    }

    function batchStakeFrom(
        address from,
        uint256 poolId,
        uint256[] calldata tokenIds
    ) external onlyMinters whenPoolOpened(poolId) {
        require(from != address(0), "Stake: address(0)");

        Pool memory pool = getPool(poolId);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(from, pool.collection, tokenIds[i], poolId);
        }

        emit BatchStake(from, poolId, pool.collection, tokenIds);
    }
}