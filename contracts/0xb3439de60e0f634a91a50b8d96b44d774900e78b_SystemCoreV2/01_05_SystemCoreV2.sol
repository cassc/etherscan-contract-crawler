// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SystemCoreV2 is Initializable, OwnableUpgradeable {
  event RwaNftAdded(address rwa);
  event RwaNftRemoved(address rwa);

  event RwaRegistryAdded(string rwa);
  event RwaRegistryRemoved(string rwa);

  mapping(address => bool) public rwaNfts;
  mapping(string => bool) public rwaRegistry;

  function initialize() public initializer {
    __Ownable_init();
  }

  function addRwaNft(address rwa) public onlyOwner {
    rwaNfts[rwa] = true;
    emit RwaNftAdded(rwa);
  }

  function removeRwaNft(address rwa) public onlyOwner {
    rwaNfts[rwa] = false;
    emit RwaNftRemoved(rwa);
  }

  function addRwaRegistry(string memory rwa) public onlyOwner {
    rwaRegistry[rwa] = true;
    emit RwaRegistryAdded(rwa);
  }

  function removeRwaRegistry(string memory rwa) public onlyOwner {
    rwaRegistry[rwa] = false;
    emit RwaRegistryRemoved(rwa);
  }
}