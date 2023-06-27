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

import '../Action.sol';
import './interfaces/IWithdrawer.sol';

/**
 * @title Withdrawer action
 * @dev Action that offers a recipient address where funds can be withdrawn. This type of action at least require
 * having withdraw permissions from the Smart Vault tied to it.
 */
contract Withdrawer is IWithdrawer, Action {
    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 45e3;

    // Address where tokens will be transferred to
    address private _recipient;

    /**
     * @dev Withdrawer action config
     * @param recipient Address of the allowed recipient
     * @param actionConfig Action config params
     */
    struct WithdrawerConfig {
        address recipient;
        ActionConfig actionConfig;
    }

    /**
     * @dev Creates a withdrawer action
     */
    constructor(WithdrawerConfig memory config) Action(config.actionConfig) {
        _setRecipient(config.recipient);
    }

    /**
     * @dev Tells the address of the allowed recipient
     */
    function getRecipient() external view override returns (address) {
        return _recipient;
    }

    /**
     * @dev Sets the recipient address. Sender must be authorized.
     * @param recipient Address of the new recipient to be set
     */
    function setRecipient(address recipient) external override auth {
        _setRecipient(recipient);
    }

    /**
     * @dev Execution function
     */
    function call(address token, uint256 amount) external override actionCall(token, amount) {
        smartVault.withdraw(token, amount, _recipient, new bytes(0));
    }

    /**
     * @dev Reverts if the token or the amount are zero
     */
    function _beforeAction(address token, uint256 amount) internal virtual override {
        super._beforeAction(token, amount);
        require(token != address(0), 'ACTION_TOKEN_ZERO');
        require(amount > 0, 'ACTION_AMOUNT_ZERO');
    }

    /**
     * @dev Internal function to sets the recipient address
     * @param recipient Address of the new recipient to be set
     */
    function _setRecipient(address recipient) internal {
        require(recipient != address(0), 'ACTION_RECIPIENT_ZERO');
        _recipient = recipient;
        emit RecipientSet(recipient);
    }
}