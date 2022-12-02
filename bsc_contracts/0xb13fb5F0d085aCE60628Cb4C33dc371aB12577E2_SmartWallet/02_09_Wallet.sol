// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

/*
   _____                      ___          __   _ _      _   
  / ____|                    | \ \        / /  | | |    | |  
 | (___  _ __ ___   __ _ _ __| |\ \  /\  / /_ _| | | ___| |_ 
  \___ \| '_ ` _ \ / _` | '__| __\ \/  \/ / _` | | |/ _ \ __|
  ____) | | | | | | (_| | |  | |_ \  /\  / (_| | | |  __/ |_ 
 |_____/|_| |_| |_|\__,_|_|   \__| \/  \/ \__,_|_|_|\___|\__|

*/                                                             

import '../interfaces/IBEP20.sol';
import './Administrable.sol';



abstract contract Wallet is Administrable {
  event Deposited(address indexed from, address indexed tokenAddress, uint amount);
  event Withdrawn(address indexed to, address indexed tokenAddress, uint amount);

  receive() external payable {
    emit Deposited(msg.sender, address(0), msg.value);
  }

  function approve(address spender, address tokenAddress, uint amount) external onlyAdmin {
    IBEP20(tokenAddress).approve(spender, amount);
  }
  
  function balance(address tokenAddress) external view returns (uint) {
    if(tokenAddress == address(0)) {
      return address(this).balance;
    } else {
      return IBEP20(tokenAddress).balanceOf(address(this));
    }
  }

  function deposit(address from, address tokenAddress, uint amount) external onlyAdmin {
    IBEP20(tokenAddress).transferFrom(from, address(this), amount);
    emit Deposited(from, tokenAddress, amount);
  }

  function depositAll(address from, address tokenAddress) external onlyAdmin {
    uint amount = IBEP20(tokenAddress).allowance(from, address(this));
    IBEP20(tokenAddress).transferFrom(from, address(this), amount);
    emit Deposited(from, tokenAddress, amount);
  }

  function withdraw(address to, address tokenAddress, uint amount) external onlyAdmin {
    if(tokenAddress == address(0)) {
      payable(to).transfer(amount);
    } else {
      IBEP20(tokenAddress).transfer(to, amount);
    }
    emit Withdrawn(to, tokenAddress, amount);
  }

  function withdrawAll(address to, address tokenAddress) external onlyAdmin {
    uint amount = 0;
    if(tokenAddress == address(0)) {
      amount = address(this).balance;
      payable(to).transfer(amount);
    } else {
      amount =  IBEP20(tokenAddress).balanceOf(address(this));
      IBEP20(tokenAddress).transfer(to, amount);
    }
    emit Withdrawn(to, tokenAddress, amount);
  }
}