// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import { IUniswapV3Factory } from './interfaces/IUniswapV3Factory.sol';
import { IUniswapV3Pool } from './interfaces/IUniswapV3Pool.sol';
import { INPM } from './interfaces/INonfungiblePositionManager.sol';
import { IWETH9 } from './interfaces/IWETH9.sol';

abstract contract UniswapBase {
  struct BaseDeployParams {
    address weth;
    address uniswapFactory;
    address nonfungiblePositionManager;
    address tokenIn;
    address tokenOut;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
  }

  struct AddLiquidity {
    address depositor; /// @dev depositor The address which the position will be credited to.
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  struct RemoveLiquidity {
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  IUniswapV3Factory public immutable FACTORY;
  IUniswapV3Pool public immutable POOL;
  address public immutable WETH;
  address public immutable NPM;
  address public immutable TOKEN_IN;
  address public immutable TOKEN_OUT;
  uint24 public immutable FEE;
  int24 public immutable TICK_LOWER;
  int24 public immutable TICK_UPPER;

  uint256 public positionId;

  constructor(BaseDeployParams memory params) {
    FACTORY = IUniswapV3Factory(params.uniswapFactory);
    NPM = params.nonfungiblePositionManager;
    TOKEN_IN = params.tokenIn;
    TOKEN_OUT = params.tokenOut;
    FEE = params.fee;
    TICK_LOWER = params.tickLower;
    TICK_UPPER = params.tickUpper;
    WETH = params.weth;
    POOL = IUniswapV3Pool(FACTORY.getPool(params.tokenIn, params.tokenOut, params.fee));
  }

  function _addLiquidity(
    AddLiquidity memory _params
  ) internal returns (uint256 _tokenId, uint128 _liquidityAdded, uint256 _amountAdded0, uint256 _amountAdded1) {
    (address token0, address token1) = TOKEN_IN < TOKEN_OUT ? (TOKEN_IN, TOKEN_OUT) : (TOKEN_OUT, TOKEN_IN);

    (_params.amount0Desired, _params.amount1Desired) = (msg.value != 0)
      ? _processEth(token0, token1, _params.amount0Desired, _params.amount1Desired, msg.value)
      : (_params.amount0Desired, _params.amount1Desired);

    if (positionId != 0) {
      (_liquidityAdded, _amountAdded0, _amountAdded1) = INPM(NPM).increaseLiquidity(
        INPM.IncreaseLiquidityParams({
          tokenId: positionId,
          amount0Desired: _params.amount0Desired,
          amount1Desired: _params.amount1Desired,
          amount0Min: _params.amount0Min,
          amount1Min: _params.amount1Min,
          deadline: _params.deadline
        })
      );
      _tokenId = positionId;
    } else {
      (_tokenId, _liquidityAdded, _amountAdded0, _amountAdded1) = INPM(NPM).mint(
        INPM.MintParams({
          token0: token0,
          token1: token1,
          fee: FEE,
          tickLower: TICK_LOWER, //Tick needs to exist (right spacing)
          tickUpper: TICK_UPPER, //Tick needs to exist (right spacing)
          amount0Desired: _params.amount0Desired,
          amount1Desired: _params.amount1Desired,
          amount0Min: _params.amount0Min, // Slippage check
          amount1Min: _params.amount1Min, // Slippage check
          recipient: address(this), // Receiver of ERC721
          deadline: _params.deadline
        })
      );
      positionId = _tokenId;
    }
  }

  function _decreaseLiquidity(
    RemoveLiquidity memory _params
  ) internal returns (uint256 _amountRemoved0, uint256 _amountRemoved1) {
    (_amountRemoved0, _amountRemoved1) = INPM(NPM).decreaseLiquidity(
      INPM.DecreaseLiquidityParams({
        tokenId: positionId,
        liquidity: _params.liquidity,
        amount0Min: _params.amount0Min,
        amount1Min: _params.amount1Min,
        deadline: _params.deadline
      })
    );
  }

  function _collect(
    address _recipient,
    uint128 _amount0Max,
    uint128 _amount1Max
  ) internal returns (uint256 _amountCollected0, uint256 _amountCollected1) {
    if (positionId == 0) return (0, 0);
    (_amountCollected0, _amountCollected1) = INPM(NPM).collect(
      INPM.CollectParams({
        tokenId: positionId,
        recipient: _recipient,
        amount0Max: _amount0Max,
        amount1Max: _amount1Max
      })
    );
  }

  function _processEth(
    address _token0,
    address _token1,
    uint256 _initialAmount0,
    uint256 _initialAmount1,
    uint256 _msgValue
  ) internal returns (uint _amount0, uint _amount1) {
    _amount0 = _initialAmount0;
    _amount1 = _initialAmount1;

    IWETH9(WETH).deposit{ value: _msgValue }();
    if (_token0 == WETH) {
      _amount0 += _msgValue;
    } else if (_token1 == WETH) {
      _amount1 += _msgValue;
    }
  }
}