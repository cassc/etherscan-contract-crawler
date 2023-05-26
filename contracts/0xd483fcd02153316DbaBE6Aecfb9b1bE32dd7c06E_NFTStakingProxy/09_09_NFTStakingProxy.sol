//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract NFTStakingProxy is TransparentUpgradeableProxy {

    constructor(address _logic,address _admin) TransparentUpgradeableProxy(_logic,_admin, "") {
    }
}