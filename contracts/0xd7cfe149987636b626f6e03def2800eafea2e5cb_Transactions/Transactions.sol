/**
 *Submitted for verification at Etherscan.io on 2022-10-14
*/

// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.0;

contract Transactions{
    uint256 transactionCount; 
    mapping (address => User) public users;

    
    //event = function called later
    event Transfer(address from, address reciever, uint amount, string message, uint256 timestamp, string keyword);
    //built in transfer event?
    
    struct User{
        address id;
        uint256 transactionCount;
        TransferStruct[] transactions;
        Contact[] contacts;
        uint256 pin;
    }

    struct TransferStruct{
        address sender;
        address reciever;
        uint amount;
        string message;
        uint256 timestamp;
        string keyword;
        string token;
    }

    struct Contact{
        string name;
        address payable contactAddress;
    }


    TransferStruct[] transactions; 

// timestamp from block.timestamp
    function addToBlockchain(address payable reciever, uint amount, string memory message, string memory keyword, string memory token) public {
        users[msg.sender].transactionCount+=1;
        users[msg.sender].transactions.push(TransferStruct(msg.sender, reciever, amount, message, block.timestamp, keyword, token));
        users[reciever].transactions.push(TransferStruct(msg.sender, reciever, amount, message, block.timestamp, keyword, token));

        emit Transfer(msg.sender, reciever, amount, message, block.timestamp, keyword);
    }
    function getAllTransactions() public view returns (TransferStruct[] memory) {
        return users[msg.sender].transactions;
    }

    function getTransactionCount() public view returns (uint256) {
        return users[msg.sender].transactionCount; 
    }

    function setPin(uint number) public{
    users[msg.sender].pin = number;
    }

    function getPin(address person) public view returns (uint256){
      return users[person].pin;
    }

/// add pictures to contact
    function addContact(address payable recipient, string memory contact_name) public{
      Contact memory newContact = Contact({
        contactAddress: recipient,
        name: contact_name
      });
      users[msg.sender].contacts.push(newContact);
    }

    function getAllContacts() public view returns (Contact[] memory){
        return users[msg.sender].contacts;
    }

}