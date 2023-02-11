// SPDX-License-Identifier: Apache 2.0
/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020-2022 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

import "../libs/LibSafeDowncast.sol";
import "../interfaces/IStructs.sol";
import "../immutable/MixinDeploymentConstants.sol";
import "./MixinStakeStorage.sol";

abstract contract MixinStakeBalances is MixinStakeStorage, MixinDeploymentConstants {
    using LibSafeDowncast for uint256;

    /// @inheritdoc IStaking
    function getGlobalStakeByStatus(IStructs.StakeStatus stakeStatus)
        external
        view
        override
        returns (IStructs.StoredBalance memory balance)
    {
        balance = _loadCurrentBalance(_globalStakeByStatus[uint8(IStructs.StakeStatus.DELEGATED)]);
        if (stakeStatus == IStructs.StakeStatus.UNDELEGATED) {
            // Undelegated stake is the difference between total stake and delegated stake
            // Note that any ZRX erroneously sent to the vault will be counted as undelegated stake
            uint256 totalStake = getGrgVault().balanceOfGrgVault();
            balance.currentEpochBalance = (totalStake - balance.currentEpochBalance).downcastToUint96();
            balance.nextEpochBalance = (totalStake - balance.nextEpochBalance).downcastToUint96();
        }
        return balance;
    }

    /// @inheritdoc IStaking
    function getOwnerStakeByStatus(address staker, IStructs.StakeStatus stakeStatus)
        external
        view
        override
        returns (IStructs.StoredBalance memory balance)
    {
        balance = _loadCurrentBalance(_ownerStakeByStatus[uint8(stakeStatus)][staker]);
        return balance;
    }

    /// @inheritdoc IStaking
    function getTotalStake(address staker) public view override returns (uint256) {
        return getGrgVault().balanceOf(staker);
    }

    /// @inheritdoc IStaking
    function getStakeDelegatedToPoolByOwner(address staker, bytes32 poolId)
        public
        view
        override
        returns (IStructs.StoredBalance memory balance)
    {
        balance = _loadCurrentBalance(_delegatedStakeToPoolByOwner[staker][poolId]);
        return balance;
    }

    /// @inheritdoc IStaking
    function getTotalStakeDelegatedToPool(bytes32 poolId)
        public
        view
        override
        returns (IStructs.StoredBalance memory balance)
    {
        balance = _loadCurrentBalance(_delegatedStakeByPoolId[poolId]);
        return balance;
    }
}