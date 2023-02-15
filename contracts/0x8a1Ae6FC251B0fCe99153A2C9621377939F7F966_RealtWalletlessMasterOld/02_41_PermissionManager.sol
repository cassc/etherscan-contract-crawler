// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

abstract contract PermissionManager is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    modifier moderatorOrAdmin() {
        require(
            hasRole(MODERATOR_ROLE, _msgSender()) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "RWM01"
        );
        _;
    }

    /**
     * @dev Initializes the contract
     */
    function __PermissionManager_init(
        address admin_,
        address moderator_,
        address operator_
    ) internal onlyInitializing {
        __PermissionManager_init_unchained(admin_, moderator_, operator_);
    }

    function __PermissionManager_init_unchained(
        address admin_,
        address moderator_,
        address operator_
    ) internal onlyInitializing {
        __AccessControl_init();
        __Pausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(MODERATOR_ROLE, moderator_);
        _grantRole(OPERATOR_ROLE, operator_);
    }

    // ADD -- REMOVE : Roles
    function addOperator(address newOperator)
        external
        onlyRole(MODERATOR_ROLE)
    {
        _grantRole(OPERATOR_ROLE, newOperator);
    }

    function removeOperator(address oldOperator)
        external
        onlyRole(MODERATOR_ROLE)
    {
        _revokeRole(OPERATOR_ROLE, oldOperator);
    }

    function addModerator(address newModerator)
        external
        onlyRole(MODERATOR_ROLE)
    {
        _grantRole(MODERATOR_ROLE, newModerator);
    }

    function removeModerator(address oldModerator)
        external
        onlyRole(MODERATOR_ROLE)
    {
        _revokeRole(MODERATOR_ROLE, oldModerator);
    }

    // --------------------------------------
    // PAUSE -- UNPAUSE
    function pause() external moderatorOrAdmin {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}