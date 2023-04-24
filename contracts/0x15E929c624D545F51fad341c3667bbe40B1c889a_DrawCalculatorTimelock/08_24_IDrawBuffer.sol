// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./IDrawBeacon.sol";

/**
 * @title  IDrawBuffer
 * @author Asymetrix Protocol Inc Team
 * @notice The DrawBuffer interface.
 */
interface IDrawBuffer {
    /**
     * @notice Emit when a new draw has been created.
     * @param drawId Draw id
     * @param draw The Draw struct
     */
    event DrawSet(uint32 indexed drawId, IDrawBeacon.Draw draw);

    /**
     * @notice Emit when a new PrizeDistributor contract address is set.
     * @param prizeDistributor A new PrizeDistributor contract address
     */
    event PrizeDistributorSet(address prizeDistributor);

    /**
     * @notice Emit when draw is marked is paid.
     * @param drawId An ID of a draw that was marked as paid
     */
    event DrawMarkedAsPaid(uint32 drawId);

    /**
     * @notice Read a PrizeDistributor contract address.
     * @return A PrizeDistributor contract address.
     */
    function getPrizeDistributor() external view returns (address);

    /**
     * @notice Read a ring buffer cardinality.
     * @return Ring buffer cardinality.
     */
    function getBufferCardinality() external view returns (uint32);

    /**
     * @notice Read a Draw from the draws ring buffer.
     * @dev    Read a Draw using the Draw.drawId to calculate position in the
     *         draws ring buffer.
     * @param drawId Draw.drawId
     * @return IDrawBeacon.Draw
     */
    function getDraw(
        uint32 drawId
    ) external view returns (IDrawBeacon.Draw memory);

    /**
     * @notice Read multiple Draws from the draws ring buffer.
     * @dev    Read multiple Draws using each drawId to calculate position in
     *         the draws ring buffer.
     * @param drawIds Array of drawIds
     * @return IDrawBeacon.Draw[] array with the draw information of the
     *         requested draw ids
     */
    function getDraws(
        uint32[] calldata drawIds
    ) external view returns (IDrawBeacon.Draw[] memory);

    /**
     * @notice Gets the number of Draws held in the draw ring buffer.
     * @dev    If no Draws have been pushed, it will return 0.
     * @dev    If the ring buffer is full, it will return the cardinality.
     * @dev    Otherwise, it will return the NewestDraw index + 1.
     * @return Number of Draws held in the draw ring buffer.
     */
    function getDrawCount() external view returns (uint32);

    /**
     * @notice Read newest Draw from draws ring buffer.
     * @dev    Uses the nextDrawIndex to calculate the most recently added Draw.
     * @return IDrawBeacon.Draw
     */
    function getNewestDraw() external view returns (IDrawBeacon.Draw memory);

    /**
     * @notice Read oldest Draw from draws ring buffer.
     * @dev    Finds the oldest Draw by comparing and/or diffing totalDraws with
     *         the cardinality.
     * @return IDrawBeacon.Draw
     */
    function getOldestDraw() external view returns (IDrawBeacon.Draw memory);

    /**
     * @notice Push Draw onto draws ring buffer history.
     * @dev    Push new draw onto draws history via authorized manager or owner.
     * @param draw IDrawBeacon.Draw
     * @return Draw.drawId
     */
    function pushDraw(IDrawBeacon.Draw calldata draw) external returns (uint32);

    /**
     * @notice Set existing Draw in draws ring buffer with new parameters.
     * @dev    Updating a Draw should be used sparingly and only in the event an
     *         incorrect Draw parameter has been stored.
     * @param newDraw IDrawBeacon.Draw
     * @return Draw.drawId
     */
    function setDraw(
        IDrawBeacon.Draw calldata newDraw
    ) external returns (uint32);

    /**
     * @notice Set a new PrizeDistributor contract address.
     * @param prizeDistributor A new PrizeDistributor contract address
     */
    function setPrizeDistributor(address prizeDistributor) external;

    /**
     * @notice Mark a draw as paid.
     * @dev    It means that the winners of the draw were paid and the draw can
     *         not be paid again.
     * @param drawId An ID of a draw that should be marked as paid
     */
    function markDrawAsPaid(uint32 drawId) external;
}