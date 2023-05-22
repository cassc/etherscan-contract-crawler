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
    address          public voola=0x70EC9f6953490Bb7169A0bcEf01D64301a627Ffc;
    address          public btc=0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address          public bnb=0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address          public usdt=0x55d398326f99059fF775485246999027B3197955;
    address[]  public path1;
    address[]  public path2;
    constructor() {
        path1=[usdt,bnb,btc,voola];
        path2=[voola,btc,bnb,usdt];
    }

    function price() external view returns(uint){
        uint[] memory amounts = router.getAmountsIn(1e9,path1);
        return amounts[0];
    }

    function getOutUsdt(uint tokenAmount) external view returns(uint usdtAmount){
        uint[] memory amounts = router.getAmountsOut(tokenAmount,path2);
        usdtAmount = amounts[3];
    }

    function getOutToken(uint usdtAmount) external view returns(uint tokenAmount){
        uint[] memory amounts = router.getAmountsOut(usdtAmount,path1);
        tokenAmount = amounts[3];
    }

    function getInUsdt(uint tokenAmount) external view returns(uint usdtAmount){
        uint[] memory amounts = router.getAmountsIn(tokenAmount,path1);
        usdtAmount = amounts[0];
    }
}