// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./Nameable.sol";
import { TokenNonOwner } from "./SetOwnerEnumerable.sol";
import { OwnerEnumerable } from "./OwnerEnumerable.sol";
import { SetApprovable, ApprovableData, TokenNonExistent } from "./SetApprovable.sol";

abstract contract Approvable is OwnerEnumerable {  
    using SetApprovable for ApprovableData; 
    ApprovableData approvable;

    function _checkTokenOwner(uint256 tokenId) internal view virtual {
        if (ownerOf(tokenId) != msg.sender) {
            revert TokenNonOwner(msg.sender, tokenId);
        }
    }    
 
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return approvable.isApprovedForAll(owner,operator);
    }  

    function approve(address to, uint256 tokenId) public virtual override {  
        _checkTokenOwner(tokenId);      
        approvable.approveForToken(to, tokenId);
        emit Approval(ownerOf(tokenId), to, tokenId);        
    }  

    function setApprovalForAll(address operator, bool approved) public virtual override {   
        approved ? approvable.approveForContract(operator): approvable.revokeApprovalForContract(operator, msg.sender);
    }       

    function validateApprovedOrOwner(address spender, uint256 tokenId) internal view {        
        if (!(spender == ownerOf(tokenId) || isApprovedForAll(ownerOf(tokenId), spender) || approvable.getApproved(tokenId) == spender)) {
            revert TokenNonOwner(spender, tokenId);
        }
    }  

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        requireMinted(tokenId);
        return approvable.tokens[tokenId].approval;
    }       

    function revokeTokenApproval(uint256 tokenId) internal {
        approvable.revokeTokenApproval(tokenId);
    }

    function revokeApprovals(address holder) internal {
        approvable.revokeApprovals(holder,tokensOwnedBy(holder));                    
    }


    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function requireMinted(uint256 tokenId) internal view virtual {
        if (!exists(tokenId)) {
            revert TokenNonExistent(tokenId);
        }
    }    

    function exists(uint256 tokenId) internal view virtual returns (bool) {
        return approvable.tokens[tokenId].exists;
    }      
}