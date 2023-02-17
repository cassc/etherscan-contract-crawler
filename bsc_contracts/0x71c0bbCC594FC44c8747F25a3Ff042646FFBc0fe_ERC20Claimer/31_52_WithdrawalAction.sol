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

import './BaseAction.sol';

/**
 * @title Withdrawal action
 * @dev Action that offers a recipient address where funds can be withdrawn. This type of action at least require
 * having withdraw permissions from the Smart Vault tied to it.
 */
abstract contract WithdrawalAction is BaseAction {
    // Address where tokens will be transferred to
    address public recipient;

    /**
     * @dev Emitted every time the recipient is set
     */
    event RecipientSet(address indexed recipient);

    /**
     * @dev Sets the recipient address. Sender must be authorized.
     * @param newRecipient Address of the new recipient to be set
     */
    function setRecipient(address newRecipient) external auth {
        require(newRecipient != address(0), 'RECIPIENT_ZERO');
        recipient = newRecipient;
        emit RecipientSet(newRecipient);
    }

    /**
     * @dev Internal function to withdraw all the available balance of a token from the Smart Vault to the recipient
     * @param token Address of the token to be withdrawn
     */
    function _withdraw(address token) internal {
        uint256 balance = _balanceOf(token);
        _withdraw(token, balance);
    }

    /**
     * @dev Internal function to withdraw a specific amount of a token from the Smart Vault to the recipient
     * @param token Address of the token to be withdrawn
     * @param amount Amount of tokens to be withdrawn
     */
    function _withdraw(address token, uint256 amount) internal {
        smartVault.withdraw(token, amount, recipient, new bytes(0));
    }
}