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

contract ERC20Claimer is BaseClaimer {
    using FixedPoint for uint256;
    using UncheckedMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 53e3;

    address public swapSigner;
    uint256 public maxSlippage;
    EnumerableSet.AddressSet private ignoredTokenSwaps;

    event SwapSignerSet(address indexed swapSigner);
    event MaxSlippageSet(uint256 maxSlippage);
    event IgnoreTokenSwapSet(address indexed token, bool ignored);

    constructor(address admin, address registry) BaseClaimer(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function setSwapSigner(address newSwapSigner) external auth {
        swapSigner = newSwapSigner;
        emit SwapSignerSet(newSwapSigner);
    }

    function setMaxSlippage(uint256 newMaxSlippage) external auth {
        require(newMaxSlippage <= FixedPoint.ONE, 'CLAIMER_SLIPPAGE_ABOVE_ONE');
        maxSlippage = newMaxSlippage;
        emit MaxSlippageSet(newMaxSlippage);
    }

    function setIgnoreTokenSwaps(address[] memory tokens, bool[] memory ignores) external auth {
        require(tokens.length == ignores.length, 'IGNORE_SWAP_TOKENS_INVALID_LEN');
        for (uint256 i = 0; i < tokens.length; i = i.uncheckedAdd(1)) {
            if (ignores[i]) ignoredTokenSwaps.add(tokens[i]);
            else ignoredTokenSwaps.remove(tokens[i]);
            emit IgnoreTokenSwapSet(tokens[i], ignores[i]);
        }
    }

    function isTokenSwapIgnored(address token) public view returns (bool) {
        return ignoredTokenSwaps.contains(token);
    }

    function getIgnoredTokenSwaps() external view returns (address[] memory) {
        return ignoredTokenSwaps.values();
    }

    function canExecute(address token) external view override returns (bool) {
        return !_isWrappedOrNativeToken(token) && totalBalance(token) > 0;
    }

    function call(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 expectedAmountOut,
        uint256 deadline,
        bytes memory data,
        bytes memory sig
    ) external auth nonReentrant {
        _initRelayedTx();
        (address token, uint256 price) = _call(tokenIn, amountIn, minAmountOut, expectedAmountOut, deadline, data, sig);
        _payRelayedTx(token, price);
    }

    function _call(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 expectedAmountOut,
        uint256 deadline,
        bytes memory data,
        bytes memory sig
    ) internal returns (address payingGasToken, uint256 payingGasTokenPrice) {
        require(!_isWrappedOrNativeToken(tokenIn), 'ERC20_CLAIMER_INVALID_TOKEN');

        address wrappedNativeToken = smartVault.wrappedNativeToken();
        _validateSig(tokenIn, wrappedNativeToken, amountIn, minAmountOut, expectedAmountOut, deadline, data, sig);

        if (isTokenSwapIgnored(tokenIn)) {
            // The threshold must be checked against the claimable balance, not against the amount out. The amount out
            // is computed considering both the claimable balance and the smart vault balance in case of a swap, but
            // if the token in is ignored, the smart vault balance must be ignored.
            // We can leverage the call information to rate the claimable balance in the wrapped native token:
            uint256 wrappedNativeTokenPrice = amountIn.divUp(expectedAmountOut);
            uint256 wrappedNativeTokenClaimableBalance = claimableBalance(tokenIn).divDown(wrappedNativeTokenPrice);
            _validateThreshold(wrappedNativeToken, wrappedNativeTokenClaimableBalance);

            _claim(tokenIn);
            payingGasToken = tokenIn;
            payingGasTokenPrice = wrappedNativeTokenPrice;
        } else {
            // The threshold must be checked against the total balance (claimable balance + smart vault balance) which
            // is already contemplated in the amount out. We use the min amount out as it represents the minimum
            // amount of token out tokens we will receive for the swap to validate the threshold.
            _validateThreshold(wrappedNativeToken, minAmountOut);
            _validateSlippage(minAmountOut, expectedAmountOut);

            _claim(tokenIn);
            smartVault.swap(
                uint8(ISwapConnector.Source.ParaswapV5),
                tokenIn,
                wrappedNativeToken,
                amountIn,
                ISmartVault.SwapLimit.MinAmountOut,
                minAmountOut,
                data
            );

            payingGasToken = wrappedNativeToken;
            payingGasTokenPrice = FixedPoint.ONE;
        }

        emit Executed();
    }

    function _validateSlippage(uint256 minAmountOut, uint256 expectedAmountOut) internal view {
        require(minAmountOut <= expectedAmountOut, 'MIN_AMOUNT_GT_EXPECTED_AMOUNT');
        uint256 slippage = FixedPoint.ONE - minAmountOut.divUp(expectedAmountOut);
        require(slippage <= maxSlippage, 'CLAIMER_SLIPPAGE_TOO_BIG');
    }

    function _validateSig(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 expectedAmountOut,
        uint256 deadline,
        bytes memory data,
        bytes memory sig
    ) internal view {
        bytes32 message = _hash(tokenIn, tokenOut, amountIn, minAmountOut, expectedAmountOut, deadline, data);
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(message), sig);
        require(signer == swapSigner, 'INVALID_SWAP_SIGNATURE');
        require(block.timestamp <= deadline, 'SWAP_DEADLINE_EXPIRED');
    }

    function _hash(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 expectedAmountOut,
        uint256 deadline,
        bytes memory data
    ) private pure returns (bytes32) {
        bool isBuy = false;
        return
            keccak256(
                abi.encodePacked(tokenIn, tokenOut, isBuy, amountIn, minAmountOut, expectedAmountOut, deadline, data)
            );
    }
}