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
import '../interfaces/IPancakeRouter.sol';



abstract contract PancakeClient {
  address private constant _routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
  address private constant _wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

  function _swap(address tokenIn, uint amountIn, address tokenOut, address recipient) internal {
    require(tokenIn != address(0) || tokenOut != address(0), 'PancakeClient: zero address for both tokens');
    if(tokenIn != address(0) && tokenOut != address(0)) {
      _swapTokensForTokens(tokenIn, amountIn, tokenOut, recipient);
    } else {
      if(tokenIn == address(0)) _swapBnbForTokens(amountIn, tokenOut, recipient);
      if(tokenOut == address(0) )_swapTokensForBnb(tokenIn, amountIn, recipient);
    }
  }

  /* ========== ========= ========== ========== ========== ========== ========== ========== */

  function _swapBnbForTokens(uint amountIn, address tokenOut, address recipient) private {
    IPancakeRouter(_routerAddress).swapExactETHForTokensSupportingFeeOnTransferTokens{value : amountIn}(
      0, 
      _swapPath(_wbnb, tokenOut), 
      recipient, 
      block.timestamp
    );
  }

  function _swapTokensForBnb(address tokenIn, uint amountIn, address recipient) private {
    require(IBEP20(tokenIn).balanceOf(address(this)) >= amountIn, 'PancakeClient: swap amount exceeds balance');
    _checkAllowance(tokenIn, amountIn);
    
    IPancakeRouter(_routerAddress).swapExactTokensForETHSupportingFeeOnTransferTokens(
      amountIn, 
      0, 
      _swapPath(tokenIn, _wbnb), 
      recipient, 
      block.timestamp
    );
  }

  function _swapTokensForTokens(address tokenIn, uint amountIn, address tokenOut, address recipient) private {
    require(tokenIn != tokenOut, 'PancakeClient: tokenIn must be different to tokenOut');
    _checkAllowance(tokenIn, amountIn);
    
    IPancakeRouter(_routerAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
      amountIn, 
      0, 
      _swapPath(tokenIn, tokenOut), 
      recipient, 
      block.timestamp
    );
  }

  function _checkAllowance(address tokenIn, uint amountIn) private {
    if(IBEP20(tokenIn).allowance(address(this), _routerAddress) < amountIn) {
      IBEP20(tokenIn).approve(_routerAddress, type(uint256).max);
    }
  }

  function _swapPath(address tokenIn, address tokenOut) private pure returns (address[] memory) {
    address[] memory path;
    if (tokenIn == _wbnb || tokenOut == _wbnb) {
      path = new address[](2);
      path[0] = tokenIn;
      path[1] = tokenOut;
    } else {
      path = new address[](3);
      path[0] = tokenIn;
      path[1] = _wbnb;
      path[2] = tokenOut;
    }
    return path;
  }
}