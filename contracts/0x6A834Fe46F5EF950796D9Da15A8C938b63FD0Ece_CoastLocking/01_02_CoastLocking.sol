// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CoastLocking {
  
  address public CONTRACT_ADDRESS = address(this);
  address manager = 0xc3F9beD906C1FfCD35fE6332be251544C94B070f;

  mapping (address => mapping (address => uint256)) public locked;
  mapping (address => uint256) public penalties;

  event Lock(address token, address locker, uint amount);
  event Unlock(address token, address unlocker, uint amount);


  modifier manager_function(){
    require(msg.sender==manager,"Only the manager can call this function");
    _;}
  
  
  function lock(address tokenAddress, uint amount) public {

    require(IERC20(tokenAddress).allowance(msg.sender,CONTRACT_ADDRESS) >= amount, "You need to approve the contract to transfer your tokens");
    
    IERC20(tokenAddress).transferFrom(msg.sender,CONTRACT_ADDRESS, amount);

    locked[msg.sender][tokenAddress] += amount;

    emit Lock(tokenAddress, msg.sender, amount);

  }


  function unlockSome(address tokenAddress, uint amount) public {

    require(locked[msg.sender][tokenAddress] >= amount, "You don't have that many tokens locked");

    locked[msg.sender][tokenAddress] -= amount;
    penalties[tokenAddress] += (5 * amount) / 100;
    
    IERC20(tokenAddress).transfer(msg.sender, (95 * amount) / 100);

    emit Unlock(tokenAddress, msg.sender, amount);

  }

  
  function unlockAll(address tokenAddress) public {

    require(locked[msg.sender][tokenAddress] > 0, "You don't have any tokens locked");
    
    uint amount = locked[msg.sender][tokenAddress];
    locked[msg.sender][tokenAddress] = 0;
    penalties[tokenAddress] += (5 * amount) / 100;
    
    IERC20(tokenAddress).transfer(msg.sender, (95 * amount) / 100);

    emit Unlock(tokenAddress, msg.sender, amount);

  }


  function withdrawToken(address tokenAddress) manager_function public {

    uint amount = penalties[tokenAddress];
    
    IERC20(tokenAddress).transfer(manager,amount);

    penalties[tokenAddress] = 0;

  }

  
}