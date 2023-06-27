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

import '@mimic-fi/v2-bridge-connector/contracts/interfaces/IHopL2AMM.sol';
import '@mimic-fi/v2-helpers/contracts/utils/EnumerableMap.sol';
import '@mimic-fi/v2-swap-connector/contracts/ISwapConnector.sol';

import './BaseSwapper.sol';
import './interfaces/IL2HopSwapper.sol';

contract L2HopSwapper is IL2HopSwapper, BaseSwapper {
    using FixedPoint for uint256;
    using EnumerableMap for EnumerableMap.AddressToAddressMap;

    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 30e3;

    // List of AMMs per token
    EnumerableMap.AddressToAddressMap private _tokenAmms;

    struct TokenAmm {
        address token;
        address amm;
    }

    /**
     * @dev L2 Hop swapper action config
     */
    struct L2HopSwapperConfig {
        TokenAmm[] tokenAmms;
        SwapperConfig swapperConfig;
    }

    /**
     * @dev Creates a L2 Hop swapper action
     */
    constructor(L2HopSwapperConfig memory config) BaseSwapper(config.swapperConfig) {
        for (uint256 i = 0; i < config.tokenAmms.length; i++) {
            _setTokenAmm(config.tokenAmms[i].token, config.tokenAmms[i].amm);
        }
    }

    /**
     * @dev Tells AMM set for a token
     */
    function getTokenAmm(address token) public view override returns (address amm) {
        (, amm) = _tokenAmms.tryGet(token);
    }

    /**
     * @dev Tells the list of AMMs set for each token
     */
    function getTokenAmms() external view override returns (address[] memory tokens, address[] memory amms) {
        tokens = _tokenAmms.keys();
        amms = _tokenAmms.values();
    }

    /**
     * @dev Sets a list of amms for a list of hTokens
     * @param hTokens List of hToken addresses to be set
     * @param amms List of AMM addresses to be set for each hToken
     */
    function setTokenAmms(address[] memory hTokens, address[] memory amms) external override auth {
        _setTokenAmms(hTokens, amms);
    }

    /**
     * @dev Execution function
     */
    function call(address hToken, uint256 amount, uint256 slippage) external override actionCall(hToken, amount) {
        _validateAmm(hToken);
        _validateSlippage(hToken, slippage);

        address tokenOut = _getApplicableTokenOut(hToken);
        bytes memory data = abi.encode(IHopL2AMM(getTokenAmm(hToken)).exchangeAddress());
        uint256 minAmountOut = amount.mulUp(FixedPoint.ONE - slippage);

        smartVault.swap(
            uint8(ISwapConnector.Source.Hop),
            hToken,
            tokenOut,
            amount,
            ISmartVault.SwapLimit.MinAmountOut,
            minAmountOut,
            data
        );
    }

    /**
     * @dev Tells if a token has an AMM set
     */
    function _isAmmValid(address token) internal view returns (bool) {
        return _tokenAmms.contains(token);
    }

    /**
     * @dev Reverts if there is no Hop AMM set for a given hToken
     */
    function _validateAmm(address hToken) internal view {
        require(_isAmmValid(hToken), 'ACTION_MISSING_HOP_TOKEN_AMM');
    }

    /**
     * @dev Sets a list of AMMs for a list of hTokens
     * @param hTokens List of hToken addresses to be set
     * @param amms List of AMM addresses to be set for each hToken
     */
    function _setTokenAmms(address[] memory hTokens, address[] memory amms) internal {
        require(hTokens.length == amms.length, 'ACTION_TOKENS_AMMS_BAD_INPUT_LEN');
        for (uint256 i = 0; i < hTokens.length; i++) {
            _setTokenAmm(hTokens[i], amms[i]);
        }
    }

    /**
     * @dev Set an AMM for a Hop token
     * @param hToken Address of the hToken to set an AMM for
     * @param amm AMM to be set
     */
    function _setTokenAmm(address hToken, address amm) internal {
        require(hToken != address(0), 'ACTION_HOP_TOKEN_ZERO');
        require(amm == address(0) || hToken == IHopL2AMM(amm).hToken(), 'ACTION_HOP_TOKEN_AMM_MISMATCH');

        amm == address(0) ? _tokenAmms.remove(hToken) : _tokenAmms.set(hToken, amm);
        emit TokenAmmSet(hToken, amm);
    }
}