// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISwapRouter.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract SellFeeDistributor is Ownable{

    ISwapRouter public _swapRouter;
    address public YdAddress;
    uint256 private constant MAX = 2**256-1;


    address public fundAddress;
    address public dividendAddress;
    address public lpDivAddress;
    address public tecDivAddress;


    uint256 public lpDividend = 200;
    uint256 public fundFee = 300;
    uint256 public tecFee = 30;
    uint256 public toLiquid = 30;
    uint256 public dividend = 40;

    uint256 public total  = lpDividend + fundFee + tecFee + toLiquid + dividend;

    address public usdt;
    bool private isOnDistribute;

    constructor (address FundAddress,address DividendAddress,address LpDivAddress,address TecDivAddress,address SwapRouter,address UsdtAddress,address YDAddress) {
        fundAddress = FundAddress;
        dividendAddress = DividendAddress;
        lpDivAddress =LpDivAddress;
        tecDivAddress = TecDivAddress;
        YdAddress = YDAddress;
        _swapRouter = ISwapRouter(SwapRouter);
        usdt = UsdtAddress;
        IERC20(usdt).approve(address(_swapRouter), MAX);
        IERC20(YdAddress).approve(address(_swapRouter), MAX);

    }


    function setAddress(address FundAddress,address DividendAddress,address LpDivAddress,address TecDivAddress) external onlyOwner{
        fundAddress = FundAddress;
        dividendAddress = DividendAddress;
        lpDivAddress =LpDivAddress;
        tecDivAddress = TecDivAddress;
    }




    function distribute() external returns(bool){
        if(isOnDistribute){
            return false;
        }
        isOnDistribute = true;
        uint ydBalance = IERC20(YdAddress).balanceOf(address(this));
        if(ydBalance <= 1e16){
            isOnDistribute = false;
            return false;
        }
        uint ydAmountToLiquid = ydBalance * toLiquid / total / 2;
        swapTokensForUsdt(ydBalance - ydAmountToLiquid);
        uint usdtBalanceThis = IERC20(usdt).balanceOf(address(this));
        addLiquidityUsdt(ydAmountToLiquid,usdtBalanceThis/2);
        uint usdtBalanceToDistribute = IERC20(usdt).balanceOf(address(this));
        if(usdtBalanceToDistribute < 1e18){
            isOnDistribute = false;
            return true;
        }
        IERC20(usdt).transfer(YdAddress,usdtBalanceToDistribute * lpDividend/total);
        IERC20(usdt).transfer(fundAddress,usdtBalanceToDistribute * fundFee/total);
        IERC20(usdt).transfer(tecDivAddress,usdtBalanceToDistribute * tecFee/total);
        IERC20(usdt).transfer(dividendAddress,usdtBalanceToDistribute * dividend/total);
        isOnDistribute = false;
        return true;
    }


    function swapTokensForUsdt(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = YdAddress;
        path[1] = usdt;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp + 60
        );
    }

    function addLiquidityUsdt(uint256 tokenAmount, uint256 usdtAmount) private {

        _swapRouter.addLiquidity(
            YdAddress,
            usdt,
            tokenAmount,
            usdtAmount,
            0,
            0,
            lpDivAddress,
            block.timestamp + 60
        );
    }


    function claimBalance(address toAddress) external onlyOwner{
        payable(toAddress).transfer(address(this).balance);
    }

    function claimToken(address token,address toAddress, uint256 amount) external onlyOwner{
        IERC20(token).transfer(toAddress, amount);
    }


}