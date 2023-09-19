// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol"; 
import "../openzeppelin-contracts/contracts/metatx/ERC2771Context.sol";

contract ERC2771ProxyAdmin is ERC2771Context, ProxyAdmin {
  constructor(
    address forwarder,
    address admin
  ) ERC2771Context(forwarder) ProxyAdmin() {
    transferOwnership(admin);
  }

  function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
    return super._msgSender();
  }

  function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
    return super._msgData();
  }
}