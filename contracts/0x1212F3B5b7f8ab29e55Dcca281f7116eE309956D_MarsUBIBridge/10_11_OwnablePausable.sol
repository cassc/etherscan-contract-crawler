//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// @notice utility contract which is ownable and pausable
contract OwnablePausable is Ownable, Pausable {
  
  constructor() {
  }

  /**
  * @dev enables owner to pause / unpause minting
  * @param _bPaused the flag to pause or unpause
  */
  function setPaused(bool _bPaused) public onlyOwner {
      if (_bPaused) _pause();
      else _unpause();
  }

}