/**
 *Submitted for verification at BscScan.com on 2023-04-25
*/

// SPDX-License-Identifier: TradDEX DAO Test
pragma solidity ^0.8.2;

contract TradDEXPresale{
    mapping(address => uint) public balances;           
    mapping(address => uint) public balances_eth;           
    
    address public admin;    
    address payable admin_to;    
    uint public invest_price = 1000000;
    uint public invest_min = 30000000000000000;        
    uint public invested_sum = 0;

    constructor(){
        admin = msg.sender;    
        admin_to = payable(admin);    
    }

    function change_invest_min(uint value) public returns(bool){
        require(msg.sender==admin,'allow only admin');
    
        invest_min = value;
        return true;
    }

    function change_invest_price(uint value) public returns(bool){
        require(msg.sender==admin,'allow only admin');
    
        invest_price = value;
        return true;
    }

    receive() external payable {
        require(msg.sender!=admin,'admin is not allowed');        
        if(msg.value<invest_min){revert('investment to low');}                

        balances[msg.sender] += (msg.value * invest_price);
        balances_eth[msg.sender] += msg.value;

        invested_sum += msg.value;

        admin_to.transfer(msg.value);
    }
}