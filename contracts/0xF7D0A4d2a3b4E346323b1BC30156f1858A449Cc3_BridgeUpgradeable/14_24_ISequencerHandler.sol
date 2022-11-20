// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
    @title Interface for handler that handles sequencer deposits and deposit executions.
    @author Router Protocol.
 */
interface ISequencerHandler {
    /// @notice Function fired to trigger Cross Chain Communication.
    /// @dev Used to transact generic calls as well as ERC20 cross-chain calls at once.
    /// @dev Can only be used when the contract is not paused and the dest chain is not unsupported.
    /// @dev Only callable by crosstalk contracts on supported chains and only when contract is not paused.
    /// @param _destChainID chainId of the destination chain defined by Router Protocol.
    /// @param _erc20 data regarding the transaction for erc20.
    /// @param _swapData data regarding the swapDetails for erc20 transaction.
    /// @param _generic data for generic cross-chain call.
    /// @param _gasLimit gas limit for the call.
    /// @param _gasPrice gas price for the call.
    /// @param _feeToken fee token for payment of fees.
    /// @param _isTransferFirst sequence for erc20 and generic call. True for prioritizing erc20 over generic call.
    function genericDepositWithERC(
        uint8 _destChainID,
        bytes memory _erc20,
        bytes calldata _swapData,
        bytes memory _generic,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken,
        bool _isTransferFirst
    ) external returns (uint64);

    /// @notice Function fired to trigger Cross Chain Communication.
    /// @dev Used to transact generic calls as well as ERC20 cross-chain calls at once.
    /// @dev Can only be used when the contract is not paused and the dest chain is not unsupported.
    /// @dev Only callable by crosstalk contracts on supported chains and only when contract is not paused.
    /// @param _destChainID chainId of the destination chain defined by Router Protocol.
    /// @param _erc20 data regarding the transaction for erc20.
    /// @param _swapData data regarding the swapDetails for erc20 transaction.
    /// @param _generic data for generic cross-chain call.
    /// @param _gasLimit gas limit for the call.
    /// @param _gasPrice gas price for the call.
    /// @param _feeToken fee token for payment of fees.
    /// @param _isTransferFirst sequence for erc20 and generic call. True for prioritizing erc20 over generic call.
    function genericDepositWithETH(
        uint8 _destChainID,
        bytes memory _erc20,
        bytes calldata _swapData,
        bytes memory _generic,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken,
        bool _isTransferFirst
    ) external payable returns (uint64);

    /// @notice Function fired to trigger Cross Chain Communication.
    /// @dev Used to transact generic calls.
    /// @dev Can only be used when the contract is not paused and the dest chain is not unsupported.
    /// @dev Only callable by crosstalk contracts on supported chains and only when contract is not paused.
    /// @param _destChainID chainId of the destination chain defined by Router Protocol.
    /// @param _generic data for generic cross-chain call.
    /// @param _gasLimit gas limit for the call.
    /// @param _gasPrice gas price for the call.
    /// @param _feeToken fee token for payment of fees.
    function genericDeposit(
        uint8 _destChainID,
        bytes memory _generic,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken
    ) external returns (uint64);

    /// @notice Function Executes a cross chain request on destination chain.
    /// @dev Can only be triggered by bridge.
    /// @param  _data Cross chain data recived from relayer consisting of the deposit record.
    function executeProposal(bytes calldata _data) external returns (bool);

    /// @notice Function to replay a transaction which was stuck due to underpricing of gas.
    /// @param  _destChainID Destination ChainID
    /// @param  _depositNonce Nonce for the transaction.
    /// @param  _gasLimit Gas limit allowed for the transaction.
    /// @param  _gasPrice Gas Price for the transaction.
    function replayDeposit(
        uint8 _destChainID,
        uint64 _depositNonce,
        uint256 _gasLimit,
        uint256 _gasPrice
    ) external;

    /// @notice Fetches chainID for the native chain
    function fetch_chainID() external view returns (uint8);
}