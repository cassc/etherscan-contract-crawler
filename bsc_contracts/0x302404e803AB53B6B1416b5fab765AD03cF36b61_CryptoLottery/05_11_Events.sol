// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Events {
  event ClaimTicketRewardEvent(uint tier, bool free_ticket, uint token_reward, uint eth_reward );
  event DepositEvent(uint value, uint tokens);
  event WithdrawEvent(uint amount);
  event CreateRoundEvent(uint round, uint token_reward, address moderator, uint time);
  event BuyTicketEvent(uint number, address player, uint256[6] numbers, uint time);
  event BuyFreeTicketEvent(uint number, address player, uint256[6] numbers, uint time);
  event BuyCLTicketEvent(uint number, address player, uint256[6] numbers, uint time);
  event AddLengindEvent(address holder, uint amount, uint time);
  event RemoveLengindEvent(address holder, uint amount, uint reward, uint percent, uint _days, uint time);

}