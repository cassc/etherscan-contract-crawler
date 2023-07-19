// SPDX-License-Identifier: GPL-3.0-or-later

// CODE COPIED FROM COMPOUND PROTOCOL (https://github.com/compound-finance/compound-protocol/tree/b9b14038612d846b83f8a009a82c38974ff2dcfe)

// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// CODE WAS SLIGHTLY MODIFIED

// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'SafeMath.sol';

contract Votes {
    using SafeMath for uint96;

    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;
    mapping(address => uint32) public checkpointsLength;

    event DelegateVotesChanged(address indexed account, uint96 oldVotes, uint96 newVotes);

    function getCurrentVotes(address account) external view returns (uint96) {
        // out of bounds access is safe and returns 0 votes
        return checkpoints[account][checkpointsLength[account] - 1].votes;
    }

    function _getPriorVotes(address account, uint256 blockNumber) internal view returns (uint96) {
        require(blockNumber < block.number, 'VO_NOT_YET_DETERMINED');

        uint32 n = checkpointsLength[account];
        if (n == 0) {
            return 0;
        }

        if (checkpoints[account][n - 1].fromBlock <= blockNumber) {
            return checkpoints[account][n - 1].votes;
        }

        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = n - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2;
            Checkpoint memory checkpoint = checkpoints[account][center];
            if (checkpoint.fromBlock == blockNumber) {
                return checkpoint.votes;
            } else if (checkpoint.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _updateVotes(
        address giver,
        address receiver,
        uint96 votes
    ) internal {
        if (giver == receiver || votes == 0) {
            return;
        }
        if (giver != address(0)) {
            uint32 n = checkpointsLength[giver];
            require(n > 0, 'VO_INSUFFICIENT_VOTES');
            // out of bounds access is safe and returns 0 votes
            uint96 oldVotes = checkpoints[giver][n - 1].votes;
            uint96 newVotes = oldVotes.sub96(votes);
            _writeCheckpoint(giver, n, newVotes);
        }

        if (receiver != address(0)) {
            uint32 n = checkpointsLength[receiver];
            // out of bounds access is safe and returns 0 votes
            uint96 oldVotes = checkpoints[receiver][n - 1].votes;
            uint96 newVotes = oldVotes.add96(votes);
            _writeCheckpoint(receiver, n, newVotes);
        }
    }

    function _writeCheckpoint(
        address account,
        uint32 n,
        uint96 votes
    ) internal {
        uint32 blockNumber = safe32(block.number);
        // out of bounds access is safe and returns 0 votes
        uint96 oldVotes = checkpoints[account][n - 1].votes;
        if (n > 0 && checkpoints[account][n - 1].fromBlock == blockNumber) {
            checkpoints[account][n - 1].votes = votes;
        } else {
            checkpoints[account][n] = Checkpoint(blockNumber, votes);
            checkpointsLength[account] = n + 1;
        }
        emit DelegateVotesChanged(account, oldVotes, votes);
    }

    function safe32(uint256 n) internal pure returns (uint32) {
        require(n < 2**32, 'VO_EXCEEDS_32_BITS');
        return uint32(n);
    }
}