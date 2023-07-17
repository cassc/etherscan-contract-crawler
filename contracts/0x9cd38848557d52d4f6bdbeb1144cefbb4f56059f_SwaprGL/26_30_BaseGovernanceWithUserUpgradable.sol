// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title Base contract which can be upgraded by Governance and requires user authorization for the upgrade
 * TODO: implement user permission for upgrade
 */
abstract contract BaseGovernanceWithUserUpgradable is
    Initializable,
    ContextUpgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant UPGRADE_MANAGER_ROLE = keccak256("UPGRADE_MANAGER_ROLE");

    address private _proposedUpgrade;

    function _onlyAdmin() internal view {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ONLY_ADMIN");
    }

    function __BaseGovernanceWithUser_init(address governer) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
        __AccessControl_init_unchained();
        __BaseGovernanceWithUser_init_unchained(governer);
    }

    function __BaseGovernanceWithUser_init_unchained(address governer) internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); // Grant DEFAULT_ADMIN to creator. Other role management scan be performed elswhere
        _setupRole(GOVERNANCE_ROLE, governer);
        _setupRole(UPGRADE_MANAGER_ROLE, _msgSender());
    }

    /**
    * @dev See {IERC1967Upgradeable-upgrade}.
    * This function is only callable by a governance role, and should be used only for proxy version upgrades
    * @param newImplementation Address of the new implementation.
    */
    function _authorizeUpgrade(address newImplementation) internal virtual override {
        require(
            hasRole(GOVERNANCE_ROLE, msg.sender) ||
                (hasRole(UPGRADE_MANAGER_ROLE, msg.sender) && (newImplementation == _proposedUpgrade)),
            "UPGR_NT_AUTH"
        );
    }

    /**
    * @dev Returns the current implementation address.
    */
    function getImplementation() public view returns (address) {
        return _getImplementation();
    }

    /**
    * @dev See {IERC1967Upgradeable-upgrade}.
    * This function is only callable by a governance role, and should be used only for proxy version upgrades
    * @param implementationAddress Address of the new implementation.
    */
    function proposeNewImplementation(address implementationAddress) external payable onlyRole(GOVERNANCE_ROLE) {
        require(implementationAddress != address(0), "SET_ZERO_ADDR");
        _proposedUpgrade = implementationAddress;
    }

    uint256[50] private __gap;
}