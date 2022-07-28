// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/governance/TimelockController.sol";

contract RoyalExecutorV2 is TimelockController {
  event GasTankFilled(
    address indexed from,
    uint256 indexed queeneId,
    uint256 value
  );

  //executor gas tank
  uint256 private _gasTank;

  // minDelay is how long you have to wait before executing
  // proposers is the list of addresses that can propose
  // executors is the list of addresses that can execute
  constructor(
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors
  ) TimelockController(minDelay, proposers, executors) {}

  /**
   * @dev Overrides timelockController receive to control funds out of this.balance to avoid selfdestruct attacks.
   */
  fallback() external payable {
    fillGasTank(0);
  }

  /**
   * @dev Overrides timelockController receive to control funds out of this.balance to avoid selfdestruct attacks.
   */
  function fillGasTank(uint256 queeneId) public payable {
    _gasTank += msg.value;

    emit GasTankFilled(msg.sender, queeneId, msg.value);
  }

  function gasMeter() external view returns (uint256) {
    return _gasTank;
  }
}