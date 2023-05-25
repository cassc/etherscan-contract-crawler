/*
 * SPDX-License-Identifier: UNLICENSED
 * Copyright © 2022 Blocksquare d.o.o.
 */

pragma solidity 0.8.14;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/// @title Blocksquare Property Token Staking Proxy
/// @author David Šenica
contract BSPTStakingProxy is TransparentUpgradeableProxy {
    constructor(
        address logic,
        address admin,
        bytes memory data
    ) TransparentUpgradeableProxy(logic, admin, data) {}
}