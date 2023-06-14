// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import { IERC20, SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { IUniswapV3Router } from '../src/interfaces/IUniswapV3Router.sol';
import { IWETH9 } from '../src/interfaces/IWETH9.sol';
import { Exit10, UniswapBase } from './Exit10.sol';
import { APermit } from './APermit.sol';

contract DepositHelper is APermit {
  using SafeERC20 for IERC20;
  uint256 private constant MAX_UINT_256 = type(uint256).max;
  uint256 private constant DEADLINE = 1e10;
  uint256 private constant RESOLUTION = 10_000;

  address private immutable UNISWAP_V3_ROUTER;
  address payable private immutable EXIT_10;
  address private immutable WETH;
  address private immutable TOKEN_0;
  address private immutable TOKEN_1;

  event SwapAndBootstrapLock(
    address indexed caller,
    uint128 liquidityAdded,
    uint256 amountAdded0,
    uint256 amountAdded1
  );
  event SwapAndCreateBond(
    address indexed caller,
    uint256 bondId,
    uint128 liquidityAdded,
    uint256 amountAdded0,
    uint256 amountAdded1
  );
  event ProcessEth(address indexed caller, uint256 amount);
  event Swap(address indexed caller, uint256 amountIn, uint256 amountOut);

  constructor(address uniswapV3Router_, address payable exit10_, address weth_) {
    UNISWAP_V3_ROUTER = uniswapV3Router_;
    EXIT_10 = exit10_;
    WETH = weth_;

    TOKEN_0 = Exit10(exit10_).POOL().token0();
    TOKEN_1 = Exit10(exit10_).POOL().token1();
    _maxApproveTokens(UNISWAP_V3_ROUTER);
    _maxApproveTokens(EXIT_10);
  }

  function swapAndBootstrapLockWithPermit(
    uint256 initialAmount0,
    uint256 initialAmount1,
    uint256 slippage,
    IUniswapV3Router.ExactInputSingleParams memory swapParams,
    PermitParameters memory permitParams0,
    PermitParameters memory permitParams1
  ) external payable returns (uint256 tokenId, uint128 liquidityAdded, uint256 amountAdded0, uint256 amountAdded1) {
    _permitTokens(permitParams0, permitParams1);
    return swapAndBootstrapLock(initialAmount0, initialAmount1, slippage, swapParams);
  }

  function swapAndCreateBondWithPermit(
    uint256 initialAmount0,
    uint256 initialAmount1,
    uint256 slippage,
    IUniswapV3Router.ExactInputSingleParams memory swapParams,
    PermitParameters memory permitParams0,
    PermitParameters memory permitParams1
  ) external payable returns (uint256 bondId, uint128 liquidityAdded, uint256 amountAdded0, uint256 amountAdded1) {
    _permitTokens(permitParams0, permitParams1);
    return swapAndCreateBond(initialAmount0, initialAmount1, slippage, swapParams);
  }

  function swapAndBootstrapLock(
    uint256 initialAmount0,
    uint256 initialAmount1,
    uint256 slippage,
    IUniswapV3Router.ExactInputSingleParams memory swapParams
  ) public payable returns (uint256 tokenId, uint128 liquidityAdded, uint256 amountAdded0, uint256 amountAdded1) {
    (tokenId, liquidityAdded, amountAdded0, amountAdded1) = Exit10(EXIT_10).bootstrapLock(
      _depositAndSwap(initialAmount0, initialAmount1, slippage, swapParams)
    );

    emit SwapAndBootstrapLock(msg.sender, liquidityAdded, amountAdded0, amountAdded1);
  }

  function swapAndCreateBond(
    uint256 initialAmount0,
    uint256 initialAmount1,
    uint256 slippage,
    IUniswapV3Router.ExactInputSingleParams memory swapParams
  ) public payable returns (uint256 bondId, uint128 liquidityAdded, uint256 amountAdded0, uint256 amountAdded1) {
    (bondId, liquidityAdded, amountAdded0, amountAdded1) = Exit10(EXIT_10).createBond(
      _depositAndSwap(initialAmount0, initialAmount1, slippage, swapParams)
    );

    emit SwapAndCreateBond(msg.sender, bondId, liquidityAdded, amountAdded0, amountAdded1);
  }

  function _depositAndSwap(
    uint256 _initialAmount0,
    uint256 _initialAmount1,
    uint256 _slippage,
    IUniswapV3Router.ExactInputSingleParams memory _swapParams
  ) internal returns (UniswapBase.AddLiquidity memory _params) {
    _depositTokens(_initialAmount0, _initialAmount1);

    if (msg.value != 0) {
      (_initialAmount0, _initialAmount1) = _processEth(_initialAmount0, _initialAmount1, msg.value);
    }

    uint256 amountOut;
    if (_swapParams.amountIn != 0) {
      amountOut = IUniswapV3Router(UNISWAP_V3_ROUTER).exactInputSingle(_swapParams);

      if (_swapParams.tokenIn == TOKEN_0) {
        _initialAmount0 = IERC20(TOKEN_0).balanceOf(address(this));
        _initialAmount1 += amountOut;
      } else {
        _initialAmount1 = IERC20(TOKEN_1).balanceOf(address(this));
        _initialAmount0 += amountOut;
      }
    }

    _params = UniswapBase.AddLiquidity({
      depositor: msg.sender,
      amount0Desired: _initialAmount0,
      amount1Desired: _initialAmount1,
      amount0Min: _initialAmount0 - (_initialAmount0 * _slippage) / RESOLUTION,
      amount1Min: _initialAmount1 - (_initialAmount1 * _slippage) / RESOLUTION,
      deadline: DEADLINE
    });

    emit Swap(msg.sender, _swapParams.amountIn, amountOut);
  }

  function _processEth(
    uint256 _initialAmount0,
    uint256 _initialAmount1,
    uint256 _msgValue
  ) internal returns (uint256 _amount0, uint256 _amount1) {
    _amount0 = _initialAmount0;
    _amount1 = _initialAmount1;

    IWETH9(WETH).deposit{ value: _msgValue }();
    if (TOKEN_0 == WETH) {
      _amount0 += _msgValue;
    } else if (TOKEN_1 == WETH) {
      _amount1 += _msgValue;
    }

    emit ProcessEth(msg.sender, _msgValue);
  }

  function _depositTokens(uint256 _amount0, uint256 _amount1) internal {
    if (_amount0 != 0) IERC20(TOKEN_0).safeTransferFrom(msg.sender, address(this), _amount0);
    if (_amount1 != 0) IERC20(TOKEN_1).safeTransferFrom(msg.sender, address(this), _amount1);
  }

  function _maxApproveTokens(address _spender) internal {
    IERC20(TOKEN_0).approve(_spender, MAX_UINT_256);
    IERC20(TOKEN_1).approve(_spender, MAX_UINT_256);
  }
}