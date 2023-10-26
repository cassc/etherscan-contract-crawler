// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/commons/receiver/ReceiverHub.sol";
import "src/commons/Permissions.sol";
import "src/commons/Pausable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract VaultETH is Initializable, ReceiverHub, Permissions, Pausable {
  error ErrorSendingETH(address _to, uint256 _amount, bytes _result);
  error ArrayLengthMismatchETH(uint256 _array1, uint256 _array2);

  uint8 public PERMISSION_SWEEP_ETH;
  uint8 public PERMISSION_SEND_ETH;

  function __initializeETH(uint8 _sweepETHPermission, uint8 _sendETHPermission) internal onlyInitializing {
    PERMISSION_SWEEP_ETH = _sweepETHPermission;
    PERMISSION_SEND_ETH = _sendETHPermission;

    __initializeReceiverHub();

    _registerPermission(PERMISSION_SWEEP_ETH);
    _registerPermission(PERMISSION_SEND_ETH);
  }

  function sweepETH(
    uint256 _id
  ) external notPaused onlyPermissioned(PERMISSION_SWEEP_ETH) {
    _sweepETH(_id);
  }

  function sweepBatchETH(
    uint256[] calldata _ids
  ) external notPaused onlyPermissioned(PERMISSION_SWEEP_ETH) {
    unchecked {
      uint256 idsLength = _ids.length;
      for (uint256 i = 0; i < idsLength; ++i) {
        _sweepETH(_ids[i]);
      }
    }
  }

  function _sweepETH(uint256 _id) internal {
    Receiver receiver = receiverFor(_id);
    uint256 balance = address(receiver).balance;
    if (balance != 0) {
      createIfNeeded(receiver, _id);
      executeOnReceiver(receiver, address(this), balance, bytes(""));
    }
  }

  function sendETH(
    address payable _to,
    uint256 _amount
  ) external notPaused onlyPermissioned(PERMISSION_SEND_ETH) {
    (bool succeed, bytes memory result) = _to.call{ value: _amount }("");
    if (!succeed) { revert ErrorSendingETH(_to, _amount, result); }
  }

  function sendBatchETH(
    address payable[] calldata  _tos,
    uint256[] calldata _amounts
  ) external notPaused onlyPermissioned(PERMISSION_SEND_ETH) {
    uint256 toLength = _tos.length;
    if (toLength != _amounts.length) {
      revert ArrayLengthMismatchETH(toLength, _amounts.length);
    }

    unchecked {
      for (uint256 i = 0; i < toLength; ++i) {
        (bool succeed, bytes memory result) = _tos[i].call{ value: _amounts[i] }("");
        if (!succeed) { revert ErrorSendingETH(_tos[i], _amounts[i], result); }
      }
    }
  }

  receive() external payable {}
}