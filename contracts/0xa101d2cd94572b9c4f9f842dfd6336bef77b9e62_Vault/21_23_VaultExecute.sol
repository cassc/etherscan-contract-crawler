// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/commons/receiver/ReceiverHub.sol";
import "src/commons/Permissions.sol";
import "src/commons/Pausable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract VaultExecute is Initializable, ReceiverHub, Permissions, Pausable {
  uint8 public PERMISSION_EXECUTE_ON_RECEIVER;
  uint8 public PERMISSION_EXECUTE;

  error CallError(address _to, uint256 _value, bytes _data, bytes _result);

  function __initializeExecute(
    uint8 _executeOnReceiverPermission,
    uint8 _executePermission
  ) internal onlyInitializing {
    PERMISSION_EXECUTE_ON_RECEIVER = _executeOnReceiverPermission;
    PERMISSION_EXECUTE = _executePermission;

    __initializeReceiverHub();

    _registerPermission(PERMISSION_EXECUTE_ON_RECEIVER);
    _registerPermission(PERMISSION_EXECUTE);
  }

  function executeOnReceiver(
    uint256 _id,
    address payable _to,
    uint256 _value,
    bytes calldata _data
  ) external notPaused onlyPermissioned(PERMISSION_EXECUTE_ON_RECEIVER) returns (bytes memory) {
    return executeOnReceiver(_id, _to, _value, _data);
  }

  function execute(
    address payable _to,
    uint256 _value,
    bytes calldata _data
  ) external notPaused onlyPermissioned(PERMISSION_EXECUTE) returns (bytes memory) {
    (bool res, bytes memory result) = _to.call{ value: _value }(_data);
    if (!res) revert CallError(_to, _value, _data, result);
    return result;
  }
}