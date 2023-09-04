// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '../AvastarsMarketplace.sol';

contract MockAvastarsMarketplaceUpgrade is AvastarsMarketplace {
  function initializeUpgrade(string memory _domain, string memory _version) public reinitializer(2) {
    __EIP712_init(_domain, _version);
  }

  function getDomainHash() public view returns (bytes32) {
    return _EIP712NameHash();
  }

    function getVersionHash() public view returns (bytes32) {
    return _EIP712VersionHash();
  }
}