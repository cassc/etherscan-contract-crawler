//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {UUPSProxyWithOwner} from "@synthetixio/core-contracts/contracts/proxy/UUPSProxyWithOwner.sol";

contract Proxy is UUPSProxyWithOwner {
  // solhint-disable-next-line no-empty-blocks
  constructor(address firstImplementation, address initialOwner) UUPSProxyWithOwner(firstImplementation, initialOwner) {}
}