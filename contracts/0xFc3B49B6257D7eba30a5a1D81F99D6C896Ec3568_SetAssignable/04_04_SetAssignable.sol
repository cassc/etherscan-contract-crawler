// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

struct AssignableData { 
    mapping(uint256 => address[]) assignments;

    mapping(address => mapping(uint256 => uint256)) assignmentIndex; 

    mapping(address => uint256) assigned;
}    

error AlreadyAssigned(uint256 tokenId);
error NotAssigned(address to);
error NotTokenOwner();

interface Supportable {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner, uint256 tokenId) external view returns (uint256);
}

library SetAssignable {

    function findAssignees(AssignableData storage self, uint256 tokenId) public view returns (address[] memory) {
        return self.assignments[tokenId];
    }

    function revokeAll(AssignableData storage self, uint256 tokenId) public {        
        for (uint256 iterator = 0; iterator < self.assignments[tokenId].length; iterator++) {
            address target = self.assignments[tokenId][iterator];
            delete self.assignmentIndex[target][tokenId];
            delete self.assigned[target];
        }
        while ( self.assignments[tokenId].length > 0) {
            self.assignments[tokenId].pop();
        }        
    }

    function iterateGuardiansBalance(AssignableData storage self, uint256[] memory guardians, address seeking, uint256 tokenId) public view returns (uint256)  {
        uint256 balance = 0;
        for (uint256 iterator = 0; iterator < guardians.length; iterator++) {
            uint256 guardian = guardians[iterator];
            balance += iterateAssignmentsBalance(self,guardian,seeking,tokenId);
        }
        return balance;
    }

    function iterateAssignmentsBalance(AssignableData storage self, uint256 guardian, address seeking, uint256 tokenId) public view returns (uint256)  {
        uint256 balance = 0;
        for (uint256 iterator = 0; iterator < self.assignments[guardian].length; iterator++) {
            address assignment =self.assignments[guardian][iterator];
            Supportable supporting = Supportable(seeking);
            if (supporting.supportsInterface(type(IERC721).interfaceId)) {
                balance += supporting.balanceOf(assignment); 
            }            
            if (supporting.supportsInterface(type(IERC1155).interfaceId)) {
                balance += supporting.balanceOf(assignment, tokenId); 
            }               
        }       
        return balance; 
    } 

    function addAssignment(AssignableData storage self, address to, uint256 tokenId) public {
        uint256 assigned = findAssignment(self, to);
        if (assigned > 0) {
            revert AlreadyAssigned(assigned);
        }
        
        self.assignments[tokenId].push(to);     
        uint256 length = self.assignments[tokenId].length;
        self.assignmentIndex[to][tokenId] = length-1;
        self.assigned[to] = tokenId;
    }    

    function removeAssignment(AssignableData storage self, address to) public {
        uint256 assigned = findAssignment(self, to);
        if (assigned > 0) {
            uint256 existingAddressIndex = self.assignmentIndex[to][assigned];
            uint256 lastAssignmentIndex = self.assignments[assigned].length-1;
            
            if (existingAddressIndex != lastAssignmentIndex) {
                address lastAssignment = self.assignments[assigned][lastAssignmentIndex];
                self.assignments[assigned][existingAddressIndex] = lastAssignment; 
                self.assignmentIndex[lastAssignment][assigned] = existingAddressIndex;
            }
            delete self.assignmentIndex[to][assigned];
            self.assignments[assigned].pop();
        } else {
            revert NotAssigned(to);
        }
    }

    function findAssignment(AssignableData storage self, address to) public view returns (uint256) {
        return self.assigned[to];
    }     
}