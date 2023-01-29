// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title Base contract which can be upgraded by Governance and requires user authorization for the upgrade
 */
abstract contract BaseGovernanceWithUserUpgradable is Initializable, ContextUpgradeable, UUPSUpgradeable, AccessControlUpgradeable {

    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant UPGRADE_MANAGER_ROLE = keccak256("UPGRADE_MANAGER_ROLE");

    address private _proposedUpgrade;

    function getImplementation() public view returns(address) {
        return _getImplementation();
    }

    function __BaseGovernanceWithUser_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
        __AccessControl_init_unchained();
        __BaseGovernanceWithUser_init_unchained();
    }

    function __BaseGovernanceWithUser_init_unchained() internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());   // Grant DEFAULT_ADMIN to creator. Other role management scan be performed elswhere
        _setupRole(GOVERNANCE_ROLE, _msgSender());
        _setupRole(UPGRADE_MANAGER_ROLE, _msgSender());
        _setRoleAdmin(UPGRADE_MANAGER_ROLE, GOVERNANCE_ROLE);
    }

    function _authorizeUpgrade(address /*newImplementation*/) internal virtual override {
        require(
            hasRole(GOVERNANCE_ROLE, msg.sender) || hasRole(UPGRADE_MANAGER_ROLE, msg.sender), 
            "ERROR: Address not authorized"
        );
    }


    function proposeNewImplementation(address implementationAddress) external onlyRole(GOVERNANCE_ROLE) {
        _proposedUpgrade = implementationAddress; 
    }
    
    uint256[50] private __gap;
}