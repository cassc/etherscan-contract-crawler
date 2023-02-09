// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/SwapModule.sol";
import "./lib/SpritzPayStorageV3.sol";

/**
 * @title SpritzPayV3
 * @notice Main entry point for Spritz payments
 */
contract SpritzPayV3 is
    Initializable,
    PausableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    SpritzPayStorageV3
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    error InvalidSourceToken();

    /**
     * @dev Emitted when a payment has been sent
     */
    event Payment(
        address to,
        address indexed from,
        address indexed sourceToken,
        uint256 sourceTokenAmount,
        address paymentToken,
        uint256 paymentTokenAmount,
        bytes32 indexed paymentReference
    );

    /**
     * @dev Constructor for upgradable contract
     */
    function initialize(
        address _admin,
        address _paymentRecipient,
        address _swapTarget,
        address _wrappedNative,
        address[] calldata _acceptedTokens
    ) public virtual initializer {
        __SpritzPayStorage_init(_admin, _paymentRecipient, _swapTarget, _wrappedNative, _acceptedTokens);
        __Pausable_init();
        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @notice Pay by direct stablecoin transfer
     * @param paymentTokenAddress Address of the target payment token
     * @param paymentTokenAmount Payment amount, denominated in target payment token
     * @param paymentReference Arbitrary reference ID of the related payment
     */
    function payWithToken(
        address paymentTokenAddress,
        uint256 paymentTokenAmount,
        bytes32 paymentReference
    ) external whenNotPaused {
        _payWithToken(msg.sender, paymentTokenAddress, paymentTokenAmount, paymentReference);
    }

    /**
     * @notice Pay by direct stablecoin transfer from an authorized delegate
     * @param from Address of the payment sender
     * @param paymentTokenAddress Address of the target payment token
     * @param paymentTokenAmount Payment amount, denominated in target payment token
     * @param paymentReference Arbitrary reference ID of the related payment
     */
    function delegatedPayWithToken(
        address from,
        address paymentTokenAddress,
        uint256 paymentTokenAmount,
        bytes32 paymentReference
    ) external whenNotPaused onlyRole(PAYMENT_DELEGATE_ROLE) {
        _payWithToken(from, paymentTokenAddress, paymentTokenAmount, paymentReference);
    }

    /**
     * @notice Initiate a stablecoin transfer from sender to recipient
     * @param from Address of the payment sender
     * @param paymentTokenAddress Address of the target payment token
     * @param paymentTokenAmount Payment amount, denominated in target payment token
     * @param paymentReference Arbitrary reference ID of the related payment
     */
    function _payWithToken(
        address from,
        address paymentTokenAddress,
        uint256 paymentTokenAmount,
        bytes32 paymentReference
    ) private onlyAcceptedToken(paymentTokenAddress) {
        emit Payment(
            _paymentRecipient,
            from,
            paymentTokenAddress,
            paymentTokenAmount,
            paymentTokenAddress,
            paymentTokenAmount,
            paymentReference
        );

        IERC20Upgradeable(paymentTokenAddress).safeTransferFrom(from, _paymentRecipient, paymentTokenAmount);
    }

    /**
     * @notice Pay by swapping and ERC-20 token. Uses
     *          Uniswap exact output trade type
     * @param path Swap path
     * @param sourceTokenAmountMax Maximum amount of the token being sold for payment
     * @param paymentTokenAmount Exact Amount of the target payment token
     * @param paymentReference Arbitrary reference ID of the related payment
     * @param deadline Swap deadline
     */
    function payWithSwap(
        address sourceTokenAddress,
        uint256 sourceTokenAmountMax,
        uint256 paymentTokenAmount,
        bytes32 paymentReference,
        uint256 deadline,
        bytes calldata path
    ) external whenNotPaused {
        _payWithSwap(
            msg.sender,
            sourceTokenAddress,
            sourceTokenAmountMax,
            paymentTokenAmount,
            paymentReference,
            deadline,
            path
        );
    }

    /**
     * @notice Pay by swapping token for an accepted output token from an authorized delegate. Uses SpritzSwapModule to facilitate the swap
     * @param sourceTokenAmountMax Maximum amount of the token being sold for payment
     * @param paymentTokenAmount Exact Amount of the target payment token
     * @param paymentReference Arbitrary reference ID of the related payment
     * @param deadline Swap deadline
     * @param path Swap path
     */
    function delegatedPayWithSwap(
        address from,
        address sourceTokenAddress,
        uint256 sourceTokenAmountMax,
        uint256 paymentTokenAmount,
        bytes32 paymentReference,
        uint256 deadline,
        bytes calldata path
    ) external whenNotPaused onlyRole(PAYMENT_DELEGATE_ROLE) {
        _payWithSwap(
            from,
            sourceTokenAddress,
            sourceTokenAmountMax,
            paymentTokenAmount,
            paymentReference,
            deadline,
            path
        );
    }

    /**
     * @notice Execute the swap and transfer to the recipient
     * @param sourceTokenAmountMax Maximum amount of the token being sold for payment
     * @param paymentTokenAmount Exact Amount of the target payment token
     * @param paymentReference Arbitrary reference ID of the related payment
     * @param deadline Swap deadline
     * @param path Swap path
     */
    function _payWithSwap(
        address from,
        address sourceTokenAddress,
        uint256 sourceTokenAmountMax,
        uint256 paymentTokenAmount,
        bytes32 paymentReference,
        uint256 deadline,
        bytes calldata path
    ) private {
        (address sourceToken, address paymentToken) = _swapModule.decodeSwapData(path);

        if (sourceTokenAddress != sourceToken) revert InvalidSourceToken();
        if (!isAcceptedToken(paymentToken)) revert NonAcceptedToken(paymentToken);

        IERC20Upgradeable(sourceToken).safeTransferFrom(from, address(_swapModule), sourceTokenAmountMax);

        uint256 sourceTokenAmountSpent = _swapModule.exactOutputSwap(
            SwapModule.ExactOutputParams(
                _paymentRecipient,
                from,
                sourceTokenAmountMax,
                paymentTokenAmount,
                deadline,
                path
            )
        );

        emit Payment(
            _paymentRecipient,
            from,
            sourceToken,
            sourceTokenAmountSpent,
            paymentToken,
            paymentTokenAmount,
            paymentReference
        );
    }

    /**
     * @notice Pay by swapping native currency. Uses
     *          Uniswap exact output trade type
     * @param path Swap path
     * @param paymentTokenAmount Exact Amount of the target payment token
     * @param paymentReference Arbitrary reference ID of the related payment
     * @param deadline Swap deadline
     */
    function payWithNativeSwap(
        uint256 paymentTokenAmount,
        bytes32 paymentReference,
        uint256 deadline,
        bytes calldata path
    ) external payable whenNotPaused {
        (address sourceToken, address paymentToken) = _swapModule.decodeSwapData(path);
        if (!isAcceptedToken(paymentToken)) revert NonAcceptedToken(paymentToken);

        uint256 sourceTokenAmountSpent = _swapModule.exactOutputNativeSwap{ value: msg.value }(
            SwapModule.ExactOutputParams({
                to: _paymentRecipient,
                from: msg.sender,
                inputTokenAmountMax: msg.value,
                paymentTokenAmount: paymentTokenAmount,
                deadline: deadline,
                swapData: path
            })
        );

        emit Payment(
            _paymentRecipient,
            msg.sender,
            sourceToken,
            sourceTokenAmountSpent,
            paymentToken,
            paymentTokenAmount,
            paymentReference
        );
    }

    /*
     * Admin functions
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setPaymentRecipient(address newPaymentRecipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setPaymentRecipient(newPaymentRecipient);
    }

    function setSwapModule(address newSwapTarget) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setSwapModule(newSwapTarget);
    }

    function addPaymentToken(address newToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addPaymentToken(newToken);
    }

    function removePaymentToken(address newToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _removePaymentToken(newToken);
    }
}