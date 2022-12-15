// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Charity is AccessControl {
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  IERC20 public tokenContract;
  mapping(address => uint256) public users;

  event ticketBought(address buyer, uint256 amount, uint256 value);
  event ticketBoughtByToken(address buyer, uint256 amount, uint256 value);
  constructor(
    address tokenAddress
  ){
    tokenContract = IERC20(tokenAddress);
   	_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  	_setupRole(ADMIN_ROLE, msg.sender);
  }

  function buyTicket(uint256 count) payable public {
    users[msg.sender] += count;
    emit ticketBought(msg.sender, count, msg.value);
  }

  function buyTicketByToken(uint256 count, uint256 tokenAmount) public {
    tokenContract.transferFrom(msg.sender, address(this), tokenAmount);
    users[msg.sender] += count;
    emit ticketBoughtByToken(msg.sender, count, tokenAmount);
  }

  function updateTokenAddress(IERC20 _newAddress) public onlyRole(ADMIN_ROLE) {
    tokenContract = IERC20(_newAddress);
  }

  // allows the owner to withdraw tokens
  function ownerWithdraw(uint256 amount, address _to, address _tokenAddr) public onlyRole(ADMIN_ROLE){
    require(_to != address(0));
    if(_tokenAddr == address(0)){
      payable(_to).transfer(amount);
    }else{
      IERC20(_tokenAddr).transfer(_to, amount);
    }
  }
}