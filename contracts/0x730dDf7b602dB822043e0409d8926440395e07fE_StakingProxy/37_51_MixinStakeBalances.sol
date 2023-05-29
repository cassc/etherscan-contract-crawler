/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

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

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "../libs/LibSafeDowncast.sol";
import "../../utils/0xUtils/LibSafeMath.sol";
import "../interfaces/IStructs.sol";
import "../immutable/MixinDeploymentConstants.sol";
import "./MixinStakeStorage.sol";
import "../../rigoToken/Inflation/InflationFace.sol";


abstract contract MixinStakeBalances is
    MixinStakeStorage,
    MixinDeploymentConstants
{
    using LibSafeMath for uint256;
    using LibSafeDowncast for uint256;

    /// @dev Gets global stake for a given status.
    /// @param stakeStatus UNDELEGATED or DELEGATED
    /// @return balance Global stake for given status.
    function getGlobalStakeByStatus(IStructs.StakeStatus stakeStatus)
        external
        view
        override
        returns (IStructs.StoredBalance memory balance)
    {
        balance = _loadCurrentBalance(
            _globalStakeByStatus[uint8(IStructs.StakeStatus.DELEGATED)]
        );
        if (stakeStatus == IStructs.StakeStatus.UNDELEGATED) {
            // Undelegated stake is the difference between total stake and delegated stake
            // Note that any ZRX erroneously sent to the vault will be counted as undelegated stake
            uint256 totalStake = getGrgVault().balanceOfGrgVault();
            balance.currentEpochBalance = totalStake.safeSub(balance.currentEpochBalance).downcastToUint96();
            balance.nextEpochBalance = totalStake.safeSub(balance.nextEpochBalance).downcastToUint96();
        }
        return balance;
    }

    /// @dev Gets an owner's stake balances by status.
    /// @param staker Owner of stake.
    /// @param stakeStatus UNDELEGATED or DELEGATED
    /// @return balance Owner's stake balances for given status.
    function getOwnerStakeByStatus(
        address staker,
        IStructs.StakeStatus stakeStatus
    )
        external
        view
        override
        returns (IStructs.StoredBalance memory balance)
    {
        balance = _loadCurrentBalance(
            _ownerStakeByStatus[uint8(stakeStatus)][staker]
        );
        return balance;
    }

    /// @dev Returns the total stake for a given staker.
    /// @param staker of stake.
    /// @return Total GRG staked by `staker`.
    function getTotalStake(address staker)
        public
        view
        override
        returns (uint256)
    {
        return getGrgVault().balanceOf(staker);
    }

    /// @dev Returns the stake delegated to a specific staking pool, by a given staker.
    /// @param staker of stake.
    /// @param poolId Unique Id of pool.
    /// @return balance Stake delegated to pool by staker.
    function getStakeDelegatedToPoolByOwner(address staker, bytes32 poolId)
        public
        view
        override
        returns (IStructs.StoredBalance memory balance)
    {
        balance = _loadCurrentBalance(_delegatedStakeToPoolByOwner[staker][poolId]);
        return balance;
    }

    /// @dev Returns the total stake delegated to a specific staking pool,
    ///      across all members.
    /// @param poolId Unique Id of pool.
    /// @return balance Total stake delegated to pool.
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