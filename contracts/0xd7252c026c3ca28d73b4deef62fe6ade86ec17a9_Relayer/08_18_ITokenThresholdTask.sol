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

import './IBaseTask.sol';

/**
 * @dev Token threshold task interface
 */
interface ITokenThresholdTask is IBaseTask {
    /**
     * @dev Threshold defined by a token address and min/max values
     */
    struct Threshold {
        address token;
        uint256 min;
        uint256 max;
    }

    /**
     * @dev The token threshold token is zero
     */
    error TaskThresholdTokenZero();

    /**
     * @dev The token threshold to be set is invalid
     */
    error TaskInvalidThresholdInput(address token, uint256 min, uint256 max);

    /**
     * @dev The token threshold has not been met
     */
    error TaskTokenThresholdNotMet(address token, uint256 amount, uint256 min, uint256 max);

    /**
     * @dev Emitted every time a default threshold is set
     */
    event DefaultTokenThresholdSet(address token, uint256 min, uint256 max);

    /**
     * @dev Emitted every time a token threshold is set
     */
    event CustomTokenThresholdSet(address indexed token, address thresholdToken, uint256 min, uint256 max);

    /**
     * @dev Tells the default token threshold
     */
    function defaultTokenThreshold() external view returns (Threshold memory);

    /**
     * @dev Tells the custom threshold defined for a specific token
     * @param token Address of the token being queried
     */
    function customTokenThreshold(address token) external view returns (Threshold memory);

    /**
     * @dev Tells the threshold that should be used for a token
     * @param token Address of the token being queried
     */
    function getTokenThreshold(address token) external view returns (Threshold memory);

    /**
     * @dev Sets a new default threshold config
     * @param thresholdToken New threshold token to be set
     * @param thresholdMin New threshold minimum to be set
     * @param thresholdMax New threshold maximum to be set
     */
    function setDefaultTokenThreshold(address thresholdToken, uint256 thresholdMin, uint256 thresholdMax) external;

    /**
     * @dev Sets a custom token threshold
     * @param token Address of the token to set a custom threshold
     * @param thresholdToken New custom threshold token to be set
     * @param thresholdMin New custom threshold minimum to be set
     * @param thresholdMax New custom threshold maximum to be set
     */
    function setCustomTokenThreshold(address token, address thresholdToken, uint256 thresholdMin, uint256 thresholdMax)
        external;
}