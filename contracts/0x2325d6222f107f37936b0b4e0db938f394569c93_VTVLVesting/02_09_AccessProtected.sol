//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;
// Note: using solidity 0.8, SafeMath not needed any more

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AccessProtected is Context {
    mapping(address => bool) private _admins; // user address => admin? mapping

    event AdminAccessSet(address indexed _admin, bool _enabled);

    constructor() {
        _admins[_msgSender()] = true;
        emit AdminAccessSet(_msgSender(), true);
    }

    /**
     * Throws if called by any account that isn't an admin or an owner.
     */
    modifier onlyAdmin() {
        require(_admins[_msgSender()], "ADMIN_ACCESS_REQUIRED");
        _;
    }

    function isAdmin(address _addressToCheck) external view returns (bool) {
        return _admins[_addressToCheck];
    }

    /**
     * @notice Set/unset Admin Access for a given address.
     *
     * @param admin - Address of the new admin (or the one to be removed)
     * @param isEnabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool isEnabled) public onlyAdmin {
        require(admin != address(0), "INVALID_ADDRESS");
        _admins[admin] = isEnabled;
        emit AdminAccessSet(admin, isEnabled);
    }
}