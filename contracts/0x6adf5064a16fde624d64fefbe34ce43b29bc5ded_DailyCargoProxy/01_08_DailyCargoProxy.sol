// SPDX-License-Identifier: Unliscensed

pragma solidity 0.8.17;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DailyCargoProxy is ERC1967Proxy {
  constructor(address impl, bytes memory data) ERC1967Proxy(impl, data) {}
}