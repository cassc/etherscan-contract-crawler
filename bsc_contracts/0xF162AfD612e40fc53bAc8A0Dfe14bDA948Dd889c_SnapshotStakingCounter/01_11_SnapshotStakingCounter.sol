// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Adminable.sol";
import "./staking/IStakingLockable.sol";

// This contract allows to get
contract SnapshotStakingCounter is Adminable {
    struct Target {
        // Supports 12 decimals (for LP). 1x = 1 * 1e12
        uint256 multiplier;
        address target;
    }
    
    mapping (uint8 => Target[]) public targets;
    
    function getTargets(uint8 id) public view returns (Target[] memory) {
        return targets[id];
    }
    
    function getVotingPower(uint8 id, address account) public view returns (uint256) {
        uint256 balance = 0;
        for (uint8 i = 0; i < targets[id].length; i++) {
            balance += targets[id][i].multiplier * IStakingLockable(targets[id][i].target).getLockedAmount(account) / 1e12;
        }
        
        return balance;
    }
    
    function setTarget(uint8 id, address target, uint256 multiplier) public onlyOwnerOrAdmin {
        if (multiplier == 0) {
            for (uint8 i = 0; i < targets[id].length; i++) {
                if (targets[id][i].target == target) {
                    targets[id][i] = targets[id][targets[id].length - 1];
                    targets[id].pop();
                    return;
                }
            }
        }
        for (uint8 i = 0; i < targets[id].length; i++) {
            if (targets[id][i].target == target) {
                targets[id][i].multiplier = multiplier;
                return;
            }
        }
        targets[id].push(Target(multiplier, target));
    }
}