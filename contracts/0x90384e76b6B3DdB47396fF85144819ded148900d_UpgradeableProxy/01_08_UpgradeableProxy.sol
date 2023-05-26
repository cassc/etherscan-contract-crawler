// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol';

// needed to be able to use the proxy for verification
contract UpgradeableProxy is ERC1967Proxy {
  // solhint-disable-next-line no-empty-blocks
  constructor(address _logic, bytes memory _data) payable ERC1967Proxy(_logic, _data) {}
}