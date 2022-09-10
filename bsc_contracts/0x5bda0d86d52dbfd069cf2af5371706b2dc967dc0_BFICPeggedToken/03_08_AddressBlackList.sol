// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract AddressBlackList is Ownable{
    
    mapping (address => bool) internal isBlockListed;
    
    event AddedBlockList(address _user);
    event RemovedBlockList(address _user);
    
    /**
    * @dev account address to check blacklisted
    */
    function getBlockListStatus(address account) external view returns (bool) {
        return isBlockListed[account];
    }

    /**
    * @dev account address of user the owner want to add in BlockList 
    */
    function addToBlockList(address account) public onlyOwner {
        require(!isBlockListed[account]);
        isBlockListed[account] = true;
        emit AddedBlockList(account);
    }

    /**
    * @dev account address of user the owner want to remove BlockList 
    */
    function removeFromBlockList(address account) public onlyOwner {
        require(isBlockListed[account]);
        isBlockListed[account] = false;
        emit RemovedBlockList(account);
    }    
}