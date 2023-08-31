// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
  function balanceOf(address owner) external view returns (uint256);
}

interface IENSResolver {
  function setAddr(bytes32 node, address addr) external;

  function addr(bytes32 node) external view returns (address);
}

interface IENSRegistry {
  function setOwner(bytes32 node, address owner) external;

  function owner(bytes32 node) external view returns (address);

  function setResolver(bytes32 node, address resolver) external;

  function resolver(bytes32 node) external view returns (address);

  function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
}

error InvalidDomain();
error WrongEtherAmount();
error WithdrawalFailed();
error NotSavedSoulsHolder();
error SubdomainAlreadyOwned();

contract SavedSoulsENS is Ownable {
  bytes32 private constant EMPTY_NAMEHASH = 0x00;

  IERC721 private immutable savedSouls;

  IENSRegistry private registry;
  IENSResolver private resolver;

  uint256 public subdomainPrice = 0.002 ether;

  mapping(address => uint8) private freeSubdomainCount;

  constructor(
    IERC721 _savedSouls,
    IENSRegistry _registry,
    IENSResolver _resolver
  ) {
    registry = _registry;
    resolver = _resolver;
    savedSouls = _savedSouls;
  }

  function newSubdomain(
    string calldata _subdomain,
    string calldata _domain,
    string calldata _topdomain
  ) external payable {
    if (savedSouls.balanceOf(msg.sender) == 0) {
      revert NotSavedSoulsHolder();
    }

    bytes32 topdomainNamehash = keccak256(
      abi.encodePacked(EMPTY_NAMEHASH, keccak256(abi.encodePacked(_topdomain)))
    );
    bytes32 domainNamehash = keccak256(
      abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(_domain)))
    );

    if (registry.owner(domainNamehash) != address(this)) {
      revert InvalidDomain();
    }

    bytes32 subdomainLabelhash = keccak256(abi.encodePacked(_subdomain));
    bytes32 subdomainNamehash = keccak256(
      abi.encodePacked(domainNamehash, subdomainLabelhash)
    );

    if (registry.owner(subdomainNamehash) != address(0)) {
      revert SubdomainAlreadyOwned();
    }

    uint8 availableSubdomains = getAvailableSubdomains(msg.sender);

    if (availableSubdomains == 0 && msg.value != subdomainPrice) {
      revert WrongEtherAmount();
    }

    if (availableSubdomains > 0) {
      freeSubdomainCount[msg.sender] += 1;
    }

    registry.setSubnodeOwner(domainNamehash, subdomainLabelhash, address(this));
    registry.setResolver(subdomainNamehash, address(resolver));
    resolver.setAddr(subdomainNamehash, msg.sender);
    registry.setOwner(subdomainNamehash, msg.sender);
  }

  function getFreeSubdomainCount(address _owner) external view returns (uint8) {
    return freeSubdomainCount[_owner];
  }

  function getAvailableSubdomains(address _owner) public view returns (uint8) {
    uint256 balance = savedSouls.balanceOf(_owner);
    uint8 usedSubdomains = freeSubdomainCount[_owner];

    if (balance >= 100) return 5 - usedSubdomains;
    if (balance >= 40) return 4 - usedSubdomains;
    if (balance >= 15) return 3 - usedSubdomains;
    if (balance >= 5) return 2 - usedSubdomains;
    if (balance >= 1) return 1 - usedSubdomains;

    return 0;
  }

  function domainOwner(
    string calldata _domain,
    string calldata _topdomain
  ) external view returns (address) {
    bytes32 topdomainNamehash = keccak256(
      abi.encodePacked(EMPTY_NAMEHASH, keccak256(abi.encodePacked(_topdomain)))
    );
    bytes32 namehash = keccak256(
      abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(_domain)))
    );

    return registry.owner(namehash);
  }

  function subdomainOwner(
    string calldata _subdomain,
    string calldata _domain,
    string calldata _topdomain
  ) external view returns (address) {
    bytes32 topdomainNamehash = keccak256(
      abi.encodePacked(EMPTY_NAMEHASH, keccak256(abi.encodePacked(_topdomain)))
    );
    bytes32 domainNamehash = keccak256(
      abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(_domain)))
    );
    bytes32 subdomainNamehash = keccak256(
      abi.encodePacked(domainNamehash, keccak256(abi.encodePacked(_subdomain)))
    );

    return registry.owner(subdomainNamehash);
  }

  function updateRegistry(IENSRegistry _registry) external onlyOwner {
    registry = _registry;
  }

  function updateResolver(IENSResolver _resolver) external onlyOwner {
    resolver = _resolver;
  }

  function updateSubdomainPrice(uint256 _price) external onlyOwner {
    subdomainPrice = _price;
  }

  function withdraw() external onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");

    if (!success) {
      revert WithdrawalFailed();
    }
  }
}