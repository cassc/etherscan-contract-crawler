// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/commons/Ownable.sol";


contract Permissions is Ownable {
  error PermissionDenied(address _sender, uint8 _permission);
  error DuplicatedPermission(uint8 _permission);

  mapping (address => bytes32) public permissions;
  mapping (uint8 => bool) public permissionExists;

  event AddPermission(address indexed _addr, uint8 _permission);
  event DelPermission(address indexed _addr, uint8 _permission);
  event ClearPermissions(address indexed _addr);

  modifier onlyPermissioned(uint8 _permission) {
    if (!hasPermission(msg.sender, _permission) && !isOwner(msg.sender)) {
      revert PermissionDenied(msg.sender, _permission);
    }

    _;
  }

  function _registerPermission(uint8 _permission) internal {
    if (permissionExists[_permission]) {
      revert DuplicatedPermission(_permission);
    }

    permissionExists[_permission] = true;
  }

  function hasPermission(address _addr, uint8 _permission) public view returns (bool) {
    return (permissions[_addr] & _maskForPermission(_permission)) != 0;
  }

  function addPermission(address _addr, uint8 _permission) external virtual onlyOwner {
    _addPermission(_addr, _permission);
  }

  function addPermissions(address _addr, uint8[] calldata _permissions) external virtual onlyOwner {
    _addPermissions(_addr, _permissions);
  }

  function delPermission(address _addr, uint8 _permission) external virtual onlyOwner {
    _delPermission(_addr, _permission);
  }

  function clearPermissions(address _addr) external virtual onlyOwner {
    _clearPermissions(_addr);
  }

  function _maskForPermission(uint8 _permission) internal pure returns (bytes32) {
    return bytes32(1 << _permission);
  }

  function _addPermission(address _addr, uint8 _permission) internal {
    permissions[_addr] |= _maskForPermission(_permission);
    emit AddPermission(_addr, _permission);
  }

  function _addPermissions(address _addr, uint8[] calldata _permissions) internal {
    unchecked {
      for (uint256 i = 0; i < _permissions.length; ++i) {
        _addPermission(_addr, _permissions[i]);
      }
    }
  }

  function _delPermission(address _addr, uint8 _permission) internal {
    permissions[_addr] &= ~_maskForPermission(_permission);
    emit DelPermission(_addr, _permission);
  }

  function _clearPermissions(address _addr) internal {
    delete permissions[_addr];
    emit ClearPermissions(_addr);
  }
}