// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/commons/receiver/ReceiverHub.sol";
import "src/commons/Permissions.sol";
import "src/commons/Pausable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


abstract contract VaultNewReceivers is Initializable, ReceiverHub, Permissions, Pausable {
  uint8 public PERMISSION_DEPLOY_RECEIVER;

  function __initializeNewReceivers(uint8 _deployReceiverPermission) internal onlyInitializing {
    PERMISSION_DEPLOY_RECEIVER = _deployReceiverPermission;

    __initializeReceiverHub();

    _registerPermission(PERMISSION_DEPLOY_RECEIVER);
  }

  function deployReceivers(
    uint256[] calldata _receivers
  ) external notPaused onlyPermissioned(PERMISSION_DEPLOY_RECEIVER) {
    unchecked {
      uint256 receiversLength = _receivers.length;

      for (uint256 i = 0; i < receiversLength; ++i) {
        useReceiver(_receivers[i]);
      }
    }
  }

  function deployReceiversRange(
    uint256 _from,
    uint256 _to
  ) external notPaused onlyPermissioned(PERMISSION_DEPLOY_RECEIVER) {
    unchecked {
      for (uint256 i = _from; i < _to; ++i) {
        useReceiver(i);
      }
    }
  }
}