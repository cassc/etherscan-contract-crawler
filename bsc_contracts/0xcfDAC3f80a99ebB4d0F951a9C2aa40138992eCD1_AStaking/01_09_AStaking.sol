// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2019-2022 RigoBlock, Rigo Intl.

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

// solhint-disable-next-line
pragma solidity =0.8.17;

import "./interfaces/IAStaking.sol";
import "../../../staking/interfaces/IStaking.sol";
import "../../../staking/interfaces/IStorage.sol";
import {IRigoToken as GRG} from "../../../rigoToken/interfaces/IRigoToken.sol";

/// @title Self Custody adapter - A helper contract for self custody.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
contract AStaking is IAStaking {
    address private immutable _stakingProxy;
    address private immutable _grgToken;
    address private immutable _grgTransferProxy;

    constructor(
        address stakingProxy,
        address grgToken,
        address grgTransferProxy
    ) {
        _stakingProxy = stakingProxy;
        _grgToken = grgToken;
        _grgTransferProxy = grgTransferProxy;
    }

    /// @inheritdoc IAStaking
    function stake(uint256 amount) external override {
        require(amount != uint256(0), "STAKE_AMOUNT_NULL_ERROR");
        address stakingProxy = _getStakingProxy();
        IStaking staking = IStaking(stakingProxy);
        bytes32 id = IStorage(stakingProxy).poolIdByRbPoolAccount(address(this));

        // create staking pool if doesn't exist.
        bytes32 poolId;
        if (id == bytes32(0)) {
            poolId = staking.createStakingPool(address(this));
            assert(poolId != 0);
        } else {
            poolId = id;
        }

        address grgTransferProxy = _getGrgTransferProxy();
        GRG(_getGrgToken()).approve(grgTransferProxy, type(uint256).max);
        staking.stake(amount);
        staking.moveStake(
            IStructs.StakeInfo({status: IStructs.StakeStatus.UNDELEGATED, poolId: poolId}),
            IStructs.StakeInfo({status: IStructs.StakeStatus.DELEGATED, poolId: poolId}),
            amount
        );

        // we make sure we remove allowance but do not clear storage
        GRG(_getGrgToken()).approve(grgTransferProxy, uint256(1));
    }

    /// @inheritdoc IAStaking
    function undelegateStake(uint256 amount) external override {
        address stakingProxy = _getStakingProxy();
        bytes32 poolId = IStorage(stakingProxy).poolIdByRbPoolAccount(address(this));
        IStaking(stakingProxy).moveStake(
            IStructs.StakeInfo({status: IStructs.StakeStatus.DELEGATED, poolId: poolId}),
            IStructs.StakeInfo({status: IStructs.StakeStatus.UNDELEGATED, poolId: poolId}),
            amount
        );
    }

    /// @inheritdoc IAStaking
    function unstake(uint256 amount) external override {
        IStaking(_getStakingProxy()).unstake(amount);
    }

    /// @inheritdoc IAStaking
    function withdrawDelegatorRewards() external override {
        address stakingProxy = _getStakingProxy();
        bytes32 poolId = IStorage(stakingProxy).poolIdByRbPoolAccount(address(this));
        // we finalize the pool in case it has not been finalized, won't do anything otherwise
        IStaking(stakingProxy).finalizePool(poolId);
        IStaking(stakingProxy).withdrawDelegatorRewards(poolId);
    }

    function _getGrgToken() private view returns (address) {
        return _grgToken;
    }

    function _getGrgTransferProxy() private view returns (address) {
        return _grgTransferProxy;
    }

    function _getStakingProxy() private view returns (address) {
        return _stakingProxy;
    }
}