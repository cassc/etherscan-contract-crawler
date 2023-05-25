// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IMintableERC20.sol";
import "./NftStakeVaultV2.sol";

/** @title SamuraiSagaStakeVaultV2
 */
contract SamuraiSagaStakeVaultV2 is NftStakeVaultV2 {
    event BatchStake(address indexed account, uint256 poolId, uint256[] tokenIds);
    event BatchUnstake(address indexed account, uint256[] tokenIds);

    constructor(IERC721 _nftCollection, IMintableERC20 _rewardToken) 
        NftStakeVaultV2(_nftCollection, _rewardToken) {
    }

    function _sendRewards(address destination, uint256 amount) internal override {
        IMintableERC20(address(rewardToken)).mint(destination, amount);
    }

    function batchStake(uint256 poolId, uint256[] calldata tokenIds) external whenPoolOpened(poolId) nonReentrant {
        address account = _msgSender();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(account, poolId, tokenIds[i]);
        }

        emit BatchStake(account, poolId, tokenIds);
    }

    function batchUnstake(uint256[] calldata tokenIds) external nonReentrant {
        address account = _msgSender();

        uint256 rewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_deposits[tokenIds[i]].owner == account, "Stake: Not owner of token");
            rewards = rewards + _unstake(account, tokenIds[i]);
        }
        _sendAndUpdateRewards(account, rewards);

        emit BatchUnstake(account, tokenIds);
    }

    function batchRestake(uint256 poolId, uint256[] calldata tokenIds) external nonReentrant {
        address account = _msgSender();

        uint256 rewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_deposits[tokenIds[i]].owner == account, "Stake: Not owner of token");
            rewards = rewards + _restake(poolId, tokenIds[i]);
        }
        _sendAndUpdateRewards(account, rewards);

        emit BatchUnstake(account, tokenIds);
        emit BatchStake(account, poolId, tokenIds);
    }
}