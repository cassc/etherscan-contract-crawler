// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/interfaces/IERC20.sol";

import "src/commons/receiver/ReceiverHub.sol";

import "src/commons/Limits.sol";
import "src/commons/Permissions.sol";
import "src/commons/Pausable.sol";

import "src/utils/SafeERC20.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract VaultERC20 is Initializable, ReceiverHub, Limits, Permissions, Pausable {
  using SafeERC20 for IERC20;

  error ErrorSweepingERC20(address _token, address _receiver, uint256 _amount, bytes _result);
  error ArrayLengthMismatchERC20(uint256 _array1, uint256 _array2);

  uint8 public PERMISSION_SWEEP_ERC20;
  uint8 public PERMISSION_SEND_ERC20;
  uint8 public PERMISSION_SEND_ERC20_LIMIT;

  function __initializeERC20(uint8 _sweepErc20Permission, uint8 _sendErc20Permission, uint8 _sendErc20LimitPermission) internal onlyInitializing {
    PERMISSION_SWEEP_ERC20 = _sweepErc20Permission;
    PERMISSION_SEND_ERC20 = _sendErc20Permission;
    PERMISSION_SEND_ERC20_LIMIT = _sendErc20LimitPermission;

    __initializeReceiverHub();

    _registerPermission(PERMISSION_SWEEP_ERC20);
    _registerPermission(PERMISSION_SEND_ERC20);
    _registerPermission(PERMISSION_SEND_ERC20_LIMIT);
  }

  function sweepERC20(
    IERC20 _token,
    uint256 _id
  ) external notPaused onlyPermissioned(PERMISSION_SWEEP_ERC20) {
    _sweepERC20(_token, _id);
  }

  function sweepBatchERC20(
    IERC20 _token,
    uint256[] calldata _ids
  ) external notPaused onlyPermissioned(PERMISSION_SWEEP_ERC20) {
    unchecked {
      uint256 idsLength = _ids.length;
      for (uint256 i = 0; i < idsLength; ++i) {
        _sweepERC20(_token, _ids[i]);
      }
    }
  }

  function _sweepERC20(
    IERC20 _token,
    uint256 _id
  ) internal {
    Receiver receiver = receiverFor(_id);
    uint256 balance = _token.balanceOf(address(receiver));

    if (balance != 0) {
      createIfNeeded(receiver, _id);

      bytes memory res = executeOnReceiver(receiver, address(_token), 0, abi.encodeWithSelector(
        IERC20.transfer.selector,
        address(this),
        balance
      ));

      if (!SafeERC20.optionalReturnsTrue(res)) {
        revert ErrorSweepingERC20(address(_token), address(receiver), balance, res);
      }
    }
  }

  function sendERC20(
    IERC20 _token,
    address _to,
    uint256 _amount
  ) external notPaused onlyPermissioned(PERMISSION_SEND_ERC20) {
    _token.safeTransfer(_to, _amount);
  }

  function sendBatchERC20(
    IERC20 _token,
    address[] calldata _to,
    uint256[] calldata _amounts
  ) external notPaused onlyPermissioned(PERMISSION_SEND_ERC20) {
    uint256 toLength = _to.length;
    if (toLength != _amounts.length) {
      revert ArrayLengthMismatchERC20(toLength, _amounts.length);
    }

    unchecked {
      for (uint256 i = 0; i < toLength; ++i) {
        _token.safeTransfer(_to[i], _amounts[i]);
      }
    }
  }

  function sendERC20WithLimit(
    IERC20 _token,
    address _to,
    uint256 _amount
  ) external notPaused onlyPermissioned(PERMISSION_SEND_ERC20_LIMIT) underLimit(_amount) {
    _token.safeTransfer(_to, _amount);
  }
}