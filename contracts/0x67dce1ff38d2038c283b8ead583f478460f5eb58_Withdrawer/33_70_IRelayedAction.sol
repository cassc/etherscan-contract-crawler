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

import './IBaseAction.sol';

/**
 * @dev Relayed action interface
 */
interface IRelayedAction is IBaseAction {
    /**
     * @dev Emitted every time the relay gas limits are set
     */
    event RelayGasLimitsSet(uint256 gasPriceLimit, uint256 priorityFeeLimit);

    /**
     * @dev Emitted every time the relay tx cost limit is set
     */
    event RelayTxCostLimitSet(uint256 txCostLimit);

    /**
     * @dev Emitted every time the relay gas token is set
     */
    event RelayGasTokenSet(address indexed token);

    /**
     * @dev Emitted every time the relay permissive mode is set
     */
    event RelayPermissiveModeSet(bool active);

    /**
     * @dev Emitted every time a relayer is added to the allow-list
     */
    event RelayerAllowed(address indexed relayer);

    /**
     * @dev Emitted every time a relayer is removed from the allow-list
     */
    event RelayerDisallowed(address indexed relayer);

    /**
     * @dev Tells the relay gas limits
     */
    function getRelayGasLimits() external view returns (uint256 gasPriceLimit, uint256 priorityFeeLimit);

    /**
     * @dev Tells the relay transaction cost limit
     */
    function getRelayTxCostLimit() external view returns (uint256);

    /**
     * @dev Tells the relay gas token
     */
    function getRelayGasToken() external view returns (address);

    /**
     * @dev Tells whether the relay permissive mode is active
     */
    function isRelayPermissiveModeActive() external view returns (bool);

    /**
     * @dev Tells if a relayer is allowed or not
     * @param relayer Address of the relayer to be checked
     */
    function isRelayer(address relayer) external view returns (bool);

    /**
     * @dev Tells the list of allowed relayers
     */
    function getRelayers() external view returns (address[] memory);

    /**
     * @dev Sets the relay gas limits
     * @param gasPriceLimit New gas price limit to be set
     * @param priorityFeeLimit New priority fee limit to be set
     */
    function setRelayGasLimits(uint256 gasPriceLimit, uint256 priorityFeeLimit) external;

    /**
     * @dev Sets the relay transaction cost limit
     * @param txCostLimit New transaction cost limit to be set
     */
    function setRelayTxCostLimit(uint256 txCostLimit) external;

    /**
     * @dev Sets the relay gas token
     * @param token Address of the token to be set as the relaying gas token
     */
    function setRelayGasToken(address token) external;

    /**
     * @dev Sets the relay permissive mode
     * @param active Whether the relay permissive mode should be active or not
     */
    function setRelayPermissiveMode(bool active) external;

    /**
     * @dev Updates the list of allowed relayers
     * @param relayersToAdd List of relayers to be added to the allow-list
     * @param relayersToRemove List of relayers to be removed from the allow-list
     */
    function setRelayers(address[] memory relayersToAdd, address[] memory relayersToRemove) external;
}