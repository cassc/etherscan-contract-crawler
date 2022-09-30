// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./StratFeeManager.sol";
import "./GasFeeThrottler.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IUnknownLens.sol";
import "./interfaces/IUnknownProxy.sol";
import "./interfaces/IMultiRewards.sol";

import "hardhat/console.sol";

contract RefractlyUnknownStrategy is StratFeeManager, GasFeeThrottler {
  using SafeERC20 for IERC20;

  address public native; // wmatic
  address public rewardToken0;
  address public rewardToken1;
  address public want; // lp token
  address public lpToken0;
  address public lpToken1;
  bool public stable;

  address private constant unknownLensAddress = 0x5b1cEB9adcec674552CB26dD55a5E5846712394C;
  address private constant unknownProxyAddress = 0xAED5a268dEE37677584af58CCC2b9e3c83Ab7dd8;

  IUnknownLens private constant unknownLens = IUnknownLens(unknownLensAddress);
  IUnknownProxy private constant unknownProxy = IUnknownProxy(unknownProxyAddress);

  uint256 private constant NATIVE_THRESHOLD = 1 ether / 200; // 0.005 wbnb
  bool public harvestOnDeposit;
  uint256 public lastHarvest;

  event StratHarvest(address indexed harvester, uint256 wantHarvested, uint256 tvl);
  event Deposit(uint256 tvl);
  event Withdraw(uint256 tvl);
  event ChargedFees(uint256 performanceFees, uint256 callFees);

  constructor(
    address _want,
    address _rewardToken0,
    address _rewardToken1,
    address _native,
    address _lpToken0,
    address _lpToken1,
    bool _stable,
    bool _harvestOnDeposit,
    CommonAddresses memory _commonAddresses
  ) StratFeeManager(_commonAddresses) {
    want = _want;
    rewardToken0 = _rewardToken0;
    rewardToken1 = _rewardToken1;
    native = _native;
    lpToken0 = _lpToken0;
    lpToken1 = _lpToken1;
    stable = _stable;
    harvestOnDeposit = _harvestOnDeposit;

    _giveAllowances();
  }

  // puts the funds to work
  function deposit() public whenNotPaused {
    uint256 wantBal = IERC20(want).balanceOf(address(this));

    if (wantBal > 0) {
      unknownProxy.depositLpAndStake(want, wantBal);
      emit Deposit(balanceOf());
    }
  }

  function withdraw(uint256 _amount) external {
    require(msg.sender == vault, "!vault");

    uint256 wantBal = IERC20(want).balanceOf(address(this));

    if (wantBal < _amount) {
      unknownProxy.unstakeLpAndWithdraw(want, _amount - wantBal);
      wantBal = IERC20(want).balanceOf(address(this));
    }

    if (wantBal > _amount) {
      wantBal = _amount;
    }

    IERC20(want).safeTransfer(vault, wantBal);

    emit Withdraw(balanceOf());
  }

  function beforeDeposit() external override {
    if (harvestOnDeposit) {
      require(msg.sender == vault, "!vault");
      _harvest(tx.origin);
    }
  }

  function harvest() external virtual gasThrottle {
    _harvest(tx.origin);
  }

  function harvest(address callFeeRecipient) external virtual gasThrottle {
    _harvest(callFeeRecipient);
  }

  function ownerHarvest() external onlyOwner {
    _harvest(tx.origin);
  }

  // compounds earnings and charges performance fee
  function _harvest(address callFeeRecipient) internal whenNotPaused {
    uint256 lpBalance = balanceOfPool();

    if (lpBalance > 0) {
      address stakingPool = unknownLens.stakingRewardsByConePool(address(want));
      unknownProxy.claimStakingRewards(stakingPool);
    }

    // Get balance of reward tokens
    uint256 reward0Balance = IERC20(rewardToken0).balanceOf(address(this));
    uint256 reward1Balance = IERC20(rewardToken1).balanceOf(address(this));

    // Swap reward tokens for native token
    if (reward0Balance > 0) {
      IRouter(router).swapExactTokensForTokensSimple(
        reward0Balance,
        0,
        rewardToken0,
        native,
        false,
        address(this),
        block.timestamp
      );
    }
    if (reward1Balance > 0) {
      IRouter(router).swapExactTokensForTokensSimple(
        reward1Balance,
        0,
        rewardToken1,
        native,
        false,
        address(this),
        block.timestamp
      );
    }

    uint256 nativeBalance = IERC20(native).balanceOf(address(this));

    if (nativeBalance > NATIVE_THRESHOLD) {
      chargeFees(nativeBalance, callFeeRecipient);
      addLiquidity();
      uint256 wantHarvested = balanceOfWant();
      deposit();

      lastHarvest = block.timestamp;
      emit StratHarvest(msg.sender, wantHarvested, balanceOf());
    }
  }

  // charge performance fee and caller fee
  function chargeFees(uint256 nativeBalance, address callFeeRecipient) internal {
    uint256 nativeBal = (nativeBalance * totalFee) / MAX_FEE;

    uint256 callFeeAmount = (nativeBal * callFee) / MAX_FEE;
    IERC20(native).safeTransfer(callFeeRecipient, callFeeAmount);

    uint256 performanceFeeAmount = (nativeBal * performanceFee) / MAX_FEE;
    IERC20(native).safeTransfer(feeRecipient, performanceFeeAmount);

    emit ChargedFees(performanceFeeAmount, callFeeAmount);
  }

  // Adds liquidity to AMM and gets more LP tokens.
  function addLiquidity() internal {
    uint256 nativeBalance = IERC20(native).balanceOf(address(this));
    uint256 nativeForSwap0 = nativeBalance / 2;
    uint256 nativeForSwap1 = nativeBalance - nativeForSwap0;

    if (stable) {
      uint256 lp0Decimals = 10**IERC20Metadata(lpToken0).decimals();
      uint256 lp1Decimals = 10**IERC20Metadata(lpToken1).decimals();

      uint256 lpToken0Balance = (IERC20(lpToken0).balanceOf(address(this)) * 1e18) / lp0Decimals;
      uint256 lpToken1Balance = (IERC20(lpToken1).balanceOf(address(this)) * 1e18) / lp1Decimals;

      IRouter.Route[] memory routes0 = new IRouter.Route[](1);
      routes0[0] = IRouter.Route({ from: native, to: lpToken0, stable: false });
      uint256 out0 = (IRouter(router).getAmountsOut(nativeForSwap0, routes0)[1] * 1e18) / lp0Decimals;

      IRouter.Route[] memory routes1 = new IRouter.Route[](1);
      routes1[0] = IRouter.Route({ from: native, to: lpToken1, stable: false });
      uint256 out1 = (IRouter(router).getAmountsOut(nativeForSwap1, routes1)[1] * 1e18) / lp1Decimals;

      (uint256 amountA, uint256 amountB, ) = IRouter(router).quoteAddLiquidity(lpToken0, lpToken1, stable, out0, out1);

      amountA = (amountA * 1e18) / lp0Decimals;
      amountB = (amountB * 1e18) / lp1Decimals;
      uint256 ratio = ((((out0 + lpToken0Balance) * 1e18) / (out1 + lpToken1Balance)) * amountB) / amountA;

      nativeForSwap0 = (nativeBalance * 1e18) / (ratio + 1e18);
      nativeForSwap1 = nativeBalance - nativeForSwap0;
    }

    if (lpToken0 != native) {
      IRouter(router).swapExactTokensForTokensSimple(
        nativeForSwap0,
        0,
        native,
        lpToken0,
        false,
        address(this),
        block.timestamp
      );
    }

    if (lpToken1 != native) {
      IRouter(router).swapExactTokensForTokensSimple(
        nativeForSwap1,
        0,
        native,
        lpToken1,
        false,
        address(this),
        block.timestamp
      );
    }

    uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
    uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));

    IRouter(router).addLiquidity(lpToken0, lpToken1, stable, lp0Bal, lp1Bal, 1, 1, address(this), block.timestamp);
  }

  // returns reward unharvested
  function rewardAvailable(address rewardToken) public returns (uint256) {
    address stakingPool = unknownLens.stakingRewardsByConePool(address(want));
    address proxyAddress = unknownLens.userProxyByAccount(address(this));

    return IMultiRewards(stakingPool).earned(proxyAddress, rewardToken);
  }

  // returns rewards unharvested
  function earned() public returns (uint256) {
    uint256 reward0Bal = rewardAvailable(rewardToken0);
    uint256 reward1Bal = rewardAvailable(rewardToken1);

    uint256 nativeOut = 0;
    if (reward0Bal > 0) {
      nativeOut += getRewardAmountOut(reward0Bal, rewardToken0);
    }

    if (reward1Bal > 0) {
      nativeOut += getRewardAmountOut(reward1Bal, rewardToken1);
    }

    return nativeOut;
  }

  // native reward amount for calling harvest
  function callReward() public returns (uint256) {
    uint256 nativeOut = earned();

    return (((nativeOut * totalFee) / MAX_FEE) * callFee) / MAX_FEE;
  }

  function getRewardAmountOut(uint256 balance, address tokenIn) internal view returns (uint256) {
    IRouter.Route[] memory routes = new IRouter.Route[](1);
    routes[0] = IRouter.Route({ from: tokenIn, to: native, stable: false });
    return IRouter(router).getAmountsOut(balance, routes)[1];
  }

  // calculate the total underlaying 'want' held by the strat.
  function balanceOf() public returns (uint256) {
    return balanceOfWant() + balanceOfPool();
  }

  // it calculates how much 'want' this contract holds.
  function balanceOfWant() public view returns (uint256) {
    return IERC20(want).balanceOf(address(this));
  }

  // it calculates how much 'want' the strategy has working in the farm.
  function balanceOfPool() public returns (uint256) {
    address stakingPool = unknownLens.stakingRewardsByConePool(address(want));
    address proxyAddress = unknownLens.userProxyByAccount(address(this));
    uint256 _amount = IERC20(stakingPool).balanceOf(proxyAddress);
    return _amount;
  }

  function setHarvestOnDeposit(bool _harvestOnDeposit) external onlyOwner {
    harvestOnDeposit = _harvestOnDeposit;
  }

  function setShouldGasThrottle(bool _shouldGasThrottle) external onlyOwner {
    shouldGasThrottle = _shouldGasThrottle;
  }

  // called as part of strat migration. Sends all the available funds back to the vault.
  function retireStrat() external {
    require(msg.sender == vault, "!vault");

    unknownProxy.unstakeLpAndWithdraw(want, balanceOfPool());

    uint256 wantBal = IERC20(want).balanceOf(address(this));
    IERC20(want).transfer(vault, wantBal);
  }

  // pauses deposits and withdraws all funds from third party systems.
  function panic() public onlyOwner {
    pause();
    unknownProxy.unstakeLpAndWithdraw(want, balanceOfPool());
  }

  function pause() public onlyOwner {
    _pause();

    _removeAllowances();
  }

  function unpause() external onlyOwner {
    _unpause();

    _giveAllowances();

    deposit();
  }

  function _giveAllowances() internal {
    IERC20(want).safeApprove(unknownProxyAddress, 0);
    IERC20(want).safeApprove(unknownProxyAddress, type(uint256).max);

    IERC20(rewardToken0).safeApprove(router, 0);
    IERC20(rewardToken0).safeApprove(router, type(uint256).max);

    IERC20(rewardToken1).safeApprove(router, 0);
    IERC20(rewardToken1).safeApprove(router, type(uint256).max);

    IERC20(native).safeApprove(router, 0);
    IERC20(native).safeApprove(router, type(uint256).max);

    IERC20(lpToken0).safeApprove(router, 0);
    IERC20(lpToken0).safeApprove(router, type(uint256).max);

    IERC20(lpToken1).safeApprove(router, 0);
    IERC20(lpToken1).safeApprove(router, type(uint256).max);
  }

  function _removeAllowances() internal {
    IERC20(want).safeApprove(unknownProxyAddress, 0);
    IERC20(rewardToken0).safeApprove(router, 0);
    IERC20(rewardToken1).safeApprove(router, 0);
    IERC20(native).safeApprove(router, 0);
    IERC20(lpToken0).safeApprove(router, 0);
    IERC20(lpToken1).safeApprove(router, 0);
  }
}