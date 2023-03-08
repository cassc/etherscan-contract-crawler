// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./StrategyFarmLP.sol";


contract StrategyFarmLPBabyDoge is StrategyFarmLP {
  using SafeERC20 for IERC20;

  address constant public BABYDOGE = 0xc748673057861a797275CD8A068AbB95A902e8de;
  address constant public ROUTER_FOR_FEE = 0x9869674E80D632F93c338bd398408273D20a6C8e;

  uint256 constant public MAX_BABYDOGE_FEE = 10**2;

  constructor(
    address _unirouter,
    address _want,
    address _output,
    address _native,

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
    _native,

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
    uint256 shares = _amount;
    if (shares > 0) {
      shares = _amount / IERC20Farm(masterchef).pricePerShare();
    }

    IERC20Farm(masterchef).withdraw(shares);
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

    if (output == BABYDOGE) {
      outputHalf = _fixBabyDogeAmount(outputHalf);
    }

    if (outputHalf == 0) return 0;

    uint256 amount0 = _checkLpOutput(lpToken0, outputToLp0Route, outputHalf);
    if (amount0 == 0) return 0;

    uint256 amount1 = _checkLpOutput(lpToken1, outputToLp1Route, outputHalf);
    if (amount1 == 0) return 0;

    uint256 minAmount = IERC20Farm(masterchef).defaultStakePPS();
    if (_calcLiquidity(amount0, amount1) < minAmount) return 0;

    return allBal;
  }

  function _swapToken(
    uint256 _amount,
    address[] memory _path,
    address _to
  ) internal override returns (uint256) {
    address tokenTo = _path[_path.length - 1];

    // default swap
    if (_path[0] != BABYDOGE && tokenTo != BABYDOGE) {
      return super._swapToken(_amount, _path, _to);
    }

    // BabyDoge swap
    uint256 before = IERC20(tokenTo).balanceOf(address(this));
    if (tokenTo == BABYDOGE) {
      super._swapToken(_amount, _path, _to);
    }
    else { // _path[0] == BABYDOGE
      IBabyDogeRouter(unirouter)
        .swapExactTokensForTokensSupportingFeeOnTransferTokens(
          _amount,
          1,
          _path,
          _to,
          block.timestamp
        );
    }

    return (IERC20(tokenTo).balanceOf(address(this)) - before);
  }

  function _addLiquidity(uint256 amountToken0, uint256 amountToken1) internal override {
    address router = unirouter;
    if (lpToken0 == BABYDOGE || lpToken1 == BABYDOGE) {
      router = ROUTER_FOR_FEE;
    }

    IBabyDogeRouter(router).addLiquidity(
      lpToken0,
      lpToken1,
      amountToken0,
      amountToken1,
      1,
      1,
      address(this),
      block.timestamp
    );
  }

  function _removeLiquidity(uint256 amount) internal override returns (
    uint256 amountToken0, uint256 amountToken1
  ) {
    (uint256 amount0, uint256 amount1) =  IBabyDogeRouter(unirouter).removeLiquidity(
      lpToken0,
      lpToken1,
      amount,
      1,
      1,
      address(this),
      block.timestamp
    );

    // fix BabyDoge output swap amount
    if (lpToken0 == BABYDOGE || lpToken1 == BABYDOGE) {
      uint256 balance = IERC20(BABYDOGE).balanceOf(address(this));

      if (lpToken0 == BABYDOGE) {
        amount0 = _fixBabyDogeAmount(amount0);
        if (balance < amount0) {
          amount0 = balance;
        }
      }
      else if (lpToken1 == BABYDOGE) {
        amount1 = _fixBabyDogeAmount(amount1);
        if (balance < amount1) {
          amount1 = balance;
        }
      }
    }

    return (amount0, amount1);
  }

  function _giveAllowances() internal override {
    super._giveAllowances();

    // IERC20(want).safeApprove(ROUTER_FOR_FEE, 0);
    // IERC20(want).safeApprove(ROUTER_FOR_FEE, type(uint256).max);

    IERC20(lpToken0).safeApprove(ROUTER_FOR_FEE, 0);
    IERC20(lpToken0).safeApprove(ROUTER_FOR_FEE, type(uint256).max);

    IERC20(lpToken1).safeApprove(ROUTER_FOR_FEE, 0);
    IERC20(lpToken1).safeApprove(ROUTER_FOR_FEE, type(uint256).max);
  }

  function _removeAllowances() internal override {
    super._removeAllowances();

    // IERC20(want).safeApprove(ROUTER_FOR_FEE, 0);
    IERC20(lpToken0).safeApprove(ROUTER_FOR_FEE, 0);
    IERC20(lpToken1).safeApprove(ROUTER_FOR_FEE, 0);
  }


  function _checkLpOutput(
    address lpToken,
    address[] memory route,
    uint256 amount
  ) private view returns (uint256) {
    if (lpToken == output) return amount;

    uint256[] memory amounts = IBabyDogeRouter(unirouter).getAmountsOut(
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

  function _fixBabyDogeAmount(uint256 amount) internal view returns (uint256) {
    uint256 coinFee = IBabyDogeCoin(BABYDOGE)._taxFee();
    coinFee+= IBabyDogeCoin(BABYDOGE)._liquidityFee();

    return amount * (MAX_BABYDOGE_FEE - coinFee) / MAX_BABYDOGE_FEE;
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
  ) external;
}

interface IBabyDogeCoin is IERC20 {
  function _taxFee() external view returns(uint256);
  function _liquidityFee() external view returns(uint256);
}