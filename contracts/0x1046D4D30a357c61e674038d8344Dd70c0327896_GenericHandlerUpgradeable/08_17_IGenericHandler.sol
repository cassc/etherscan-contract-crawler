// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/// @title Interface for handler that handles generic deposits and deposit executions.
/// @author Router Protocol.
interface IGenericHandler {
    function genericDeposit(
        uint8 _destChainID,
        bytes4 _selector,
        bytes calldata _data,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken
    ) external returns (uint64);

    function executeProposal(bytes calldata data) external;

    /// @notice Function to replay a transaction which was stuck due to underpricing of gas
    /// @param  _destChainID Destination ChainID
    /// @param  _depositNonce Nonce for the transaction.
    /// @param  _gasLimit Gas limit allowed for the transaction.
    /// @param  _gasPrice Gas Price for the transaction.
    function replayGenericDeposit(
        uint8 _destChainID,
        uint64 _depositNonce,
        uint256 _gasLimit,
        uint256 _gasPrice
    ) external;
}