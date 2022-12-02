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



interface IPancakeRouter {

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}