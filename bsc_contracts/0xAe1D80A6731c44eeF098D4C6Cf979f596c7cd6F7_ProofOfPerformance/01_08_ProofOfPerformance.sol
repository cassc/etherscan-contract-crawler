// SPDX-License-Identifier: Apache 2.0

/*

 Copyright 2017-2019 RigoBlock, Rigo Investment Sagl, 2020 Rigo Intl.

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
pragma solidity 0.8.17;

import {IProofOfPerformance} from "../interfaces/IProofOfPerformance.sol";
import {IStaking} from "../../staking/interfaces/IStaking.sol";
import {IStructs} from "../../staking/interfaces/IStructs.sol";

/// @title Proof of Performance - Controls parameters of inflation.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
contract ProofOfPerformance is IProofOfPerformance {
    address private immutable _stakingProxy;

    constructor(address stakingProxy) {
        _stakingProxy = stakingProxy;
    }

    /// @inheritdoc IProofOfPerformance
    function creditPopRewardToStakingProxy(address targetPool) external override {
        address stakingProxy = _getStakingProxy();
        uint256 poolLockedBalances = IStaking(stakingProxy)
            .getOwnerStakeByStatus(targetPool, IStructs.StakeStatus.DELEGATED)
            .currentEpochBalance;

        // if address has locked balances, staking pool exists.
        require(poolLockedBalances != uint256(0), "POP_STAKING_POOL_BALANCES_NULL_ERROR");

        IStaking(stakingProxy).creditPopReward(targetPool, poolLockedBalances);
    }

    /// @inheritdoc IProofOfPerformance
    function proofOfPerformance(address targetPool) external view override returns (uint256) {
        return
            IStaking(_getStakingProxy())
                .getOwnerStakeByStatus(targetPool, IStructs.StakeStatus.DELEGATED)
                .currentEpochBalance;
    }

    function _getStakingProxy() private view returns (address) {
        return _stakingProxy;
    }
}