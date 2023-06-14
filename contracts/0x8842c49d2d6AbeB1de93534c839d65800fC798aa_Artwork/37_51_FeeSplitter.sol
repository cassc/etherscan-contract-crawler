// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import { IERC20, SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { IUniswapV3Pool } from './interfaces/IUniswapV3Pool.sol';
import { ISwapper } from './interfaces/ISwapper.sol';
import { Masterchef } from './Masterchef.sol';
import { Exit10 } from './Exit10.sol';

contract FeeSplitter is Ownable {
  using SafeERC20 for IERC20;

  uint16 constant SLIPPAGE = 10; //0.1%
  uint32 constant ORACLE_SECONDS = 60;
  uint256 constant MAX_UINT_256 = type(uint256).max;

  address immutable MASTERCHEF; // STO - BOOT Stakers
  address immutable SWAPPER;
  address payable public exit10;

  event SetExit10(address indexed caller, address indexed exit10);
  event CollectFees(uint256 amountTokenOut, uint256 amountTokenIn);
  event UpdateFees(address indexed caller, uint256 amountExchangedIn, uint256 rewardsMasterchef, uint256 rewardsExit10);
  event Swap(uint256 amountIn, uint256 amountOut);

  constructor(address masterchef_, address swapper_) {
    MASTERCHEF = masterchef_;
    SWAPPER = swapper_;
  }

  modifier onlyAuthorized() {
    require(msg.sender == exit10, 'FeeSplitter: Caller not authorized');
    _;
  }

  function setExit10(address payable exit10_) external onlyOwner {
    exit10 = exit10_;
    IERC20(Exit10(exit10).TOKEN_OUT()).approve(SWAPPER, MAX_UINT_256);
    IERC20(Exit10(exit10).TOKEN_IN()).approve(MASTERCHEF, MAX_UINT_256);
    renounceOwnership();

    emit SetExit10(msg.sender, exit10);
  }

  function collectFees(uint256 amountTokenOut, uint256 amountTokenIn) external onlyAuthorized {
    if (amountTokenOut != 0) {
      IERC20(Exit10(exit10).TOKEN_OUT()).safeTransferFrom(exit10, address(this), amountTokenOut);
    }
    if (amountTokenIn != 0) {
      IERC20(Exit10(exit10).TOKEN_IN()).safeTransferFrom(exit10, address(this), amountTokenIn);
    }

    emit CollectFees(amountTokenOut, amountTokenIn);
  }

  function updateFees(uint256 swapAmountOut) external returns (uint256 totalExchangedIn) {
    uint256 balanceTokenOut = IERC20(Exit10(exit10).TOKEN_OUT()).balanceOf(address(this));

    swapAmountOut = Math.min(swapAmountOut, balanceTokenOut);
    if (swapAmountOut != 0) {
      totalExchangedIn = _swap(swapAmountOut);
    }

    uint256 balanceTokenIn = IERC20(Exit10(exit10).TOKEN_IN()).balanceOf(address(this));

    uint256 mcTokenIn = (balanceTokenIn << 1) / 10; // 20%
    uint256 exit10TokenIn = balanceTokenIn - mcTokenIn; // 80%

    if (mcTokenIn != 0) {
      Masterchef(MASTERCHEF).updateRewards(mcTokenIn);
    }
    if (exit10TokenIn != 0) {
      // Invest tokenIn and send it to Exit10
      // For now just send it to Exit10 as tokenIn
      IERC20(Exit10(exit10).TOKEN_IN()).safeTransfer(exit10, exit10TokenIn);
      Exit10(exit10).updateRewards(exit10TokenIn);
    }

    emit UpdateFees(msg.sender, totalExchangedIn, mcTokenIn, exit10TokenIn);
  }

  function _swap(uint256 _amount) internal returns (uint256 _amountAcquired) {
    ISwapper.SwapParameters memory params = ISwapper.SwapParameters({
      recipient: address(this),
      tokenIn: Exit10(exit10).TOKEN_OUT(), // TOKEN_OUT is the sell token going into the swap
      tokenOut: Exit10(exit10).TOKEN_IN(), // TOKEN_IN is the buy token going out of the swap
      fee: Exit10(exit10).FEE(),
      amountIn: _amount,
      slippage: SLIPPAGE,
      oracleSeconds: ORACLE_SECONDS
    });

    _amountAcquired = ISwapper(SWAPPER).swap(params);

    emit Swap(_amount, _amountAcquired);
  }
}