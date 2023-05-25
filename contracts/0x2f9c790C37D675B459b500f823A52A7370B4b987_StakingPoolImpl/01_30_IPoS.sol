// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Interface PoS
pragma solidity >=0.7.0 <0.9.0;

interface IPoS {
    /// @notice Produce a block
    /// @param _index the index of the instance of pos you want to interact with
    /// @dev this function can only be called by a worker, user never calls it directly
    function produceBlock(uint256 _index) external returns (bool);

    /// @notice Get reward manager address
    /// @param _index index of instance
    /// @return address of instance's RewardManager
    function getRewardManagerAddress(uint256 _index)
        external
        view
        returns (address);

    /// @notice Get block selector address
    /// @param _index index of instance
    /// @return address of instance's block selector
    function getBlockSelectorAddress(uint256 _index)
        external
        view
        returns (address);

    /// @notice Get block selector index
    /// @param _index index of instance
    /// @return index of instance's block selector
    function getBlockSelectorIndex(uint256 _index)
        external
        view
        returns (uint256);

    /// @notice Get staking address
    /// @param _index index of instance
    /// @return address of instance's staking contract
    function getStakingAddress(uint256 _index) external view returns (address);

    /// @notice Get state of a particular instance
    /// @param _index index of instance
    /// @param _user address of user
    /// @return bool if user is eligible to produce next block
    /// @return address of user that was chosen to build the block
    /// @return current reward paid by the network for that block
    function getState(uint256 _index, address _user)
        external
        view
        returns (
            bool,
            address,
            uint256
        );

    function terminate(uint256 _index) external;
}