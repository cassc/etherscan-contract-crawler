// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./NiftyPermissions.sol";

abstract contract Ownable is NiftyPermissions {        
    
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);        

    function owner() public view virtual returns (address) {
        return _owner;
    }
        
    function transferOwnership(address newOwner) public virtual {
        _requireOnlyValidSender();                
        address oldOwner = _owner;        
        _owner = newOwner;        
        emit OwnershipTransferred(oldOwner, newOwner);        
    }
}