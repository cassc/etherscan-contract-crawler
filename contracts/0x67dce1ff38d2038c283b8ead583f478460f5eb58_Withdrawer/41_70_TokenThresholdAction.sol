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

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';

import './BaseAction.sol';
import './interfaces/ITokenThresholdAction.sol';

/**
 * @dev Token threshold action. It mainly works with token threshold configs that can be used to tell if
 * a specific token amount is compliant with certain minimum or maximum values. Token threshold actions
 * make use of a default threshold config as a fallback in case there is no custom threshold defined for the token
 * being evaluated.
 */
abstract contract TokenThresholdAction is ITokenThresholdAction, BaseAction {
    using FixedPoint for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Default threshold
    Threshold private _defaultThreshold;

    // Custom thresholds per token
    TokenToThresholdMap private _customThresholds;

    /**
     * @dev Enumerable map of tokens to threshold configs
     */
    struct TokenToThresholdMap {
        EnumerableSet.AddressSet tokens;
        mapping (address => Threshold) thresholds;
    }

    /**
     * @dev Custom token threshold config
     */
    struct CustomThreshold {
        address token;
        Threshold threshold;
    }

    /**
     * @dev Token threshold config. Only used in the constructor.
     * @param defaultThreshold Default threshold to be set
     * @param tokens List of tokens to define a custom threshold for
     * @param thresholds List of custom thresholds to define for each token
     */
    struct TokenThresholdConfig {
        Threshold defaultThreshold;
        CustomThreshold[] customThresholds;
    }

    /**
     * @dev Creates a new token threshold action
     */
    constructor(TokenThresholdConfig memory config) {
        if (config.defaultThreshold.token != address(0)) {
            _setDefaultTokenThreshold(config.defaultThreshold);
        }

        for (uint256 i = 0; i < config.customThresholds.length; i++) {
            _setCustomTokenThreshold(config.customThresholds[i].token, config.customThresholds[i].threshold);
        }
    }

    /**
     * @dev Tells the default token threshold
     */
    function getDefaultTokenThreshold() public view override returns (Threshold memory) {
        return _defaultThreshold;
    }

    /**
     * @dev Tells the token threshold defined for a specific token
     * @param token Address of the token being queried
     */
    function getCustomTokenThreshold(address token)
        public
        view
        override
        returns (bool exists, Threshold memory threshold)
    {
        threshold = _customThresholds.thresholds[token];
        return (_customThresholds.tokens.contains(token), threshold);
    }

    /**
     * @dev Tells the list of custom token thresholds set
     */
    function getCustomTokenThresholds()
        public
        view
        override
        returns (address[] memory tokens, Threshold[] memory thresholds)
    {
        tokens = new address[](_customThresholds.tokens.length());
        thresholds = new Threshold[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            (address token, Threshold memory threshold) = _getTokenThresholdAt(i);
            tokens[i] = token;
            thresholds[i] = threshold;
        }
    }

    /**
     * @dev Sets a new default threshold config
     * @param threshold Threshold config to be set as the default one. Threshold token cannot be zero and max amount
     * must be greater than or equal to the min amount, with the exception of max being set to zero in which case it
     * will be ignored.
     */
    function setDefaultTokenThreshold(Threshold memory threshold) external override auth {
        _setDefaultTokenThreshold(threshold);
    }

    /**
     * @dev Unsets the default threshold, it ignores the request if it was not set
     */
    function unsetDefaultTokenThreshold() external override auth {
        _unsetDefaultTokenThreshold();
    }

    /**
     * @dev Sets a list of tokens thresholds
     * @param tokens List of token addresses to set its custom thresholds
     * @param thresholds Lists of thresholds be set for each token. Threshold token cannot be zero and max amount
     * must be greater than or equal to the min amount, with the exception of max being set to zero in which case it
     * will be ignored.
     */
    function setCustomTokenThresholds(address[] memory tokens, Threshold[] memory thresholds) external override auth {
        _setCustomTokenThresholds(tokens, thresholds);
    }

    /**
     * @dev Unsets a list of custom threshold tokens, it ignores nonexistent custom thresholds
     * @param tokens List of token addresses to unset its custom thresholds
     */
    function unsetCustomTokenThresholds(address[] memory tokens) external override auth {
        _unsetCustomTokenThresholds(tokens);
    }

    /**
     * @dev Returns the token-threshold that should be applied for a token. If there is a custom threshold set it will
     * prioritized over the default threshold. If non of them are defined a null threshold is returned.
     * @param token Address of the token querying the threshold of
     */
    function _getApplicableTokenThreshold(address token) internal view returns (Threshold memory) {
        (bool exists, Threshold memory threshold) = getCustomTokenThreshold(token);
        return exists ? threshold : getDefaultTokenThreshold();
    }

    /**
     * @dev Tells if a token and amount are compliant with a threshold, returns true if the threshold is not set
     * @param threshold Threshold to be evaluated
     * @param token Address of the token to be validated
     * @param amount Token amount to be validated
     */
    function _isTokenThresholdValid(Threshold memory threshold, address token, uint256 amount)
        internal
        view
        returns (bool)
    {
        if (threshold.token == address(0)) return true;
        uint256 price = _getPrice(token, threshold.token);
        uint256 convertedAmount = amount.mulDown(price);
        return convertedAmount >= threshold.min && (threshold.max == 0 || convertedAmount <= threshold.max);
    }

    /**
     * @dev Reverts if the requested token and amount does not comply with the given threshold config
     */
    function _beforeAction(address token, uint256 amount) internal virtual override {
        Threshold memory threshold = _getApplicableTokenThreshold(token);
        require(_isTokenThresholdValid(threshold, token, amount), 'ACTION_TOKEN_THRESHOLD_NOT_MET');
    }

    /**
     * @dev Sets a new default threshold config
     * @param threshold Threshold config to be set as the default one. Threshold token cannot be zero and max amount
     * must be greater than or equal to the min amount, with the exception of max being set to zero in which case it
     * will be ignored.
     */
    function _setDefaultTokenThreshold(Threshold memory threshold) internal {
        _validateThreshold(threshold);
        _defaultThreshold = threshold;
        emit DefaultTokenThresholdSet(threshold);
    }

    /**
     * @dev Unsets a the default threshold config
     */
    function _unsetDefaultTokenThreshold() internal {
        delete _defaultThreshold;
        emit DefaultTokenThresholdUnset();
    }

    /**
     * @dev Sets a list of custom tokens thresholds
     * @param tokens List of token addresses to set its custom thresholds
     * @param thresholds Lists of thresholds be set for each token
     */
    function _setCustomTokenThresholds(address[] memory tokens, Threshold[] memory thresholds) internal {
        require(tokens.length == thresholds.length, 'TOKEN_THRESHOLDS_INPUT_INV_LEN');
        for (uint256 i = 0; i < tokens.length; i++) {
            _setCustomTokenThreshold(tokens[i], thresholds[i]);
        }
    }

    /**
     * @dev Sets a custom of tokens thresholds
     * @param token Address of the token to set a custom threshold for
     * @param threshold Thresholds be set. Threshold token cannot be zero and max amount must be greater than or
     * equal to the min amount, with the exception of max being set to zero in which case it will be ignored.
     */
    function _setCustomTokenThreshold(address token, Threshold memory threshold) internal {
        require(token != address(0), 'THRESHOLD_TOKEN_ADDRESS_ZERO');
        _validateThreshold(threshold);

        _customThresholds.thresholds[token] = threshold;
        _customThresholds.tokens.add(token);
        emit CustomTokenThresholdSet(token, threshold);
    }

    /**
     * @dev Unsets a list of custom threshold tokens, it ignores nonexistent custom thresholds
     * @param tokens List of token addresses to unset its custom thresholds
     */
    function _unsetCustomTokenThresholds(address[] memory tokens) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            delete _customThresholds.thresholds[token];
            if (_customThresholds.tokens.remove(token)) emit CustomTokenThresholdUnset(token);
        }
    }

    /**
     * @dev Returns the token-threshold pair stored at position `i` in the map. Note that there are no guarantees on
     * the ordering of entries inside the array, and it may change when more entries are added or removed. O(1).
     * @param i Index to be accessed in the enumerable map, must be strictly less than its length
     */
    function _getTokenThresholdAt(uint256 i) private view returns (address, Threshold memory) {
        address token = _customThresholds.tokens.at(i);
        return (token, _customThresholds.thresholds[token]);
    }

    /**
     * @dev Reverts if a threshold is not considered valid, that is if the token is zero or if the max amount is greater
     * than zero but lower than the min amount.
     */
    function _validateThreshold(Threshold memory threshold) private pure {
        require(threshold.token != address(0), 'INVALID_THRESHOLD_TOKEN_ZERO');
        require(threshold.max == 0 || threshold.max >= threshold.min, 'INVALID_THRESHOLD_MAX_LT_MIN');
    }
}