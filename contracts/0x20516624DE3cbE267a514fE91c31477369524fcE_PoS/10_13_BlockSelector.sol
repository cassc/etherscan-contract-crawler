// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Block Selector

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "@cartesi/util/contracts/CartesiMath.sol";
import "@cartesi/util/contracts/InstantiatorImpl.sol";
import "@cartesi/util/contracts/Decorated.sol";

contract BlockSelector is InstantiatorImpl, Decorated, CartesiMath {
    using SafeMath for uint256;

    uint256 constant C_256 = 256; // 256 blocks
    uint256 constant DIFFICULTY_BASE_MULTIPLIER = 256000000; //256 M
    uint256 constant ADJUSTMENT_BASE = 1000000; // 1M

    struct BlockSelectorCtx {
        // @dev the order of variables are important for storage packing
        // 32 bytes constants
        uint256 minDifficulty; // lower bound for difficulty
        // 32 bytes var
        uint256 difficulty; // difficulty parameter defines how big the interval will be

        // 20 bytes constants
        address posManagerAddress;

        // 4 bytes constants
        uint32 difficultyAdjustmentParameter; // how fast the difficulty gets adjusted to reach the desired interval, number * 1000000
        uint32 targetInterval; // desired block selection interval in ethereum blocks

        // 4 bytes var
        uint32 blockCount; // how many blocks have been created
        uint32 ethBlockCheckpoint; // ethereum block number when current selection started
    }

    mapping(uint256 => BlockSelectorCtx) internal instance;

    event BlockProduced(
        uint256 indexed index,
        address indexed producer,
        uint32 blockNumber,
        uint256 roundDuration,
        uint256 difficulty
    );

    modifier onlyAfterGoalDefinition(uint256 _index){
        // cannot produce if block selector goal hasnt been decided yet
        // goal is defined the block after selection was reset
        require(
            block.number >= instance[_index].ethBlockCheckpoint + 1,
            "Goal for new block hasnt been decided yet"
        );
        _;

    }

    /// @notice Instantiates a BlockSelector structure
    /// @param _minDifficulty lower bound for difficulty parameter
    /// @param _initialDifficulty starting difficulty
    /// @param _difficultyAdjustmentParameter how quickly the difficulty gets updated
    /// according to the difference between time passed and target interval.
    /// @param _targetInterval how often we want produce noether blocks, in ethereum blocks
    /// @param _posManagerAddress address of ProofOfStake that will use this instance
    function instantiate(
        uint256 _minDifficulty,
        uint256 _initialDifficulty,
        uint32 _difficultyAdjustmentParameter,
        uint32 _targetInterval,
        address _posManagerAddress
    ) public returns (uint256)
    {
        instance[currentIndex].minDifficulty = _minDifficulty;
        instance[currentIndex].difficulty = _initialDifficulty;
        instance[currentIndex].difficultyAdjustmentParameter = _difficultyAdjustmentParameter;
        instance[currentIndex].targetInterval = _targetInterval;
        instance[currentIndex].posManagerAddress = _posManagerAddress;

        instance[currentIndex].ethBlockCheckpoint = uint32(block.number); // first selection starts when the instance is created

        active[currentIndex] = true;
        return currentIndex++;
    }

    /// @notice Calculates the log of the random number between the goal and callers address
    /// @param _index the index of the instance of block selector you want to interact with
    /// @param _user address to calculate log of random
    /// @return log of random number between goal and callers address * 1M
    function getLogOfRandom(uint256 _index, address _user) internal view returns (uint256) {
        // seed for goal takes a block in the future (+1) so it is harder to manipulate
        bytes32 currentGoal = blockhash(
            getSeed(uint256(instance[_index].ethBlockCheckpoint + 1), block.number)
        );
        bytes32 hashedAddress = keccak256(abi.encodePacked(_user));
        uint256 distance = uint256(keccak256(abi.encodePacked(hashedAddress, currentGoal)));

        return CartesiMath.log2ApproxTimes1M(distance);
    }

    /// @notice Produces a block
    /// @param _index the index of the instance of block selector you want to interact with
    /// @param _user address that has the right to produce block
    /// @param _weight number that will weight the random number, will be the number of staked tokens
    function produceBlock(
        uint256 _index,
        address _user,
        uint256 _weight
    )
    public
    onlyAfterGoalDefinition(_index)
    returns (bool)
    {
        BlockSelectorCtx storage bsc = instance[_index];

        require(_weight > 0, "Caller can't have zero staked tokens");
        require(msg.sender == bsc.posManagerAddress, "Function can only be called by pos address");

        if (canProduceBlock(_index, _user, _weight)) {
            emit BlockProduced(
                _index,
                _user,
                bsc.blockCount,
                getSelectionBlockDuration(_index),
                bsc.difficulty
            );

            return _blockProduced(_index);
        }

        return false;
    }

    /// @notice Check if address is allowed to produce block
    /// @param _index the index of the instance of block selector you want to interact with
    /// @param _user the address that is gonna get checked
    /// @param _weight number that will weight the random number, most likely will be the number of staked tokens
    function canProduceBlock(uint256 _index, address _user, uint256 _weight) public view returns (bool) {
        BlockSelectorCtx storage bsc = instance[_index];

        // cannot produce if block selector goal hasnt been decided yet
        // goal is defined the block after selection was reset
        if (block.number <= bsc.ethBlockCheckpoint + 1) {
            return false;
        }

        uint256 blockDuration = getSelectionBlockDuration(_index);

        return (
            (_weight.mul(blockDuration)) > bsc.difficulty.mul((DIFFICULTY_BASE_MULTIPLIER - getLogOfRandom(_index, _user)))
        );
    }

    /// @notice Block produced, declare producer and adjust difficulty
    /// @param _index the index of the instance of block selector you want to interact with
    function _blockProduced(uint256 _index) private returns (bool) {
        BlockSelectorCtx storage bsc = instance[_index];

        // adjust difficulty
        bsc.difficulty = getNewDifficulty(
            bsc.minDifficulty,
            bsc.difficulty,
            uint32((block.number).sub(uint256(bsc.ethBlockCheckpoint))),
            bsc.targetInterval,
            bsc.difficultyAdjustmentParameter
        );

        _reset(_index);
        return true;
    }

    /// @notice Reset instance, advancing round and choosing new goal
    /// @param _index the index of the instance of block selector you want to interact with
    function _reset(uint256 _index) private {
        BlockSelectorCtx storage bsc = instance[_index];

        bsc.blockCount++;
        bsc.ethBlockCheckpoint = uint32(block.number);
    }

    function getSeed(
        uint256 _previousTarget,
        uint256 _currentBlock
    )
    internal
    pure
    returns (uint256)
    {
        uint256 diff = _currentBlock.sub(_previousTarget);
        uint256 res = diff.div(C_256);

        // if difference is multiple of 256 (256, 512, 1024)
        // preserve old target
        if (diff % C_256 == 0) {
            return _previousTarget.add((res - 1).mul(C_256));
        }

        return _previousTarget.add(res.mul(C_256));
    }

    /// @notice Calculates new difficulty parameter
    /// @param _minDiff minimum difficulty of instance
    /// @param _oldDiff is the difficulty of previous round
    /// @param _blocksPassed how many ethereum blocks have passed
    /// @param _targetInterval is how long a round is supposed to take
    /// @param _adjustmentParam is how fast the difficulty gets adjusted,
    ///         should be number * 1000000
    function getNewDifficulty(
        uint256 _minDiff,
        uint256 _oldDiff,
        uint32 _blocksPassed,
        uint32 _targetInterval,
        uint32 _adjustmentParam
    )
    internal
    pure
    returns (uint256)
    {
        // @dev to save gas on evaluation, instead of returning the _oldDiff when the target
        // was exactly matched - we increase the difficulty.
        if (_blocksPassed <= _targetInterval) {
            return _oldDiff.add(_oldDiff.mul(_adjustmentParam).div(ADJUSTMENT_BASE) + 1);
        }

        uint256 newDiff = _oldDiff.sub(_oldDiff.mul(_adjustmentParam).div(ADJUSTMENT_BASE) + 1);

        return newDiff > _minDiff ? newDiff : _minDiff;
    }

    /// @notice Returns the number of blocks
    /// @param _index the index of the instance of block selector to be interact with
    /// @return number of blocks
    function getBlockCount(uint256 _index) public view returns (uint32) {
        return instance[_index].blockCount;
    }

    /// @notice Returns current difficulty
    /// @param _index the index of the instance of block selector to be interact with
    /// @return difficulty of current selection
    function getDifficulty(uint256 _index) public view returns (uint256) {
        return instance[_index].difficulty;
    }

    /// @notice Returns min difficulty
    /// @param _index the index of the instance of block selector to be interact with
    /// @return min difficulty of instance
    function getMinDifficulty(uint256 _index) public view returns (uint256) {
        return instance[_index].minDifficulty;
    }

    /// @notice Returns difficulty adjustment parameter
    /// @param _index the index of the instance of block selector to be interact with
    /// @return difficulty adjustment parameter
    function getDifficultyAdjustmentParameter(
        uint256 _index
    )
    public
    view
    returns (uint32)
    {
        return instance[_index].difficultyAdjustmentParameter;
    }

    /// @notice Returns target interval
    /// @param _index the index of the instance of block selector to be interact with
    /// @return target interval
    function getTargetInterval(uint256 _index) public view returns (uint32) {
        return instance[_index].targetInterval;
    }

    /// @notice Returns time since last selection started, in ethereum blocks
    /// @param _index the index of the instance of block selector to be interact with
    /// @return number of etheereum blocks passed since last selection started
    /// @dev block duration resets every 256 blocks
    function getSelectionBlockDuration(uint256 _index)
    public
    view
    returns (uint256)
    {
        BlockSelectorCtx storage bsc = instance[_index];

        uint256 goalBlock = uint256(bsc.ethBlockCheckpoint + 1);

        // target hasnt been set
        if (goalBlock >= block.number) return 0;

        uint256 blocksPassed = (block.number).sub(goalBlock);

        // if blocksPassed is multiple of 256, 256 blocks have passed
        // this avoids blocksPassed going to zero right before target change
        if (blocksPassed % C_256 == 0) return C_256;

        return blocksPassed % C_256;
    }

    function getState(uint256 _index, address _user)
    public view returns (uint256[5] memory _uintValues) {
        BlockSelectorCtx storage i = instance[_index];

        uint256[5] memory uintValues = [
            block.number,
            i.ethBlockCheckpoint + 1, // initial selection goal
            i.difficulty,
            getSelectionBlockDuration(_index), // blocks passed
            getLogOfRandom(_index, _user)
        ];

        return uintValues;
    }

    function isConcerned(uint256, address) public override pure returns (bool) {
        return false; // isConcerned is only for the main concern (PoS)
    }

    function getSubInstances(uint256, address)
        public override pure returns (address[] memory _addresses,
            uint256[] memory _indices)
    {
        address[] memory a;
        uint256[] memory i;

        a = new address[](0);
        i = new uint256[](0);

        return (a, i);
    }
}