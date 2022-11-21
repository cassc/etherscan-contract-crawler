// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./Token.sol";
import "./Events.sol";
import "./Lottery.sol";

contract CrowdSale is Token, Events, Lottery {

   uint public tokenPrice;
   uint public softCap;
   uint public raisedAmount;
   uint public withdrawAmount;
   uint public time;

   CrowdSaleStatus public crowd_sale_status;

   enum CrowdSaleStatus {
        ON,
        OFF
   }

   constructor(uint _tokenPrice, uint _interval, uint _t_price, uint _ticket_p_cl, uint _f, uint _ico_soft_cap, uint _ico_time, uint _n_game_reward) Lottery(_interval, _t_price, _ticket_p_cl, _f, _n_game_reward) {
     tokenPrice = _tokenPrice;
     softCap = _ico_soft_cap;
     time = block.timestamp + _ico_time;
   }

   function deposit () external payable {
     require(crowd_sale_status == CrowdSaleStatus.ON, 'CrowdSale is closed');
     require(block.timestamp <= time, 'Time is over');

     raisedAmount += msg.value;

     uint tokens = msg.value / tokenPrice; // error.
     uint __tokens = tokens * 10 ** 18;
     _token_reward += __tokens * 3;

     _mint(msg.sender, __tokens);
     emit DepositEvent(msg.value, __tokens);
   }

   function winthdraw (uint amount) external onlyOwner {
     require(withdrawAmount + amount <= raisedAmount, 'Contract is empty');
     
     withdrawAmount += amount;

     _lottery_owner.transfer(amount);

     emit WithdrawEvent(amount);
   }

   function turnOn() external onlyOwner{
     crowd_sale_status = CrowdSaleStatus.ON; 
   }

   function turnOff() external onlyOwner {
     crowd_sale_status = CrowdSaleStatus.OFF; 
   }

   function changeTime(uint _time) external onlyOwner {
     time = block.timestamp + _time;
   }
}