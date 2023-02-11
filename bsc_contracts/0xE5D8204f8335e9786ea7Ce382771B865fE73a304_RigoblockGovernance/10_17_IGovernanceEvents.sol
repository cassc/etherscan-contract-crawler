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

import "./IGovernanceVoting.sol";

interface IGovernanceEvents {
    /// @notice Emitted when a new proposal is created.
    /// @param proposer Address of the proposer.
    /// @param proposalId Number of the proposal.
    /// @param actions Struct array of actions (targets, datas, values).
    /// @param startBlockOrTime Timestamp in seconds after which proposal can be voted on.
    /// @param endBlockOrTime Timestamp in seconds after which proposal can be executed.
    /// @param description String description of proposal.
    event ProposalCreated(
        address proposer,
        uint256 proposalId,
        IGovernanceVoting.ProposedAction[] actions,
        uint256 startBlockOrTime,
        uint256 endBlockOrTime,
        string description
    );

    /// @notice Emitted when a proposal is executed.
    /// @param proposalId Number of the proposal.
    event ProposalExecuted(uint256 proposalId);

    /// @notice Emmited when the governance strategy is upgraded.
    /// @param newStrategy Address of the new strategy contract.
    event StrategyUpgraded(address newStrategy);

    /// @notice Emitted when voting thresholds get updated.
    /// @dev Only governance can update thresholds.
    /// @param proposalThreshold Number of votes required to add a proposal.
    /// @param quorumThreshold Number of votes required to execute a proposal.
    event ThresholdsUpdated(uint256 proposalThreshold, uint256 quorumThreshold);

    /// @notice Emitted when implementation written to proxy storage.
    /// @dev Emitted also at first variable initialization.
    /// @param newImplementation Address of the new implementation.
    event Upgraded(address indexed newImplementation);

    /// @notice Emitted when a voter votes.
    /// @param voter Address of the voter.
    /// @param proposalId Number of the proposal.
    /// @param voteType Number of vote type.
    /// @param votingPower Number of votes.
    event VoteCast(address voter, uint256 proposalId, IGovernanceVoting.VoteType voteType, uint256 votingPower);
}