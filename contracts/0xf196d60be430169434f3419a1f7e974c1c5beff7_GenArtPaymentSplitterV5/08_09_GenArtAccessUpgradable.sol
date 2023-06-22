// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @dev This implements access control for owner and admins
 */
abstract contract GenArtAccessUpgradable is OwnableUpgradeable {
    mapping(address => bool) public admins;
    address public genArtAdmin;

    function __GenArtAccessUpgradable_init(address owner, address admin)
        internal
        onlyInitializing
    {
        __GenArtAccessUpgradable_init_unchained(owner, admin);
    }

    function __GenArtAccessUpgradable_init_unchained(
        address owner,
        address admin
    ) internal onlyInitializing {
        _transferOwnership(owner);
        genArtAdmin = owner;
        admins[admin] = true;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        address sender = _msgSender();
        require(
            owner() == sender || admins[sender],
            "GenArtAccessUpgradable: caller is not the owner nor admin"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the ECLIPSE admin.
     */
    modifier onlyGenArtAdmin() {
        address sender = _msgSender();
        require(
            genArtAdmin == sender,
            "GenArtAccessUpgradable: caller is not eclipse admin"
        );
        _;
    }

    function setGenArtAdmin(address admin) public onlyGenArtAdmin {
        genArtAdmin = admin;
    }

    function setAdminAccess(address admin, bool access) public onlyGenArtAdmin {
        admins[admin] = access;
    }
}