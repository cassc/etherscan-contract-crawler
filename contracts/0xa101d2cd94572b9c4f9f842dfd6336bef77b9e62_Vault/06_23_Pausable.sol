// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/commons/Ownable.sol";
import "src/commons/Permissions.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Pausable is Initializable, Ownable, Permissions {
  error ContractPaused();

  event Unpaused(address _sender);
  event Paused(address _sender);

  enum State { Invalid, Unpaused, Paused }

  State internal _state = State.Unpaused;
  uint8 public PERMISSION_PAUSE;

  function __initializePausable(uint8 _permissionPause) internal onlyInitializing {
    PERMISSION_PAUSE = _permissionPause;
    __initializeOwnable();
  }

  modifier notPaused() {
    if (_state == State.Paused) {
      revert ContractPaused();
    }

    _;
  }

  function isPaused() public view returns (bool) {
    return _state == State.Paused;
  }

  function pause() external onlyPermissioned(PERMISSION_PAUSE) {
    _state = State.Paused;
    emit Paused(msg.sender);
  }

  function unpause() external onlyOwner {
    _state = State.Unpaused;
    emit Unpaused(msg.sender);
  }
}