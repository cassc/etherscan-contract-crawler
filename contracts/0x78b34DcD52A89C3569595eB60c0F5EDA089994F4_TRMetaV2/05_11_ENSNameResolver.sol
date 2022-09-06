//SPDX-License-Identifier: Unlicense
// thanks to shahruz.eth and the OKPC team

pragma solidity ^0.8.4;

interface IReverseRegistrar {
  function node(address addr) external view returns (bytes32);
}

interface IReverseResolver {
  function name(bytes32 node) external view returns (string memory);
}

contract ENSNameResolver {
  IReverseRegistrar constant registrar = IReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);
  IReverseResolver constant resolver = IReverseResolver(0xA2C122BE93b0074270ebeE7f6b7292C7deB45047);

  function getENSName(address addr) public view returns (string memory) {
    try resolver.name(registrar.node(addr)) {
      return resolver.name(registrar.node(addr));
    } catch {
      return '';
    }
  }
}