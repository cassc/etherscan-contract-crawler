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

import './interfaces/IBEP20.sol';
import './utils/Administrable.sol';
import './utils/PancakeClient.sol';
import './utils/Wallet.sol';



contract SmartWallet is Administrable, PancakeClient, Wallet {
  event SwapOccurred(address indexed tokenIn, uint amountIn, address indexed tokenOut);

  function swap(address tokenIn, uint amountIn, address tokenOut) external onlyAdmin {
    _swap(tokenIn, amountIn, tokenOut, address(this));
    emit SwapOccurred(tokenIn, amountIn, tokenOut);
  }
}