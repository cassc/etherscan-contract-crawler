// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { RoleBearers } from './RoleBearers.sol';

/**
 * @title MinterRole
 * @notice Base contract that implements the Minter role
 */
abstract contract MinterRole is RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('Minter');

    /**
     * @notice Emitted when the Minter role status for the account is updated
     * @param account The account address
     * @param value The Minter role status flag
     */
    event SetMinter(address indexed account, bool indexed value);

    /**
     * @notice Getter of the Minter role bearer count
     * @return The Minter role bearer count
     */
    function minterCount() external view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    /**
     * @notice Getter of the complete list of the Minter role bearers
     * @return The complete list of the Minter role bearers
     */
    function fullMinterList() external view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    /**
     * @notice Getter of the Minter role bearer status
     * @param _account The account address
     */
    function isMinter(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function _setMinter(address _account, bool _value) internal {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetMinter(_account, _value);
    }
}