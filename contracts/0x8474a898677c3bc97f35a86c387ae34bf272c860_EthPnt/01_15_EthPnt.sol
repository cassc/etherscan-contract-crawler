//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20PresetFixedSupplyUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetFixedSupplyUpgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";

contract EthPnt is ERC20PresetFixedSupplyUpgradeable, ERC20PermitUpgradeable {
    function initialize(address _daoTreasury) external initializer {
        __ERC20PresetFixedSupply_init("pNetwork Token", "ethPNT", 8800000000000000000000000, _daoTreasury);
        __ERC20Permit_init("pNetwork Token");
    }
}