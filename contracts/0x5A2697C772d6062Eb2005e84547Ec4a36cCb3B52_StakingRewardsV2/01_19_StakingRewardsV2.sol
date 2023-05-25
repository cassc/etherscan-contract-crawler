//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./StakingLockable.sol";
import "../interfaces/IMigrationReceiver.sol";

/// @author  umb.network
contract StakingRewardsV2 is StakingLockable {
    constructor(
        address _owner,
        address _rewardsDistribution,
        address _umb,
        address _rUmb1,
        address _rUmb2
    ) StakingLockable(_owner, _rewardsDistribution, _umb, _rUmb1, _rUmb2) {}

    /// @param _newPool address of new pool, where tokens will be staked
    /// @param _data additional data for new pool
    function getRewardAndMigrate(IMigrationReceiver _newPool, bytes calldata _data) external {
        uint256 reward = _getReward(msg.sender, address(_newPool));
        _newPool.migrateTokenCallback(rUmb2, msg.sender, reward, _data);
    }

    /// @param _newPool address of new pool, where tokens will be staked
    /// @param _amount amount of staked tokens to migrate to new pool
    /// @param _data additional data for new pool
    function withdrawAndMigrate(IMigrationReceiver _newPool, uint256 _amount, bytes calldata _data) external {
        _withdraw(_amount, msg.sender, address(_newPool));
        _newPool.migrateTokenCallback(umb, msg.sender, _amount, _data);
    }

    function unlockAndMigrate(IMigrationReceiver _newPool, uint256[] calldata _ids, bytes calldata _data) external {
        (address token, uint256 totalRawAmount) = _unlockTokensFor(msg.sender, _ids, address(_newPool));
        _newPool.migrateTokenCallback(token, msg.sender, totalRawAmount, _data);
    }
}