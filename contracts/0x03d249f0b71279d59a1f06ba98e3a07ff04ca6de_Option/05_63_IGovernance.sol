// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

/**
 * @title Governance interface.
 * @author DeOrderBook
 * @custom:license
 *
 *                Copyright (c) 2023 DeOrderBook
 *
 *           Licensed under the Apache License, Version 2.0 (the "License");
 *           you may not use this file except in compliance with the License.
 *           You may obtain a copy of the License at
 *
 *               http://www.apache.org/licenses/LICENSE-2.0
 *
 *           Unless required by applicable law or agreed to in writing, software
 *           distributed under the License is distributed on an "AS IS" BASIS,
 *           WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *           See the License for the specific language governing permissions and
 *           limitations under the License.
 *
 * @dev Interface for managing the governance process.
 */
interface IGovernance {
    /**
     * @notice Get the receipt for a given voter on a given proposal
     * @dev Returns the receipt for the specified voter on the specified proposal
     * @param proposalId The ID of the proposal to retrieve the receipt for
     * @param voter The address of the voter to retrieve the receipt for
     * @return The receipt as a tuple (votes, status)
     */
    function getReceipt(uint256 proposalId, address voter) external view returns (uint256, uint8);

    /**
     * @notice Check if a given proposal has been successful
     * @dev Returns a boolean indicating if the specified proposal has been successful
     * @param proposalId The ID of the proposal to check
     * @return A boolean indicating if the proposal was successful
     */
    function isProposalSuccessful(uint256 proposalId) external view returns (bool);

    /**
     * @notice Get the snapshot block number for a given proposal
     * @dev Returns the snapshot block number for the specified proposal
     * @param proposalId The ID of the proposal to retrieve the snapshot for
     * @return The snapshot block number for the proposal
     */
    function proposalSnapshot(uint256 proposalId) external view returns (uint256);

    /**
     * @notice Get the address of the governance executor
     * @dev Returns the address of the governance executor
     * @return The address of the governance executor
     */
    function executor() external view returns (address);
}