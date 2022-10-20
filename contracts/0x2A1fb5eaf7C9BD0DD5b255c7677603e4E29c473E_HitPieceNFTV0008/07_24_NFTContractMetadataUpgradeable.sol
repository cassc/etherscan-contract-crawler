// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./OwnableUpgradeable.sol";

abstract contract NFTContractMetadataUpgradeable is OwnableUpgradeable {

  string internal _baseContractURI;

  function contractURI() public view returns (string memory) {
      return _baseContractURI;
  }
  function setContractURI(string memory _newContractURI) public onlyOwner {
      _baseContractURI = _newContractURI;
  }
}