// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";

abstract contract CollaborativeOwnable is Ownable {
  using Address for address;

  mapping(address => bool) private _collaborators;
  uint256 private _collaboratorCount;
  
  constructor() {
    
  }

  function isCollaborator(address collaboratorAddress) public view virtual returns (bool) {
    return _collaborators[collaboratorAddress];
  }

  modifier onlyCollaborator() {
      require(owner() == _msgSender() || _collaborators[_msgSender()], "CO1");
      _;
  }

  function addCollaborator(address collaboratorAddress) public onlyCollaborator {
    require(collaboratorAddress != address(0), "CO2");
    require(!_collaborators[collaboratorAddress], "CO3");

    _collaborators[collaboratorAddress] = true;
    _collaboratorCount++;
  }

  function removeCollaborator(address collaboratorAddress) public onlyCollaborator {
    require(collaboratorAddress != address(0), "CO4");
    require(_collaborators[collaboratorAddress], "CO4");
    require(_collaboratorCount > 1, "CO4");
    
    _collaborators[collaboratorAddress] = false;
    _collaboratorCount--;
  }
}