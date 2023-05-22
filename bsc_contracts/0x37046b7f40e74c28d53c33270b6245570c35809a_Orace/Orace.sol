/**
 *Submitted for verification at BscScan.com on 2023-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
contract Orace  {
    IUniswapV2Router public router =IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address          public eth=0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address          public bnb=0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address          public usdt=0x55d398326f99059fF775485246999027B3197955;
    address[]  public path1;
    address[]  public path2;
    constructor() {
        path1=[usdt,bnb,eth];
        path2=[eth,bnb,usdt];
    }

    function price() external view returns(uint){
        uint[] memory amounts = router.getAmountsIn(1e18,path1);
        return amounts[0];
    }

    function getOutUsdt(uint tokenAmount) external view returns(uint usdtAmount){
        uint[] memory amounts = router.getAmountsOut(tokenAmount,path2);
        usdtAmount = amounts[2];
    }

    function getOutToken(uint usdtAmount) external view returns(uint tokenAmount){
        uint[] memory amounts = router.getAmountsOut(usdtAmount,path1);
        tokenAmount = amounts[2];
    }

    function getInUsdt(uint tokenAmount) external view returns(uint usdtAmount){
        uint[] memory amounts = router.getAmountsIn(tokenAmount,path1);
        usdtAmount = amounts[0];
    }
}