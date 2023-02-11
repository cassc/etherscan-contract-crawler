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

import "../IRigoblockGovernance.sol";
import "./IRigoblockGovernanceFactory.sol";

interface IGovernanceStrategy {
    /// @notice Reverts if initialization paramters are incorrect.
    /// @dev Only used at initialization, as params deleted from factory storage after setup.
    /// @param params Tuple of factory parameters.
    function assertValidInitParams(IRigoblockGovernanceFactory.Parameters calldata params) external view;

    /// @notice Reverts if thresholds are incorrect.
    /// @param proposalThreshold Number of votes required to make a proposal.
    /// @param quorumThreshold Number of votes required for a proposal to succeed.
    function assertValidThresholds(uint256 proposalThreshold, uint256 quorumThreshold) external view;

    /// @notice Returns the state of a proposal for a required quorum.
    /// @param proposal Tuple of the proposal.
    /// @param minimumQuorum Number of votes required for a proposal to pass.
    /// @return Tuple of the proposal state.
    function getProposalState(IRigoblockGovernance.Proposal calldata proposal, uint256 minimumQuorum)
        external
        view
        returns (IRigoblockGovernance.ProposalState);

    /// @notice Return the voting period.
    /// @return Number of seconds of period duration.
    function votingPeriod() external view returns (uint256);

    /// @notice Returns the voting timestamps.
    /// @return startBlockOrTime Timestamp when proposal starts.
    /// @return endBlockOrTime Timestamp when voting ends.
    function votingTimestamps() external view returns (uint256 startBlockOrTime, uint256 endBlockOrTime);

    /// @notice Return a user's voting power.
    /// @param account Address to check votes for.
    function getVotingPower(address account) external view returns (uint256);
}