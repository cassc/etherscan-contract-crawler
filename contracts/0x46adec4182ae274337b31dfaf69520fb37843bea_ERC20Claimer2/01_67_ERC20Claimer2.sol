// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v2-helpers/contracts/math/UncheckedMath.sol';
import '@mimic-fi/v2-swap-connector/contracts/ISwapConnector.sol';

import './BaseClaimer.sol';

contract ERC20Claimer2 is BaseClaimer {
    using FixedPoint for uint256;
    using UncheckedMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 60e3;

    address public tokenOut;
    address public swapSigner;
    uint256 public maxSlippage;
    EnumerableSet.AddressSet private ignoredTokenSwaps;

    event TokenOutSet(address indexed tokenOut);
    event SwapSignerSet(address indexed swapSigner);
    event MaxSlippageSet(uint256 maxSlippage);
    event IgnoreTokenSwapSet(address indexed token, bool ignored);

    struct Config {
        address admin;
        address registry;
        address smartVault;
        address feeClaimer;
        address tokenOut;
        address swapSigner;
        uint256 maxSlippage;
        address[] ignoreTokens;
        address thresholdToken;
        uint256 thresholdAmount;
        address relayer;
        uint256 gasPriceLimit;
    }

    constructor(Config memory config) BaseClaimer(config.admin, config.registry) {
        smartVault = ISmartVault(config.smartVault);
        emit SmartVaultSet(config.smartVault);

        feeClaimer = config.feeClaimer;
        emit FeeClaimerSet(config.feeClaimer);

        _setTokenOut(config.tokenOut);
        _setSwapSigner(config.swapSigner);
        _setMaxSlippage(config.maxSlippage);
        for (uint256 i = 0; i < config.ignoreTokens.length; i++) {
            _setIgnoreTokenSwap(config.ignoreTokens[i], true);
        }

        thresholdToken = config.thresholdToken;
        thresholdAmount = config.thresholdAmount;
        emit ThresholdSet(config.thresholdToken, config.thresholdAmount);

        isRelayer[config.relayer] = true;
        emit RelayerSet(config.relayer, true);

        gasPriceLimit = config.gasPriceLimit;
        emit LimitsSet(config.gasPriceLimit, 0);
    }

    function setTokenOut(address newTokenOut) external auth {
        _setTokenOut(newTokenOut);
    }

    function setSwapSigner(address newSwapSigner) external auth {
        _setSwapSigner(newSwapSigner);
    }

    function setMaxSlippage(uint256 newMaxSlippage) external auth {
        _setMaxSlippage(newMaxSlippage);
    }

    function setIgnoreTokenSwaps(address[] memory tokens, bool[] memory ignores) external auth {
        require(tokens.length == ignores.length, 'IGNORE_SWAP_TOKENS_INVALID_LEN');
        for (uint256 i = 0; i < tokens.length; i = i.uncheckedAdd(1)) {
            _setIgnoreTokenSwap(tokens[i], ignores[i]);
        }
    }

    function isTokenSwapIgnored(address token) public view returns (bool) {
        return ignoredTokenSwaps.contains(token);
    }

    function getIgnoredTokenSwaps() external view returns (address[] memory) {
        return ignoredTokenSwaps.values();
    }

    function canExecute(address token) external view override returns (bool) {
        return !Denominations.isNativeToken(token) && totalBalance(token) > 0;
    }

    function call(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 expectedAmountOut,
        uint256 deadline,
        bytes memory data,
        bytes memory sig
    ) external auth nonReentrant redeemGas(tokenOut) {
        require(!Denominations.isNativeToken(tokenIn), 'ERC20_CLAIMER_INVALID_TOKEN');
        _validateSig(tokenIn, amountIn, minAmountOut, expectedAmountOut, deadline, data, sig);

        if (isTokenSwapIgnored(tokenIn)) {
            // The threshold must be checked against the claimable balance, not against the amount out. The amount out
            // is computed considering both the claimable balance and the smart vault balance in case of a swap, but
            // if the token in is ignored, the smart vault balance must be ignored.
            // We can leverage the call information to rate the claimable balance in the token out:
            uint256 tokenOutPrice = amountIn.divUp(expectedAmountOut);
            uint256 tokenOutClaimableBalance = claimableBalance(tokenIn).divDown(tokenOutPrice);
            _validateThreshold(tokenOut, tokenOutClaimableBalance);

            _claim(tokenIn);
        } else {
            // The threshold must be checked against the total balance (claimable balance + smart vault balance) which
            // is already contemplated in the amount out. We use the min amount out as it represents the minimum
            // amount of token out tokens we will receive for the swap to validate the threshold.
            _validateThreshold(tokenOut, minAmountOut);
            _validateSlippage(minAmountOut, expectedAmountOut);

            _claim(tokenIn);
            smartVault.swap(
                uint8(ISwapConnector.Source.ParaswapV5),
                tokenIn,
                tokenOut,
                amountIn,
                ISmartVault.SwapLimit.MinAmountOut,
                minAmountOut,
                data
            );
        }

        emit Executed();
    }

    function _setTokenOut(address newTokenOut) internal {
        tokenOut = newTokenOut;
        emit TokenOutSet(newTokenOut);
    }

    function _setSwapSigner(address newSwapSigner) internal {
        swapSigner = newSwapSigner;
        emit SwapSignerSet(newSwapSigner);
    }

    function _setMaxSlippage(uint256 newMaxSlippage) internal {
        require(newMaxSlippage <= FixedPoint.ONE, 'CLAIMER_SLIPPAGE_ABOVE_ONE');
        maxSlippage = newMaxSlippage;
        emit MaxSlippageSet(newMaxSlippage);
    }

    function _setIgnoreTokenSwap(address token, bool ignore) internal {
        if (ignore) ignoredTokenSwaps.add(token);
        else ignoredTokenSwaps.remove(token);
        emit IgnoreTokenSwapSet(token, ignore);
    }

    function _validateSlippage(uint256 minAmountOut, uint256 expectedAmountOut) internal view {
        require(minAmountOut <= expectedAmountOut, 'MIN_AMOUNT_GT_EXPECTED_AMOUNT');
        uint256 slippage = FixedPoint.ONE - minAmountOut.divUp(expectedAmountOut);
        require(slippage <= maxSlippage, 'CLAIMER_SLIPPAGE_TOO_BIG');
    }

    function _validateSig(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 expectedAmountOut,
        uint256 deadline,
        bytes memory data,
        bytes memory sig
    ) internal view {
        bytes32 message = _hash(tokenIn, amountIn, minAmountOut, expectedAmountOut, deadline, data);
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(message), sig);
        require(signer == swapSigner, 'INVALID_SWAP_SIGNATURE');
        require(block.timestamp <= deadline, 'SWAP_DEADLINE_EXPIRED');
    }

    function _hash(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 expectedAmountOut,
        uint256 deadline,
        bytes memory data
    ) private view returns (bytes32) {
        bool isBuy = false;
        return
            keccak256(
                abi.encodePacked(tokenIn, tokenOut, isBuy, amountIn, minAmountOut, expectedAmountOut, deadline, data)
            );
    }
}