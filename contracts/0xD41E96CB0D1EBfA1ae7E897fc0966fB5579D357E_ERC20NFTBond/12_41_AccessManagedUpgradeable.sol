// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Roles.sol";

abstract contract AccessManagedUpgradeable is Initializable {
    IAccessControl private _accessControl;

    event AccessManagerUpdated(address indexed newAddressManager);

    modifier onlyRole(bytes32 role) {
        require(_hasRole(role, msg.sender), "AccessManagedUpgradeable::Missing Role");
        _;
    }

    function __AccessManaged_init(address manager) internal initializer {
        _accessControl = IAccessControl(manager);
        emit AccessManagerUpdated(manager);
    }

    function setAccessManager(address newManager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _accessControl = IAccessControl(newManager);
        emit AccessManagerUpdated(newManager);
    }

    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        return _accessControl.hasRole(role, account);
    }

    uint256[49] private __gap;
}