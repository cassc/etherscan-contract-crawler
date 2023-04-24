// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "../interfaces/IPrizeDistributionBuffer.sol";
import "../interfaces/IPrizeDistributor.sol";

import "./IDrawBuffer.sol";
import "./ITicket.sol";

/**
 * @title  Asymetrix Protocol V1 IDrawCalculator
 * @author Asymetrix Protocol Inc Team
 * @notice The DrawCalculator interface.
 */
interface IDrawCalculator {
    ///@notice Emitted when the contract is initialized
    event Deployed(
        ITicket indexed ticket,
        IDrawBuffer indexed drawBuffer,
        IPrizeDistributionBuffer indexed prizeDistributionBuffer
    );

    ///@notice Emitted when the prizeDistributor is set/updated
    event PrizeDistributorSet(IPrizeDistributor indexed prizeDistributor);

    /**
     * @notice Calculates the prize amount for a user for Multiple Draws.
     *         Typically called by a PrizeDistributor.
     * @param user User for which to calculate prize amount.
     * @param drawIds drawId array for which to calculate prize amounts for.
     * @return List of number of user picks ordered by drawId.
     */
    function calculateNumberOfUserPicks(
        address user,
        uint32[] calldata drawIds
    ) external view returns (uint256[] memory);

    /**
     * @notice Read global DrawBuffer variable.
     * @return IDrawBuffer
     */
    function getDrawBuffer() external view returns (IDrawBuffer);

    /**
     * @notice Read global prizeDistributionBuffer variable.
     * @return IPrizeDistributionBuffer
     */
    function getPrizeDistributionBuffer()
        external
        view
        returns (IPrizeDistributionBuffer);

    /**
     * @notice Returns a users balances expressed as a fraction of the total
     *         supply over time.
     * @param user The users address
     * @param drawIds The drawIds to consider
     * @return Array of balances
     */
    function getNormalizedBalancesForDrawIds(
        address user,
        uint32[] calldata drawIds
    ) external view returns (uint256[] memory);
}