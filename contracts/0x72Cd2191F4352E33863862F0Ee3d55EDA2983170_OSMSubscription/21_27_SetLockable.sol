// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { InvalidOwner } from "./SetOwnerEnumerable.sol";
struct LockableData { 

    mapping(address => uint256) lockableStatusIndex; 

    mapping(address => LockableStatus) lockableStatus;  
} 


struct LockableStatus {
    bool isLocked;
    uint256 lockedAt;
    address custodian;
    uint256 balance;
    address[] approvedAll;
    bool exists;
}

uint64 constant MAX_INT = 2**64 - 1;

error OnlyCustodianCanLock();

error OnlyOwnerCanSetCustodian();

error WalletLockedByOwner();


library SetLockable {           

    function lockWallet(LockableData storage self, address holder) public {
        LockableStatus storage status = self.lockableStatus[holder];    
        if (msg.sender != status.custodian) {
            revert OnlyCustodianCanLock();
        }       
        status.isLocked = true;
        status.lockedAt = block.timestamp;
    }

    function unlockWallet(LockableData storage self, address holder) public {        
        LockableStatus storage status = self.lockableStatus[holder];
        if (msg.sender != status.custodian) {
            revert OnlyCustodianCanLock();
        }                   
        
        status.isLocked = false;
        status.lockedAt = MAX_INT;
    }

    function setCustodian(LockableData storage self, address custodianAddress,  address holder) public {
        if (msg.sender != holder) {
            revert OnlyOwnerCanSetCustodian();
        }    
        LockableStatus storage status = self.lockableStatus[holder];
        status.custodian = custodianAddress;
    }

    function findCustodian(LockableData storage self, address wallet) public view returns (address) {
        return self.lockableStatus[wallet].custodian;
    }

    function forceUnlock(LockableData storage self, address owner) public {        
        LockableStatus storage status = self.lockableStatus[owner];
        status.isLocked = false;
        status.lockedAt = MAX_INT;
    }
            
}