// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./OffchainAggregator.sol";

// ExposedOffchainAggregator exposes certain internal OffchainAggregator
// methods/structures so that golang code can access them, and we get
// reliable type checking on their usage
contract ExposedOffchainAggregator is OffchainAggregator {

  constructor()
    OffchainAggregator(
      0, 0, 0, 0, 0, LinkTokenInterface(address(0)), 0, 0, AccessControllerInterface(address(0)), AccessControllerInterface(address(0)), 0, ""
    )
    {}

  function exposedConfigDigestFromConfigData(
    address _contractAddress,
    uint64 _configCount,
    address[] calldata _signers,
    address[] calldata _transmitters,
    uint8 _threshold,
    uint64 _encodedConfigVersion,
    bytes calldata _encodedConfig
  ) external pure returns (bytes16) {
    return configDigestFromConfigData(_contractAddress, _configCount,
      _signers, _transmitters, _threshold, _encodedConfigVersion,
      _encodedConfig);
  }
}