// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2023 Rigo Intl.

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

pragma solidity >=0.8.0 <0.9.0;

import "./IGovernanceEvents.sol";

interface IGovernanceVoting {
    enum VoteType {
        For,
        Against,
        Abstain
    }

    /// @notice Casts a vote for the given proposal.
    /// @dev Only callable during the voting period for that proposal. One address can only vote once.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param voteType Whether to support, not support or abstain.
    function castVote(uint256 proposalId, VoteType voteType) external;

    /// @notice Casts a vote for the given proposal, by signature.
    /// @dev Only callable during the voting period for that proposal. One voter can only vote once.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param voteType Whether to support, not support or abstain.
    /// @param v the v field of the signature.
    /// @param r the r field of the signature.
    /// @param s the s field of the signature.
    function castVoteBySignature(
        uint256 proposalId,
        VoteType voteType,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice Executes a proposal that has passed and is currently executable.
    /// @param proposalId The ID of the proposal to execute.
    function execute(uint256 proposalId) external payable;

    struct ProposedAction {
        address target;
        bytes data;
        uint256 value;
    }

    /// @notice Creates a proposal on the the given actions. Must have at least `proposalThreshold`.
    /// @dev Must have at least `proposalThreshold` of voting power to call this function.
    /// @param actions The proposed actions. An action specifies a contract call.
    /// @param description A text description for the proposal.
    /// @return proposalId The ID of the newly created proposal.
    function propose(ProposedAction[] calldata actions, string calldata description)
        external
        returns (uint256 proposalId);
}