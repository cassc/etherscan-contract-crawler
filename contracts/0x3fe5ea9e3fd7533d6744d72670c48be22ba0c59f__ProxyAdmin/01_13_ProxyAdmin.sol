// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract _ProxyAdmin is ProxyAdmin {
    constructor() ProxyAdmin() {}
}