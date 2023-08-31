// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 引入UniswapV2Router02合约
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IERC20.sol";

contract UniswapTokenSeller {
    // 定义UniswapV2Router02合约的地址
    address private uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    event AmountsOutLog(uint256[] amounts);
    event AmountsOutLog1(uint256[] amounts);
    event buyLog(uint256 amounts);
    event saleLog(uint256[] amounts);




    // 定义要卖出的代币地址
    
    // 定义UniswapV2Router02合约实例
    IUniswapV2Router02 private uniswapRouter;
    
    constructor() {
        uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
    }
    
    function BuyToken(uint256 sale_type,address token_address) external payable {

        // 查询发送的金额能买多少
        uint256[] memory amounts = uniswapRouter.getAmountsOut(
            msg.value, // 发送的金额
            getPathForETHToToken(token_address)
        );
        emit AmountsOutLog(amounts);

        // 定义token合约
        address tokenAddress = token_address;

        // 购买token 到合约自己
        uniswapRouter.swapExactETHForTokens{
             value: msg.value
        }(
            0, 
            getPathForETHToToken(token_address), 
            address(this), 
            block.timestamp+30
        );

        // 获取自己的代币余额
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(this));
        emit buyLog(tokenBalance);

        // 查询代币余额能换多少weth
        uint256[] memory amounts1 = uniswapRouter.getAmountsOut(
            msg.value, // 发送的金额
            getPathForTokenToETH(token_address)
        );
        emit AmountsOutLog1(amounts1);



        // 批准Uniswap合约使用调用者的代币
        IERC20(tokenAddress).approve(uniswapRouterAddress, tokenBalance);
                
        // 在Uniswap上卖出代币获取ETH
        if(sale_type == 1){
            uniswapRouter.swapExactTokensForETH(
                tokenBalance,  // 卖出的代币数量
                0,             // 最小接收的ETH数量，设置为0表示不限制最小值
                getPathForTokenToETH(token_address),  // 代币到ETH的路径
                msg.sender,    // 接收ETH的地址
                block.timestamp  // 交易截止时间，设置为当前区块时间戳
            );
        }else if(sale_type == 2){
            uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenBalance,  // 卖出的代币数量
                0,             // 最小接收的ETH数量，设置为0表示不限制最小值
                getPathForTokenToETH(token_address),  // 代币到ETH的路径
                msg.sender,    // 接收ETH的地址
                block.timestamp  // 交易截止时间，设置为当前区块时间戳
            );

        }
    }
    
    function getPathForTokenToETH(address token_address) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = token_address;
        path[1] = uniswapRouter.WETH();
        
        return path;
    }

    function getPathForETHToToken(address token_address) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = token_address;
        
        return path;
    }

}