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
import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v2-helpers/contracts/utils/Denominations.sol';
import '@mimic-fi/v2-helpers/contracts/utils/ERC20Helpers.sol';

import './interfaces/IBaseAction.sol';

/**
 * @title BaseAction
 * @dev Simple action implementation with a Smart Vault reference and using the Authorizer mixin
 */
contract BaseAction is IBaseAction, Authorizer, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Whether the action is paused or not
    bool private _paused;

    // Group ID of the action
    uint8 private _groupId;

    // Smart Vault reference
    ISmartVault public immutable override smartVault;

    /**
     * @dev Modifier to tag the execution function of an action to trigger before and after hooks automatically
     */
    modifier actionCall(address token, uint256 amount) {
        _beforeAction(token, amount);
        _;
        _afterAction(token, amount);
    }

    /**
     * @dev Base action config. Only used in the constructor.
     * @param owner Address that will be granted with permissions to authorize and authorize
     * @param smartVault Address of the smart vault this action will reference, it cannot be changed once set
     * @param groupId Id of the group to which this action must refer to, use zero to avoid grouping
     */
    struct BaseConfig {
        address owner;
        address smartVault;
        uint8 groupId;
    }

    /**
     * @dev Creates a new base action
     */
    constructor(BaseConfig memory config) {
        smartVault = ISmartVault(config.smartVault);
        _authorize(config.owner, Authorizer.authorize.selector);
        _authorize(config.owner, Authorizer.unauthorize.selector);
        _setGroupId(config.groupId);
    }

    /**
     * @dev It allows receiving native token transfers
     */
    receive() external payable {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Tells the action is paused or not
     */
    function isPaused() public view override returns (bool) {
        return _paused;
    }

    /**
     * @dev Tells the group ID of the action
     */
    function getGroupId() public view override returns (uint8) {
        return _groupId;
    }

    /**
     * @dev Tells the balance of the action for a given token
     * @param token Address of the token querying the balance of
     * @notice Denominations.NATIVE_TOKEN_ADDRESS can be used to query the native token balance
     */
    function getActionBalance(address token) public view override returns (uint256) {
        return ERC20Helpers.balanceOf(token, address(this));
    }

    /**
     * @dev Tells the balance of the Smart Vault for a given token
     * @param token Address of the token querying the balance of
     * @notice Denominations.NATIVE_TOKEN_ADDRESS can be used to query the native token balance
     */
    function getSmartVaultBalance(address token) public view override returns (uint256) {
        return ERC20Helpers.balanceOf(token, address(smartVault));
    }

    /**
     * @dev Tells the total balance for a given token
     * @param token Address of the token querying the balance of
     * @notice Denominations.NATIVE_TOKEN_ADDRESS can be used to query the native token balance
     */
    function getTotalBalance(address token) public view override returns (uint256) {
        return getActionBalance(token) + getSmartVaultBalance(token);
    }

    /**
     * @dev Pauses an action
     */
    function pause() external override auth {
        require(!_paused, 'ACTION_ALREADY_PAUSED');
        _paused = true;
        emit Paused();
    }

    /**
     * @dev Unpauses an action
     */
    function unpause() external override auth {
        require(_paused, 'ACTION_ALREADY_UNPAUSED');
        _paused = false;
        emit Unpaused();
    }

    /**
     * @dev Sets a group ID for the action. Sender must be authorized
     * @param groupId ID of the group to be set for the action
     */
    function setGroupId(uint8 groupId) external override auth {
        _setGroupId(groupId);
    }

    /**
     * @dev Transfers action's assets to the Smart Vault
     * @param token Address of the token to be transferred
     * @param amount Amount of tokens to be transferred
     * @notice Denominations.NATIVE_TOKEN_ADDRESS can be used to transfer the native token balance
     */
    function transferToSmartVault(address token, uint256 amount) external override auth {
        _transferToSmartVault(token, amount);
    }

    /**
     * @dev Hook to be called before the action call starts. This implementation only adds a non-reentrant, auth, and
     * not-paused guard. It should be overwritten to add any extra logic that must run before the action is executed.
     */
    function _beforeAction(address, uint256) internal virtual nonReentrant auth {
        require(!_paused, 'ACTION_PAUSED');
    }

    /**
     * @dev Hook to be called after the action call has finished. This implementation only emits the Executed event.
     * It should be overwritten to add any extra logic that must run after the action has been executed.
     */
    function _afterAction(address, uint256) internal virtual {
        emit Executed();
    }

    /**
     * @dev Sets a group ID for the action
     * @param groupId ID of the group to be set for the action
     */
    function _setGroupId(uint8 groupId) internal {
        _groupId = groupId;
        emit GroupIdSet(groupId);
    }

    /**
     * @dev Internal function to transfer action's assets to the Smart Vault
     * @param token Address of the token to be transferred
     * @param amount Amount of tokens to be transferred
     * @notice Denominations.NATIVE_TOKEN_ADDRESS can be used to transfer the native token balance
     */
    function _transferToSmartVault(address token, uint256 amount) internal {
        ERC20Helpers.transfer(token, address(smartVault), amount);
    }

    /**
     * @dev Fetches a base/quote price from the smart vault's oracle. This function can be overwritten to implement
     * a secondary way of fetching oracle prices.
     */
    function _getPrice(address base, address quote) internal view virtual returns (uint256) {
        return base == quote ? FixedPoint.ONE : smartVault.getPrice(base, quote);
    }

    /**
     * @dev Tells whether a token is the native or the wrapped native token
     */
    function _isWrappedOrNative(address token) internal view returns (bool) {
        return Denominations.isNativeToken(token) || token == _wrappedNativeToken();
    }

    /**
     * @dev Tells the wrapped native token address
     */
    function _wrappedNativeToken() internal view returns (address) {
        return smartVault.wrappedNativeToken();
    }
}