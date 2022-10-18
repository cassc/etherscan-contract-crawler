// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract PermissionsUpgradeable is Initializable, AccessControlUpgradeable {
    bytes32 public constant GOVERN_ROLE = keccak256("GOVERN_ROLE");

    function Permissions_init(address _governor) public initializer {
        __AccessControl_init();
        _setupGovernor(_governor);
        _setRoleAdmin(GOVERN_ROLE, GOVERN_ROLE);
    }

    modifier onlyGovernor() {
        require(
            isGovernor(msg.sender),
            "Permissions::onlyGovernor: Caller is not a governor"
        );
        _;
    }

    function createRole(bytes32 role, bytes32 adminRole) external onlyGovernor {
        _setRoleAdmin(role, adminRole);
    }

    function grantGovernor(address governor) external onlyGovernor {
        grantRole(GOVERN_ROLE, governor);
    }

    function revokeGovernor(address governor) external onlyGovernor {
        revokeRole(GOVERN_ROLE, governor);
    }

    function isGovernor(address _address) public view virtual returns (bool) {
        return hasRole(GOVERN_ROLE, _address);
    }

    function _setupGovernor(address governor) internal {
        _setupRole(GOVERN_ROLE, governor);
    }
}