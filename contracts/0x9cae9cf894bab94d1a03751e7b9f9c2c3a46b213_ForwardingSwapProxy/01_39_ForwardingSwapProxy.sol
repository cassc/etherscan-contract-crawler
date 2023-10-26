// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "prb-math/contracts/PRBMathSD59x18.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

import "./interfaces/IERC20Extension.sol";

import "./BaseSwapProxy.sol";
import "./Whitelist.sol";

/// @title ForwardingSwapProxy
contract ForwardingSwapProxy is AccessControlEnumerable, Pausable, ReentrancyGuard, BaseSwapProxy, Whitelist {
    // Using Fixed point calculations for these types
    using PRBMathSD59x18 for int256;
    using PRBMathUD60x18 for uint256;
    using SafeERC20 for IERC20Extension;

    using UniswapV2Helpers for IUniswapV2Router02;

    constructor(address _admin) BaseSwapProxy(_admin) Whitelist(_admin) {}

    function _validateSwap(IERC20Extension _fromToken, IERC20Extension _toToken, address _swapContract) internal view {
        require(_fromToken != _toToken, "_fromToken equal to _toToken");
        require(isWhitelisted(_swapContract), "Not whitelisted");
    }

    function _handleSwapCompletion(
        IERC20Extension _fromToken,
        IERC20Extension _toToken,
        uint256 _amountRequested,
        uint256 _amountReturned,
        uint256 _feeTotalInETH
    ) internal {
        if (_feeTotalInETH != 0) {
            vault.paidFees{value: _feeTotalInETH}(msg.sender, _feeTotalInETH);
        }

        emit ProxySwapWithFee(
            address(_fromToken),
            address(_toToken),
            _amountRequested,
            _amountReturned,
            _feeTotalInETH
        );
    }

    function proxySwapWithFee(
        IERC20Extension _fromToken,
        IERC20Extension _toToken,
        SwapParams calldata _swapParams,
        uint256 _gasRefund,
        uint256 _minimumReturnAmount
    ) external payable override whenNotPaused nonReentrant {
        _validateSwap(_fromToken, _toToken, _swapParams.to);

        (uint256 amountRequested, uint256 amountReturned, uint256 feeTotalInETH) = _swapTokens(
            _fromToken,
            _toToken,
            _swapParams,
            _gasRefund,
            _minimumReturnAmount
        );

        _handleSwapCompletion(_fromToken, _toToken, amountRequested, amountReturned, feeTotalInETH);
    }

    function proxySwapWithPermit(
        IERC20Extension _fromToken,
        IERC20Extension _toToken,
        SwapParams calldata _swapParams,
        uint256 _minimumReturnAmount,
        uint256 _gasRefund,
        IPermit2.PermitSingle calldata _permit,
        bytes calldata _signature
    ) external override whenNotPaused nonReentrant {
        _validateSwap(_fromToken, _toToken, _swapParams.to);

        (uint256 amountRequested, uint256 amountReturned, uint256 feeTotalInETH) = _swapTokens(
            _fromToken,
            _toToken,
            _swapParams,
            _gasRefund,
            _minimumReturnAmount,
            _permit,
            _signature
        );

        _handleSwapCompletion(_fromToken, _toToken, amountRequested, amountReturned, feeTotalInETH);
    }

    function getExchangeRate(IERC20Extension _fromToken, IERC20Extension _toToken) external view returns (uint256) {
        return _getExchangeRate(_fromToken, _toToken);
    }

    function getChainlinkRate(
        IERC20Extension _fromToken,
        IERC20Extension _toToken
    ) external view override returns (uint256 exchangeRate) {
        return _getChainlinkRate(_fromToken, _toToken);
    }

    function getUniswapV2Rate(
        IERC20Extension _fromToken,
        IERC20Extension _toToken
    ) external view override returns (uint256) {
        return _getUniswapV2Rate(_fromToken, _toToken);
    }

    function calculatePercentageFeeInETH(
        IERC20Extension _token,
        uint256 _amount,
        uint256 _gasRefund
    ) external view override returns (uint256 feeTotalInETH, uint256 feeTotalInToken) {
        return _calculatePercentageFeeInETH(_token, _amount, _gasRefund);
    }

    function scaleAmountFromDecimals(
        uint256 _amount,
        uint8 _inputDecimals,
        uint8 _outputDecimals
    ) external pure returns (uint256) {
        return _scaleAmountFromDecimals(_amount, _inputDecimals, _outputDecimals);
    }
}