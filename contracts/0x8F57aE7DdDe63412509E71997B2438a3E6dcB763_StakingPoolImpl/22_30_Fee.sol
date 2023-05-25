// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0 <0.9.0;

/// @title Calculator of pool owner commission for each block reward
/// @author Danilo Tuler
/// @notice This provides flexibility for different commission models
interface Fee {
    /// @notice calculates the total amount of the reward that will be directed to the pool owner
    /// @return amount of tokens taken by the pool owner as commission
    function getCommission(uint256 posIndex, uint256 rewardAmount)
        external
        view
        returns (uint256);
}