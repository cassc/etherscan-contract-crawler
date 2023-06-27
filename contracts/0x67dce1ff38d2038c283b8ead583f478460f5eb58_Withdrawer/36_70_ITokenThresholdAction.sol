// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General External License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General External License for more details.

// You should have received a copy of the GNU General External License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import './IBaseAction.sol';

/**
 * @dev Token threshold action interface
 */
interface ITokenThresholdAction is IBaseAction {
    /**
     * @dev Threshold defined by a token address and min/max values
     */
    struct Threshold {
        address token;
        uint256 min;
        uint256 max;
    }

    /**
     * @dev Emitted every time a default threshold is set
     */
    event DefaultTokenThresholdSet(Threshold threshold);

    /**
     * @dev Emitted every time the default threshold is unset
     */
    event DefaultTokenThresholdUnset();

    /**
     * @dev Emitted every time a token threshold is set
     */
    event CustomTokenThresholdSet(address indexed token, Threshold threshold);

    /**
     * @dev Emitted every time a token threshold is unset
     */
    event CustomTokenThresholdUnset(address indexed token);

    /**
     * @dev Tells the default token threshold
     */
    function getDefaultTokenThreshold() external view returns (Threshold memory);

    /**
     * @dev Tells the token threshold defined for a specific token
     * @param token Address of the token being queried
     */
    function getCustomTokenThreshold(address token) external view returns (bool exists, Threshold memory threshold);

    /**
     * @dev Tells the list of custom token thresholds set
     */
    function getCustomTokenThresholds() external view returns (address[] memory tokens, Threshold[] memory thresholds);

    /**
     * @dev Sets a new default threshold config
     * @param threshold Threshold config to be set as the default one
     */
    function setDefaultTokenThreshold(Threshold memory threshold) external;

    /**
     * @dev Unsets the default threshold, it ignores the request if it was not set
     */
    function unsetDefaultTokenThreshold() external;

    /**
     * @dev Sets a list of tokens thresholds
     * @param tokens List of token addresses to set its custom thresholds
     * @param thresholds Lists of thresholds be set for each token
     */
    function setCustomTokenThresholds(address[] memory tokens, Threshold[] memory thresholds) external;

    /**
     * @dev Unsets a list of custom threshold tokens, it ignores nonexistent custom thresholds
     * @param tokens List of token addresses to unset its custom thresholds
     */
    function unsetCustomTokenThresholds(address[] memory tokens) external;
}