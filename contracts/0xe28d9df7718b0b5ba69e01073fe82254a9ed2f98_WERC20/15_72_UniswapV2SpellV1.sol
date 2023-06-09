pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

import './BasicSpell.sol';
import '../utils/HomoraMath.sol';
import '../../interfaces/IUniswapV2Factory.sol';
import '../../interfaces/IUniswapV2Router02.sol';
import '../../interfaces/IUniswapV2Pair.sol';
import '../../interfaces/IWStakingRewards.sol';

contract UniswapV2SpellV1 is BasicSpell {
  using SafeMath for uint;
  using HomoraMath for uint;

  IUniswapV2Factory public factory;
  IUniswapV2Router02 public router;

  mapping(address => mapping(address => address)) public pairs;

  constructor(
    IBank _bank,
    address _werc20,
    IUniswapV2Router02 _router
  ) public BasicSpell(_bank, _werc20, _router.WETH()) {
    router = _router;
    factory = IUniswapV2Factory(_router.factory());
  }

  function getPair(address tokenA, address tokenB) public returns (address) {
    address lp = pairs[tokenA][tokenB];
    if (lp == address(0)) {
      lp = factory.getPair(tokenA, tokenB);
      require(lp != address(0), 'no lp token');
      ensureApprove(tokenA, address(router));
      ensureApprove(tokenB, address(router));
      ensureApprove(lp, address(router));
      pairs[tokenA][tokenB] = lp;
      pairs[tokenB][tokenA] = lp;
    }
    return lp;
  }

  /// @dev Compute optimal deposit amount
  /// @param amtA amount of token A desired to deposit
  /// @param amtB amount of token B desired to deposit
  /// @param resA amount of token A in reserve
  /// @param resB amount of token B in reserve
  function optimalDeposit(
    uint amtA,
    uint amtB,
    uint resA,
    uint resB
  ) internal pure returns (uint swapAmt, bool isReversed) {
    if (amtA.mul(resB) >= amtB.mul(resA)) {
      swapAmt = _optimalDepositA(amtA, amtB, resA, resB);
      isReversed = false;
    } else {
      swapAmt = _optimalDepositA(amtB, amtA, resB, resA);
      isReversed = true;
    }
  }

  /// @dev Compute optimal deposit amount helper.
  /// @param amtA amount of token A desired to deposit
  /// @param amtB amount of token B desired to deposit
  /// @param resA amount of token A in reserve
  /// @param resB amount of token B in reserve
  /// Formula: https://blog.alphafinance.io/byot/
  function _optimalDepositA(
    uint amtA,
    uint amtB,
    uint resA,
    uint resB
  ) internal pure returns (uint) {
    require(amtA.mul(resB) >= amtB.mul(resA), 'Reversed');
    uint a = 997;
    uint b = uint(1997).mul(resA);
    uint _c = (amtA.mul(resB)).sub(amtB.mul(resA));
    uint c = _c.mul(1000).div(amtB.add(resB)).mul(resA);
    uint d = a.mul(c).mul(4);
    uint e = HomoraMath.sqrt(b.mul(b).add(d));
    uint numerator = e.sub(b);
    uint denominator = a.mul(2);
    return numerator.div(denominator);
  }

  struct Amounts {
    uint amtAUser;
    uint amtBUser;
    uint amtLPUser;
    uint amtABorrow;
    uint amtBBorrow;
    uint amtLPBorrow;
    uint amtAMin;
    uint amtBMin;
  }

  function addLiquidityInternal(
    address tokenA,
    address tokenB,
    Amounts calldata amt
  ) internal {
    address lp = getPair(tokenA, tokenB);

    // 1. Get user input amounts
    doTransmitETH();
    doTransmit(tokenA, amt.amtAUser);
    doTransmit(tokenB, amt.amtBUser);
    doTransmit(lp, amt.amtLPUser);

    // 2. Borrow specified amounts
    doBorrow(tokenA, amt.amtABorrow);
    doBorrow(tokenB, amt.amtBBorrow);
    doBorrow(lp, amt.amtLPBorrow);

    // 3. Calculate optimal swap amount
    uint swapAmt;
    bool isReversed;
    {
      uint amtA = IERC20(tokenA).balanceOf(address(this));
      uint amtB = IERC20(tokenB).balanceOf(address(this));
      uint resA;
      uint resB;
      if (IUniswapV2Pair(lp).token0() == tokenA) {
        (resA, resB, ) = IUniswapV2Pair(lp).getReserves();
      } else {
        (resB, resA, ) = IUniswapV2Pair(lp).getReserves();
      }
      (swapAmt, isReversed) = optimalDeposit(amtA, amtB, resA, resB);
    }

    // 4. Swap optimal amount
    {
      address[] memory path = new address[](2);
      (path[0], path[1]) = isReversed ? (tokenB, tokenA) : (tokenA, tokenB);
      router.swapExactTokensForTokens(swapAmt, 0, path, address(this), now);
    }

    // 5. Add liquidity
    router.addLiquidity(
      tokenA,
      tokenB,
      IERC20(tokenA).balanceOf(address(this)),
      IERC20(tokenB).balanceOf(address(this)),
      amt.amtAMin,
      amt.amtBMin,
      address(this),
      now
    );
  }

  function addLiquidityWERC20(
    address tokenA,
    address tokenB,
    Amounts calldata amt
  ) external payable {
    address lp = getPair(tokenA, tokenB);
    // 1-5. add liquidity
    addLiquidityInternal(tokenA, tokenB, amt);

    // 6. Put collateral
    doPutCollateral(lp, IERC20(lp).balanceOf(address(this)));

    // 7. Refund leftovers to users
    doRefundETH();
    doRefund(tokenA);
    doRefund(tokenB);
  }

  function addLiquidityWStakingRewards(
    address tokenA,
    address tokenB,
    Amounts calldata amt,
    address wstaking
  ) external payable {
    address lp = getPair(tokenA, tokenB);
    address reward = IWStakingRewards(wstaking).reward();

    // 1-5. add liquidity
    addLiquidityInternal(tokenA, tokenB, amt);

    // 6. Take out collateral
    uint positionId = bank.POSITION_ID();
    (, address collToken, uint collId, uint collSize) = bank.getPositionInfo(positionId);
    if (collSize > 0) {
      require(IWStakingRewards(collToken).getUnderlyingToken(collId) == lp, 'incorrect underlying');
      bank.takeCollateral(wstaking, collId, collSize);
      IWStakingRewards(wstaking).burn(collId, collSize);
    }

    // 7. Put collateral
    ensureApprove(lp, wstaking);
    uint amount = IERC20(lp).balanceOf(address(this));
    uint id = IWStakingRewards(wstaking).mint(amount);
    if (!IWStakingRewards(wstaking).isApprovedForAll(address(this), address(bank))) {
      IWStakingRewards(wstaking).setApprovalForAll(address(bank), true);
    }
    bank.putCollateral(address(wstaking), id, amount);

    // 8. Refund leftovers to users
    doRefundETH();
    doRefund(tokenA);
    doRefund(tokenB);

    // 9. Refund reward
    doRefund(reward);
  }

  struct RepayAmounts {
    uint amtLPTake;
    uint amtLPWithdraw;
    uint amtARepay;
    uint amtBRepay;
    uint amtLPRepay;
    uint amtAMin;
    uint amtBMin;
  }

  function removeLiquidityInternal(
    address tokenA,
    address tokenB,
    RepayAmounts calldata amt
  ) internal {
    address lp = getPair(tokenA, tokenB);
    uint positionId = bank.POSITION_ID();

    uint amtARepay = amt.amtARepay;
    uint amtBRepay = amt.amtBRepay;
    uint amtLPRepay = amt.amtLPRepay;

    // 2. Compute repay amount if MAX_INT is supplied (max debt)
    if (amtARepay == uint(-1)) {
      amtARepay = bank.borrowBalanceCurrent(positionId, tokenA);
    }
    if (amtBRepay == uint(-1)) {
      amtBRepay = bank.borrowBalanceCurrent(positionId, tokenB);
    }
    if (amtLPRepay == uint(-1)) {
      amtLPRepay = bank.borrowBalanceCurrent(positionId, lp);
    }

    // 3. Compute amount to actually remove
    uint amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amt.amtLPWithdraw);

    // 4. Remove liquidity
    (uint amtA, uint amtB) =
      router.removeLiquidity(tokenA, tokenB, amtLPToRemove, 0, 0, address(this), now);

    // 5. MinimizeTrading
    uint amtADesired = amtARepay.add(amt.amtAMin);
    uint amtBDesired = amtBRepay.add(amt.amtBMin);

    if (amtA < amtADesired && amtB >= amtBDesired) {
      address[] memory path = new address[](2);
      (path[0], path[1]) = (tokenB, tokenA);
      router.swapTokensForExactTokens(
        amtADesired.sub(amtA),
        amtB.sub(amtBDesired),
        path,
        address(this),
        now
      );
    } else if (amtA >= amtADesired && amtB < amtBDesired) {
      address[] memory path = new address[](2);
      (path[0], path[1]) = (tokenA, tokenB);
      router.swapTokensForExactTokens(
        amtBDesired.sub(amtB),
        amtA.sub(amtADesired),
        path,
        address(this),
        now
      );
    }

    // 6. Repay
    doRepay(tokenA, amtARepay);
    doRepay(tokenB, amtBRepay);
    doRepay(lp, amtLPRepay);

    // 7. Slippage control
    require(IERC20(tokenA).balanceOf(address(this)) >= amt.amtAMin);
    require(IERC20(tokenB).balanceOf(address(this)) >= amt.amtBMin);
    require(IERC20(lp).balanceOf(address(this)) >= amt.amtLPWithdraw);

    // 8. Refund leftover
    doRefundETH();
    doRefund(tokenA);
    doRefund(tokenB);
    doRefund(lp);
  }

  function removeLiquidityWERC20(
    address tokenA,
    address tokenB,
    RepayAmounts calldata amt
  ) external {
    address lp = getPair(tokenA, tokenB);

    // 1. Take out collateral
    doTakeCollateral(lp, amt.amtLPTake);

    // 2-8. remove liquidity
    removeLiquidityInternal(tokenA, tokenB, amt);
  }

  function removeLiquidityWStakingRewards(
    address tokenA,
    address tokenB,
    RepayAmounts calldata amt,
    address wstaking
  ) external {
    address lp = getPair(tokenA, tokenB);
    uint positionId = bank.POSITION_ID();
    (, address collToken, uint collId, ) = bank.getPositionInfo(positionId);
    address reward = IWStakingRewards(wstaking).reward();

    // 1. Take out collateral
    require(IWStakingRewards(collToken).getUnderlyingToken(collId) == lp, 'incorrect underlying');
    bank.takeCollateral(wstaking, collId, amt.amtLPTake);
    IWStakingRewards(wstaking).burn(collId, amt.amtLPTake);

    // 2-8. remove liquidity
    removeLiquidityInternal(tokenA, tokenB, amt);

    // 9. Refund reward
    doRefund(reward);
  }

  function harvestWStakingRewards(address wstaking) external {
    address reward = IWStakingRewards(wstaking).reward();
    uint positionId = bank.POSITION_ID();
    (, , uint collId, ) = bank.getPositionInfo(positionId);
    address lp = IWStakingRewards(wstaking).getUnderlyingToken(collId);

    // 1. Take out collateral
    bank.takeCollateral(wstaking, collId, uint(-1));
    IWStakingRewards(wstaking).burn(collId, uint(-1));

    // 2. put collateral
    uint amount = IERC20(lp).balanceOf(address(this));
    ensureApprove(lp, wstaking);
    uint id = IWStakingRewards(wstaking).mint(amount);
    bank.putCollateral(wstaking, id, amount);

    // 3. Refund reward
    doRefund(reward);
  }
}