// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract Pausable is PausableUpgradeable, OwnableUpgradeable {
    function __PausableUpgradeable_init() internal onlyInitializing {
        __Ownable_init();
        __Pausable_init_unchained();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}