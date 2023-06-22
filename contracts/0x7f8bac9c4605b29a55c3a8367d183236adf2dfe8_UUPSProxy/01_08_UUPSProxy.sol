// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

// Import OZ Proxy contracts
import {ERC1967Proxy} from "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

contract UUPSProxy is ERC1967Proxy {
    constructor(address _implementation, bytes memory _data) ERC1967Proxy(_implementation, _data) {}
}