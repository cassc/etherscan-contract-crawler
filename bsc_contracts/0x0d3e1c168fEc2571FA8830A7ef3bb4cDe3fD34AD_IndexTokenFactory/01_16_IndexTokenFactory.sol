// SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./IndexToken.sol";

contract IndexTokenFactory {
  address public baseContract;
  address[] public clones;

  event Created(
    address indexed owner,
    address indexed token
  );

  constructor(address baseContract_) {
    baseContract = baseContract_;
  }

  function clonesLength() external view returns (uint256) {
    return clones.length;
  }

  function create(IndexToken.InitParams calldata parameters, bytes32 salt) external returns (address) {
    address clone = Clones.cloneDeterministic(baseContract, salt);
    IndexToken(clone).initialize(parameters);
    IndexToken(clone).transferOwnership(msg.sender);
    clones.push(clone);
    emit Created(msg.sender, clone);
    return clone;
  }

  function predict(bytes32 salt) external view returns (address) {
    return Clones.predictDeterministicAddress(baseContract, salt);
  }
}