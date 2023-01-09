// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./NftPoolToken.sol";
import "./LPData.sol";
import "./Math.sol";
import "./INftizePoolLpManager.sol";

/// @title NftizePoolLpManager sushi LP manager contract
contract NftizePoolLpManager is INftizePoolLpManager {
    address public constant SUSHISWAP_FACTORY_ADDRESS = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address public constant SUSHISWAP_ROUTER_ADDRESS = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    IUniswapV2Factory public constant sushiswapFactory = IUniswapV2Factory(SUSHISWAP_FACTORY_ADDRESS);
    IUniswapV2Router02 public constant sushiswapRouter = IUniswapV2Router02(SUSHISWAP_ROUTER_ADDRESS);

    IERC20 public theosToken;

    event TheosClaimed(uint256 amount);
    error InsufficientLPLiquidity(uint256 theosAmount, uint256 poolTokenAmount);

    constructor(address theosAddress) {
        theosToken = IERC20(theosAddress);
    }

    function claimTheosLiquidity(address poolTokenAddress, LPData memory lpProvider) external {
        IUniswapV2Pair sushiLP = IUniswapV2Pair(lpProvider.lpTokenAddress);
        NftPoolToken poolToken = NftPoolToken(poolTokenAddress);

        uint256 theosReserveAmount;
        uint256 poolTokenReserveAmount;
        uint256 timestamp;
        uint256 lpTokenAmount;

        if (address(theosToken) < address(poolToken)) {
            (theosReserveAmount, poolTokenReserveAmount, timestamp) = sushiLP.getReserves();
            lpTokenAmount =
                (Math.sqrt(lpProvider.theosTokenAmount * lpProvider.indexPoolTokenAmount)) -
                sushiLP.MINIMUM_LIQUIDITY();
        } else {
            (poolTokenReserveAmount, theosReserveAmount, timestamp) = sushiLP.getReserves();
            lpTokenAmount =
                (Math.sqrt(lpProvider.indexPoolTokenAmount * lpProvider.theosTokenAmount)) -
                sushiLP.MINIMUM_LIQUIDITY();
        }

        sushiLP.approve(address(sushiswapRouter), lpTokenAmount);
        sushiLP.transferFrom(msg.sender, address(this), lpTokenAmount);

        sushiswapRouter.removeLiquidity(
            address(theosToken), // tokenA
            address(poolToken), // tokenB
            lpTokenAmount, // Sushi LP token amount
            lpProvider.theosTokenAmount / 2,
            lpProvider.indexPoolTokenAmount / 2,
            address(this), // to address for returned tokens
            block.timestamp
        );

        poolToken.burn(poolToken.balanceOf(address(this)));
        theosToken.transfer(lpProvider.depositor, theosToken.balanceOf(address(this)));

        emit TheosClaimed(theosToken.balanceOf(msg.sender));
    }
}