// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../interfaces/SwapModule.sol";

contract SpritzPayStorageV3 is Initializable, AccessControlEnumerableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     * @dev Emitted when the payment recipient has been changed
     */
    event PaymentRecipientChanged(address recipient, address sender);

    /**
     * @dev Emitted when an accepted payment token has been added
     */
    event PaymentTokenAdded(address token);

    /**
     * @dev Emitted when an accepted payment token has been removed
     */
    event PaymentTokenRemoved(address token);

    /**
     * @notice Thrown when setting one of our stored addresses to zero
     */
    error SetZeroAddress();

    /**
     * @notice Thrown when paying with unrecognized token
     */
    error NonAcceptedToken(address token);

    /**
     * @notice Thrown when an unauthorised wallet tries to call a guarded method
     * @param caller The wallet calling the guarded method
     */
    error UnauthorizedExecutor(address caller);

    address internal _paymentRecipient;
    address internal _swapTarget;
    address internal _wrappedNative;

    /// @notice List of all accepted payment tokens
    EnumerableSetUpgradeable.AddressSet internal _acceptedPaymentTokens;

    address internal _v3SwapTarget;
    address internal _smartPay;
    SwapModule internal _swapModule;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant PAYMENT_DELEGATE_ROLE = keccak256("PAYMENT_DELEGATE_ROLE");

    modifier onlyAcceptedToken(address paymentToken) {
        if (!_acceptedPaymentTokens.contains(paymentToken)) {
            revert NonAcceptedToken(paymentToken);
        }
        _;
    }

    /**
     * @dev Initializes the contract
     */
    function __SpritzPayStorage_init(
        address newAdmin,
        address newPaymentRecipient,
        address newSwapTarget,
        address newWrappedNative,
        address[] calldata acceptedTokens
    ) internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, newAdmin);
        _setupRole(PAUSER_ROLE, newAdmin);
        _setPaymentRecipient(newPaymentRecipient);
        _setSwapTarget(newSwapTarget);
        _setWrappedNative(newWrappedNative);
        for (uint256 i = 0; i < acceptedTokens.length; i++) {
            _addPaymentToken(acceptedTokens[i]);
        }
    }

    /**
     * @dev Sets a new address for the payment recipient
     */
    function _setPaymentRecipient(address newPaymentRecipient) internal virtual {
        if (newPaymentRecipient == address(0)) revert SetZeroAddress();
        _paymentRecipient = newPaymentRecipient;
        emit PaymentRecipientChanged(_paymentRecipient, msg.sender);
    }

    /**
     * @dev Returns the address of the payment recipient
     */
    function paymentRecipient() public view virtual returns (address) {
        return _paymentRecipient;
    }

    /**
     * @dev Sets a new address for the swap target
     */
    function _setSwapTarget(address newSwapTarget) internal virtual {
        _swapTarget = newSwapTarget;
    }

    /**
     * @dev Sets a new address for the v3 swap target
     */
    function _setV3SwapTarget(address newSwapTarget) internal virtual {
        _v3SwapTarget = newSwapTarget;
    }

    /**
     * @dev Returns the address of the swap target
     */
    function swapTarget() public view virtual returns (address) {
        return _swapTarget;
    }

    /**
     * @dev Returns the address of the swap target
     */
    function v3SwapTarget() public view virtual returns (address) {
        return _v3SwapTarget;
    }

    /**
     * @dev Returns the address of the swap target
     */
    function swapModule() public view virtual returns (address) {
        return address(_swapModule);
    }

    /**
     * @dev Sets a new address for the wrapped native token
     */
    function _setWrappedNative(address newWrappedNative) internal virtual {
        if (newWrappedNative == address(0)) revert SetZeroAddress();
        _wrappedNative = newWrappedNative;
    }

    /**
     * @dev Sets a new address for the wrapped native token
     */
    function _setSwapModule(address newSwapModule) internal virtual {
        if (newSwapModule == address(0)) revert SetZeroAddress();
        _swapModule = SwapModule(newSwapModule);
    }

    /**
     * @dev Get all accepted payment tokens
     * @return Whether this payment token is accepted
     */
    function isAcceptedToken(address tokenAddress) internal view returns (bool) {
        return _acceptedPaymentTokens.contains(tokenAddress);
    }

    /**
     * @dev Get all accepted payment tokens
     * @return An array of the unique token addresses
     */
    function acceptedPaymentTokens() external view returns (address[] memory) {
        return _acceptedPaymentTokens.values();
    }

    /**
     * @dev Adds an accepted payment token
     */
    function _addPaymentToken(address newToken) internal virtual {
        _acceptedPaymentTokens.add(newToken);
        emit PaymentTokenAdded(newToken);
    }

    /**
     * @dev Adds an accepted payment token
     */
    function _removePaymentToken(address newToken) internal virtual {
        _acceptedPaymentTokens.remove(newToken);
        emit PaymentTokenRemoved(newToken);
    }
}