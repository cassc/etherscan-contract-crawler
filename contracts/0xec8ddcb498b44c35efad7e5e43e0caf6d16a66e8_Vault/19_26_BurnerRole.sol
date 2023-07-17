// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { RoleBearers } from './RoleBearers.sol';

/**
 * @title BurnerRole
 * @notice Base contract that implements the Burner role
 */
abstract contract BurnerRole is RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('Burner');

    /**
     * @notice Emitted when the Burner role status for the account is updated
     * @param account The account address
     * @param value The Burner role status flag
     */
    event SetBurner(address indexed account, bool indexed value);

    /**
     * @notice Getter of the Burner role bearer count
     * @return The Burner role bearer count
     */
    function burnerCount() external view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    /**
     * @notice Getter of the complete list of the Burner role bearers
     * @return The complete list of the Burner role bearers
     */
    function fullBurnerList() external view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    /**
     * @notice Getter of the Burner role bearer status
     * @param _account The account address
     */
    function isBurner(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function _setBurner(address _account, bool _value) internal {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetBurner(_account, _value);
    }
}