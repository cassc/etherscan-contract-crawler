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

import './IBaseTask.sol';

/**
 * @dev Volume limited task interface
 */
interface IVolumeLimitedTask is IBaseTask {
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
     * @dev The volume limit token is zero
     */
    error TaskVolumeLimitTokenZero();

    /**
     * @dev The volume limit to be set is invalid
     */
    error TaskInvalidVolumeLimitInput(address token, uint256 amount, uint256 period);

    /**
     * @dev The volume limit has been exceeded
     */
    error TaskVolumeLimitExceeded(address token, uint256 limit, uint256 volume);

    /**
     * @dev Emitted every time a default volume limit is set
     */
    event DefaultVolumeLimitSet(address indexed token, uint256 amount, uint256 period);

    /**
     * @dev Emitted every time a custom volume limit is set
     */
    event CustomVolumeLimitSet(address indexed token, address indexed limitToken, uint256 amount, uint256 period);

    /**
     * @dev Tells the default volume limit set
     */
    function defaultVolumeLimit() external view returns (VolumeLimit memory);

    /**
     * @dev Tells the custom volume limit set for a specific token
     * @param token Address of the token being queried
     */
    function customVolumeLimit(address token) external view returns (VolumeLimit memory);

    /**
     * @dev Tells the volume limit that should be used for a token
     * @param token Address of the token being queried
     */
    function getVolumeLimit(address token) external view returns (VolumeLimit memory);

    /**
     * @dev Sets a the default volume limit config
     * @param limitToken Address of the token to measure the volume limit
     * @param limitAmount Amount of tokens to be applied for the volume limit
     * @param limitPeriod Frequency to Amount of tokens to be applied for the volume limit
     */
    function setDefaultVolumeLimit(address limitToken, uint256 limitAmount, uint256 limitPeriod) external;

    /**
     * @dev Sets a custom volume limit
     * @param token Address of the token to set a custom volume limit for
     * @param limitToken Address of the token to measure the volume limit
     * @param limitAmount Amount of tokens to be applied for the volume limit
     * @param limitPeriod Frequency to Amount of tokens to be applied for the volume limit
     */
    function setCustomVolumeLimit(address token, address limitToken, uint256 limitAmount, uint256 limitPeriod) external;
}