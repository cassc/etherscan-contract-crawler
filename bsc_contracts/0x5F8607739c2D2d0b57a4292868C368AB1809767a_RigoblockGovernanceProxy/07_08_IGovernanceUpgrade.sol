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

interface IGovernanceUpgrade {
    /// @notice Updates the proposal and quorum thresholds to the given values.
    /// @dev Only callable by the governance contract itself.
    /// @dev Thresholds can only be updated via a successful governance proposal.
    /// @param newProposalThreshold The new value for the proposal threshold.
    /// @param newQuorumThreshold The new value for the quorum threshold.
    function updateThresholds(uint256 newProposalThreshold, uint256 newQuorumThreshold) external;

    /// @notice Updates the governance implementation address.
    /// @dev Only callable after successful voting.
    /// @param newImplementation Address of the new governance implementation contract.
    function upgradeImplementation(address newImplementation) external;

    /// @notice Updates the governance strategy plugin.
    /// @dev Only callable by the governance contract itself.
    /// @param newStrategy Address of the new strategy contract.
    function upgradeStrategy(address newStrategy) external;
}