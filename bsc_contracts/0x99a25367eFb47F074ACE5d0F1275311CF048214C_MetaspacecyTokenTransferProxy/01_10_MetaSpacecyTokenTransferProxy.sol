// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./proxy/TokenTransferProxy.sol";

contract MetaspacecyTokenTransferProxy is TokenTransferProxy {
  string public constant name = "Metaspacecy Token Transfer Proxy";

  constructor (ProxyRegistry registryAddress) {
    registry = registryAddress;
  }
}