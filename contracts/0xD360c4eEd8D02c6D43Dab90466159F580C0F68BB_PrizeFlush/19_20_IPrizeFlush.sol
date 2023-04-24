// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "../../core/interfaces/IControlledToken.sol";
import "../../core/interfaces/IPrizePool.sol";
import "../../core/interfaces/IReserve.sol";

interface IPrizeFlush {
    /**
     * @notice Emit when the flush function has executed.
     * @param destination Address receiving funds
     * @param amount      Amount of tokens transferred
     */
    event Flushed(address indexed destination, uint256 amount);

    /**
     * @notice Emit when destination is set.
     * @param destination Destination address
     */
    event DestinationSet(address destination);

    /**
     * @notice Emit when capturing the award amount from PrizePool.
     * @param totalPrizeCaptured Total prize captured from the PrizePool
     */
    event Distributed(uint256 totalPrizeCaptured);

    /**
     * @notice Emit when an individual prize split is awarded.
     * @param user         User address being awarded
     * @param prizeAwarded Awarded prize amount
     * @param token        Token address
     */
    event PrizeAwarded(
        address indexed user,
        uint256 prizeAwarded,
        IControlledToken indexed token
    );

    /**
     * @notice Emit when reserve is set.
     * @param reserve Reserve address
     */
    event ReserveSet(IReserve reserve);

    /**
     * @notice Emit when prizePool is set.
     * @param prizePool PrizePool address
     */
    event PrizePoolSet(IPrizePool prizePool);

    /**
     * @notice Emit when protocolFeeRecipient is set.
     * @param protocolFeeRecipient ProtocolFeeRecipient address
     */
    event ProtocolFeeRecipientSet(address protocolFeeRecipient);

    /**
     * @notice Emit when protocolFeePercentage is set.
     * @param protocolFeePercentage ProtocolFeePercentage number
     */
    event ProtocolPercentageSet(uint16 protocolFeePercentage);

    /// @notice Read global destination variable. It shows where the funds will
    ///         be moved at the end.
    function getDestination() external view returns (address);

    /// @notice Read global reserve variable. Contract that tracks funds earned
    ///         over time periods.
    function getReserve() external view returns (IReserve);

    /// @notice Read global prizePool variable. Pool from where to capture the
    ///         award balance.
    function getPrizePool() external view returns (IPrizePool);

    /// @notice Read global ProtocolFeeRecipient variable. Address that will
    ///         receive the protocolFee.
    function getProtocolFeeRecipient() external view returns (address);

    /// @notice Read global ProtocolFeePercentage variable. Portion of the
    ///abi      obtained yield that will be paid to the protocol as a fee.
    function getProtocolFeePercentage() external view returns (uint16);

    /// @notice Set global destination variable. PrizeDistributor contract that
    ///         will receive the obtained yield.
    function setDestination(address _destination) external returns (address);

    /// @notice Set global reserve variable.
    function setReserve(IReserve _reserve) external returns (IReserve);

    /// @notice Set global prizePool variable. PrizePool from where to get the
    ///abi      yield from.
    function setPrizePool(IPrizePool _prizePool) external returns (IPrizePool);

    /// @notice Set global protocolFeeRecipient variable.
    function setProtocolFeeRecipient(
        address _protocolFeeRecipient
    ) external returns (address);

    /// @notice Set global protocolFeePercentage variable.
    function setProtocolFeePercentage(
        uint16 _protocolFeePercentage
    ) external returns (uint16);

    /**
     * @notice Migrate interest from PrizePool to PrizeDistributor and the
     *         protocolFeeRecipient in a single transaction.
     * @dev    Captures interest, checkpoint data and transfers tokens to final
     *         destination.
     * @return True if operation is successful.
     */
    function flush() external returns (bool);
}