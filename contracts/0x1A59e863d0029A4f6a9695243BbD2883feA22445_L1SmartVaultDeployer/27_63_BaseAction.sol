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

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import '@mimic-fi/v2-smart-vault/contracts/ISmartVault.sol';
import '@mimic-fi/v2-helpers/contracts/auth/Authorizer.sol';
import '@mimic-fi/v2-helpers/contracts/utils/Denominations.sol';
import '@mimic-fi/v2-helpers/contracts/utils/ERC20Helpers.sol';
import '@mimic-fi/v2-registry/contracts/implementations/BaseAuthorizedImplementation.sol';

import './IAction.sol';

/**
 * @title BaseAction
 * @dev Simple action implementation with a Smart Vault reference and using the Authorizer mixin
 */
contract BaseAction is IAction, BaseAuthorizedImplementation, ReentrancyGuard {
    bytes32 public constant override NAMESPACE = keccak256('ACTION');

    // Smart Vault reference
    ISmartVault public override smartVault;

    /**
     * @dev Emitted every time a new smart vault is set
     */
    event SmartVaultSet(address indexed smartVault);

    /**
     * @dev Creates a new BaseAction
     * @param admin Address to be granted authorize and unauthorize permissions
     * @param registry Address of the Mimic Registry
     */
    constructor(address admin, address registry) BaseAuthorizedImplementation(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Sets the Smart Vault tied to the Action. Sender must be authorized. It can be set only once.
     * @param newSmartVault Address of the smart vault to be set
     */
    function setSmartVault(address newSmartVault) external auth {
        require(address(smartVault) == address(0), 'SMART_VAULT_ALREADY_SET');
        smartVault = ISmartVault(newSmartVault);
        emit SmartVaultSet(newSmartVault);
    }

    /**
     * @dev Tells the balance of the Smart Vault for a given token
     * @param token Address of the token querying the balance of
     * @notice Denominations.NATIVE_TOKEN_ADDRESS can be used to query the native token balance
     */
    function _balanceOf(address token) internal view returns (uint256) {
        return ERC20Helpers.balanceOf(token, address(smartVault));
    }

    /**
     * @dev Tells the wrapped native token address if the given address is the native token
     * @param token Address of the token to be checked
     */
    function _wrappedIfNative(address token) internal view returns (address) {
        return Denominations.isNativeToken(token) ? smartVault.wrappedNativeToken() : token;
    }

    /**
     * @dev Tells whether the given token is either the native or wrapped native token
     * @param token Address of the token being queried
     */
    function _isWrappedOrNativeToken(address token) internal view returns (bool) {
        return Denominations.isNativeToken(token) || token == smartVault.wrappedNativeToken();
    }
}