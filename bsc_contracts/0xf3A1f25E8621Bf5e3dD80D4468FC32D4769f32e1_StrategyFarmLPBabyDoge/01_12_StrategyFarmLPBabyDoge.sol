// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./StrategyFarmLP.sol";


contract StrategyFarmLPBabyDoge is StrategyFarmLP {

  constructor(
    address _unirouter,
    address _want,
    address _output,
    address _wbnb,

    address _callFeeRecipient,
    address _frfiFeeRecipient,
    address _strategistFeeRecipient,

    address _safeFarmFeeRecipient,

    address _treasuryFeeRecipient,
    address _systemFeeRecipient
  ) StrategyFarmLP(
    _unirouter,
    _want,
    _output,
    _wbnb,

    _callFeeRecipient,
    _frfiFeeRecipient,
    _strategistFeeRecipient,

    _safeFarmFeeRecipient,

    _treasuryFeeRecipient,
    _systemFeeRecipient
  ) {
  }


  // it calculates how much 'want' the strategy has working in the farm.
  function balanceOfPool() public view override virtual returns (uint256) {
    (uint256 _amount,, ) = IERC20Farm(masterchef).userInfo(address(this));
    return _amount * IERC20Farm(masterchef).pricePerShare();
  }

  function pendingReward() public view override virtual returns (uint256 amount) {
    amount = IERC20Farm(masterchef).pendingReward(address(this));
    return amount * (MAX_FEE - poolFee) / MAX_FEE;
  }


// INTERNAL FUNCTIONS

  function _poolDeposit(uint256 _amount) internal override virtual {
    if (_amount > 0) {
      IERC20Farm(masterchef).deposit(_amount);
    }
    else { // harvest
      _poolWithdraw(0);
    }
  }

  function _poolWithdraw(uint256 _amount) internal override virtual {
    IERC20Farm(masterchef).withdraw(_amount);
  }

  function _emergencyWithdraw() internal override virtual {
    uint256 poolBal = balanceOfPool();
    if (poolBal > 0) {
      IERC20Farm(masterchef).emergencyWithdraw();
    }
  }

  // skip swaps on non liquidity
  function _outputBalance() internal override returns (uint256) {
    uint256 allBal = super._outputBalance();
    uint256 outputHalf = (allBal * (MAX_FEE - poolFee) / MAX_FEE) / 2;
    if (outputHalf == 0) return 0;

    uint256 amount0 = _checkLpOutput(lpToken0, outputToLp0Route, outputHalf);
    if (amount0 == 0) return 0;

    uint256 amount1 = _checkLpOutput(lpToken1, outputToLp1Route, outputHalf);
    if (amount1 == 0) return 0;

    uint256 minAmount = IERC20Farm(masterchef).defaultStakePPS();
    if (_calcLiquidity(amount0, amount1) < minAmount) return 0;

    return allBal;
  }

  function _checkLpOutput(
    address lpToken,
    address[] memory route,
    uint256 amount
  ) private view returns (uint256) {
    if (lpToken == output) return amount;

    uint256[] memory amounts = IUniswapRouterETH(unirouter).getAmountsOut(
      amount, route
    );

    return amounts[amounts.length - 1];
  }

  function _calcLiquidity(
    uint256 _amount0, uint256 _amount1
  ) private view returns (uint256) {
    uint256 totalSupply = IUniswapV2Pair(want).totalSupply();
    (uint256 reserve0, uint256 reserve1) = IUniswapV2Pair(want).getReserves();

    uint256 liquidity0 = _amount0 * totalSupply / reserve0;
    uint256 liquidity1 = _amount1 * totalSupply / reserve1;

    return liquidity0 < liquidity1 // return min liquidity
      ? liquidity0
      : liquidity1;
  }

  function _swapToken(
    uint256 _amount,
    address[] memory _path,
    address _to
  ) internal override returns (uint256[] memory amounts) {
    if (_path[0] == output) {
      return IBabyDogeRouter(unirouter).swapExactTokensForTokens(
        _amount,
        1,
        _path,
        _to,
        block.timestamp
      );
    }
    else {
      return IBabyDogeRouter(unirouter)
        .swapExactTokensForTokensSupportingFeeOnTransferTokens(
          _amount,
          1,
          _path,
          _to,
          block.timestamp
        );
    }
  }
}

interface IERC20Farm {
  function pricePerShare() external view returns (uint256);
  function defaultStakePPS() external view returns (uint256);

  function userInfo(address) external view returns (
    uint256, uint256 , uint256
  ); // shares, rewardDebt, depositBlock
  function pendingReward(address) external view returns (uint256);

  function deposit(uint256) external;
  function withdraw(uint256) external;
  function emergencyWithdraw() external;
}

interface IBabyDogeRouter is IUniswapRouterETH {
  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
}