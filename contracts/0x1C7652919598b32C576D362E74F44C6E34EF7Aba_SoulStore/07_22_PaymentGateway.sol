// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../libraries/Errors.sol";
import "../interfaces/dex/IUniswapRouter.sol";

/// @title Pay using a Decentralized automated market maker (AMM) when needed
/// @author Masa Finance
/// @notice Smart contract to call a Dex AMM smart contract to pay to a reserve wallet recipient
/// @dev This smart contract will call the Uniswap Router interface, based on
/// https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
abstract contract PaymentGateway is AccessControl {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct PaymentParams {
        address swapRouter; // Swap router address
        address wrappedNativeToken; // Wrapped native token address
        address stableCoin; // Stable coin to pay the fee in (USDC)
        address masaToken; // Utility token to pay the fee in (MASA)
        address reserveWallet; // Wallet that will receive the fee
    }

    /* ========== STATE VARIABLES =========================================== */

    address public swapRouter;
    address public wrappedNativeToken;

    address public stableCoin; // USDC. It also needs to be enabled as payment method, if we want to pay in USDC
    address public masaToken; // MASA. It also needs to be enabled as payment method, if we want to pay in MASA

    // enabled payment methods: ETH and ERC20 tokens
    mapping(address => bool) public enabledPaymentMethod;
    address[] public enabledPaymentMethods;

    address public reserveWallet;

    /* ========== INITIALIZE ================================================ */

    /// @notice Creates a new Dex AMM
    /// @dev Creates a new Decentralized automated market maker (AMM) smart contract,
    // that will call the Uniswap Router interface
    /// @param admin Administrator of the smart contract
    /// @param paymentParams Payment params
    constructor(address admin, PaymentParams memory paymentParams) {
        if (paymentParams.swapRouter == address(0)) revert ZeroAddress();
        if (paymentParams.wrappedNativeToken == address(0))
            revert ZeroAddress();
        if (paymentParams.stableCoin == address(0)) revert ZeroAddress();
        if (paymentParams.reserveWallet == address(0)) revert ZeroAddress();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        swapRouter = paymentParams.swapRouter;
        wrappedNativeToken = paymentParams.wrappedNativeToken;
        stableCoin = paymentParams.stableCoin;
        masaToken = paymentParams.masaToken;
        reserveWallet = paymentParams.reserveWallet;
    }

    /* ========== RESTRICTED FUNCTIONS ====================================== */

    /// @notice Sets the swap router address
    /// @dev The caller must have the admin role to call this function
    /// @param _swapRouter New swap router address
    function setSwapRouter(address _swapRouter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_swapRouter == address(0)) revert ZeroAddress();
        if (swapRouter == _swapRouter) revert SameValue();
        swapRouter = _swapRouter;
    }

    /// @notice Sets the wrapped native token address
    /// @dev The caller must have the admin role to call this function
    /// @param _wrappedNativeToken New wrapped native token address
    function setWrappedNativeToken(address _wrappedNativeToken)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_wrappedNativeToken == address(0)) revert ZeroAddress();
        if (wrappedNativeToken == _wrappedNativeToken) revert SameValue();
        wrappedNativeToken = _wrappedNativeToken;
    }

    /// @notice Sets the stable coin to pay the fee in (USDC)
    /// @dev The caller must have the admin role to call this function
    /// @param _stableCoin New stable coin to pay the fee in
    function setStableCoin(address _stableCoin)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_stableCoin == address(0)) revert ZeroAddress();
        if (stableCoin == _stableCoin) revert SameValue();
        stableCoin = _stableCoin;
    }

    /// @notice Sets the utility token to pay the fee in (MASA)
    /// @dev The caller must have the admin role to call this function
    /// It can be set to address(0) to disable paying in MASA
    /// @param _masaToken New utility token to pay the fee in
    function setMasaToken(address _masaToken)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (masaToken == _masaToken) revert SameValue();
        masaToken = _masaToken;
    }

    /// @notice Adds a new token as a valid payment method
    /// @dev The caller must have the admin role to call this function
    /// @param _paymentMethod New token to add
    function enablePaymentMethod(address _paymentMethod)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (enabledPaymentMethod[_paymentMethod]) revert AlreadyAdded();

        enabledPaymentMethod[_paymentMethod] = true;
        enabledPaymentMethods.push(_paymentMethod);
    }

    /// @notice Removes a token as a valid payment method
    /// @dev The caller must have the admin role to call this function
    /// @param _paymentMethod Token to remove
    function disablePaymentMethod(address _paymentMethod)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (!enabledPaymentMethod[_paymentMethod])
            revert NonExistingErc20Token(_paymentMethod);

        enabledPaymentMethod[_paymentMethod] = false;
        for (uint256 i = 0; i < enabledPaymentMethods.length; i++) {
            if (enabledPaymentMethods[i] == _paymentMethod) {
                enabledPaymentMethods[i] = enabledPaymentMethods[
                    enabledPaymentMethods.length - 1
                ];
                enabledPaymentMethods.pop();
                break;
            }
        }
    }

    /// @notice Set the reserve wallet
    /// @dev The caller must have the admin role to call this function
    /// @param _reserveWallet New reserve wallet
    function setReserveWallet(address _reserveWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_reserveWallet == address(0)) revert ZeroAddress();
        if (_reserveWallet == reserveWallet) revert SameValue();
        reserveWallet = _reserveWallet;
    }

    /* ========== MUTATIVE FUNCTIONS ======================================== */

    /* ========== VIEWS ===================================================== */

    /// @notice Returns all available payment methods
    /// @dev Returns the address of all available payment methods
    /// @return Array of all enabled payment methods
    function getEnabledPaymentMethods()
        external
        view
        returns (address[] memory)
    {
        return enabledPaymentMethods;
    }

    /* ========== PRIVATE FUNCTIONS ========================================= */

    /// @notice Converts an amount from a stable coin to a payment method amount
    /// @dev This method will perform the swap between the stable coin and the
    /// payment method, and return the amount of the payment method,
    /// performing the swap if necessary
    /// @param paymentMethod Address of token that user want to pay
    /// @param amount Price to be converted in the specified payment method
    function _convertFromStableCoin(address paymentMethod, uint256 amount)
        internal
        view
        returns (uint256)
    {
        if (!enabledPaymentMethod[paymentMethod] || paymentMethod == stableCoin)
            revert InvalidToken(paymentMethod);

        if (paymentMethod == address(0)) {
            return _estimateSwapAmount(wrappedNativeToken, stableCoin, amount);
        } else {
            return _estimateSwapAmount(paymentMethod, stableCoin, amount);
        }
    }

    /// @notice Performs the payment in any payment method
    /// @dev This method will transfer the funds to the reserve wallet, performing
    /// the swap if necessary
    /// @param paymentMethod Address of token that user want to pay
    /// @param amount Price to be paid in the specified payment method
    function _pay(address paymentMethod, uint256 amount) internal {
        if (amount == 0) return;
        if (!enabledPaymentMethod[paymentMethod])
            revert InvalidPaymentMethod(paymentMethod);
        if (paymentMethod == address(0)) {
            // ETH
            if (msg.value < amount) revert InsufficientEthAmount(amount);
            (bool success, ) = payable(reserveWallet).call{value: amount}("");
            if (!success) revert TransferFailed();
            if (msg.value > amount) {
                // return diff
                uint256 refund = msg.value.sub(amount);
                (success, ) = payable(msg.sender).call{value: refund}("");
                if (!success) revert RefundFailed();
            }
        } else {
            // ERC20 token, including MASA and USDC
            IERC20(paymentMethod).safeTransferFrom(
                msg.sender,
                reserveWallet,
                amount
            );
        }
    }

    function _estimateSwapAmount(
        address _fromToken,
        address _toToken,
        uint256 _amountOut
    ) private view returns (uint256) {
        uint256[] memory amounts;
        address[] memory path;
        path = _getPathFromTokenToToken(_fromToken, _toToken);
        amounts = IUniswapRouter(swapRouter).getAmountsIn(_amountOut, path);
        return amounts[0];
    }

    function _getPathFromTokenToToken(address fromToken, address toToken)
        private
        view
        returns (address[] memory)
    {
        if (fromToken == wrappedNativeToken || toToken == wrappedNativeToken) {
            address[] memory path = new address[](2);
            path[0] = fromToken == wrappedNativeToken
                ? wrappedNativeToken
                : fromToken;
            path[1] = toToken == wrappedNativeToken
                ? wrappedNativeToken
                : toToken;
            return path;
        } else {
            address[] memory path = new address[](3);
            path[0] = fromToken;
            path[1] = wrappedNativeToken;
            path[2] = toToken;
            return path;
        }
    }

    /* ========== MODIFIERS ================================================= */

    /* ========== EVENTS ==================================================== */
}