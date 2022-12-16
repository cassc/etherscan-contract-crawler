// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/
pragma solidity 0.8.4;


import "../../openzeppelin/Math.sol";
import "../../openzeppelin/SafeERC20.sol";
import "./StrategyStorage.sol";
import "../governance/ControllableV2.sol";
import "../interface/IStrategy.sol";
import "../interface/IFeeRewardForwarder.sol";
import "../interface/IBookkeeper.sol";
import "../interface/ISmartVault.sol";
import "../../third_party/uniswap/IUniswapV2Pair.sol";
import "../../third_party/uniswap/IUniswapV2Router02.sol";

/// @title Abstract contract for base strategy functionality
///        Implementation must support proxy
/// @author belbix
abstract contract ProxyStrategyBase is IStrategy, ControllableV2, StrategyStorage {
  using SafeERC20 for IERC20;

  uint internal constant _BUY_BACK_DENOMINATOR = 100_00;
  uint internal constant _TOLERANCE_DENOMINATOR = 1000;

  //************************ MODIFIERS **************************

  /// @dev Only for linked Vault or Governance/Controller.
  ///      Use for functions that should have strict access.
  modifier restricted() {
    require(msg.sender == _vault()
    || msg.sender == address(_controller())
      || IController(_controller()).governance() == msg.sender,
      "SB: Not Gov or Vault");
    _;
  }

  /// @dev Extended strict access with including HardWorkers addresses
  ///      Use for functions that should be called by HardWorkers
  modifier hardWorkers() {
    require(msg.sender == _vault()
    || msg.sender == address(_controller())
    || IController(_controller()).isHardWorker(msg.sender)
      || IController(_controller()).governance() == msg.sender,
      "SB: Not HW or Gov or Vault");
    _;
  }

  /// @dev Allow operation only for Controller
  modifier onlyController() {
    require(_controller() == msg.sender, "SB: Not controller");
    _;
  }

  /// @dev This is only used in `investAllUnderlying()`
  ///      The user can still freely withdraw from the strategy
  modifier onlyNotPausedInvesting() {
    require(!_onPause(), "SB: Paused");
    _;
  }

  /// @notice Initialize contract after setup it as proxy implementation
  /// @param _controller Controller address
  /// @param _underlying Underlying token address
  /// @param _vault SmartVault address that will provide liquidity
  /// @param __rewardTokens Reward tokens that the strategy will farm
  /// @param _bbRatio Buy back ratio
  function initializeStrategyBase(
    address _controller,
    address _underlying,
    address _vault,
    address[] memory __rewardTokens,
    uint _bbRatio
  ) public initializer {
    ControllableV2.initializeControllable(_controller);
    require(ISmartVault(_vault).underlying() == _underlying, "SB: Wrong underlying");
    require(IControllable(_vault).isController(_controller), "SB: Wrong controller");
    _setUnderlying(_underlying);
    _setVault(_vault);
    require(_bbRatio <= _BUY_BACK_DENOMINATOR, "SB: Too high buyback ratio");
    _setBuyBackRatio(_bbRatio);

    // prohibit the movement of tokens that are used in the main logic
    for (uint i = 0; i < __rewardTokens.length; i++) {
      _rewardTokens.push(__rewardTokens[i]);
      _unsalvageableTokens[__rewardTokens[i]] = true;
    }
    _unsalvageableTokens[_underlying] = true;
    _setToleranceNumerator(999);
  }

  // *************** VIEWS ****************

  /// @notice Reward tokens of external project
  /// @return Reward tokens array
  function rewardTokens() external view override returns (address[] memory) {
    return _rewardTokens;
  }

  /// @notice Strategy underlying, the same in the Vault
  /// @return Strategy underlying token
  function underlying() external view override returns (address) {
    return _underlying();
  }

  /// @notice Underlying balance of this contract
  /// @return Balance of underlying token
  function underlyingBalance() external view override returns (uint) {
    return IERC20(_underlying()).balanceOf(address(this));
  }

  /// @notice SmartVault address linked to this strategy
  /// @return Vault address
  function vault() external view override returns (address) {
    return _vault();
  }

  /// @notice Return true for tokens that governance can't touch
  /// @return True if given token unsalvageable
  function unsalvageableTokens(address token) external override view returns (bool) {
    return _unsalvageableTokens[token];
  }

  /// @notice Strategy buy back ratio
  /// @return Buy back ratio
  function buyBackRatio() external view override returns (uint) {
    return _buyBackRatio();
  }

  /// @notice Return underlying balance + balance in the reward pool
  /// @return Sum of underlying balances
  function investedUnderlyingBalance() external override virtual view returns (uint) {
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return _rewardPoolBalance() + IERC20(_underlying()).balanceOf(address(this));
  }

  function rewardPoolBalance() external override view returns (uint) {
    return _rewardPoolBalance();
  }

  /// @dev When this flag is true, the strategy will not be able to invest. But users should be able to withdraw.
  function pausedInvesting() external override view returns (bool) {
    return _onPause();
  }

  //******************** GOVERNANCE *******************


  /// @notice In case there are some issues discovered about the pool or underlying asset
  ///         Governance can exit the pool properly
  ///         The function is only used for emergency to exit the pool
  ///         Pause investing
  function emergencyExit() external override hardWorkers {
    emergencyExitRewardPool();
    _setOnPause(true);
  }

  /// @notice Pause investing into the underlying reward pools
  function pauseInvesting() external override hardWorkers {
    _setOnPause(true);
  }

  /// @notice Resumes the ability to invest into the underlying reward pools
  function continueInvesting() external override restricted {
    _setOnPause(false);
  }

  /// @notice Controller can claim coins that are somehow transferred into the contract
  ///         Note that they cannot come in take away coins that are used and defined in the strategy itself
  /// @param recipient Recipient address
  /// @param recipient Token address
  /// @param recipient Token amount
  function salvage(address recipient, address token, uint amount)
  external override onlyController {
    // To make sure that governance cannot come in and take away the coins
    require(!_unsalvageableTokens[token], "SB: Not salvageable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /// @notice Withdraws all the asset to the vault
  function withdrawAllToVault() external override hardWorkers {
    exitRewardPool();
    IERC20(_underlying()).safeTransfer(_vault(), IERC20(_underlying()).balanceOf(address(this)));
  }

  /// @notice Withdraws some asset to the vault
  /// @param amount Asset amount
  function withdrawToVault(uint amount) external override hardWorkers {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint uBalance = IERC20(_underlying()).balanceOf(address(this));
    if (amount > uBalance) {
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint needToWithdraw = amount - uBalance;
      uint toWithdraw = Math.min(_rewardPoolBalance(), needToWithdraw);
      withdrawAndClaimFromPool(toWithdraw);
    }
    uBalance = IERC20(_underlying()).balanceOf(address(this));
    uint amountAdjusted = Math.min(amount, uBalance);
    require(amountAdjusted > amount * toleranceNumerator() / _TOLERANCE_DENOMINATOR, "SB: Withdrew too low");
    IERC20(_underlying()).safeTransfer(_vault(), amountAdjusted);
  }

  /// @notice Stakes everything the strategy holds into the reward pool
  function investAllUnderlying() external override hardWorkers onlyNotPausedInvesting {
    _investAllUnderlying();
  }

  /// @dev Set withdraw loss tolerance numerator
  function setToleranceNumerator(uint numerator) external restricted {
    require(numerator <= _TOLERANCE_DENOMINATOR, "SB: Too high");
    _setToleranceNumerator(numerator);
  }

  function setBuyBackRatio(uint value) external restricted {
    require(value <= _BUY_BACK_DENOMINATOR, "SB: Too high buyback ratio");
    _setBuyBackRatio(value);
  }

  // ***************** INTERNAL ************************

  /// @notice Balance of given reward token on this contract
  function _rewardBalance(uint rewardTokenIdx) internal view returns (uint) {
    return IERC20(_rewardTokens[rewardTokenIdx]).balanceOf(address(this));
  }

  /// @dev Tolerance to difference between asked and received values on user withdraw action
  ///      Where 0 is full tolerance, and range of 1-999 means how many % of tokens do you expect as minimum
  function toleranceNumerator() internal view virtual returns (uint){
    return _toleranceNumerator();
  }

  /// @notice Stakes everything the strategy holds into the reward pool
  function _investAllUnderlying() internal {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    uint uBalance = IERC20(_underlying()).balanceOf(address(this));
    if (uBalance > 0) {
      depositToPool(uBalance);
    }
  }

  /// @dev Withdraw everything from external pool
  function exitRewardPool() internal virtual {
    uint bal = _rewardPoolBalance();
    if (bal != 0) {
      withdrawAndClaimFromPool(bal);
    }
  }

  /// @dev Withdraw everything from external pool without caring about rewards
  function emergencyExitRewardPool() internal {
    uint bal = _rewardPoolBalance();
    if (bal != 0) {
      emergencyWithdrawFromPool();
    }
  }

  /// @dev Default implementation of liquidation process
  ///      Send all profit to FeeRewardForwarder
  function liquidateRewardDefault() internal {
    _liquidateReward(true);
  }

  function liquidateRewardSilently() internal {
    _liquidateReward(false);
  }

  function _liquidateReward(bool revertOnErrors) internal {
    address forwarder = IController(_controller()).feeRewardForwarder();
    uint targetTokenEarnedTotal = 0;
    for (uint i = 0; i < _rewardTokens.length; i++) {
      address rt = _rewardTokens[i];
      uint amount = IERC20(rt).balanceOf(address(this));
      if (amount != 0) {
        IERC20(rt).safeApprove(forwarder, 0);
        IERC20(rt).safeApprove(forwarder, amount);
        // it will sell reward token to Target Token and distribute it to SmartVault and PS
        uint targetTokenEarned = 0;
        if (revertOnErrors) {
          targetTokenEarned = IFeeRewardForwarder(forwarder).distribute(amount, rt, _vault());
        } else {
          //slither-disable-next-line unused-return,variable-scope,uninitialized-local
          try IFeeRewardForwarder(forwarder).distribute(amount, rt, _vault()) returns (uint r) {
            targetTokenEarned = r;
          } catch {}
        }
        targetTokenEarnedTotal += targetTokenEarned;
      }
    }
    if (targetTokenEarnedTotal > 0) {
      IBookkeeper(IController(_controller()).bookkeeper()).registerStrategyEarned(targetTokenEarnedTotal);
    }
  }

  /// @dev Liquidate rewards and buy underlying asset
  function autocompound() internal {
    address forwarder = IController(_controller()).feeRewardForwarder();
    for (uint i = 0; i < _rewardTokens.length; i++) {
      address rt = _rewardTokens[i];
      uint amount = IERC20(rt).balanceOf(address(this));
      if (amount != 0) {
        uint toCompound = amount * (_BUY_BACK_DENOMINATOR - _buyBackRatio()) / _BUY_BACK_DENOMINATOR;
        IERC20(rt).safeApprove(forwarder, 0);
        IERC20(rt).safeApprove(forwarder, toCompound);
        IFeeRewardForwarder(forwarder).liquidate(rt, _underlying(), toCompound);
      }
    }
  }

  /// @dev Default implementation of auto-compounding for swap pairs
  ///      Liquidate rewards, buy assets and add to liquidity pool
  function autocompoundLP(address _router) internal {
    address forwarder = IController(_controller()).feeRewardForwarder();
    for (uint i = 0; i < _rewardTokens.length; i++) {
      address rt = _rewardTokens[i];
      uint amount = IERC20(rt).balanceOf(address(this));
      if (amount != 0) {
        uint toCompound = amount * (_BUY_BACK_DENOMINATOR - _buyBackRatio()) / _BUY_BACK_DENOMINATOR;
        IERC20(rt).safeApprove(forwarder, 0);
        IERC20(rt).safeApprove(forwarder, toCompound);

        IUniswapV2Pair pair = IUniswapV2Pair(_underlying());
        if (rt != pair.token0()) {
          uint token0Amount = IFeeRewardForwarder(forwarder).liquidate(rt, pair.token0(), toCompound / 2);
          require(token0Amount != 0, "SB: Token0 zero amount");
        }
        if (rt != pair.token1()) {
          uint token1Amount = IFeeRewardForwarder(forwarder).liquidate(rt, pair.token1(), toCompound / 2);
          require(token1Amount != 0, "SB: Token1 zero amount");
        }
        addLiquidity(_underlying(), _router);
      }
    }
  }

  /// @dev Add all available tokens to given pair
  function addLiquidity(address _pair, address _router) internal {
    IUniswapV2Router02 router = IUniswapV2Router02(_router);
    IUniswapV2Pair pair = IUniswapV2Pair(_pair);
    address _token0 = pair.token0();
    address _token1 = pair.token1();

    uint amount0 = IERC20(_token0).balanceOf(address(this));
    uint amount1 = IERC20(_token1).balanceOf(address(this));

    IERC20(_token0).safeApprove(_router, 0);
    IERC20(_token0).safeApprove(_router, amount0);
    IERC20(_token1).safeApprove(_router, 0);
    IERC20(_token1).safeApprove(_router, amount1);
    //slither-disable-next-line unused-return
    router.addLiquidity(
      _token0,
      _token1,
      amount0,
      amount1,
      1,
      1,
      address(this),
      block.timestamp
    );
  }

  //******************** VIRTUAL *********************
  // This functions should be implemented in the strategy contract

  function _rewardPoolBalance() internal virtual view returns (uint);

  //slither-disable-next-line dead-code
  function depositToPool(uint amount) internal virtual;

  //slither-disable-next-line dead-code
  function withdrawAndClaimFromPool(uint amount) internal virtual;

  //slither-disable-next-line dead-code
  function emergencyWithdrawFromPool() internal virtual;

  //slither-disable-next-line dead-code
  function liquidateReward() internal virtual;

}