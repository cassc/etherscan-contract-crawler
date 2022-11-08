// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Eligibility Calculator Implementation

pragma solidity ^0.8.0;

import "./Eligibility.sol";
import "./abstracts/AEligibilityCal.sol";

contract EligibilityCalImpl is AEligibilityCal {
    /// @notice Check if address is allowed to produce block
    /// @param _difficulty difficulty of current selection process
    /// @param _ethBlockStamp ethereum block number when current selection started
    /// @param _user the address that is gonna get checked
    /// @param _weight number that will weight the random number, most likely will be the number of staked tokens
    function canProduceBlock(
        uint256 _difficulty,
        uint256 _ethBlockStamp,
        address _user,
        uint256 _weight
    ) internal view override returns (bool) {
        return
            block.number >
            Eligibility.whenCanProduceBlock(
                _difficulty,
                _ethBlockStamp,
                _user,
                _weight
            );
    }

    /// @notice Check when address is allowed to produce block
    /// @param _difficulty difficulty of current selection process
    /// @param _ethBlockStamp ethereum block number when current selection started
    /// @param _user the address that is gonna get checked
    /// @param _weight number that will weight the random number, most likely will be the number of staked tokens
    function whenCanProduceBlock(
        uint256 _difficulty,
        uint256 _ethBlockStamp,
        address _user,
        uint256 _weight
    ) internal view override returns (uint256) {
        return
            Eligibility.whenCanProduceBlock(
                _difficulty,
                _ethBlockStamp,
                _user,
                _weight
            );
    }

    function getSelectionBlocksPassed(
        uint256 _ethBlockStamp
    ) internal view override returns (uint256) {
        return Eligibility.getSelectionBlocksPassed(_ethBlockStamp);
    }
}