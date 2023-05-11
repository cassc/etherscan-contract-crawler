pragma solidity 0.8.17;

import { IStream } from "../../lib/interfaces/IStream.sol";

/// @title IIntervals
/// @author Matthew Harrison
/// @notice An interface for the Intervals stream contract
interface IIntervals is IStream {
    /// @notice Initialize the contract
    /// @param _owner The owner address of the contract
    /// @param _startDate The start date of the stream
    /// @param _endDate The end date of the stream
    /// @param _interval The interval of the stream
    /// @param _tip The tip of the stream, paid to the bot
    /// @param _owed The amount owed to the recipient
    /// @param _recipient The recipient address of the stream
    /// @param _token The token address of the stream
    function initialize(
        address _owner,
        uint64 _startDate,
        uint64 _endDate,
        uint32 _interval,
        uint96 _tip,
        uint256 _owed,
        address _recipient,
        address _token,
        address _botDAO
    ) external;

    /// @notice Get the current meta information about the stream
    /// @return The start date of the stream
    /// @return The end date of the stream
    /// @return The interval of the stream
    /// @return The tip of the stream
    /// @return The amount paid to the recipient
    /// @return The amount owed to the recipient
    /// @return The recipient address of the stream
    function getCurrentInterval() external view returns (uint64, uint64, uint32, uint96, uint256, uint256, address);
}