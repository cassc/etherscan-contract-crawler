// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Stoppable is Ownable {
  bool stopped;

  modifier nonStopped() {
    require(!stopped, "STOPPED: Contract is stopped");
    _;
  }

  function stop(bool _stop) public onlyOwner {
    stopped = _stop;
  }
}