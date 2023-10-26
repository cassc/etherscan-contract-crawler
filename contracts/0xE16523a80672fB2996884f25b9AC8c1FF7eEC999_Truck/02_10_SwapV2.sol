// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SwapV2 is Ownable {

    mapping(address => bool) public pairs;

    function setPairs(address[] calldata addr, uint pairs_) external onlyOwner() {
        for (uint i; i < addr.length; i++) {
            pairs[addr[i]] = (pairs_ != 0);
        }
    }

    function _isLiquidity(address from, address to) internal view returns(bool isAdd,bool isDel){
        address pair;
        if (pairs[from]) pair = from;
        if (pairs[to]) pair = to;
        if (pair == address(0)) return (false, false);

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        address usdtAddr; uint usdtNum;
        (uint r0, uint r1,) = IUniswapV2Pair(pair).getReserves();
        if(token0 != address(this)){
            usdtNum = r0;
            usdtAddr = token0;
        }
        if(token1 != address(this)){
          usdtNum = r1;
          usdtAddr = token1;
        }
        uint usdtNumNew = IERC20(usdtAddr).balanceOf(pair);
        isAdd = pairs[to] && usdtNumNew > usdtNum;
        isDel = pairs[from] && usdtNumNew < usdtNum;
    }

}