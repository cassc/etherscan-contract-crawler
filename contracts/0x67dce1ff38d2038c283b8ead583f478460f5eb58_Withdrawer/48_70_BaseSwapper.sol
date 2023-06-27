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
import '@mimic-fi/v2-helpers/contracts/utils/Denominations.sol';
import '@mimic-fi/v2-helpers/contracts/utils/EnumerableMap.sol';

import './interfaces/IBaseSwapper.sol';
import '../Action.sol';

/**
 * @title Base swapper action
 * @dev Action that offers the basic components for more detailed swap actions.
 */
abstract contract BaseSwapper is IBaseSwapper, Action {
    using FixedPoint for uint256;
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using EnumerableMap for EnumerableMap.AddressToAddressMap;

    // Default token out
    address private _defaultTokenOut;

    // Default maximum slippage in fixed point
    uint256 private _defaultMaxSlippage;

    // Token out per token
    EnumerableMap.AddressToAddressMap private _customTokensOut;

    // Maximum slippage per token address
    EnumerableMap.AddressToUintMap private _customMaxSlippages;

    /**
     * @dev Custom token out config
     */
    struct CustomTokenOut {
        address token;
        address tokenOut;
    }

    /**
     * @dev Custom max slippage config
     */
    struct CustomMaxSlippage {
        address token;
        uint256 maxSlippage;
    }

    /**
     * @dev Swapper action config
     */
    struct SwapperConfig {
        address tokenOut;
        uint256 maxSlippage;
        CustomTokenOut[] customTokensOut;
        CustomMaxSlippage[] customMaxSlippages;
        ActionConfig actionConfig;
    }

    /**
     * @dev Creates a swapper action
     */
    constructor(SwapperConfig memory config) Action(config.actionConfig) {
        _setDefaultTokenOut(config.tokenOut);
        _setDefaultMaxSlippage(config.maxSlippage);

        for (uint256 i = 0; i < config.customTokensOut.length; i++) {
            _setCustomTokenOut(config.customTokensOut[i].token, config.customTokensOut[i].tokenOut);
        }

        for (uint256 i = 0; i < config.customMaxSlippages.length; i++) {
            _setCustomMaxSlippage(config.customMaxSlippages[i].token, config.customMaxSlippages[i].maxSlippage);
        }
    }

    /**
     * @dev Tells the default token threshold
     */
    function getDefaultTokenOut() public view override returns (address) {
        return _defaultTokenOut;
    }

    /**
     * @dev Tells the default token threshold
     */
    function getDefaultMaxSlippage() public view override returns (uint256) {
        return _defaultMaxSlippage;
    }

    /**
     * @dev Tells the token out defined for a specific token
     */
    function getCustomTokenOut(address token) public view override returns (bool, address) {
        return _customTokensOut.tryGet(token);
    }

    /**
     * @dev Tells the max slippage defined for a specific token
     */
    function getCustomMaxSlippage(address token) public view override returns (bool, uint256) {
        return _customMaxSlippages.tryGet(token);
    }

    /**
     * @dev Tells the list of custom token outs set
     */
    function getCustomTokensOut() public view override returns (address[] memory tokens, address[] memory tokensOut) {
        tokens = _customTokensOut.keys();
        tokensOut = _customTokensOut.values();
    }

    /**
     * @dev Tells the list of custom max slippages set
     */
    function getCustomMaxSlippages()
        public
        view
        override
        returns (address[] memory tokens, uint256[] memory maxSlippages)
    {
        tokens = _customMaxSlippages.keys();
        maxSlippages = _customMaxSlippages.values();
    }

    /**
     * @dev Sets the default token out
     */
    function setDefaultTokenOut(address tokenOut) external override auth {
        _setDefaultTokenOut(tokenOut);
    }

    /**
     * @dev Sets the default max slippage
     */
    function setDefaultMaxSlippage(uint256 maxSlippage) external override auth {
        _setDefaultMaxSlippage(maxSlippage);
    }

    /**
     * @dev Sets a list of custom token outs
     */
    function setCustomTokensOut(address[] memory tokens, address[] memory tokensOut) external override auth {
        _setCustomTokensOut(tokens, tokensOut);
    }

    /**
     * @dev Sets a list of custom token outs
     */
    function setCustomMaxSlippages(address[] memory tokens, uint256[] memory maxSlippages) external override auth {
        _setCustomMaxSlippages(tokens, maxSlippages);
    }

    /**
     * @dev Tells the token out that should be used for a token
     */
    function _getApplicableTokenOut(address token) internal view returns (address) {
        (bool exists, address tokenOut) = getCustomTokenOut(token);
        return exists ? tokenOut : getDefaultTokenOut();
    }

    /**
     * @dev Tells the max slippage that should be used for a token
     */
    function _getApplicableMaxSlippage(address token) internal view returns (uint256) {
        (bool exists, uint256 maxSlippage) = getCustomMaxSlippage(token);
        return exists ? maxSlippage : getDefaultMaxSlippage();
    }

    /**
     * @dev Tells if a slippage is valid based on the max slippage configured for a token
     */
    function _isSlippageValid(address token, uint256 slippage) internal view returns (bool) {
        return slippage <= _getApplicableMaxSlippage(token);
    }

    /**
     * @dev Reverts if the requested slippage is above the max slippage configured for a token
     */
    function _validateSlippage(address token, uint256 slippage) internal view {
        require(_isSlippageValid(token, slippage), 'ACTION_SLIPPAGE_TOO_HIGH');
    }

    /**
     * @dev Reverts if the token or the amount are zero
     */
    function _beforeAction(address token, uint256 amount) internal virtual override {
        super._beforeAction(token, amount);
        require(token != address(0), 'ACTION_TOKEN_ZERO');
        require(amount > 0, 'ACTION_AMOUNT_ZERO');
        require(_getApplicableTokenOut(token) != address(0), 'ACTION_TOKEN_OUT_NOT_SET');
    }

    /**
     * @dev Sets the default token out
     * @param tokenOut Default token out to be set
     */
    function _setDefaultTokenOut(address tokenOut) internal {
        _defaultTokenOut = tokenOut;
        emit DefaultTokenOutSet(tokenOut);
    }

    /**
     * @dev Sets the default max slippage
     * @param maxSlippage Default max slippage to be set
     */
    function _setDefaultMaxSlippage(uint256 maxSlippage) internal {
        require(maxSlippage <= FixedPoint.ONE, 'ACTION_SLIPPAGE_ABOVE_ONE');
        _defaultMaxSlippage = maxSlippage;
        emit DefaultMaxSlippageSet(maxSlippage);
    }

    /**
     * @dev Sets a list of custom tokens out for a set of tokens
     * @param tokens List of addresses of the tokens to set the custom token out for
     * @param tokensOut List of addresses of the tokens out to be set
     */
    function _setCustomTokensOut(address[] memory tokens, address[] memory tokensOut) internal {
        require(tokens.length == tokensOut.length, 'ACTION_TOKENS_OUT_BAD_INPUT_LEN');
        for (uint256 i = 0; i < tokens.length; i++) {
            _setCustomTokenOut(tokens[i], tokensOut[i]);
        }
    }

    /**
     * @dev Sets a custom token out for a token
     * @param token Address of the token to set the custom token out for
     * @param tokenOut Address of the token out to be set
     */
    function _setCustomTokenOut(address token, address tokenOut) internal {
        tokenOut == address(0) ? _customTokensOut.remove(token) : _customTokensOut.set(token, tokenOut);
        emit CustomTokenOutSet(token, tokenOut);
    }

    /**
     * @dev Sets a list of custom max slippages for a set of tokens
     * @param tokens List of addresses of the tokens to set the custom max slippage for
     * @param maxSlippages List of max slippages to be set
     */
    function _setCustomMaxSlippages(address[] memory tokens, uint256[] memory maxSlippages) internal {
        require(tokens.length == maxSlippages.length, 'ACTION_SLIPPAGES_BAD_INPUT_LEN');
        for (uint256 i = 0; i < tokens.length; i++) {
            _setCustomMaxSlippage(tokens[i], maxSlippages[i]);
        }
    }

    /**
     * @dev Sets a custom max slippage for a token
     * @param token Address of the token to set the custom max slippage for
     * @param maxSlippage Max slippage to be set
     */
    function _setCustomMaxSlippage(address token, uint256 maxSlippage) internal {
        require(maxSlippage <= FixedPoint.ONE, 'ACTION_SLIPPAGE_ABOVE_ONE');
        maxSlippage == 0 ? _customMaxSlippages.remove(token) : _customMaxSlippages.set(token, maxSlippage);
        emit CustomMaxSlippageSet(token, maxSlippage);
    }
}