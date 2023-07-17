// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { RoleBearers } from './RoleBearers.sol';

/**
 * @title MultichainRouterRole
 * @notice Base contract that implements the Multichain Router role
 */
abstract contract MultichainRouterRole is RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('MultichainRouter');

    /**
     * @notice Emitted when the Multichain Router role status for the account is updated
     * @param account The account address
     * @param value The Multichain Router role status flag
     */
    event SetMultichainRouter(address indexed account, bool indexed value);

    /**
     * @notice Getter of the Multichain Router role bearer count
     * @return The Multichain Router role bearer count
     */
    function multichainRouterCount() external view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    /**
     * @notice Getter of the complete list of the Multichain Router role bearers
     * @return The complete list of the Multichain Router role bearers
     */
    function fullMultichainRouterList() external view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    /**
     * @notice Getter of the Multichain Router role bearer status
     * @param _account The account address
     */
    function isMultichainRouter(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function _setMultichainRouter(address _account, bool _value) internal {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetMultichainRouter(_account, _value);
    }
}