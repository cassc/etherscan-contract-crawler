// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
* @dev Contract module that provides an access control mechanism using
* modules {AccessControl} and {Ownable}.
* There are 4 roles: owner, default admin, admin and minter. For owner
* and default admin rights see {AccessControl} and {Ownable}
* documentation.
*/
abstract contract Access is AccessControl, Ownable {
    /**
    * @dev See {AccessControl}.
    */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /**
    * @dev Modifier that checks if caller has minter role. Reverts with
    * `Access: caller is not a minter`
    */
    modifier onlyMinter(){
        require(hasMinterRole(msg.sender), "Access: caller is not a minter");
        _;
    }

    /**
    * @dev Modifier that checks if caller has admin role. Reverts with
    * `Access: caller is not an admin`
    */
    modifier onlyAdmin(){
        require(hasAdminRole(msg.sender), "Access: caller is not an admin");
        _;
    }

    /**
    * @dev Initializes the contract setting the deployer as the owner.
    * Also granting admin role to the owner.
    */
    constructor () Ownable() {
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
    * @dev Returns `true` if `_address` has been granted admin role.
    */
    function hasAdminRole (address _address) public view returns (bool) {
        return hasRole(ADMIN_ROLE, _address);
    }

    /**
    * @dev Returns `true` if `_address` has been granted minter role.
    */
    function hasMinterRole (address _address) public view returns (bool) {
        return hasRole(MINTER_ROLE, _address);
    }
    
    /**
    *   @dev See {IERC165-supportsInterface}.
    */
    function supportsInterface(bytes4 _interfaceId) public view virtual override (AccessControl) returns (bool){
        return super.supportsInterface(_interfaceId);
    }

    /**
    * @dev Grants minter role to `_address`. Only an admin can use this functionality.
    */
    function grantMinterRole (address _address) public onlyAdmin{
        _grantRole(MINTER_ROLE, _address);
    }

    /**
    * @dev Revokes minter role from `_address`. Only admins can use this functionality.
    */
    function revokeMinterRole (address _address) public onlyAdmin {
        _revokeRole(MINTER_ROLE, _address);
    }

    /**
    * @dev Revokes admin role from `_address`. Only the owner can use this functionality.
    */
    function revokeAdminRole (address _address) public onlyOwner {
        _revokeRole(ADMIN_ROLE, _address);
    }

    /**
    * @dev Grants admin role to `_address`. Only the owner can use this functionality.
    */
    function grantAdminRole (address _address) public onlyOwner {
        _grantRole(ADMIN_ROLE, _address);
    }
}