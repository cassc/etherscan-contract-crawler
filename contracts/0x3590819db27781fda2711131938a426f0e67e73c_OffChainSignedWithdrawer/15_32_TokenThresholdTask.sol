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

pragma solidity ^0.8.3;

import '@mimic-fi/v3-authorizer/contracts/Authorized.sol';
import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';

import '../interfaces/base/ITokenThresholdTask.sol';

/**
 * @dev Token threshold task. It mainly works with token threshold configs that can be used to tell if
 * a specific token amount is compliant with certain minimum or maximum values. Token threshold tasks
 * make use of a default threshold config as a fallback in case there is no custom threshold defined for the token
 * being evaluated.
 */
abstract contract TokenThresholdTask is ITokenThresholdTask, Authorized {
    using FixedPoint for uint256;

    // Default threshold
    Threshold internal _defaultThreshold;

    // Custom thresholds per token
    mapping (address => Threshold) internal _customThresholds;

    /**
     * @dev Threshold defined by a token address and min/max values
     */
    struct Threshold {
        address token;
        uint256 min;
        uint256 max;
    }

    /**
     * @dev Custom token threshold config. Only used in the initializer.
     */
    struct CustomThresholdConfig {
        address token;
        Threshold threshold;
    }

    /**
     * @dev Token threshold config. Only used in the initializer.
     * @param defaultThreshold Default threshold to be set
     * @param customThresholdConfigs List of custom threshold configs to be set
     */
    struct TokenThresholdConfig {
        Threshold defaultThreshold;
        CustomThresholdConfig[] customThresholdConfigs;
    }

    /**
     * @dev Initializes the token threshold task. It does not call upper contracts initializers.
     * @param config Token threshold task config
     */
    function __TokenThresholdTask_init(TokenThresholdConfig memory config) internal onlyInitializing {
        __TokenThresholdTask_init_unchained(config);
    }

    /**
     * @dev Initializes the token threshold task. It does call upper contracts initializers.
     * @param config Token threshold task config
     */
    function __TokenThresholdTask_init_unchained(TokenThresholdConfig memory config) internal onlyInitializing {
        Threshold memory defaultThreshold = config.defaultThreshold;
        _setDefaultTokenThreshold(defaultThreshold.token, defaultThreshold.min, defaultThreshold.max);

        for (uint256 i = 0; i < config.customThresholdConfigs.length; i++) {
            CustomThresholdConfig memory customThresholdConfig = config.customThresholdConfigs[i];
            Threshold memory custom = customThresholdConfig.threshold;
            _setCustomTokenThreshold(customThresholdConfig.token, custom.token, custom.min, custom.max);
        }
    }

    /**
     * @dev Tells the default token threshold
     */
    function defaultTokenThreshold() external view override returns (address thresholdToken, uint256 min, uint256 max) {
        Threshold memory threshold = _defaultThreshold;
        return (threshold.token, threshold.min, threshold.max);
    }

    /**
     * @dev Tells the token threshold defined for a specific token
     * @param token Address of the token being queried
     */
    function customTokenThreshold(address token)
        external
        view
        override
        returns (address thresholdToken, uint256 min, uint256 max)
    {
        Threshold memory threshold = _customThresholds[token];
        return (threshold.token, threshold.min, threshold.max);
    }

    /**
     * @dev Tells the threshold that should be used for a token, it prioritizes custom thresholds over the default one
     * @param token Address of the token being queried
     */
    function getTokenThreshold(address token)
        external
        view
        virtual
        override
        returns (address thresholdToken, uint256 min, uint256 max)
    {
        Threshold memory threshold = _getTokenThreshold(token);
        return (threshold.token, threshold.min, threshold.max);
    }

    /**
     * @dev Sets a new default threshold config
     * @param thresholdToken New threshold token to be set
     * @param min New threshold minimum to be set
     * @param max New threshold maximum to be set
     */
    function setDefaultTokenThreshold(address thresholdToken, uint256 min, uint256 max)
        external
        override
        authP(authParams(thresholdToken, min, max))
    {
        _setDefaultTokenThreshold(thresholdToken, min, max);
    }

    /**
     * @dev Sets a custom token threshold
     * @param token Address of the token to set a custom threshold for
     * @param thresholdToken New custom threshold token to be set
     * @param min New custom threshold minimum to be set
     * @param max New custom threshold maximum to be set
     */
    function setCustomTokenThreshold(address token, address thresholdToken, uint256 min, uint256 max)
        external
        override
        authP(authParams(token, thresholdToken, min, max))
    {
        _setCustomTokenThreshold(token, thresholdToken, min, max);
    }

    /**
     * @dev Fetches a base/quote price
     */
    function _getPrice(address base, address quote) internal view virtual returns (uint256);

    /**
     * @dev Tells the threshold that should be used for a token, it prioritizes custom thresholds over the default one
     * @param token Address of the token being queried
     */
    function _getTokenThreshold(address token) internal view returns (Threshold memory) {
        Threshold storage customThreshold = _customThresholds[token];
        return customThreshold.token == address(0) ? _defaultThreshold : customThreshold;
    }

    /**
     * @dev Before token threshold task hook
     */
    function _beforeTokenThresholdTask(address token, uint256 amount) internal virtual {
        Threshold memory threshold = _getTokenThreshold(token);
        if (threshold.token == address(0)) return;

        uint256 convertedAmount = threshold.token == token ? amount : amount.mulDown(_getPrice(token, threshold.token));
        bool isValid = convertedAmount >= threshold.min && (threshold.max == 0 || convertedAmount <= threshold.max);
        if (!isValid) revert TaskTokenThresholdNotMet(threshold.token, convertedAmount, threshold.min, threshold.max);
    }

    /**
     * @dev After token threshold task hook
     */
    function _afterTokenThresholdTask(address, uint256) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Sets a new default threshold config
     * @param thresholdToken New threshold token to be set
     * @param min New threshold minimum to be set
     * @param max New threshold maximum to be set
     */
    function _setDefaultTokenThreshold(address thresholdToken, uint256 min, uint256 max) internal {
        _setTokenThreshold(_defaultThreshold, thresholdToken, min, max);
        emit DefaultTokenThresholdSet(thresholdToken, min, max);
    }

    /**
     * @dev Sets a custom of tokens thresholds
     * @param token Address of the token to set a custom threshold for
     * @param thresholdToken New custom threshold token to be set
     * @param min New custom threshold minimum to be set
     * @param max New custom threshold maximum to be set
     */
    function _setCustomTokenThreshold(address token, address thresholdToken, uint256 min, uint256 max) internal {
        if (token == address(0)) revert TaskThresholdTokenZero();
        _setTokenThreshold(_customThresholds[token], thresholdToken, min, max);
        emit CustomTokenThresholdSet(token, thresholdToken, min, max);
    }

    /**
     * @dev Sets a threshold
     * @param threshold Threshold to be updated
     * @param token New threshold token to be set
     * @param min New threshold minimum to be set
     * @param max New threshold maximum to be set
     */
    function _setTokenThreshold(Threshold storage threshold, address token, uint256 min, uint256 max) private {
        // If there is no threshold, all values must be zero
        bool isZeroThreshold = token == address(0) && min == 0 && max == 0;
        bool isNonZeroThreshold = token != address(0) && (max == 0 || max >= min);
        if (!isZeroThreshold && !isNonZeroThreshold) revert TaskInvalidThresholdInput(token, min, max);

        threshold.token = token;
        threshold.min = min;
        threshold.max = max;
    }
}