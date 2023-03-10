// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import { SetAssignable, AssignableData, NotTokenOwner, NotAssigned } from "./SetAssignable.sol";
import { OwnerEnumerable } from "./OwnerEnumerable.sol";
import "./Phaseable.sol";


abstract contract Assignable is Phaseable {  
    using SetAssignable for AssignableData;
    AssignableData assignables;
    
    function assignColdStorage(uint256 tokenId) external {        
        if (msg.sender != ownerOf(tokenId)) {
            revert NotTokenOwner();
        }
        assignables.addAssignment(msg.sender,tokenId);
    }
    
    function revokeColdStorage(uint256 tokenId) external {        
        if (assignables.findAssignment(msg.sender) != tokenId) {
            revert NotAssigned(msg.sender);
        }
        assignables.removeAssignment(msg.sender);
    }   
    
    function revokeAssignments(uint256 tokenId) external {        
        if (msg.sender != ownerOf(tokenId)) {
            revert NotTokenOwner();
        }
        assignables.revokeAll(tokenId);
    }    
    
    function findAssignments(uint256 tokenId) external view returns (address[] memory){        
        return assignables.findAssignees(tokenId);
    }        

    function balanceOf(address seekingContract, address owner) external view returns (uint256) {        
        uint256 guardianBalance = balanceOf(owner);
        if (guardianBalance > 0) {
            uint256[] memory guardians = tokensOwnedBy(owner);
            return assignables.iterateGuardiansBalance(guardians, seekingContract, 0);
        }
        return 0;
    }     
}