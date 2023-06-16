// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./ContractRoyaltiesStream.sol";
contract ContractRoyaltiesFactory {
  event ContractDeployed(address indexed owner, address indexed group, string title);
  address public immutable implementation;
  constructor() {
    implementation = address(new ContractRoyaltiesStream());
  }
  function genesis(string calldata title, ContractRoyaltiesStream.Member[] calldata members) external returns (address) {
    address payable clone = payable(Clones.clone(implementation));
    ContractRoyaltiesStream s = ContractRoyaltiesStream(clone);
    s.initialize(members);
    emit ContractDeployed(msg.sender, clone, title);
    return clone;
  }
}