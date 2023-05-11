// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

import { IStream } from "../../lib/interfaces/IStream.sol";

/// @title IMilestones
/// @author Matthew Harrison
/// @notice An interface for the Milestones stream contract
interface IMilestones is IStream {
    /// @notice Initialize the contract
    /// @param _owner The owner address of the contract
    /// @param _msPayments The payments for each milestone
    /// @param _msDates The dates for each milestone
    /// @param _tip The tip of the stream, paid to the bot
    /// @param _recipient The recipient address of the stream
    /// @param _token The token used for stream payments
    function initialize(
        address _owner,
        uint256[] calldata _msPayments,
        uint64[] calldata _msDates,
        uint96 _tip,
        address _recipient,
        address _token,
        address _botDAO
    ) external;

    /// @notice Get the current meta information about the stream
    /// @return The current milestone index
    /// @return The current milestone payment
    /// @return The current milestone date
    /// @return The tip of the stream
    /// @return The recipient address of the stream
    function getCurrentMilestone() external view returns (uint48, uint256, uint64, uint96, address);

    /// @notice Get the milestone payment and date via an index
    /// @param index The index of the milestone
    /// @return The milestone payment
    /// @return The milestone date
    function getMilestone(uint88 index) external view returns (uint256, uint64);

    /// @notice Get the length of the milestones array
    /// @return The length of the milestones array
    function getMilestoneLength() external view returns (uint256, uint256);
}