// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0;

interface StakingPoolFactory {
    /// @notice Creates a new staking pool using a flat commission model
    /// emits NewFlatRateCommissionStakingPool with the parameters of the new pool
    /// @return new pool address
    function createFlatRateCommission(uint256 commission)
        external
        payable
        returns (address);

    /// @notice Creates a new staking pool using a gas tax commission model
    /// emits NewGasTaxCommissionStakingPool with the parameters of the new pool
    /// @return new pool address
    function createGasTaxCommission(uint256 gas)
        external
        payable
        returns (address);

    /// @notice Returns configuration for the working pools of the current version
    /// @return _pos address for the PoS contract
    function getPoS() external view returns (address _pos);

    /// @notice Event emmited when a pool is created
    /// @param pool address of the new pool
    /// @param fee address of the commission contract
    event NewFlatRateCommissionStakingPool(address indexed pool, address fee);

    /// @notice Event emmited when a pool is created
    /// @param pool address of the new pool
    /// @param fee address of thhe commission contract
    event NewGasTaxCommissionStakingPool(address indexed pool, address fee);
}