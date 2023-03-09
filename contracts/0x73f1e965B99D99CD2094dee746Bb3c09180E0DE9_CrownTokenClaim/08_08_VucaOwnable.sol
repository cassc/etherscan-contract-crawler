// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract VucaOwnable is Ownable {
  address public candidateOwner;
  event NewCandidateOwner(address indexed candidate);

  function transferOwnership(address _candidateOwner) public override onlyOwner {
    require(_candidateOwner != address(0), "Ownable: candidate owner is the zero address");
    candidateOwner = _candidateOwner;
    emit NewCandidateOwner(_candidateOwner);
  }

  function claimOwnership() external {
    require(candidateOwner == _msgSender(), "Ownable: caller is not the candidate owner");
    _transferOwnership(candidateOwner);
    candidateOwner = address(0);
  }
}