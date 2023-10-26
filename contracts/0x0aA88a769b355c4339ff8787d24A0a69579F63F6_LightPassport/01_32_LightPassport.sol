// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ColorPassportUpgradable.sol";
import "./PassportRegistry.sol";
import "./PassportUpgradable.sol";


contract LightPassport is Initializable, ColorPassportUpgradable {

    function initialize(
        address defaultAdmin_,
        string[] memory levels_,
        uint256 maxSupply_,
        PassportUpgradable specialPassport_,
        PassportRegistry passportRegistry_) initializer public {
        __ColorPassport_init(defaultAdmin_, levels_, maxSupply_, "Standard Passport", "QTLPASS", specialPassport_, passportRegistry_);
    }
}