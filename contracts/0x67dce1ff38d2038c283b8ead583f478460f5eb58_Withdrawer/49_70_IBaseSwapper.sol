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

pragma solidity >=0.8.0;

import '../../IAction.sol';

/**
 * @dev Base swapper action interface
 */
interface IBaseSwapper is IAction {
    /**
     * @dev Emitted every time the default token out is set
     */
    event DefaultTokenOutSet(address indexed tokenOut);

    /**
     * @dev Emitted every time a custom token out is set
     */
    event CustomTokenOutSet(address indexed token, address tokenOut);

    /**
     * @dev Emitted every time the default max slippage is set
     */
    event DefaultMaxSlippageSet(uint256 maxSlippage);

    /**
     * @dev Emitted every time a custom max slippage is set
     */
    event CustomMaxSlippageSet(address indexed token, uint256 maxSlippage);

    /**
     * @dev Tells the default token threshold
     */
    function getDefaultTokenOut() external view returns (address);

    /**
     * @dev Tells the default token threshold
     */
    function getDefaultMaxSlippage() external view returns (uint256);

    /**
     * @dev Tells the token out defined for a specific token
     * @param exists Whether a token out for that token was set
     * @param tokenOut Token out defined for the queried token
     */
    function getCustomTokenOut(address token) external view returns (bool exists, address tokenOut);

    /**
     * @dev Tells the max slippage defined for a specific token
     * @param exists Whether a max slippage for that token was set
     * @param maxSlippage Max slippage defined for the queried token
     */
    function getCustomMaxSlippage(address token) external view returns (bool exists, uint256 maxSlippage);

    /**
     * @dev Tells the list of custom token outs set
     */
    function getCustomTokensOut() external view returns (address[] memory tokens, address[] memory tokensOut);

    /**
     * @dev Tells the list of custom max slippages set
     */
    function getCustomMaxSlippages() external view returns (address[] memory tokens, uint256[] memory maxSlippages);

    /**
     * @dev Sets the default token out
     */
    function setDefaultTokenOut(address tokenOut) external;

    /**
     * @dev Sets the default max slippage
     */
    function setDefaultMaxSlippage(uint256 maxSlippage) external;

    /**
     * @dev Sets a list of custom token outs
     */
    function setCustomTokensOut(address[] memory tokens, address[] memory tokensOut) external;

    /**
     * @dev Sets a list of custom token outs
     */
    function setCustomMaxSlippages(address[] memory tokens, uint256[] memory maxSlippages) external;
}