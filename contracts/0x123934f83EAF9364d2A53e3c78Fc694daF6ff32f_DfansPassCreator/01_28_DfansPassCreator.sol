// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DfansPass.sol";

contract DfansPassCreator is Ownable {
  event ContractDeployed(address indexed owner, address indexed passAddress);
  address public implementation;

  constructor(address _implementation) {
      implementation = _implementation;
  }

  function setImplementation(address newImplementation) external onlyOwner {
      implementation = newImplementation;
  }

  function createDfansPass(
      string memory name,
      string memory symbol,
      string memory collectionId,
      uint96 royaltyFraction,
      address payable beneficiary,
      address payable owner,
      uint256 initialPublish,
      bool transferMintETH,
      uint256 fixedPrice
  ) external returns (address) {
      address payable clone = payable(Clones.clone(implementation));
      DfansPass dp = DfansPass(clone);
      dp.initialize(name, symbol, collectionId, royaltyFraction, beneficiary, owner, initialPublish, transferMintETH, fixedPrice);
      emit ContractDeployed(owner, clone);
      return clone;
  }
}