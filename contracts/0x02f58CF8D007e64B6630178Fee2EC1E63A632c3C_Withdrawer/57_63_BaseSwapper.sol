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

import '@mimic-fi/v2-smart-vaults-base/contracts/actions/BaseAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/TokenThresholdAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/RelayedAction.sol';

abstract contract BaseSwapper is BaseAction, TokenThresholdAction, RelayedAction {
    using FixedPoint for uint256;
    using UncheckedMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public tokenOut;
    address public swapSigner;
    uint256 public defaultMaxSlippage;
    mapping (address => uint256) public tokenMaxSlippages;
    EnumerableSet.AddressSet private deniedTokens;

    event TokenOutSet(address indexed tokenOut);
    event SwapSignerSet(address indexed swapSigner);
    event DefaultMaxSlippageSet(uint256 maxSlippage);
    event TokenMaxSlippageSet(address indexed token, uint256 maxSlippage);
    event DeniedTokenSet(address indexed token, bool denied);

    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function getTokenSlippage(address token) public view returns (uint256) {
        uint256 tokenMaxSlippage = tokenMaxSlippages[token];
        return tokenMaxSlippage > 0 ? tokenMaxSlippage : defaultMaxSlippage;
    }

    function isTokenDenied(address token) public view returns (bool) {
        return deniedTokens.contains(token);
    }

    function getDeniedTokens() external view returns (address[] memory) {
        return deniedTokens.values();
    }

    function setTokenOut(address newTokenOut) external auth {
        require(newTokenOut != address(0), 'SWAPPER_TOKEN_ADDRESS_ZERO');
        tokenOut = newTokenOut;
        emit TokenOutSet(newTokenOut);
    }

    function setSwapSigner(address newSwapSigner) external auth {
        swapSigner = newSwapSigner;
        emit SwapSignerSet(newSwapSigner);
    }

    function setDefaultMaxSlippage(uint256 slippage) external auth {
        require(slippage <= FixedPoint.ONE, 'SWAPPER_DEFAULT_SLIPPAGE_ABOVE_1');
        defaultMaxSlippage = slippage;
        emit DefaultMaxSlippageSet(slippage);
    }

    function setTokenMaxSlippage(address token, uint256 slippage) external auth {
        require(token != address(0), 'SWAPPER_TOKEN_ADDRESS_ZERO');
        require(slippage <= FixedPoint.ONE, 'SWAPPER_TOKEN_SLIPPAGE_ABOVE_1');
        tokenMaxSlippages[token] = slippage;
        emit TokenMaxSlippageSet(token, slippage);
    }

    function setDeniedTokens(address[] memory tokens, bool[] memory denies) external auth {
        require(tokens.length == denies.length, 'SWAPPER_DENIED_TOKENS_INV_LEN');
        for (uint256 i = 0; i < tokens.length; i = i.uncheckedAdd(1)) {
            if (denies[i]) deniedTokens.add(tokens[i]);
            else deniedTokens.remove(tokens[i]);
            emit DeniedTokenSet(tokens[i], denies[i]);
        }
    }

    function _validateToken(address token) internal view {
        require(token != address(0), 'SWAPPER_TOKEN_ADDRESS_ZERO');
        require(!Denominations.isNativeToken(token), 'SWAPPER_NATIVE_TOKEN');
        require(!isTokenDenied(token), 'SWAPPER_DENIED_TOKEN');
    }

    function _validateSlippage(address tokenIn, uint256 minAmountOut, uint256 expectedAmountOut) internal view {
        if (minAmountOut >= expectedAmountOut) return; // Return if in case we have a positive slippage
        uint256 slippage = FixedPoint.ONE - minAmountOut.divUp(expectedAmountOut);
        require(slippage <= getTokenSlippage(tokenIn), 'SWAPPER_SLIPPAGE_TOO_BIG');
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
        require(signer == swapSigner, 'SWAPPER_INVALID_SIGNATURE');
        require(block.timestamp <= deadline, 'SWAPPER_DEADLINE_EXPIRED');
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