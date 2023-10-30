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

import '@mimic-fi/v3-authorizer/contracts/interfaces/IAuthorized.sol';

/**
 * @dev Base task interface
 */
interface IBaseTask is IAuthorized {
    // Execution type serves for relayers in order to distinguish how each task must be executed
    // solhint-disable-next-line func-name-mixedcase
    function EXECUTION_TYPE() external view returns (bytes32);

    /**
     * @dev The balance connectors are the same
     */
    error TaskSameBalanceConnectors(bytes32 connectorId);

    /**
     * @dev The smart vault's price oracle is not set
     */
    error TaskSmartVaultPriceOracleNotSet(address smartVault);

    /**
     * @dev Emitted every time a task is executed
     */
    event Executed();

    /**
     * @dev Emitted every time the balance connectors are set
     */
    event BalanceConnectorsSet(bytes32 indexed previous, bytes32 indexed next);

    /**
     * @dev Tells the address of the Smart Vault tied to it, it cannot be changed
     */
    function smartVault() external view returns (address);

    /**
     * @dev Tells the address from where the token amounts to execute this task are fetched.
     * This address must the the Smart Vault in case the previous balance connector is set.
     */
    function getTokensSource() external view returns (address);

    /**
     * @dev Tells the amount a task should use for a token
     * @param token Address of the token being queried
     */
    function getTaskAmount(address token) external view returns (uint256);

    /**
     * @dev Tells the previous and next balance connectors id of the previous task in the workflow
     */
    function getBalanceConnectors() external view returns (bytes32 previous, bytes32 next);

    /**
     * @dev Sets the balance connector IDs
     * @param previous Balance connector id of the previous task in the workflow
     * @param next Balance connector id of the next task in the workflow
     */
    function setBalanceConnectors(bytes32 previous, bytes32 next) external;
}