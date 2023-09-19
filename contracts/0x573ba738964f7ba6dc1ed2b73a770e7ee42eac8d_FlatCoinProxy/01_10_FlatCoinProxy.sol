// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
 * @dev Implementation of the Flat Coin.
 *
 */
contract FlatCoinProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, admin_, _data) {}
}