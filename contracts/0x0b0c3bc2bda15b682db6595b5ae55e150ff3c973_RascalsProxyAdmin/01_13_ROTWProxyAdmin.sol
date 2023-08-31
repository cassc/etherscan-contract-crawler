// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract RascalsProxyAdmin is ProxyAdmin {
    constructor(address _multiSig) {
        _transferOwnership(_multiSig);
    }
}