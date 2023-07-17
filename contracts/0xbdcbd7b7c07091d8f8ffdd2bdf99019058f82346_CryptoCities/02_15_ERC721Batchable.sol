// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../base/OwnableRecoverable.sol";

// ERC721Batchable wraps multiple commonly used base contracts into a single contract
// 
// it includes:
//  ERC721 with Enumerable
//  contract ownership & recovery
//  contract pausing
//  treasury 
//  batching

abstract contract ERC721Batchable is ERC721Enumerable, Pausable, OwnableRecoverable 
{   
    // the treasure address that can make withdrawals from the contract balance
    address public treasury;

    constructor()  
    {
       
    }

    // used to stop a contract function from being reentrant-called 
    bool private _reentrancyLock = false;
    modifier reentrancyGuard {
        require(!_reentrancyLock, "ReentrancyGuard: reentrant call");
 
        _reentrancyLock = true;
        _;
        _reentrancyLock = false;
    }


    /// PAUSING

    // only the contract owner can pause and unpause
    // can't pause if already paused
    // can't unpause if already unpaused
    // disables minting, burning, transfers (including marketplace accepted offers)

    function pause() external virtual onlyOwner {        
        _pause();        
    }
    function unpause() external virtual onlyOwner {
        _unpause();
    }

    // this hook is called by _mint, _burn & _transfer 
    // it allows us to block these actions while the contract is paused
    // also prevent transfers to the contract address
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        require(to != address(this), "cant transfer to the contract address");
        
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "token transfer while contract paused");
    }


    /// TREASURY

    // can only be called by the contract owner
    // withdrawals can only be made to the treasury account

    // allows for a dedicated address to be used for withdrawals
    function setTreasury(address newTreasury) external onlyOwner { 
        require(newTreasury!=address(0), "cant be 0 address");
        treasury = newTreasury;
    }

    // funds can be withdrawn to the treasury account for safe keeping
    function treasuryOut(uint amount) external onlyOwner reentrancyGuard {
        
        // can withdraw any amount up to the account balance (0 will withdraw everything)
        uint balance = address(this).balance;
        if(amount == 0 || amount > balance) amount = balance;

        // make the withdrawal
        (bool success, ) = treasury.call{value:amount}("");
        require(success, "transfer failed");
    }
    
    // the owner can pay funds in at any time although this is not needed
    // perhaps the contract needs to hold a certain balance in future for some external requirement
    function treasuryIn() external payable onlyOwner {

    }


    /// BATCHING

    // all normal ERC721 read functions can be batched
    // this allows for any user or app to look up all their tokens in a single call or via paging

    function tokenByIndexBatch(uint256[] memory indexes) public view virtual returns (uint256[] memory) {
        uint256[] memory batch = new uint256[](indexes.length);

        for (uint256 i = 0; i < indexes.length; i++) {
            batch[i] = tokenByIndex(indexes[i]);
        }

        return batch; 
    }

    function balanceOfBatch(address[] memory owners) external view virtual returns (uint256[] memory) {
        uint256[] memory batch = new uint256[](owners.length);

        for (uint256 i = 0; i < owners.length; i++) {
            batch[i] = balanceOf(owners[i]);
        }

        return batch;        
    }

    function ownerOfBatch(uint256[] memory tokenIds) external view virtual returns (address[] memory) {  
        address[] memory batch = new address[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            batch[i] = ownerOf(tokenIds[i]);
        }

        return batch;
    }

    function tokenURIBatch(uint256[] memory tokenIds) external view virtual returns (string[] memory) {
        string[] memory batch = new string[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            batch[i] = tokenURI(tokenIds[i]);
        }

        return batch;
    }

    function getApprovedBatch(uint256[] memory tokenIds) external view virtual returns (address[] memory) {
        address[] memory batch = new address[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            batch[i] = getApproved(tokenIds[i]);
        }

        return batch;
    }

    function tokenOfOwnerByIndexBatch(address owner_, uint256[] memory indexes) external view virtual returns (uint256[] memory) {
        uint256[] memory batch = new uint256[](indexes.length);

        for (uint256 i = 0; i < indexes.length; i++) {
            batch[i] = tokenOfOwnerByIndex(owner_, indexes[i]);
        }

        return batch;
    }

}