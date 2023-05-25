// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IMintableERC20.sol";
import "./libraries/NftStakingPool.sol";
import "./libraries/MinterAccess.sol";

/**
 * @title OnnaBugeishaStaking
 */
contract OnnaBugeishaStaking is NftStakingPool, MinterAccess {
    constructor(IERC721 _nftCollection, IMintableERC20 _rewardToken) NftStakingPool(_nftCollection, _rewardToken) {}

    function _sendRewards(address destination, uint256 amount) internal override {
        IMintableERC20(address(rewardToken)).mint(destination, amount);
    }

    function stakeFrom(address from, uint256 poolId, uint256 tokenId) external onlyMinters {
        require(from != address(0), "Stake: address(0)");
        _stake(from, poolId, tokenId);
        emit Stake(from, poolId, tokenId);
    }

    function batchStakeFrom(address from, uint256 poolId, uint256[] calldata tokenIds) external onlyMinters {
        require(from != address(0), "Stake: address(0)");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(from, poolId, tokenIds[i]);
        }

        emit BatchStake(from, poolId, tokenIds);
    }
}