// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This implements access control for owner and admins
 */
abstract contract EclipseAccess is Ownable {
    mapping(address => bool) public admins;
    address public eclipseAdmin;

    constructor() Ownable() {
        eclipseAdmin = _msgSender();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        address sender = _msgSender();
        require(
            owner() == sender || admins[sender],
            "EclipseAccess: caller is not the owner nor admin"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the Eclipse admin.
     */
    modifier onlyEclipseAdmin() {
        address sender = _msgSender();
        require(
            eclipseAdmin == sender,
            "EclipseAccess: caller is not eclipse admin"
        );
        _;
    }

    function setEclipseAdmin(address admin) public onlyEclipseAdmin {
        eclipseAdmin = admin;
    }

    function setAdminAccess(
        address admin,
        bool access
    ) public onlyEclipseAdmin {
        admins[admin] = access;
    }
}