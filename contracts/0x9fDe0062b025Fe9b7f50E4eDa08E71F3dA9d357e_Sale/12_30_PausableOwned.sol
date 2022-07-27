// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PausableOwned is Ownable, Pausable {
  /**
   * @dev Pause the contract
   * Only `owner` can call
   */
  function pause() public onlyOwner {
    super._pause();
  }

  /**
   * @dev Unpause the contract
   * Only `owner` can call
   */
  function unpause() public onlyOwner {
    super._unpause();
  }
}