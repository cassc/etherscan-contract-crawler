// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./Approvable.sol";
import { SetLockable, LockableStatus,  LockableData, WalletLockedByOwner } from "./SetLockable.sol";

abstract contract Lockable is Approvable {    
    using SetLockable for LockableData; 
    LockableData lockable;

    bool soulBound = false;

    function custodianOf(uint256 id)
        public
        view
        returns (address)
    {             
        return lockable.findCustodian(ownerOf(id));
    }     

    function lockWallet(uint256 id) public {           
        revokeApprovals(ownerOf(id));
        lockable.lockWallet(ownerOf(id));
    }

    function unlockWallet(uint256 id) public {              
        lockable.unlockWallet(ownerOf(id));
    }    

    function _forceUnlock(uint256 id) internal {  
        lockable.forceUnlock(ownerOf(id));
    }    

    function setCustodian(uint256 id, address custodianAddress) public {       
        lockable.setCustodian(custodianAddress,ownerOf(id));
    }


    function isLocked(uint256 id) public view returns (bool) {  
        if (enumerationExists(id)) {
            return lockable.lockableStatus[ownerOf(id)].isLocked || soulBound;
        }
        return soulBound;
    } 

    function lockedSince(uint256 id) public view returns (uint256) {     
        return lockable.lockableStatus[ownerOf(id)].lockedAt;
    }     

    function validateLock(uint256 tokenId) internal view {
        if (isLocked(tokenId)) {
            revert WalletLockedByOwner();
        }
    }

    function soulBind() internal {
        soulBound = true;
    }
    
    function releaseSoul() internal {
        soulBound = false;
    }    
}