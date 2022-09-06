//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../interfaces/IUniswapV3Factory.sol";
import "../interfaces/IUniswapV3Pool.sol";
import "../interfaces/INonfungiblePositionManager.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract InitialLiquidityVaultStorage is ReentrancyGuard{

    IERC20 public token;  // project token
    IERC20 public TOS;  //  tos token

    IUniswapV3Factory public UniswapV3Factory;
    INonfungiblePositionManager public NonfungiblePositionManager;
    uint24 public fee;
    IUniswapV3Pool public pool;
    address public token0Address;
    address public token1Address;
    uint256 public initialTosPrice ;
    uint256 public initialTokenPrice ;
    uint160 public initSqrtPriceX96 ;
    uint256 constant INITIAL_PRICE_DIV = 1e18;
    int24 public tickIntervalMinimum;
    bool public boolReadyToCreatePool;

    uint256 public lpToken;

    int24 tickSpacings ;
}