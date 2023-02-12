// SPDX-License-Identifier: Apache 2.0
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

import "../../../../governance/IRigoblockGovernance.sol";

interface IAGovernance {
    /// @notice Allows to make a proposal to the Rigoblock governance.
    /// @param actions Array of tuples of proposed actions.
    /// @param description A human-readable description.
    function propose(IRigoblockGovernance.ProposedAction[] memory actions, string memory description) external;

    /// @notice Allows a pool to vote on a proposal.
    /// @param proposalId Number of the proposal.
    /// @param voteType Enum of the vote type.
    function castVote(uint256 proposalId, IRigoblockGovernance.VoteType voteType) external;

    /// @notice Allows a pool to execute a proposal.
    /// @param proposalId Number of the proposal.
    function execute(uint256 proposalId) external;
}