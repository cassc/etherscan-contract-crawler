// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract AdminableUpgradeable is Initializable, OwnableUpgradeable, AccessControlUpgradeable {
    function initialize() public virtual initializer {
        OwnableUpgradeable.__Ownable_init();
        AccessControlUpgradeable.__AccessControl_init();
        
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyOwnerOrAdmin() {
        require(
            owner() == _msgSender() ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Adminable: caller is not the owner or admin"
        );
        _;
    }
}