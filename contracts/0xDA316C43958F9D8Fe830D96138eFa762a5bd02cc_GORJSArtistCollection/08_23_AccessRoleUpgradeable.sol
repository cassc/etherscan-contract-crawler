//SPDX-License-Identifier: UNLICENSED
// AUDIT: LCL-06 | UNLOCKED COMPILER VERSION
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract AccessRoleUpgradeable is Initializable, AccessControlUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    function __AccessRole_init(address account) internal onlyInitializing {
        __AccessRole_init_unchained(account);
    }

    function __AccessRole_init_unchained(address account) internal onlyInitializing {
        __AccessControl_init();
        // AUDIT: ARU-01 | CENTRALIZATION RELATED RISKS IN AccessRoleUpgradeable
        // dev: we set default admin as multi-sig public wallet.
        _setupRole(DEFAULT_ADMIN_ROLE, account);
        _setupRole(ADMIN_ROLE, account);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    modifier onlyAdmin {
        _checkRole(ADMIN_ROLE);
        _;
    }

    function grantAdminRole(address account) public {
        grantRole(ADMIN_ROLE, account);
    }

    function revokeAdminRole(address account) public {
        revokeRole(ADMIN_ROLE, account);
    }
}