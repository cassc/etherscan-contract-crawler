// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBreedManager.sol";

abstract contract Breedable is Ownable {
  IBreedManager public breedManager;

  function setBreedManager(address _manager) external onlyOwner {
	  breedManager = IBreedManager(_manager);
  }
}