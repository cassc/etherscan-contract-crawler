/**
 *Submitted for verification at Etherscan.io on 2023-05-02
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.12;

interface ERC20 {
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract CTCFee{
  
  
    
    event OwnershipTransferred(address);
    address public owner = msg.sender;
    
    address public contractAddr = address(this);
    
    event DepositAt(address user, uint tariff, uint amount);
    event Withdraw(address user, uint amount);
    
    constructor() {
        
    }



    function transferToken(uint _amount, address tokenAddr,address _toAddress) external payable  {
            require( _amount >= 0);
            ERC20 tokenObj    = ERC20(tokenAddr);
            require(tokenObj.balanceOf(msg.sender) >= _amount, "Insufficient User Token balance");
            require(tokenObj.allowance(msg.sender,contractAddr)>=_amount,"Insufficient allowance");
            tokenObj.transferFrom(msg.sender, _toAddress, _amount);
             emit DepositAt(msg.sender, 0, _amount);
    } 


   
    // Owner Token Withdraw    
    // Only owner can withdraw token 
    function withdrawToken(address tokenAddress, address to, uint amount) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        ERC20 _token = ERC20(tokenAddress);
        _token.transfer(to, amount);
        return true;
    }
    
    // Owner BNB Withdraw
    // Only owner can withdraw BNB from contract
    function withdrawBNB(address payable to, uint amount) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        to.transfer(amount);
        return true;
    }
     

    // Ownership Transfer
    // Only owner can call this function
    function transferOwnership(address to) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot transfer ownership to zero address");
        owner = to;
        emit OwnershipTransferred(to);
        return true;
    }

}