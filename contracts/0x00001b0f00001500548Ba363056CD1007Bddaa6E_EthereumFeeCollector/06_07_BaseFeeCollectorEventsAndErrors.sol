// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @notice BaseFeeCollectorEventsAndErrors contains errors and events
 *         related to fee collector interaction.
 */
interface BaseFeeCollectorEventsAndErrors {
    /**
     * @dev Emit an event whenever the contract owner registers a
     *      new operator.
     *
     * @param newOperator The new operator of the contract.
     */
    event OperatorUpdated(address newOperator);

    /**
     * @dev Revert with an error when an ERC20 token transfer returns a falsey
     *      value.
     *
     * @param token      The token for which the ERC20 transfer was attempted.
     * @param to         The recipient of the attempted ERC20 transfer.
     * @param amount     The amount for the attempted ERC20 transfer.
     */
    error BadReturnValueFromERC20OnTransfer(
        address token,
        address to,
        uint256 amount
    );

    /**
     * @dev Revert with an error when attempting to withdrawal
     *      an amount greater than the current balance.
     */
    error InvalidNativeTokenAmount(uint256 amount);

    /**
     * @dev Revert with an error when attempting to initialize
     *      outside the constructor.
     */
    error InvalidInitialization();

    /**
     * @dev Revert with an error when attempting to call an operation
     *      while the caller is not the owner of the wallet.
     */
    error InvalidOperator();

    /**
     * @dev Revert with an error when attempting to call a withdrawal
     *      operation with an incorrect withdrawal wallet.
     */
    error InvalidWithdrawalWallet(address withdrawalWallet);

    /**
     * @dev Revert with an error when attempting to set a
     *      new withdrawal wallet and supplying the null address.
     */
    error NewWithdrawalWalletIsNullAddress();

    /**
     * @dev Revert with an error when attempting to set the
     *      new operator and supplying the null address.
     */
    error OperatorIsNullAddress();

    /**
     * @dev Revert with an error when an ERC20, ERC721, or ERC1155 token
     *      transfer reverts.
     *
     * @param token      The token for which the transfer was attempted.
     * @param to         The recipient of the attempted transfer.
     * @param identifier The identifier for the attempted transfer.
     * @param amount     The amount for the attempted transfer.
     */
    error TokenTransferGenericFailure(
        address token,
        address to,
        uint256 identifier,
        uint256 amount
    );
}