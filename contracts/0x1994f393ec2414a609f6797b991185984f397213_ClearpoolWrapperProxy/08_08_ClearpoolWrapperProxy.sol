// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ClearpoolWrapperProxy is ERC1967Proxy {
  constructor(address _logic, bytes memory _data) ERC1967Proxy(_logic, _data) {}
}