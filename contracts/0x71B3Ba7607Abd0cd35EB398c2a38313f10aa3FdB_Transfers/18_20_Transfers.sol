// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../interfaces/IWrappedNativeCurrency.sol";
import "../interfaces/ITransfers.sol";
import "../interfaces/IUniswapRouter.sol";
import "../utils/Sweepable.sol";
import "../permit2/src/interfaces/ISignatureTransfer.sol";

import "hardhat/console.sol";

// @inheritdoc ITransfers
contract Transfers is Context, Ownable, Pausable, ReentrancyGuard, Sweepable, ITransfers {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWrappedNativeCurrency;

    // @dev Map of operator addresses and fee destinations.
    mapping(address => address) private feeDestinations;

    // @dev Map of operator addresses to a map of transfer intent ids that have been processed
    mapping(address => mapping(bytes16 => bool)) private processedTransferIntents;

    // @dev Represents native token of a chain (e.g. ETH or MATIC)
    address private immutable NATIVE_CURRENCY = address(0);

    // @dev Uniswap on-chain contract
    IUniswapRouter private immutable uniswap;

    // @dev permit2 SignatureTransfer contract address. Used for tranferring tokens with a signature instead of a full transaction.
    // See: https://github.com/Uniswap/permit2
    ISignatureTransfer public immutable permit2;

    // @dev Canonical wrapped token for this chain. e.g. (wETH or wMATIC).
    IWrappedNativeCurrency private immutable wrappedNativeCurrency;

    // @param _uniswap The address of the Uniswap V3 swap router
    // @param _wrappedNativeCurrency The address of the wrapped token for this chain
    constructor(
        IUniswapRouter _uniswap,
        ISignatureTransfer _permit2,
        address _initialOperator,
        address _initialFeeDestination,
        IWrappedNativeCurrency _wrappedNativeCurrency
    ) {
        uniswap = _uniswap;
        permit2 = _permit2;
        wrappedNativeCurrency = _wrappedNativeCurrency;

        // Sets an initial operator to enable immediate payment processing
        feeDestinations[_initialOperator] = _initialFeeDestination;
    }

    // @dev Raises errors if the intent is invalid
    // @param _intent The intent to validate
    modifier validIntent(TransferIntent calldata _intent) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                _intent.recipientAmount,
                _intent.deadline,
                _intent.recipient,
                _intent.recipientCurrency,
                _intent.refundDestination,
                _intent.feeAmount,
                _intent.id,
                _intent.operator,
                block.chainid,
                _msgSender(),
                address(this)
            )
        );

        bytes32 signedMessageHash;
        if (_intent.prefix.length == 0) {
            // Use 'default' message prefix.
            signedMessageHash = ECDSA.toEthSignedMessageHash(hash);
        } else {
            // Use custom message prefix.
            signedMessageHash = keccak256(abi.encodePacked(_intent.prefix, hash));
        }

        address signer = ECDSA.recover(signedMessageHash, _intent.signature);

        if (signer != _intent.operator) {
            revert InvalidSignature();
        }

        if (_intent.deadline < block.timestamp) {
            revert ExpiredIntent();
        }

        if (_intent.recipient == address(0)) {
            revert NullRecipient();
        }

        if (processedTransferIntents[_intent.operator][_intent.id]) {
            revert AlreadyProcessed();
        }

        _;
    }

    // @dev Raises an error if the operator in the transfer intent is not registered.
    // @param _intent The intent to validate
    modifier operatorIsRegistered(TransferIntent calldata _intent) {
        if (feeDestinations[_intent.operator] == address(0)) revert OperatorNotRegistered();

        _;
    }

    modifier exactValueSent(TransferIntent calldata _intent) {
        // Make sure the correct value was sent
        uint256 neededAmount = _intent.recipientAmount + _intent.feeAmount;
        if (msg.value > neededAmount) {
            revert InvalidNativeAmount(int256(msg.value - neededAmount));
        } else if (msg.value < neededAmount) {
            revert InvalidNativeAmount(-int256(neededAmount - msg.value));
        }

        _;
    }

    // @inheritdoc ITransfers
    function transferNative(TransferIntent calldata _intent)
        external
        payable
        override
        nonReentrant
        whenNotPaused
        validIntent(_intent)
        operatorIsRegistered(_intent)
        exactValueSent(_intent)
    {
        // Make sure the recipient wants the native currency
        if (_intent.recipientCurrency != NATIVE_CURRENCY) revert IncorrectCurrency(NATIVE_CURRENCY);

        // Complete the payment
        transferFundsToDestinations(_intent);
        succeedPayment(_intent, msg.value, NATIVE_CURRENCY);
    }

    // @inheritdoc ITransfers
    function transferToken(
        TransferIntent calldata _intent,
        Permit2SignatureTransferData calldata _signatureTransferData
    ) external override nonReentrant whenNotPaused validIntent(_intent) operatorIsRegistered(_intent) {
        // Make sure the recipient wants a token and the payer is sending it
        if (
            _intent.recipientCurrency == NATIVE_CURRENCY ||
            _signatureTransferData.permit.permitted.token != _intent.recipientCurrency
        ) {
            revert IncorrectCurrency(_signatureTransferData.permit.permitted.token);
        }

        // Make sure the payer has enough of the payment token
        IERC20 erc20 = IERC20(_intent.recipientCurrency);
        uint256 neededAmount = _intent.recipientAmount + _intent.feeAmount;
        uint256 payerBalance = erc20.balanceOf(_msgSender());
        if (payerBalance < neededAmount) {
            revert InsufficientBalance(neededAmount - payerBalance);
        }

        // Make sure the payer is transferring the right amount to this contract
        if (
            _signatureTransferData.transferDetails.to != address(this) ||
            _signatureTransferData.transferDetails.requestedAmount != neededAmount
        ) {
            revert InvalidTransferDetails();
        }

        // Transfer the payment token to this contract
        permit2.permitTransferFrom(
            _signatureTransferData.permit,
            _signatureTransferData.transferDetails,
            _msgSender(),
            _signatureTransferData.signature
        );

        // Complete the payment
        transferFundsToDestinations(_intent);
        succeedPayment(_intent, neededAmount, _intent.recipientCurrency);
    }

    // @inheritdoc ITransfers
    // @dev Wraps msg.value into wrapped token and transfers to recipient.
    function wrapAndTransfer(TransferIntent calldata _intent)
        external
        payable
        override
        nonReentrant
        whenNotPaused
        validIntent(_intent)
        operatorIsRegistered(_intent)
        exactValueSent(_intent)
    {
        // Make sure the recipient wants to receive the wrapped native currency
        if (_intent.recipientCurrency != address(wrappedNativeCurrency)) revert IncorrectCurrency(NATIVE_CURRENCY);

        // Wrap the sent native currency
        wrappedNativeCurrency.deposit{value: msg.value}();

        // Complete the payment
        transferFundsToDestinations(_intent);
        succeedPayment(_intent, msg.value, NATIVE_CURRENCY);
    }

    // @inheritdoc ITransfers
    // @dev Requires _msgSender() to have approved this contract to use the wrapped token.
    // @dev Unwraps into native token and transfers native token (e.g. ETH) to _intent.recipient.
    function unwrapAndTransfer(
        TransferIntent calldata _intent,
        Permit2SignatureTransferData calldata _signatureTransferData
    ) external override nonReentrant whenNotPaused validIntent(_intent) operatorIsRegistered(_intent) {
        // Make sure the recipient wants the native currency and that the payer is
        // sending the wrapped native currency
        if (
            _intent.recipientCurrency != NATIVE_CURRENCY ||
            _signatureTransferData.permit.permitted.token != address(wrappedNativeCurrency)
        ) {
            revert IncorrectCurrency(_signatureTransferData.permit.permitted.token);
        }

        // Make sure the payer has enough of the wrapped native currency
        uint256 neededAmount = _intent.recipientAmount + _intent.feeAmount;
        uint256 payerBalance = wrappedNativeCurrency.balanceOf(_msgSender());
        if (payerBalance < neededAmount) {
            revert InsufficientBalance(neededAmount - payerBalance);
        }

        // Make sure the payer is transferring the right amount of the wrapped native currency to the contract
        if (
            _signatureTransferData.transferDetails.to != address(this) ||
            _signatureTransferData.transferDetails.requestedAmount != neededAmount
        ) {
            revert InvalidTransferDetails();
        }

        // Transfer the payer's wrapped native currency to the contract
        permit2.permitTransferFrom(
            _signatureTransferData.permit,
            _signatureTransferData.transferDetails,
            _msgSender(),
            _signatureTransferData.signature
        );

        // Complete the payment
        unwrapAndTransferFundsToDestinations(_intent);
        succeedPayment(_intent, neededAmount, address(wrappedNativeCurrency));
    }

    /*------------------------------------------------------------------*\
    | Swap and Transfer
    \*------------------------------------------------------------------*/

    // @inheritdoc ITransfers
    function swapAndTransferUniswapV3Native(TransferIntent calldata _intent, uint24 poolFeesTier)
        external
        payable
        override
        nonReentrant
        whenNotPaused
        validIntent(_intent)
        operatorIsRegistered(_intent)
    {
        // Perform the swap
        uint256 amountSwapped = swapTokens(_intent, address(wrappedNativeCurrency), msg.value, poolFeesTier);

        // Return any native currency not used for the swap
        sendNative(_msgSender(), msg.value - amountSwapped, true);

        // Complete the payment
        unwrapAndTransferFundsToDestinations(_intent);
        succeedPayment(_intent, amountSwapped, NATIVE_CURRENCY);
    }

    // @inheritdoc ITransfers
    function swapAndTransferUniswapV3Token(
        TransferIntent calldata _intent,
        Permit2SignatureTransferData calldata _signatureTransferData,
        uint24 poolFeesTier
    ) external override nonReentrant whenNotPaused validIntent(_intent) operatorIsRegistered(_intent) {
        // Make sure the transfer is to this contract
        if (_signatureTransferData.transferDetails.to != address(this)) {
            revert InvalidTransferDetails();
        }

        // Transfer the payer's tokens to this contract
        permit2.permitTransferFrom(
            _signatureTransferData.permit,
            _signatureTransferData.transferDetails,
            _msgSender(),
            _signatureTransferData.signature
        );

        // Make sure uniswap can move the input tokens
        IERC20 tokenIn = IERC20(_signatureTransferData.permit.permitted.token);

        if (tokenIn.allowance(address(this), address(uniswap)) != 0) {
            tokenIn.safeApprove(address(uniswap), 0);
        }

        tokenIn.safeApprove(address(uniswap), type(uint256).max);

        // Perform the swap
        uint256 maxWillingToPay = _signatureTransferData.transferDetails.requestedAmount;
        uint256 amountSwapped = swapTokens(_intent, address(tokenIn), maxWillingToPay, poolFeesTier);

        // Return any of the input token not used for the swap
        uint256 refundAmount = maxWillingToPay - amountSwapped;
        if (tokenIn.balanceOf(address(this)) < refundAmount) {
            revert SwapRefundFailed();
        }
        tokenIn.safeTransfer(_msgSender(), refundAmount);

        // Complete the payment
        unwrapAndTransferFundsToDestinations(_intent);
        succeedPayment(_intent, amountSwapped, address(tokenIn));
    }

    function swapTokens(
        TransferIntent calldata _intent,
        address tokenIn,
        uint256 maxAmountWillingToPay,
        uint24 poolFeesTier
    ) internal returns (uint256) {
        // If the seller is requesting native currency, we need to swap for the wrapped
        // version of that currency first, then unwrap it and send it to the seller.
        address tokenOut = _intent.recipientCurrency == NATIVE_CURRENCY
            ? address(wrappedNativeCurrency)
            : _intent.recipientCurrency;

        uint256 neededAmount = _intent.recipientAmount + _intent.feeAmount;

        // Set up the parameters for exactOutputSingle
        IUniswapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: poolFeesTier,
            recipient: address(this),
            deadline: _intent.deadline,
            amountOut: neededAmount,
            amountInMaximum: maxAmountWillingToPay,
            sqrtPriceLimitX96: 0
        });

        IERC20 tokenOutContract = IERC20(tokenOut);
        uint256 tokenOutBalance = tokenOutContract.balanceOf(address(this));

        // Execute the swap. The exact amount of the provided currency used is returned.
        try uniswap.exactOutputSingle{value: msg.value}(params) returns (uint256 amountSpent) {
            if (tokenOutContract.balanceOf(address(this)) - tokenOutBalance != neededAmount) {
                revert SwapIncorrectOutput();
            }
            // Request any excess native currency be transferred from Uniswap back to this contract
            try uniswap.refundETH() {
                return amountSpent;
            } catch Error(string memory reason) {
                revert RefundFailedString(reason);
            } catch (bytes memory reason) {
                revert RefundFailedBytes(reason);
            }
        } catch Error(string memory reason) {
            revert SwapFailedString(reason);
        } catch (bytes memory reason) {
            revert SwapFailedBytes(reason);
        }
    }

    function transferFundsToDestinations(TransferIntent calldata _intent) internal {
        if (_intent.recipientCurrency == NATIVE_CURRENCY) {
            sendNative(_intent.recipient, _intent.recipientAmount, false);
            sendNative(feeDestinations[_intent.operator], _intent.feeAmount, false);
        } else {
            IERC20 requestedCurrency = IERC20(_intent.recipientCurrency);
            requestedCurrency.safeTransfer(_intent.recipient, _intent.recipientAmount);
            requestedCurrency.safeTransfer(feeDestinations[_intent.operator], _intent.feeAmount);
        }
    }

    function unwrapAndTransferFundsToDestinations(TransferIntent calldata _intent) internal {
        if (_intent.recipientCurrency == NATIVE_CURRENCY) {
            wrappedNativeCurrency.withdraw(_intent.recipientAmount + _intent.feeAmount);
        }
        transferFundsToDestinations(_intent);
    }

    function succeedPayment(
        TransferIntent calldata _intent,
        uint256 spentAmount,
        address spentCurrency
    ) internal {
        processedTransferIntents[_intent.operator][_intent.id] = true;
        emit Transferred(_intent.operator, _intent.id, _intent.recipient, _msgSender(), spentAmount, spentCurrency);
    }

    function sendNative(
        address destination,
        uint256 amount,
        bool isRefund
    ) internal {
        (bool success, bytes memory data) = payable(destination).call{value: amount}("");
        if (!success) {
            revert NativeTransferFailed(destination, amount, isRefund, data);
        }
    }

    // @notice Registers an operator with a custom fee destination.
    function registerOperatorWithFeeDestination(address _feeDestination) public {
        feeDestinations[_msgSender()] = _feeDestination;

        emit OperatorRegistered(_msgSender(), _feeDestination);
    }

    // @notice Registers an operator, using the operator's address as the fee destination.
    function registerOperator() public {
        feeDestinations[_msgSender()] = _msgSender();

        emit OperatorRegistered(_msgSender(), feeDestinations[_msgSender()]);
    }

    function unregisterOperator() public {
        delete feeDestinations[_msgSender()];

        emit OperatorUnregistered(_msgSender());
    }

    // @notice Allows the owner to pause the contract.
    function pause() public onlyOwner {
        _pause();
    }

    // @notice Allows the owner to un-pause the contract.
    function unpause() public onlyOwner {
        _unpause();
    }

    // @dev Required as Uniswap can transfer native tokens to our contract.
    receive() external payable {}
}