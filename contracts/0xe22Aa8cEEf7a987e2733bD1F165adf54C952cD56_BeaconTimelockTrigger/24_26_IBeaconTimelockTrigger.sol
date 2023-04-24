// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "../../core/interfaces/IDrawBeacon.sol";

import "./IPrizeDistributionFactory.sol";
import "./IDrawCalculatorTimelock.sol";

/**
 * @title  Asymetrix Protocol V1 IBeaconTimelockTrigger
 * @author Asymetrix Protocol Inc Team
 * @notice The IBeaconTimelockTrigger smart contract interface.
 */
interface IBeaconTimelockTrigger {
    /// @notice Emitted when the contract is deployed.
    event Deployed(
        IPrizeDistributionFactory indexed prizeDistributionFactory,
        IDrawCalculatorTimelock indexed timelock
    );

    /**
     * @notice Emitted when Draw is locked and totalNetworkTicketSupply is
     *         pushed to PrizeDistributionFactory
     * @param drawId Draw ID
     * @param draw Draw
     * @param totalNetworkTicketSupply totalNetworkTicketSupply
     */
    event DrawLockedAndTotalNetworkTicketSupplyPushed(
        uint32 indexed drawId,
        IDrawBeacon.Draw draw,
        uint256 totalNetworkTicketSupply
    );

    /**
     * @notice Locks next Draw, logs the totalNetworkTicketSupply to
     *         PrizeDistributionFactory and triggers the prize distribution push.
     * @dev    Restricts new draws for N seconds by forcing timelock on the next
     *         target draw id.
     * @param draw Draw
     * @param totalNetworkTicketSupply totalNetworkTicketSupply
     */
    function push(
        IDrawBeacon.Draw memory draw,
        uint256 totalNetworkTicketSupply
    ) external;
}