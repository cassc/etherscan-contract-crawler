// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Proxied} from "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import {Initializable, OFTUpgradeable} from "./contracts-upgradeable/token/oft/OFTUpgradeable.sol";

contract Valeria is Initializable, OFTUpgradeable, Proxied {
    function initialize(
        uint256 _initialSupply,
        address _lzEndpoint
    ) public initializer {
        __OFTUpgradeable_init("Valeria", "VAL", _lzEndpoint);
        _mint(_msgSender(), _initialSupply);
    }
}