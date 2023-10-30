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

pragma solidity ^0.8.17;

import '@mimic-fi/v3-authorizer/contracts/Authorized.sol';
import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';

import '../interfaces/base/IVolumeLimitedTask.sol';

/**
 * @dev Volume limit config for tasks. It allows setting volume limit per period of time.
 */
abstract contract VolumeLimitedTask is IVolumeLimitedTask, Authorized {
    using FixedPoint for uint256;

    // Default volume limit
    VolumeLimit internal _defaultVolumeLimit;

    // Custom volume limits per token
    mapping (address => VolumeLimit) internal _customVolumeLimits;

    /**
     * @dev Volume limit config
     * @param token Address to measure the volume limit
     */
    struct VolumeLimit {
        address token;
        uint256 amount;
        uint256 accrued;
        uint256 period;
        uint256 nextResetTime;
    }

    /**
     * @dev Volume limit params. Only used in the initializer.
     */
    struct VolumeLimitParams {
        address token;
        uint256 amount;
        uint256 period;
    }

    /**
     * @dev Custom token volume limit config. Only used in the initializer.
     */
    struct CustomVolumeLimitConfig {
        address token;
        VolumeLimitParams volumeLimit;
    }

    /**
     * @dev Volume limit config. Only used in the initializer.
     */
    struct VolumeLimitConfig {
        VolumeLimitParams defaultVolumeLimit;
        CustomVolumeLimitConfig[] customVolumeLimitConfigs;
    }

    /**
     * @dev Initializes the volume limited task. It does call upper contracts initializers.
     * @param config Volume limited task config
     */
    function __VolumeLimitedTask_init(VolumeLimitConfig memory config) internal onlyInitializing {
        __VolumeLimitedTask_init_unchained(config);
    }

    /**
     * @dev Initializes the volume limited task. It does not call upper contracts initializers.
     * @param config Volume limited task config
     */
    function __VolumeLimitedTask_init_unchained(VolumeLimitConfig memory config) internal onlyInitializing {
        VolumeLimitParams memory defaultLimit = config.defaultVolumeLimit;
        _setDefaultVolumeLimit(defaultLimit.token, defaultLimit.amount, defaultLimit.period);

        for (uint256 i = 0; i < config.customVolumeLimitConfigs.length; i++) {
            CustomVolumeLimitConfig memory customVolumeLimitConfig = config.customVolumeLimitConfigs[i];
            VolumeLimitParams memory custom = customVolumeLimitConfig.volumeLimit;
            _setCustomVolumeLimit(customVolumeLimitConfig.token, custom.token, custom.amount, custom.period);
        }
    }

    /**
     * @dev Tells the default volume limit set
     */
    function defaultVolumeLimit()
        external
        view
        override
        returns (address limitToken, uint256 amount, uint256 accrued, uint256 period, uint256 nextResetTime)
    {
        VolumeLimit memory limit = _defaultVolumeLimit;
        return (limit.token, limit.amount, limit.accrued, limit.period, limit.nextResetTime);
    }

    /**
     * @dev Tells the custom volume limit set for a specific token
     * @param token Address of the token being queried
     */
    function customVolumeLimit(address token)
        external
        view
        override
        returns (address limitToken, uint256 amount, uint256 accrued, uint256 period, uint256 nextResetTime)
    {
        VolumeLimit memory limit = _customVolumeLimits[token];
        return (limit.token, limit.amount, limit.accrued, limit.period, limit.nextResetTime);
    }

    /**
     * @dev Tells the volume limit that should be used for a token, it prioritizes custom limits over the default one
     * @param token Address of the token being queried
     */
    function getVolumeLimit(address token)
        external
        view
        override
        returns (address limitToken, uint256 amount, uint256 accrued, uint256 period, uint256 nextResetTime)
    {
        VolumeLimit memory limit = _getVolumeLimit(token);
        return (limit.token, limit.amount, limit.accrued, limit.period, limit.nextResetTime);
    }

    /**
     * @dev Sets a the default volume limit config
     * @param limitToken Address of the token to measure the volume limit
     * @param limitAmount Amount of tokens to be applied for the volume limit
     * @param limitPeriod Frequency to Amount of tokens to be applied for the volume limit
     */
    function setDefaultVolumeLimit(address limitToken, uint256 limitAmount, uint256 limitPeriod)
        external
        override
        authP(authParams(limitToken, limitAmount, limitPeriod))
    {
        _setDefaultVolumeLimit(limitToken, limitAmount, limitPeriod);
    }

    /**
     * @dev Sets a custom volume limit
     * @param token Address of the token to set a custom volume limit for
     * @param limitToken Address of the token to measure the volume limit
     * @param limitAmount Amount of tokens to be applied for the volume limit
     * @param limitPeriod Frequency to Amount of tokens to be applied for the volume limit
     */
    function setCustomVolumeLimit(address token, address limitToken, uint256 limitAmount, uint256 limitPeriod)
        external
        override
        authP(authParams(token, limitToken, limitAmount, limitPeriod))
    {
        _setCustomVolumeLimit(token, limitToken, limitAmount, limitPeriod);
    }

    /**
     * @dev Fetches a base/quote price
     */
    function _getPrice(address base, address quote) internal view virtual returns (uint256);

    /**
     * @dev Tells the volume limit that should be used for a token, it prioritizes custom limits over the default one
     * @param token Address of the token being queried
     */
    function _getVolumeLimit(address token) internal view returns (VolumeLimit storage) {
        VolumeLimit storage customLimit = _customVolumeLimits[token];
        return customLimit.token == address(0) ? _defaultVolumeLimit : customLimit;
    }

    /**
     * @dev Before volume limited task hook
     */
    function _beforeVolumeLimitedTask(address token, uint256 amount) internal virtual {
        VolumeLimit memory limit = _getVolumeLimit(token);
        if (limit.token == address(0)) return;

        uint256 amountInLimitToken = limit.token == token ? amount : amount.mulDown(_getPrice(token, limit.token));
        uint256 processedVolume = amountInLimitToken + (block.timestamp < limit.nextResetTime ? limit.accrued : 0);
        if (processedVolume > limit.amount) revert TaskVolumeLimitExceeded(limit.token, limit.amount, processedVolume);
    }

    /**
     * @dev After volume limited task hook
     */
    function _afterVolumeLimitedTask(address token, uint256 amount) internal virtual {
        VolumeLimit storage limit = _getVolumeLimit(token);
        if (limit.token == address(0)) return;

        uint256 amountInLimitToken = limit.token == token ? amount : amount.mulDown(_getPrice(token, limit.token));
        if (block.timestamp >= limit.nextResetTime) {
            limit.accrued = 0;
            limit.nextResetTime = block.timestamp + limit.period;
        }
        limit.accrued += amountInLimitToken;
    }

    /**
     * @dev Sets the default volume limit
     * @param limitToken Address of the token to measure the volume limit
     * @param limitAmount Amount of tokens to be applied for the volume limit
     * @param limitPeriod Frequency to Amount of tokens to be applied for the volume limit
     */
    function _setDefaultVolumeLimit(address limitToken, uint256 limitAmount, uint256 limitPeriod) internal {
        _setVolumeLimit(_defaultVolumeLimit, limitToken, limitAmount, limitPeriod);
        emit DefaultVolumeLimitSet(limitToken, limitAmount, limitPeriod);
    }

    /**
     * @dev Sets a custom volume limit
     * @param token Address of the token to set a custom volume limit for
     * @param limitToken Address of the token to measure the volume limit
     * @param limitAmount Amount of tokens to be applied for the volume limit
     * @param limitPeriod Frequency to Amount of tokens to be applied for the volume limit
     */
    function _setCustomVolumeLimit(address token, address limitToken, uint256 limitAmount, uint256 limitPeriod)
        internal
    {
        if (token == address(0)) revert TaskVolumeLimitTokenZero();
        _setVolumeLimit(_customVolumeLimits[token], limitToken, limitAmount, limitPeriod);
        emit CustomVolumeLimitSet(token, limitToken, limitAmount, limitPeriod);
    }

    /**
     * @dev Sets a volume limit
     * @param limit Volume limit to be updated
     * @param token Address of the token to measure the volume limit
     * @param amount Amount of tokens to be applied for the volume limit
     * @param period Frequency to Amount of tokens to be applied for the volume limit
     */
    function _setVolumeLimit(VolumeLimit storage limit, address token, uint256 amount, uint256 period) private {
        // If there is no limit, all values must be zero
        bool isZeroLimit = token == address(0) && amount == 0 && period == 0;
        bool isNonZeroLimit = token != address(0) && amount > 0 && period > 0;
        if (!isZeroLimit && !isNonZeroLimit) revert TaskInvalidVolumeLimitInput(token, amount, period);

        // Changing the period only affects the end time of the next period, but not the end date of the current one
        limit.period = period;

        // Changing the amount does not affect the totalizator, it only applies when updating the accrued amount.
        // Note that it can happen that the new amount is lower than the accrued amount if the amount is lowered.
        // However, there shouldn't be any accounting issues with that.
        limit.amount = amount;

        // Therefore, only clean the totalizators if the limit is being removed
        if (isZeroLimit) {
            limit.accrued = 0;
            limit.nextResetTime = 0;
        } else {
            // If limit is not zero, set the next reset time if it wasn't set already
            // Otherwise, if the token is being changed the accrued amount must be updated accordingly
            if (limit.nextResetTime == 0) {
                limit.accrued = 0;
                limit.nextResetTime = block.timestamp + period;
            } else if (limit.token != token) {
                uint256 price = _getPrice(limit.token, token);
                limit.accrued = limit.accrued.mulDown(price);
            }
        }

        // Finally simply set the new requested token
        limit.token = token;
    }
}