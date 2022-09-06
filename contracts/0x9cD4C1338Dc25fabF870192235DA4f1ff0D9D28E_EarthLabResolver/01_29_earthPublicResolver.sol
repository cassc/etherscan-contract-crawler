// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol";

contract EarthLabResolver is PublicResolver {
  constructor(INameWrapper wrapper)
    PublicResolver(
      ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e),
      wrapper,
      0x0000000000000000000000000000000000000000,
      0x0000000000000000000000000000000000000000
    )
  {}
}