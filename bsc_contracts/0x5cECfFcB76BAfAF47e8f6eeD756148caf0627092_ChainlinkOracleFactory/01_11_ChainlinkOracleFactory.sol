// SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./ChainlinkOracle.sol";

contract ChainlinkOracleFactory {
  address public implementation;

  constructor(address implementation_) {
    implementation = implementation_;
  }

  function create(address aggregator, uint8 tokenDecimals, uint8 usdtDecimals) external returns (address) {
    bytes32 salt = keccak256(abi.encode(aggregator, tokenDecimals, usdtDecimals));
    address clone = Clones.cloneDeterministic(implementation, salt);
    ChainlinkOracle(clone).initialize(aggregator, tokenDecimals, usdtDecimals);
    return clone;
  }

  function predict(address aggregator, uint8 tokenDecimals, uint8 usdtDecimals) external view returns (address) {
    bytes32 salt = keccak256(abi.encode(aggregator, tokenDecimals, usdtDecimals));
    return Clones.predictDeterministicAddress(implementation, salt);
  }
}