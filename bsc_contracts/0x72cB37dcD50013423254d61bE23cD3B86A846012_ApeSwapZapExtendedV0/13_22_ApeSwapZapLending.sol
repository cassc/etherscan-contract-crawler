// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../ApeSwapZap.sol";
import "./lib/ICErc20.sol";

abstract contract ApeSwapZapLending is ApeSwapZap {
    using SafeERC20 for IERC20;
    using SafeERC20 for ICErc20;

    /// @dev Native token market underlying
    address public constant LENDING_NATIVE_UNDERLYING = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event ZapLendingMarket(IERC20 inputToken, uint256 inputAmount, ICErc20 market, uint256 outputAmount);

    constructor() {}

    /// @notice Zap token single asset lending market
    /// @param inputToken Input token to zap
    /// @param inputAmount Amount of input tokens to zap
    /// @param path Path from input token to stake token
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param market Lending market to deposit to
    function zapLendingMarket(
        IERC20 inputToken,
        uint256 inputAmount,
        address[] calldata path,
        uint256 minAmountsSwap,
        uint256 deadline,
        ICErc20 market
    ) external nonReentrant {
        inputAmount = _transferIn(inputToken, inputAmount);
        uint256 cTokensReceived = _zapLendingMarket(inputToken, inputAmount, path, minAmountsSwap, deadline, market);
        market.transfer(msg.sender, cTokensReceived);
    }

    /// @notice Zap native token to a Lending Market
    /// @param path Path from input token to stake token
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param market Lending market to deposit to
    function zapLendingMarketNative(
        address[] calldata path,
        uint256 minAmountsSwap,
        uint256 deadline,
        ICErc20 market
    ) external payable nonReentrant {
        (IERC20 weth, uint256 inputAmount) = _wrapNative();
        uint256 cTokensReceived = _zapLendingMarket(weth, inputAmount, path, minAmountsSwap, deadline, market);
        market.transfer(msg.sender, cTokensReceived);
    }

    /** INTERNAL FUNCTIONS **/

    /// @notice Zap token single asset lending market
    /// @param inputToken Input token to zap
    /// @param inputAmount Amount of input tokens to zap
    /// @param path Path from input token to stake token
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param market Lending market to deposit to
    function _zapLendingMarket(
        IERC20 inputToken,
        uint256 inputAmount,
        address[] calldata path,
        uint256 minAmountsSwap,
        uint256 deadline,
        ICErc20 market
    ) internal returns (uint256 cTokensReceived) {
        // Validate path and market underlying
        IERC20 underlyingToken = IERC20(market.underlying());
        IERC20 outputToken = underlyingToken;
        if (address(underlyingToken) == LENDING_NATIVE_UNDERLYING) {
            /// @dev The lending market uses a special address to represent native token
            outputToken = IERC20(address(WNATIVE));
        }
        require(
            (address(inputToken) == path[0] && address(outputToken) == path[path.length - 1]),
            "ApeSwapZapLending: Wrong path for inputToken or principalToken"
        );

        _routerSwap(inputAmount, minAmountsSwap, path, deadline, true);

        if (address(underlyingToken) == LENDING_NATIVE_UNDERLYING) {
            uint256 depositAmount = _unwrapNative();
            market.mint{value: depositAmount}();
        } else {
            uint256 depositAmount = underlyingToken.balanceOf(address(this));
            underlyingToken.approve(address(market), depositAmount);
            uint256 mintFailure = market.mint(depositAmount);
            require(mintFailure == 0, "ApeSwapZapLending: Mint failed");
            underlyingToken.approve(address(market), 0);
        }
        cTokensReceived = market.balanceOf(address(this));
        require(cTokensReceived > 0, "ApeSwapZapLending: Nothing deposited");

        emit ZapLendingMarket(inputToken, inputAmount, market, cTokensReceived);
    }
}