// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Owned} from "solmate/src/auth/Owned.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {UniswapLiquidity} from "./libraries/UniswapLiquidity.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
   .--.
  |o_o |
  |:_/ |
//   \ \  
(|     | )  
'/_'|_'\

 /$$$$$$$                               /$$$$$$$                                         /$$          
| $$__  $$                             | $$__  $$                                       |__/          
| $$  \ $$ /$$$$$$   /$$$$$$   /$$$$$$ | $$  \ $$ /$$$$$$  /$$$$$$$   /$$$$$$  /$$   /$$ /$$ /$$$$$$$ 
| $$$$$$$//$$__  $$ /$$__  $$ /$$__  $$| $$$$$$$//$$__  $$| $$__  $$ /$$__  $$| $$  | $$| $$| $$__  $$
| $$____/| $$$$$$$$| $$  \ $$| $$$$$$$$| $$____/| $$$$$$$$| $$  \ $$| $$  \ $$| $$  | $$| $$| $$  \ $$
| $$     | $$_____/| $$  | $$| $$_____/| $$     | $$_____/| $$  | $$| $$  | $$| $$  | $$| $$| $$  | $$
| $$     |  $$$$$$$| $$$$$$$/|  $$$$$$$| $$     |  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$/| $$| $$  | $$
|__/      \_______/| $$____/  \_______/|__/      \_______/|__/  |__/ \____  $$ \______/ |__/|__/  |__/
                   | $$                                              /$$  \ $$                        
                   | $$                                             |  $$$$$$/                        
                   |__/                                              \______/                         

PepePenguin ($PP) Deployer!

Launching on 4/20, PepePenguin is here to Make Memes Great Again (MMGA)! Join the MMGA movement and slide 
into the future of the bigglest meme token, owned and driven by the community, as a meme coin should be.
No tax, no games, no CEX's, no BS, just yuge and bigly classy memes! Don't miss out on the revolution!


Simple, No BS:
- 100% tokens paired with liquidity
- liquidity locked for 42.69 weeks
- Starting Liquidity 2ETH

@PPepe_Penguin
https://mmgapepepenguin.com/

*/


contract PPDeployer is Owned {
    uint24 public constant V3_FEE_TIER = 10000; // 1% fee tier
    IERC20 public immutable TOKEN;
    uint256 public constant LOCK_DURATION = 42.69 weeks;
    uint256 public immutable LOCK_START;
    uint256 public immutable INITIAL_LIQ_ETH;

    uint256 public lpToken;
    constructor(address token, uint256 initLiquidityETH) Owned(msg.sender) {
        require(address(msg.sender).balance >= initLiquidityETH, "Can Only deploy once you have secured funds");

        TOKEN = IERC20(token);
        LOCK_START = block.timestamp;
        INITIAL_LIQ_ETH = initLiquidityETH;
    }

    /* 
        Checks for promised funds, initializes pool and adds liquidity
    */
    function launchAndLockLP() external payable onlyOwner {
        require(lpToken == 0, "Already launched");

        uint256 tokenBalance = TOKEN.balanceOf(address(this));
        uint256 ethBalance = address(this).balance;
        UniswapLiquidity.WETH.deposit{ value: ethBalance }();

        require(UniswapLiquidity.WETH.balanceOf(address(this)) == ethBalance, "Deposit to WETH failed.");
        require(ethBalance == INITIAL_LIQ_ETH, "Must Initialize Liquidity with promised Initial ETH");
        require(tokenBalance == TOKEN.totalSupply(), "Must Initialize Liquidity with total supply");
        
        UniswapLiquidity.WETH.approve(address(UniswapLiquidity.V3_LP_MANAGER), ethBalance);
        TOKEN.approve(address(UniswapLiquidity.V3_LP_MANAGER), tokenBalance);

        (address token0, address token1) = UniswapLiquidity.orderTokens(address(TOKEN), address(UniswapLiquidity.WETH));
        (uint256 normTokenAmount, uint256 normWETHAmount) = UniswapLiquidity.normalizeAmounts(tokenBalance, ethBalance, TOKEN.decimals(), UniswapLiquidity.WETH.decimals());
        (uint256 amount0, uint256 amount1) = token0 == address(TOKEN) ? (normTokenAmount, normWETHAmount) : (normWETHAmount, normTokenAmount);
        (int24 lowerTick, int24 upperTick) = UniswapLiquidity.maxTickBoundary(V3_FEE_TIER);

        uint160 initialSqrtPriceX96 = UniswapLiquidity.sqrtPriceX96FromAmounts(amount0, amount1);
        UniswapLiquidity.V3_LP_MANAGER.createAndInitializePoolIfNecessary(token0, token1, V3_FEE_TIER, initialSqrtPriceX96);
        
        (lpToken,,,) = UniswapLiquidity.V3_LP_MANAGER.mint(
            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: V3_FEE_TIER,
                tickLower: lowerTick,
                tickUpper: upperTick,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 1000
            })
        );
    }

    /* 
        Transfers ownership of LP ONLY AFTER the lock is up
    */
    function redeemnLPAfterLock() external onlyOwner {
        require(block.timestamp > LOCK_START + LOCK_DURATION, "Liquidity hasn't unlocked");

        UniswapLiquidity.V3_LP_MANAGER.transferFrom(address(this), owner, lpToken);
    }

    /* 
        Can only collect the LP fees associated with the liquidity position
    */
    function collectLPFees() external onlyOwner {
        require(lpToken != 0, "Liquidity not set");

        (uint256 amount0, uint256 amount1) = UniswapLiquidity.V3_LP_MANAGER.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: lpToken,
                recipient: owner,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
    }
    
}