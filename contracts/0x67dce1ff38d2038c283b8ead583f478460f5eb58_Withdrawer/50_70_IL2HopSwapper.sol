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

import './IBaseSwapper.sol';

/**
 * @dev L2 Hop swapper action interface
 */
interface IL2HopSwapper is IBaseSwapper {
    /**
     * @dev Emitted every time an AMM is set for a token
     */
    event TokenAmmSet(address indexed token, address amm);

    /**
     * @dev Tells AMM set for a token
     */
    function getTokenAmm(address token) external view returns (address amm);

    /**
     * @dev Tells the list of AMMs set for each token
     */
    function getTokenAmms() external view returns (address[] memory tokens, address[] memory amms);

    /**
     * @dev Sets a list of amms for a list of hTokens
     * @param hTokens List of hToken addresses to be set
     * @param amms List of AMM addresses to be set for each hToken
     */
    function setTokenAmms(address[] memory hTokens, address[] memory amms) external;

    /**
     * @dev Execution function
     */
    function call(address tokenIn, uint256 amountIn, uint256 slippage) external;
}