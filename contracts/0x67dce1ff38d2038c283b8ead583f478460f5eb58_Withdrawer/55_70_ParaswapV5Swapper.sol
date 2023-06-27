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

import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v2-swap-connector/contracts/ISwapConnector.sol';

import './BaseSwapper.sol';
import './interfaces/IParaswapV5Swapper.sol';

/**
 * @title Paraswap V5 swapper action
 * @dev Action that extends the swapper action to use Paraswap v5
 */
contract ParaswapV5Swapper is IParaswapV5Swapper, BaseSwapper {
    using FixedPoint for uint256;

    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 55e3;

    // Address of the Paraswap quote signer
    address private _quoteSigner;

    /**
     * @dev Paraswap v5 swapper action config
     */
    struct Paraswap5SwapperConfig {
        address quoteSigner;
        SwapperConfig swapperConfig;
    }

    /**
     * @dev Creates a paraswap v5 swapper action
     */
    constructor(Paraswap5SwapperConfig memory config) BaseSwapper(config.swapperConfig) {
        _setQuoteSigner(config.quoteSigner);
    }

    /**
     * @dev Tells the address of the allowed quote signer
     */
    function getQuoteSigner() external view override returns (address) {
        return _quoteSigner;
    }

    /**
     * @dev Sets the quote signer address. Sender must be authorized.
     * @param quoteSigner Address of the new quote signer to be set
     */
    function setQuoteSigner(address quoteSigner) external override auth {
        _setQuoteSigner(quoteSigner);
    }

    /**
     * @dev Execution function
     */
    function call(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 expectedAmountOut,
        uint256 deadline,
        bytes memory data,
        bytes memory sig
    ) external override actionCall(tokenIn, amountIn) {
        uint256 slippage = FixedPoint.ONE - minAmountOut.divUp(expectedAmountOut);
        _validateSlippage(tokenIn, slippage);

        address tokenOut = _getApplicableTokenOut(tokenIn);
        _validateQuoteSigner(tokenIn, tokenOut, amountIn, minAmountOut, expectedAmountOut, deadline, data, sig);

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

    /**
     * @dev Tells if a quote signer is valid
     */
    function _isValidQuoteSigner(address quoteSigner) internal view returns (bool) {
        return quoteSigner == _quoteSigner;
    }

    /**
     * @dev Reverts if the quote was signed by someone else than the quote signer or if its expired
     */
    function _validateQuoteSigner(
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
        require(_isValidQuoteSigner(signer), 'ACTION_INVALID_QUOTE_SIGNER');
        require(block.timestamp <= deadline, 'ACTION_QUOTE_SIGNER_DEADLINE');
    }

    /**
     * @dev Sets the quote signer address
     * @param quoteSigner Address of the new quote signer to be set
     */
    function _setQuoteSigner(address quoteSigner) internal {
        require(quoteSigner != address(0), 'ACTION_QUOTE_SIGNER_ZERO');
        _quoteSigner = quoteSigner;
        emit QuoteSignerSet(quoteSigner);
    }

    /**
     * @dev Builds the quote message to check the signature of the quote signer
     */
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