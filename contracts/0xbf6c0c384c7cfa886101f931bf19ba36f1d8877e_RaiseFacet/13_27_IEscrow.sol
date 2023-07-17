// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

/// @notice Interface for escrow contract.
interface IEscrow {
    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev Struct used in 'withdraw' and 'batchWithdraw' function to store receiver data.
    /// @param receiver Receiver address
    /// @param amount Amount to send for the given receiver
    struct ReceiverData {
        address receiver;
        uint256 amount;
    }

    // -----------------------------------------------------------------------
    //                              Events
    // -----------------------------------------------------------------------

    event Withdraw(address token, address receiver, uint256 amount);

    // -----------------------------------------------------------------------
    //                              Errors
    // -----------------------------------------------------------------------

    error InvalidSender(address sender, address expected); // 0xe1130dba
    error DataMismatch(); // 0x866c41db

    // -----------------------------------------------------------------------
    //                          External functions
    // -----------------------------------------------------------------------

    /// @dev Withdrawal of asset from escrow to user.
    /// @param _token Token to transfer
    /// @param _receiverData Receiver data (address and amount)
    function withdraw(address _token, ReceiverData calldata _receiverData) external;

    /// @dev Withdrawal of asset in batch from escrow to users.
    /// @param _token Token to transfer
    /// @param _receiverData Array of receivers data (addresses and amounts)
    function batchWithdraw(address _token, ReceiverData[] calldata _receiverData) external;
}