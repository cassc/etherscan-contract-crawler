// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '../resolvers/Resolver.sol';
import './BaseRegistrarImplementation.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import 'hardhat/console.sol';

// NounishClubController registers a random name from 0 to 9999
// for accounts that have one or more claims available.
contract NounishClubController is Ownable {
  using ECDSA for bytes32;

  event NameRegistered(
    string name,
    bytes32 indexed label,
    address indexed owner
  );

  BaseRegistrarImplementation base;
  address private signer;
  mapping(address => mapping(uint256 => bool)) usedNonces;

  constructor(BaseRegistrarImplementation _base, address _signer) {
    base = _base;
    signer = _signer;
  }

  function register(
    uint16 number,
    uint256 nonce,
    uint256 expiry,
    address resolver,
    address addr,
    bytes memory signature
  ) public {
    require(!usedNonces[msg.sender][nonce], 'nonce already used');

    bytes32 hash = keccak256(
      abi.encodePacked(msg.sender, number, nonce, expiry, resolver, addr)
    );
    address msgSigner = hash.toEthSignedMessageHash().recover(signature);
    require(msgSigner == signer, 'invalid signature');

    require(expiry > block.timestamp, 'expired');

    string memory name = Strings.toString(number);

    usedNonces[msg.sender][nonce] = true;
    _register(name, resolver, addr);
  }

  // Register the given name.
  function _register(
    string memory name,
    address resolver,
    address addr
  ) private {
    require(_available(name), 'name not available');

    bytes32 label = keccak256(bytes(name));
    uint256 tokenId = uint256(label);

    // Copied from NNSRegistrarControllerWithReservation.sol.
    if (resolver != address(0)) {
      // Set this contract as the (temporary) owner, giving it
      // permission to set up the resolver.
      base.register(tokenId, address(this));

      // The nodehash of this label
      bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), label));

      // Set the resolver
      base.ens().setResolver(nodehash, resolver);

      // Configure the resolver
      if (addr != address(0)) {
        Resolver(resolver).setAddr(nodehash, addr);
      }

      // Now transfer full ownership to the expected owner
      base.reclaim(tokenId, msg.sender);
      base.transferFrom(address(this), msg.sender, tokenId);
    } else {
      require(addr == address(0));
      base.register(tokenId, msg.sender);
    }
    emit NameRegistered(name, label, msg.sender);
  }

  // Checks if the name is available in the registry and not blocked.
  function _available(string memory name) private view returns (bool) {
    bytes32 label = keccak256(bytes(name));
    uint256 tokenId = uint256(label);
    return base.available(tokenId);
  }
}