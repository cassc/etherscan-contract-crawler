//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; 


/// @title Owned
/// @author Cao Huang
contract Owned{
    
    address payable public  owner;
    
     /// @notice Store the contract owner address
    function owned() public {        
        owner=payable(msg.sender);
    }
    
}
/// @title Mortal
/// @author Cao Huang
contract Mortal is Owned{
    
    /// @notice Destroy the smart contract
    /// @dev Destroy the smart contract using selfdestruct() function that returns all funds to the owner address
    function kill() public{
        
        require(msg.sender==owner);        
        selfdestruct(owner);
    }
}
