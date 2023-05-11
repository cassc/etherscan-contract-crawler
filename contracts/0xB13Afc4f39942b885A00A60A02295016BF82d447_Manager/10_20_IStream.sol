// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

import { IPausable } from "../../utils/interfaces/IPausable.sol";

/// @title IStream
/// @author Matthew Harrison
/// @notice An interface for the Stream contract
interface IStream is IPausable {
    /// @notice The address of the token for payments
    function token() external view returns (address);

    /// @notice The address of the of the botDAO
    function botDAO() external view returns (address);

    /// @notice Emits event when funds are disbursed
    /// @param streamId contract address of the stream
    /// @param amount amount of funds disbursed
    /// @param streamType type of stream
    event FundsDisbursed(address streamId, uint256 amount, string streamType);

    /// @notice Emits event when funds are disbursed
    /// @param streamId contract address of the stream
    /// @param amount amount of funds withdrawn
    event Withdraw(address streamId, uint256 amount);

    /// @notice Emits event when recipient is changed
    /// @param oldRecipient old recipient address
    /// @param newRecipient new recipient address
    event RecipientChanged(address oldRecipient, address newRecipient);

    /// @dev Thrown if the start date is greater than the end date
    error INCORRECT_DATE_RANGE();

    /// @dev Thrown if if the stream has not started
    error STREAM_HASNT_STARTED();

    /// @dev Thrown if the stream has made its final payment
    error STREAM_FINISHED();

    /// @dev Thrown if msg.sender is not the recipient
    error ONLY_RECIPIENT();

    /// @dev Thrown if the transfer failed.
    error TRANSFER_FAILED();

    /// @dev Thrown if the stream is an ERC20 stream and reverts if ETH was sent.
    error NO_ETHER();

    /// @notice Retrieve the current balance of a stream
    function balance() external returns (uint256);

    /// @notice Retrieve the next payment of a stream
    function nextPayment() external returns (uint256);

    /// @notice Release of streams
    /// @return amount of funds released
    function release() external returns (uint256);

    /// @notice Release funds of a single stream with no tip payout
    function claim() external returns (uint256);

    /// @notice Withdraw funds from smart contract, only the owner can do this.
    function withdraw() external;

    /// // @notice Unpause stream
    function unpause() external;

    /// @notice Change the recipient address
    /// @param newRecipient The new recipient address
    function changeRecipient(address newRecipient) external;
}