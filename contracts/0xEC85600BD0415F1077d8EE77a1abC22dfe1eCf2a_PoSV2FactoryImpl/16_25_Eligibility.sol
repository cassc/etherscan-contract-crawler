// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Block Selector Library

pragma solidity ^0.8.0;

import "@cartesi/util/contracts/UnrolledCordic.sol";

library Eligibility {
    uint256 constant C_40 = 40; // 40 blocks
    uint256 constant C_256 = 256; // 256 blocks
    uint256 constant DIFFICULTY_BASE_MULTIPLIER = 256 * 1e18; // 256 with 18 decimal places
    uint256 constant UINT256_MAX = 2 ** 256 - 1;

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
    ) external view returns (uint256) {
        // cannot produce if block selector goal hasnt been decided yet
        // goal is defined the block after selection was reset
        // cannot produce if weight is zero
        //slither-disable-next-line  incorrect-equality
        if (getSelectionBlocksPassed(_ethBlockStamp) == 0 || _weight == 0) {
            return UINT256_MAX;
        }

        uint256 multiplier;
        // we want overflow and underflow on purpose
        unchecked {
            multiplier =
                DIFFICULTY_BASE_MULTIPLIER -
                getLogOfRandom(_user, _ethBlockStamp);
        }

        uint256 blocksToWait = (_difficulty * multiplier) / (_weight * 1e12);
        // restore the multiple 256 based on current block number
        //slither-disable-next-line  divide-before-multiply
        uint256 cycleOf256 = C_256 *
            ((block.number - _ethBlockStamp - C_40 - 1) / C_256);

        return blocksToWait + _ethBlockStamp + C_40 + cycleOf256;
    }

    /// @notice Calculates the log of the random number between the goal and callers address
    /// @param _user address to calculate log of random
    /// @param _ethBlockStamp main chain block number of last sidechain block
    /// @return log of random number between goal and callers address * 1M
    function getLogOfRandom(
        address _user,
        uint256 _ethBlockStamp
    ) internal view returns (uint256) {
        // seed for goal takes a block in the future (+40) so it is harder to manipulate
        bytes32 currentGoal = blockhash(
            getSeed(_ethBlockStamp + C_40, block.number)
        );
        bytes32 hashedAddress = keccak256(abi.encodePacked(_user));
        uint256 distance = uint256(
            keccak256(abi.encodePacked(hashedAddress, currentGoal))
        );

        return UnrolledCordic.log2Times1e18(distance);
    }

    function getSeed(
        uint256 _previousTarget,
        uint256 _currentBlock
    ) internal pure returns (uint256) {
        uint256 diff = _currentBlock - _previousTarget;
        //slither-disable-next-line  divide-before-multiply
        uint256 res = diff / C_256;

        // if difference is multiple of 256 (256, 512, 1024)
        // preserve old target
        //slither-disable-next-line  incorrect-equality
        if (diff % C_256 == 0) {
            return _previousTarget + ((res - 1) * C_256);
        }

        //slither-disable-next-line  divide-before-multiply
        return _previousTarget + (res * C_256);
    }

    /// @notice Returns the duration in blocks of current selection proccess
    /// @param _ethBlockStamp ethereum block number of last sidechain block
    /// @return number of ethereum blocks passed since last selection goal was defined
    /// @dev blocks passed resets when target resets
    function getSelectionBlocksPassed(
        uint256 _ethBlockStamp
    ) internal view returns (uint256) {
        unchecked {
            // new goal block is decided 40 blocks after sidechain block is created
            uint256 goalBlock = _ethBlockStamp + C_40;

            // target hasnt been set
            if (goalBlock >= block.number) return 0;

            uint256 blocksPassed = block.number - goalBlock;

            // if blocksPassed is multiple of 256, 256 blocks have passed
            // this avoids blocksPassed going to zero right before target change
            //slither-disable-next-line  incorrect-equality
            if (blocksPassed % C_256 == 0) return C_256;

            return blocksPassed % C_256;
        }
    }
}