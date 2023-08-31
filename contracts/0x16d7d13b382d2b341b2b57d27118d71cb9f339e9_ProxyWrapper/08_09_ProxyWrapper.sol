// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "ERC1967Proxy.sol";

// Needed for Etherscan verification
contract ProxyWrapper is ERC1967Proxy {
    constructor(address _logic, bytes memory _data) payable ERC1967Proxy(_logic, _data) {}
}
