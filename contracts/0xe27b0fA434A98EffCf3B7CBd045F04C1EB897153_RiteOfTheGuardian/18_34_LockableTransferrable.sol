// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Lockable.sol";
import { LockableStatus,InvalidTransferRecipient,ContractIsNot721Receiver } from "./SetLockable.sol";



abstract contract LockableTransferrable is Lockable {  
    using Address for address;

    function approve(address to, uint256 tokenId) public virtual override {  
        validateLock(tokenId);
        super.approve(to,tokenId);      
    }  

    function setApprovalForAll(address operator, bool approved) public virtual override {           
        validateLock(tokensOwnedBy(msg.sender)[0]);
        super.setApprovalForAll(operator,approved);     
    }        

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {        
        validateApprovedOrOwner(msg.sender, tokenId);
        validateLock(tokenId);
        _transfer(from,to,tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
                
        if(to == address(0)) {
            revert InvalidTransferRecipient();
        }

        revokeTokenApproval(tokenId);   

        if (enumerationExists(tokenId)) {
            swapOwner(from,to,tokenId);
        }
        
        packedTransferFrom(from, to, tokenId);

        completeTransfer(from,to,tokenId);    
    }   

    function completeTransfer(
        address from,
        address to,
        uint256 tokenId) internal {

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }    

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        validateApprovedOrOwner(msg.sender, tokenId);
        validateLock(tokenId);
        _safeTransfer(from, to, tokenId, data);
    }     

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert ContractIsNot721Receiver();
        }        
        _transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert InvalidTransferRecipient();
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }    

}