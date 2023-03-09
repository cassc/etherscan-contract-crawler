//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import { Ownable } from "./Ownable.sol";

/** 
* @notice Base contract which allows owner to set an admin to select the pauser, 
* blacklister, and rescuer. Only the contract owner can modify the admin.
*/

abstract contract PermissionAdmin is Ownable{

    address private _permissionAdmin;

    event permissionAdminChanged(address indexed admin);

    modifier onlyPermissionAdmin() {
        require(
            msg.sender == _permissionAdmin, 
            "caller not permission admin"
        );
        _;
    }

     /**
     * @notice Returns current rescuer
     * @return permissionAdmin's address
     */
    function getPermissionAdmin() external view returns (address) {
        return _permissionAdmin;
    }

     /**
     * @notice sets the current permission admin
     */
    function setPermissionAdmin(address _newAdmin) external onlyOwner {
        require(
            _newAdmin != address(0), 
            "No zero addr"
        );
        _permissionAdmin = _newAdmin;
        emit permissionAdminChanged(_permissionAdmin);
    }

}