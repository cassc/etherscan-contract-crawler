// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

// We are using the standard openzeppelin contract. This is needed to make hardhat compile
// this contract as well.
// solhint-disable-next-line no-empty-blocks
contract BridgeProxyAdmin is ProxyAdmin {

}