// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Permissions {

    /// @notice permission tpye
    /// mian permission
    uint8 public constant OWNER = 0;
    /// @notice type => address => bool
    mapping (uint8 => mapping(address => bool)) public permissions;
    /// @notice set permission event
    event PermissionSet(uint8 indexed permission, address indexed account, bool indexed value);

    /// @notice check permission
    modifier onlyCaller(uint8 _permission) {
        require(permissions[_permission][msg.sender], "Calls have not allowed");
        _;
    }

    /// @notice set permission
    function _setPermission(uint8 _permission, address _account, bool _value) internal {
        permissions[_permission][_account] = _value;
        emit PermissionSet(_permission, _account, _value);
    }

    /// @notice set permissions
    function setPermissions(uint8[] calldata _permissions, address[] calldata _accounts, bool[] calldata _values) external onlyCaller(OWNER) {
        require(_permissions.length == _accounts.length && _accounts.length == _values.length, "Lengths are not equal");
        for (uint i = 0; i < _permissions.length; i++) {
            _setPermission(_permissions[i], _accounts[i], _values[i]);
        }
    }
    
}