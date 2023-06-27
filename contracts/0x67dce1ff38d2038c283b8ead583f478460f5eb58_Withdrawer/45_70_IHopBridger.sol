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

import './IBaseBridger.sol';

/**
 * @dev Hop bridger action interface
 */
interface IHopBridger is IBaseBridger {
    /**
     * @dev Emitted every time the relayer is set
     */
    event RelayerSet(address indexed relayer);

    /**
     * @dev Emitted every time the max deadline is set
     */
    event MaxDeadlineSet(uint256 maxDeadline);

    /**
     * @dev Emitted every time the default max fee percentage is set
     */
    event DefaultMaxFeePctSet(uint256 maxFeePct);

    /**
     * @dev Emitted every time the default max slippage is set
     */
    event DefaultMaxSlippageSet(uint256 maxSlippage);

    /**
     * @dev Emitted every time a custom max fee percentage is set
     */
    event CustomMaxFeePctSet(address indexed token, uint256 maxFeePct);

    /**
     * @dev Emitted every time a custom max slippage is set
     */
    event CustomMaxSlippageSet(address indexed token, uint256 maxSlippage);

    /**
     * @dev Emitted every time a Hop entrypoint is set for a token
     */
    event TokenHopEntrypointSet(address indexed token, address indexed entrypoint);

    /**
     * @dev Tells the relayer address, only used when bridging from L1 to L2
     */
    function getRelayer() external view returns (address);

    /**
     * @dev Tells the max deadline
     */
    function getMaxDeadline() external view returns (uint256);

    /**
     * @dev Tells the default token threshold
     */
    function getDefaultMaxSlippage() external view returns (uint256);

    /**
     * @dev Tells the default max fee pct
     */
    function getDefaultMaxFeePct() external view returns (uint256);

    /**
     * @dev Tells the max fee percentage defined for a specific token
     */
    function getCustomMaxFeePct(address token) external view returns (bool exists, uint256 maxFeePct);

    /**
     * @dev Tells the list of custom max fee percentages set
     */
    function getCustomMaxFeePcts() external view returns (address[] memory tokens, uint256[] memory maxFeePcts);

    /**
     * @dev Tells the max slippage defined for a specific token
     */
    function getCustomMaxSlippage(address token) external view returns (bool exists, uint256 maxSlippage);

    /**
     * @dev Tells the list of custom max slippages set
     */
    function getCustomMaxSlippages() external view returns (address[] memory tokens, uint256[] memory maxSlippages);

    /**
     * @dev Tells Hop entrypoint set for a token
     */
    function getTokenHopEntrypoint(address token) external view returns (bool exists, address entrypoint);

    /**
     * @dev Tells the list of Hop entrypoints set for each token
     */
    function getTokenHopEntrypoints() external view returns (address[] memory tokens, address[] memory entrypoints);

    /**
     * @dev Sets the relayer, only used when bridging from L1 to L2
     * @param relayer New relayer address to be set
     */
    function setRelayer(address relayer) external;

    /**
     * @dev Sets the max deadline
     * @param maxDeadline New max deadline to be set
     */
    function setMaxDeadline(uint256 maxDeadline) external;

    /**
     * @dev Sets the default max fee percentage
     * @param maxFeePct New default max fee percentage to be set
     */
    function setDefaultMaxFeePct(uint256 maxFeePct) external;

    /**
     * @dev Sets the default max slippage
     * @param maxSlippage New default max slippage to be set
     */
    function setDefaultMaxSlippage(uint256 maxSlippage) external;

    /**
     * @dev Sets a list of custom max fee percentages
     * @param tokens List of token addresses to set a max fee percentage for
     * @param maxFeePcts List of max fee percentages to be set for each token
     */
    function setCustomMaxFeePcts(address[] memory tokens, uint256[] memory maxFeePcts) external;

    /**
     * @dev Sets a list of custom max slippages
     * @param tokens List of token addresses to set a max slippage for
     * @param maxSlippages List of max slippages to be set for each token
     */
    function setCustomMaxSlippages(address[] memory tokens, uint256[] memory maxSlippages) external;

    /**
     * @dev Sets a list of entrypoints for a list of tokens
     * @param tokens List of token addresses to set a Hop entrypoint for
     * @param entrypoints List of Hop entrypoint addresses to be set for each token
     */
    function setTokenHopEntrypoints(address[] memory tokens, address[] memory entrypoints) external;

    /**
     * @dev Execution function
     */
    function call(address token, uint256 amount, uint256 slippage, uint256 fee) external;
}