// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract UpgradeableBase is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
     constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function init() internal onlyInitializing  {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    } 
}