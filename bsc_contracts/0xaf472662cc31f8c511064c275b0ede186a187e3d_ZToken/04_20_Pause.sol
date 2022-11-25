// SPDX-License-Identifier: PRIVATE
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./Roles.sol";

abstract contract Pause is PausableUpgradeable, Roles {
    function initialize() public virtual override initializer {
        __Pausable_init_unchained();

        Roles.initialize();
    }

    function pause() external onlyAdmin {
        if (!paused()) {
            _pause();
        }
    }

    function unpause() external onlyAdmin {
        if (paused()) {
            _unpause();
        }
    }
}