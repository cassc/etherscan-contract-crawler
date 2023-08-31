// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

abstract contract MPCManageable {
  event MPCUpdated(address indexed oldMPC, address indexed newMPC, uint256 effectiveTime);

  uint256 public constant DELAY = 2 days;

  address internal _oldMPC;
  address internal _newMPC;
  uint256 internal _newMPCEffectiveTime;

  constructor(address _MPC) {
    _updateMPC(_MPC, 0);
  }

  modifier onlyMPC() {
    _checkMPC();
    _;
  }

  function mpc() public view returns (address) {
    if (block.timestamp >= _newMPCEffectiveTime) {
      return _newMPC;
    }

    return _oldMPC;
  }

  function updateMPC(address newMPC) public onlyMPC {
    _updateMPC(newMPC, DELAY);
  }

  function _updateMPC(address newMPC, uint256 delay) private {
    require(newMPC != address(0), "MPCManageable: Nullable MPC");

    _oldMPC = mpc();
    _newMPC = newMPC;
    _newMPCEffectiveTime = block.timestamp + delay;

    emit MPCUpdated(_oldMPC, _newMPC, _newMPCEffectiveTime);
  }

  function _checkMPC() internal view {
    require(msg.sender == mpc(), "MPCManageable: Non MPC");
  }
}