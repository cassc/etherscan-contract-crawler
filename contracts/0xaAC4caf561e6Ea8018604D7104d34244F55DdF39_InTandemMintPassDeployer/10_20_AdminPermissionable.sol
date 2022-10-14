//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


abstract contract AdminPermissionable is AccessControl, Ownable {
    error NotAdminOrOwner();
    error NotAdminOrModerator();
    error ZeroAdminAddress();
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    modifier onlyAdmin() {
        if (!(owner() == _msgSender() || hasRole(DEFAULT_ADMIN_ROLE, _msgSender())))
            revert NotAdminOrOwner();
        _;
    }

    modifier onlyAdminOrModerator() {
        if (!(owner() == _msgSender() ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
            hasRole(MODERATOR_ROLE, _msgSender())))
            revert NotAdminOrModerator();
        _;
    }

    modifier checkAdminAddress(address _address) {
        if (_address == address(0)){
            revert ZeroAdminAddress();
        }
        _;
    }

    function setAdminPermission(address _address) external onlyAdmin checkAdminAddress(_address) {
        _grantRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function removeAdminPermission(address _address) external onlyAdmin checkAdminAddress(_address) {
        _revokeRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function isAdmin() internal view returns(uint8){
        if (owner() == _msgSender() || hasRole(DEFAULT_ADMIN_ROLE, _msgSender())){
            return 1;
        }
        return 0;
    }

}