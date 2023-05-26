// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract OwnablePausable is OwnableUpgradeable, PausableUpgradeable {
    // solhint-disable-next-line func-name-mixedcase
    function __OwnablePausable_init(address owner_) internal onlyInitializing {
        __OwnablePausable_init_unchained(owner_);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __OwnablePausable_init_unchained(address owner_) internal onlyInitializing {
        require(owner_ != address(0), "Owner is zero address");

        __Ownable_init();
        __Pausable_init();

        _transferOwnership(owner_);
    }

    /**
     * @notice Pauses crowdsale - disables all transfer operations
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses crowdsale - enables all transfer operations
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}