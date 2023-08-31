// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @dev This implements access control for owner and admins
 */
abstract contract EclipseAccessUpgradable is OwnableUpgradeable {
    mapping(address => bool) public admins;
    address public eclipseAdmin;
    address public contractAdmin;

    function __EclipseAccessUpgradable_init(
        address owner,
        address admin,
        address contractAdmin_
    ) internal onlyInitializing {
        __EclipseAccessUpgradable_init_unchained(owner, admin, contractAdmin_);
    }

    function __EclipseAccessUpgradable_init_unchained(
        address owner,
        address admin,
        address contractAdmin_
    ) internal onlyInitializing {
        _transferOwnership(owner);
        eclipseAdmin = admin;
        contractAdmin = contractAdmin_;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        address sender = _msgSender();
        require(
            owner() == sender || admins[sender],
            "EclipseAccessUpgradable: caller is not the owner nor admin"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the ECLIPSE admin.
     */
    modifier onlyEclipseAdmin() {
        address sender = _msgSender();
        require(
            eclipseAdmin == sender,
            "EclipseAccessUpgradable: caller is not eclipse admin"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the ECLIPSE admin.
     */
    modifier onlyContractAdmin() {
        address sender = _msgSender();
        require(
            contractAdmin == sender,
            "EclipseAccessUpgradable: caller is not contract admin"
        );
        _;
    }

    function setEclipseAdmin(address admin) public onlyEclipseAdmin {
        eclipseAdmin = admin;
    }

    function setAdminAccess(address admin, bool access) public onlyAdmin {
        admins[admin] = access;
    }

    function setContractAdmin(address contractAdmin_) public onlyContractAdmin {
        contractAdmin = contractAdmin_;
    }
}