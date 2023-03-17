// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../permit2/src/interfaces/ISignatureTransfer.sol";

// @notice Description of the transfer
// @member recipientAmount Amount of currency to transfer
// @member deadline The timestamp by when the transfer must be in a block.
// @member chainId The chain which the transfer must occur on.
// @member recipient The address which will receive the funds.
// @member recipientCurrency The currency address that amount is priced in.
// @member refundDestination The address which will receive any refunds. If blank, this will be msg.sender.
// @member feeAmount The fee value (in currency) to send to the operator.
// @member id An ID which can be used to track payments.
// @member operator The address of the operator (who created and signed the intent).
// @member signature A hash of all the other struct properties signed by the operator.
// @dev signature=keccak(encodePacked(..allPropsInOrder, chainId, _msgSender(), address(transfersContract))
struct TransferIntent {
    uint256 recipientAmount;
    uint256 deadline;
    address payable recipient;
    address recipientCurrency;
    address refundDestination;
    uint256 feeAmount;
    bytes16 id;
    address operator;
    bytes signature;
}

struct Permit2SignatureTransferData {
    ISignatureTransfer.PermitTransferFrom permit;
    ISignatureTransfer.SignatureTransferDetails transferDetails;
    bytes signature;
}

// @title Transfers Contract
// @notice Functions for making checked transfers between accounts
interface ITransfers {
    // @notice Emitted when a transfer is completed
    // @param operator The operator for the transfer intent
    // @param id The ID of the transfer intent
    // @param recipient Who recieved the funds.
    // @param sender Who sent the funds.
    // @param spentAmount How much the payer sent
    // @param spentCurrency What currency the payer sent
    event Transferred(
        address indexed operator,
        bytes16 id,
        address recipient,
        address sender,
        uint256 spentAmount,
        address spentCurrency
    );

    // @notice Raised when a protocol token transfer fails
    // @param recipient Who the transfer was intended for
    // @param amount The amount of the transfer
    // @param isRefund Whether the transfer was part of a refund
    // @param data The data returned from the failed call
    error NativeTransferFailed(address recipient, uint256 amount, bool isRefund, bytes data);

    // @notice Emitted when an operator is registered
    // @param operator The operator that was registered
    // @param feeDestination The new fee destination for the operator
    event OperatorRegistered(address operator, address feeDestination);

    // @notice Emitted when an operator is unregistered
    // @param operator The operator that was registered
    event OperatorUnregistered(address operator);

    // @notice Raised when the operator in the intent is not registered
    error OperatorNotRegistered();

    // @notice Raised when the intent signature is invalid
    error InvalidSignature();

    // @notice Raised when the invalid amount of native currency is provided
    // @param difference The surplus (or deficit) amount sent
    error InvalidNativeAmount(int256 difference);

    // @notice Raised when the payer does not have enough of the payment token
    // @param difference The balance deficit
    error InsufficientBalance(uint256 difference);

    // @notice Raised when providing an intent with the incorrect currency. e.g. a USDC intent to wrapAndTransfer(..)
    // @param attemptedCurrency The currency the payer attempted to pay with
    error IncorrectCurrency(address attemptedCurrency);

    // @notice Raised when the permit2 transfer details are incorrect
    error InvalidTransferDetails();

    // @notice Raised when an intent is paid past its deadline
    error ExpiredIntent();

    // @notice Raised when an intent's recipient is the null address
    error NullRecipient();

    // @notice Raised when an intent has already been processed
    error AlreadyProcessed();

    // @notice Raised when a refund after a swap fails and returns a reason string
    // @param reason The error reason returned from the swap
    error RefundFailedString(string reason);

    // @notice Raised when a refund after a swap fails and returns another error
    // @param reason The error reason returned from the swap
    error RefundFailedBytes(bytes reason);

    // @notice Raised when a swap fails and returns a reason string
    // @param reason The error reason returned from the swap
    error SwapFailedString(string reason);

    // @notice Raised when a swap fails and returns another error
    // @param reason The error reason returned from the swap
    error SwapFailedBytes(bytes reason);

    // @notice Raised if the swap does not give us enough output token
    error SwapRefundFailed();

    // @notice Raised if the swap does not give us enough output token
    error SwapIncorrectOutput();

    // @notice Transfer the exact amount of currency from the sender to the recipient.
    // @dev If currency is an ERC-20, the user must have approved this contract prior to invoking.
    // @param _intent The intent which describes the transfer
    function transferNative(TransferIntent calldata _intent) external payable;

    // @notice Transfer the exact amount of currency from the sender to the recipient.
    // @dev If currency is an ERC-20, the user must have approved this contract prior to invoking.
    // @param _intent The intent which describes the transfer
    function transferToken(
        TransferIntent calldata _intent,
        Permit2SignatureTransferData calldata _signatureTransferData
    ) external;

    // @notice Takes native currency (e.g. ETH) from the sender and sends wrapped currency (e.g. wETH) to the recipient.
    // @param _intent The intent which describes the transfer
    function wrapAndTransfer(TransferIntent calldata _intent) external payable;

    // @notice Takes wrapped currency (e.g. wETH) from the sender and sends native currency (e.g. ETH) to the recipient.
    // @dev If currency is an ERC-20, the user must have approved this contract prior to invoking.
    // @param _intent The intent which describes the transfer
    function unwrapAndTransfer(
        TransferIntent calldata _intent,
        Permit2SignatureTransferData calldata _signatureTransferData
    ) external;

    // @notice Allows the sender to pay for an intent in any currency using Uniswap.
    // @dev If _providedCurrencyAddress is an ERC-20, the user must have approved this contract prior to invoking.
    // @param _intent The intent which describes the transfer
    // @param _providedCurrencyAddress The currency address which the sender wishes to pay for the intent.
    // @param _maxAmountWillingToPay The maximum amount of _providedCurrencyAddress the sender is willing to pay.
    // @param fee The Uniswap pool fee the user wishes to pay. See: https://docs.uniswap.org/protocol/concepts/V3-overview/fees#pool-fees-tiers
    function swapAndTransferUniswapV3Native(TransferIntent calldata _intent, uint24 poolFeesTier) external payable;

    // @notice Allows the sender to pay for an intent in any currency using Uniswap.
    // @dev If _providedCurrencyAddress is an ERC-20, the user must have approved this contract prior to invoking.
    // @param _intent The intent which describes the transfer
    // @param _providedCurrencyAddress The currency address which the sender wishes to pay for the intent.
    // @param _maxAmountWillingToPay The maximum amount of _providedCurrencyAddress the sender is willing to pay.
    // @param fee The Uniswap pool fee the user wishes to pay. See: https://docs.uniswap.org/protocol/concepts/V3-overview/fees#pool-fees-tiers
    function swapAndTransferUniswapV3Token(
        TransferIntent calldata _intent,
        Permit2SignatureTransferData calldata _signatureTransferData,
        uint24 poolFeesTier
    ) external;
}