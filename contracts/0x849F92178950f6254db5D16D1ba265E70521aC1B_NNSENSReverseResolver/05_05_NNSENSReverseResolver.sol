// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import {ENS} from '../registry/ENS.sol';
import {INameResolver} from '../resolvers/profiles/INameResolver.sol';
import {IAddrResolver} from '../resolvers/profiles/IAddrResolver.sol';
import './ENSNamehash.sol';

contract NNSENSReverseResolver {

  using ENSNamehash for bytes;

  bytes32 private constant ADDR_REVERSE_NODE =
    0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
  bytes32 private constant ZERO_ADDRESS =
    0x918d5359431a7007dec0d4722530b0726c0e1010a959bd8b871a6a5d6337144a;

  ENS public immutable ens;
  ENS public immutable nns;

  constructor(address _nns, address _ens) {
    nns = ENS(_nns);
    ens = ENS(_ens);
  }

  function resolve(address addr) public view returns (string memory) {
    string memory name = _resolve(addr, nns);
    if (bytes(name).length == 0 && address(ens) != address(0)) {
      return _resolve(addr, ens);
    }
    return name;
  }

  function _resolve(address addr, ENS registry)
    private
    view
    returns (string memory)
  {
    // Resolve addr to name.
    bytes32 n = reverseAddrNode(addr);
    address resolverAddress = registry.resolver(n);
    if (resolverAddress == address(0)) {
      return '';
    }
    INameResolver nameResolver = INameResolver(resolverAddress);
    string memory name = nameResolver.name(n);
    if (
      bytes(name).length == 0 ||
      keccak256(abi.encodePacked(name)) == ZERO_ADDRESS
    ) {
      return '';
    }

    // Reverse check.
    bytes32 nameNode = bytes(name).namehash();
    address addrResolverAddr = registry.resolver(nameNode);
    if (addrResolverAddr == address(0)) {
      return '';
    }
    IAddrResolver addrResolver = IAddrResolver(addrResolverAddr);
    address revAddr = addrResolver.addr(nameNode);
    if (revAddr != addr) {
      return '';
    }
 
    return name;
  }

  function reverseAddrNode(address addr) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ADDR_REVERSE_NODE, sha3HexAddress(addr)));
  }

  function sha3HexAddress(address addr) private pure returns (bytes32 ret) {
    addr;
    ret; // Stop warning us about unused variables
    assembly {
      let
        lookup
      := 0x3031323334353637383961626364656600000000000000000000000000000000

      for {
        let i := 40
      } gt(i, 0) {

      } {
        i := sub(i, 1)
        mstore8(i, byte(and(addr, 0xf), lookup))
        addr := div(addr, 0x10)
        i := sub(i, 1)
        mstore8(i, byte(and(addr, 0xf), lookup))
        addr := div(addr, 0x10)
      }

      ret := keccak256(0, 40)
    }
  }
}