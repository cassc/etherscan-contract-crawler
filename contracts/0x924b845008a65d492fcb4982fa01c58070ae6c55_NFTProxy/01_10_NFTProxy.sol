// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract NFTProxy is TransparentUpgradeableProxy {
    constructor(
        address implementation_,
        address proxyAdmin_
    ) TransparentUpgradeableProxy(implementation_, proxyAdmin_, bytes("")) {}
}