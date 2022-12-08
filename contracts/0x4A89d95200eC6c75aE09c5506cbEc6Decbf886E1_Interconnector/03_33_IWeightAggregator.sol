// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

interface IWeightAggregator {
    /**
     * @notice Returns Buyback weight for the user
     */
    function getBuybackWeight(address account) external view returns (uint256);

    /**
     * @notice Return voting weight for the user
     */
    function getVotingWeight(address account) external view returns (uint256);
}