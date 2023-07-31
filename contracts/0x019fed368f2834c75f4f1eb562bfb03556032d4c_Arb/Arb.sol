/**
 *Submitted for verification at Etherscan.io on 2023-07-26
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
 }
contract Arb {
	 function getAmountOutMin(address router, address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint256) {
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint256[] memory amountOutMins = IUniswapV2Router(router).getAmountsOut(_amount, path);
		return amountOutMins[path.length -1];
	}
    function estimateDualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 _amount) external view returns (uint256) {
		uint256 amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
		uint256 amtBack2 = getAmountOutMin(_router2, _token2, _token1, amtBack1);
		return amtBack2;
	}

    function getOutsMins(address _router1, address _router2, address base_token, address[] memory _tokens, uint256 _amount) public view returns (uint256[] memory) {
        uint256[] memory OutsMins = new uint256[](2 *_tokens.length);
		// Прямой обмен
        for (uint256 i = 0; i < _tokens.length; i++) {
			uint256 amtBack1 = getAmountOutMin(_router1, base_token, _tokens[i], _amount);
			uint256 amtBack2 = getAmountOutMin(_router2, _tokens[i], base_token, amtBack1);
			OutsMins[i] = amtBack2;
        }
		// Обратный обмен
		for (uint256 i = 0; i < _tokens.length; i++) {  
			uint256 amtBack1 = getAmountOutMin(_router2, base_token, _tokens[i], _amount);
			uint256 amtBack2 = getAmountOutMin(_router1, _tokens[i], base_token, amtBack1);
			OutsMins[i + _tokens.length] = amtBack2;
        }
        return OutsMins;
    }
}