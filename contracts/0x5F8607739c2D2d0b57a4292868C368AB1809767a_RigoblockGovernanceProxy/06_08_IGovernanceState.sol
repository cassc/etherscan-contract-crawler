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

interface IGovernanceState {
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Qualified,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    enum TimeType {
        Blocknumber,
        Timestamp
    }

    struct Proposal {
        uint256 actionsLength;
        uint256 startBlockOrTime;
        uint256 endBlockOrTime;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votesAbstain;
        bool executed;
    }

    struct ProposalWrapper {
        Proposal proposal;
        IGovernanceVoting.ProposedAction[] proposedAction;
    }

    /// @notice Returns the actions proposed for a given proposal.
    /// @param proposalId Number of the proposal.
    /// @return proposedActions Array of tuple of proposed actions.
    function getActions(uint256 proposalId)
        external
        view
        returns (IGovernanceVoting.ProposedAction[] memory proposedActions);

    /// @notice Returns a proposal for a given id.
    /// @param proposalId The number of the proposal.
    /// @return proposalWrapper Tuple wrapper of the proposal and proposed actions tuples.
    function getProposalById(uint256 proposalId) external view returns (ProposalWrapper memory proposalWrapper);

    /// @notice Returns the state of a proposal.
    /// @param proposalId Number of the proposal.
    /// @return Number of proposal state.
    function getProposalState(uint256 proposalId) external view returns (ProposalState);

    struct Receipt {
        bool hasVoted;
        uint96 votes;
        IGovernanceVoting.VoteType voteType;
    }

    /// @notice Returns the receipt of a voter for a given proposal.
    /// @param proposalId Number of the proposal.
    /// @param voter Address of the voter.
    /// @return Tuple of voter receipt.
    function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory);

    /// @notice Computes the current voting power of the given account.
    /// @param account The address of the account.
    /// @return votingPower The current voting power of the given account.
    function getVotingPower(address account) external view returns (uint256 votingPower);

    struct GovernanceParameters {
        address strategy;
        uint256 proposalThreshold;
        uint256 quorumThreshold;
        TimeType timeType;
    }

    struct EnhancedParams {
        GovernanceParameters params;
        string name;
        string version;
    }

    /// @notice Returns the governance parameters.
    /// @return Tuple of the governance parameters.
    function governanceParameters() external view returns (EnhancedParams memory);

    /// @notice Returns the name of the governace.
    /// @return Human readable string of the name.
    function name() external view returns (string memory);

    /// @notice Returns the total number of proposals.
    /// @return count The number of proposals.
    function proposalCount() external view returns (uint256 count);

    /// @notice Returns all proposals ever made to the governance.
    /// @return proposalWrapper Tuple array of all governance proposals.
    function proposals() external view returns (ProposalWrapper[] memory proposalWrapper);

    /// @notice Returns the voting period.
    /// @return Number of blocks or seconds.
    function votingPeriod() external view returns (uint256);
}