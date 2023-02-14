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

import '@mimic-fi/v2-smart-vault/contracts/ISmartVault.sol';
import '@mimic-fi/v2-helpers/contracts/auth/IAuthorizer.sol';

/**
 * @title IAction
 * @dev Action interface it must follow the IAuthorizer interface
 */
interface IAction is IAuthorizer {
    /**
     * @dev Emitted every time an action is executed
     */
    event Executed();

    /**
     * @dev Tells the address of the Smart Vault tied to it, it cannot be changed
     */
    function smartVault() external view returns (ISmartVault);
}