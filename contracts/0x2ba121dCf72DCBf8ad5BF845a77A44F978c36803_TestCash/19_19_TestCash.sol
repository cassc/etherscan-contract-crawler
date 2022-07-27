// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";

contract TestCash is Initializable, ERC20PresetMinterPauserUpgradeable {

    constructor() {
        initialize("TestCash", "TC");
    }
}