// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { RoleBearers } from './RoleBearers.sol';

/**
 * @title AssetSpenderRole
 * @notice Base contract that implements the Asset Spender role
 */
abstract contract AssetSpenderRole is RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('AssetSpender');

    /**
     * @notice Emitted when the Asset Spender role status for the account is updated
     * @param account The account address
     * @param value The Asset Spender role status flag
     */
    event SetAssetSpender(address indexed account, bool indexed value);

    /**
     * @notice Emitted when the caller is not an Asset Spender role bearer
     */
    error OnlyAssetSpenderError();

    /**
     * @dev Modifier to check if the caller is an Asset Spender role bearer
     */
    modifier onlyAssetSpender() {
        if (!isAssetSpender(msg.sender)) {
            revert OnlyAssetSpenderError();
        }

        _;
    }

    /**
     * @notice Getter of the Asset Spender role bearer count
     * @return The Asset Spender role bearer count
     */
    function assetSpenderCount() external view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    /**
     * @notice Getter of the complete list of the Asset Spender role bearers
     * @return The complete list of the Asset Spender role bearers
     */
    function fullAssetSpenderList() external view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    /**
     * @notice Getter of the Asset Spender role bearer status
     * @param _account The account address
     */
    function isAssetSpender(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function _setAssetSpender(address _account, bool _value) internal {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetAssetSpender(_account, _value);
    }
}