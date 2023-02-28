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

import "../../openzeppelin/SafeERC20.sol";
import "../../openzeppelin/Math.sol";
import "../../openzeppelin/ReentrancyGuard.sol";
import "../governance/Controllable.sol";
import "../interface/IStrategy.sol";
import "../interface/ISmartVault.sol";
import "../interface/IStrategySplitter.sol";
import "./StrategySplitterStorage.sol";
import "../ArrayLib.sol";

/// @title Proxy solution for connection a vault with multiple strategies
/// @dev Should be used with TetuProxyControlled.sol
/// @author belbix
contract StrategySplitter is Controllable, IStrategy, StrategySplitterStorage, IStrategySplitter, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using ArrayLib for address[];

  // ************ VARIABLES **********************
  /// @notice Strategy type for statistical purposes
  string public constant override STRATEGY_NAME = "StrategySplitter";
  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant VERSION = "1.0.1";
  uint internal constant _PRECISION = 1e18;
  uint public constant STRATEGY_RATIO_DENOMINATOR = 100;
  uint public constant WITHDRAW_REQUEST_TIMEOUT = 1 hours;
  uint internal constant _MIN_OP = 1;

  address[] public override strategies;
  mapping(address => uint) public override strategiesRatios;
  mapping(address => uint) public override withdrawRequestsCalls;

  // ***************** EVENTS ********************
  event StrategyAdded(address strategy);
  event StrategyRemoved(address strategy);
  event StrategyRatioChanged(address strategy, uint ratio);
  event RequestWithdraw(address user, uint amount, uint time);
  event Salvage(address recipient, address token, uint256 amount);
  event RebalanceAll(uint underlyingBalance, uint strategiesBalancesSum);
  event Rebalance(address strategy);

  /// @notice Initialize contract after setup it as proxy implementation
  /// @dev Use it only once after first logic setup
  ///      Initialize Controllable with sender address
  function initialize(
    address _controller,
    address _underlying,
    address __vault
  ) external initializer {
    Controllable.initializeControllable(_controller);
    _setUnderlying(_underlying);
    _setVault(__vault);
  }

  // ******************** MODIFIERS ****************************

  /// @dev Only for linked Vault or Governance/Controller.
  ///      Use for functions that should have strict access.
  modifier restricted() {
    require(msg.sender == _vault()
    || msg.sender == address(controller())
      || isGovernance(msg.sender),
      "SS: Not Gov or Vault");
    _;
  }

  /// @dev Extended strict access with including HardWorkers addresses
  ///      Use for functions that should be called by HardWorkers
  modifier hardWorkers() {
    require(msg.sender == _vault()
    || msg.sender == address(controller())
    || IController(controller()).isHardWorker(msg.sender)
      || isGovernance(msg.sender),
      "SS: Not HW or Gov or Vault");
    _;
  }

  // ******************** SPLITTER SPECIFIC LOGIC ****************************

  /// @dev Add new managed strategy. Should be an uniq address.
  ///      Strategy should have the same underlying with current contract.
  ///      The new strategy will have zero rate. Need to setup correct rate later.
  function addStrategy(address _strategy) external override onlyController {
    _addStrategy(_strategy);
  }

  function _addStrategy(address _strategy) internal {
    require(IStrategy(_strategy).underlying() == _underlying(), "SS: Wrong underlying");
    strategies.addUnique(_strategy);
    emit StrategyAdded(_strategy);
  }

  /// @dev Remove given strategy, reset the ratio and withdraw all underlying to this contract
  function removeStrategy(address _strategy) external override onlyControllerOrGovernance {
    require(strategies.length > 1, "SS: Can't remove last strategy");
    strategies.findAndRemove(_strategy, true);
    uint ratio = strategiesRatios[_strategy];
    strategiesRatios[_strategy] = 0;
    if (ratio != 0) {
      address strategyWithHighestRatio = strategies[0];
      strategiesRatios[strategyWithHighestRatio] = ratio + strategiesRatios[strategyWithHighestRatio];
      strategies.sortAddressesByUintReverted(strategiesRatios);
    }
    IERC20(_underlying()).safeApprove(_strategy, 0);
    // for expensive strategies should be called before removing
    IStrategy(_strategy).withdrawAllToVault();
    emit StrategyRemoved(_strategy);
  }

  function setStrategyRatios(address[] memory _strategies, uint[] memory _ratios) external override hardWorkers {
    require(_strategies.length == strategies.length, "SS: Wrong input strategies");
    require(_strategies.length == _ratios.length, "SS: Wrong input arrays");
    uint sum;
    for (uint i; i < _strategies.length; i++) {
      bool exist = false;
      for (uint j; j < strategies.length; j++) {
        if (strategies[j] == _strategies[i]) {
          exist = true;
          break;
        }
      }
      require(exist, "SS: Strategy not exist");
      sum += _ratios[i];
      strategiesRatios[_strategies[i]] = _ratios[i];
      emit StrategyRatioChanged(_strategies[i], _ratios[i]);
    }
    require(sum == STRATEGY_RATIO_DENOMINATOR, "SS: Wrong sum");

    // sorting strategies by ratios
    strategies.sortAddressesByUintReverted(strategiesRatios);
  }

  /// @dev It is a little trick how to determinate was strategy fully initialized or not.
  ///      When we add strategies we don't setup ratios immediately.
  ///      Strategy ratios if setup once the sum must be equal to denominator.
  ///      It means zero sum of ratios will indicate that this contract was never initialized.
  ///      Until we setup ratios we able to add strategies without time-lock.
  function strategiesInited() external view override returns (bool) {
    uint sum;
    for (uint i; i < strategies.length; i++) {
      sum += strategiesRatios[strategies[i]];
    }
    return sum == STRATEGY_RATIO_DENOMINATOR;
  }

  // *************** STRATEGY GOVERNANCE ACTIONS **************

  /// @dev Try to withdraw all from all strategies. May be too expensive to handle in one tx
  function withdrawAllToVault() external override hardWorkers {
    for (uint i = 0; i < strategies.length; i++) {
      IStrategy(strategies[i]).withdrawAllToVault();
    }
    transferAllUnderlyingToVault();
  }

  /// @dev We can't call emergency exit on strategies
  ///      Transfer all available tokens to the vault
  function emergencyExit() external override restricted {
    transferAllUnderlyingToVault();
    _setOnPause(1);
  }

  /// @dev Cascade withdraw from strategies start from with higher ratio until reach the target amount.
  ///      For large amounts with multiple strategies may not be possible to process this function.
  function withdrawToVault(uint256 amount) external override hardWorkers {
    uint uBalance = IERC20(_underlying()).balanceOf(address(this));
    if (uBalance < amount) {
      for (uint i; i < strategies.length; i++) {
        IStrategy strategy = IStrategy(strategies[i]);
        uint strategyBalance = strategy.investedUnderlyingBalance();
        if (strategyBalance <= amount) {
          strategy.withdrawAllToVault();
        } else {
          if (amount > _MIN_OP) {
            strategy.withdrawToVault(amount);
          }
        }
        uBalance = IERC20(_underlying()).balanceOf(address(this));
        if (uBalance >= amount) {
          break;
        }
      }
    }
    transferAllUnderlyingToVault();
  }

  /// @dev User may indicate that he wants to withdraw given amount
  ///      We will try to transfer given amount to this contract in a separate transaction
  function requestWithdraw(uint _amount) external nonReentrant {
    uint lastRequest = withdrawRequestsCalls[msg.sender];
    if (lastRequest != 0) {
      // anti-spam protection
      require(lastRequest + WITHDRAW_REQUEST_TIMEOUT < block.timestamp, "SS: Request timeout");
    }
    uint userBalance = ISmartVault(_vault()).underlyingBalanceWithInvestmentForHolder(msg.sender);
    // add 10 for avoid rounding troubles
    require(_amount <= userBalance + 10, "SS: You want too much");
    uint want = _wantToWithdraw() + _amount;
    // add 10 for avoid rounding troubles
    require(want <= _investedUnderlyingBalance() + 10, "SS: Want more than balance");
    _setWantToWithdraw(want);

    withdrawRequestsCalls[msg.sender] = block.timestamp;
    emit RequestWithdraw(msg.sender, _amount, block.timestamp);
  }

  /// @dev User can try to withdraw requested amount from the first eligible strategy.
  ///      In case of big request should be called multiple time
  function processWithdrawRequests() external nonReentrant {
    uint balance = IERC20(_underlying()).balanceOf(address(this));
    uint want = _wantToWithdraw();
    if (balance >= want) {
      // already have enough balance
      _setWantToWithdraw(0);
      return;
    }
    // we should not want to withdraw more than we have
    // _investedUnderlyingBalance always higher than balance
    uint wantAdjusted = Math.min(want, _investedUnderlyingBalance()) - balance;
    for (uint i; i < strategies.length; i++) {
      IStrategy _strategy = IStrategy(strategies[i]);
      uint strategyBalance = _strategy.investedUnderlyingBalance();
      if (strategyBalance == 0) {
        // suppose we withdrew all in previous calls
        continue;
      }
      if (strategyBalance > wantAdjusted) {
        if (wantAdjusted > _MIN_OP) {
          _strategy.withdrawToVault(wantAdjusted);
        }
      } else {
        // we don't have enough amount in this strategy
        // withdraw all and call this function again
        _strategy.withdrawAllToVault();
      }
      // withdraw only from 1 eligible strategy
      break;
    }

    // update want to withdraw
    if (IERC20(_underlying()).balanceOf(address(this)) >= want) {
      _setWantToWithdraw(0);
    }
  }

  /// @dev Transfer token to recipient if it is not in forbidden list
  function salvage(address recipient, address token, uint256 amount) external override onlyController {
    require(token != _underlying(), "SS: Not salvageable");
    // To make sure that governance cannot come in and take away the coins
    for (uint i = 0; i < strategies.length; i++) {
      require(!IStrategy(strategies[i]).unsalvageableTokens(token), "SS: Not salvageable");
    }
    IERC20(token).safeTransfer(recipient, amount);
    emit Salvage(recipient, token, amount);
  }

  /// @dev Expensive call, probably will need to call each strategy in separated txs
  function doHardWork() external override hardWorkers {
    for (uint i = 0; i < strategies.length; i++) {
      IStrategy(strategies[i]).doHardWork();
    }
  }

  /// @dev Don't invest for keeping tx cost cheap
  ///      Need to call rebalance after this
  function investAllUnderlying() external override hardWorkers {
    _setNeedRebalance(1);
  }

  /// @dev Rebalance all strategies in one tx
  ///      Require a lot of gas and should be used carefully
  ///      In case of huge gas cost use rebalance for each strategy separately
  function rebalanceAll() external hardWorkers {
    require(_onPause() == 0, "SS: Paused");
    _setNeedRebalance(0);
    // collect balances sum
    uint _underlyingBalance = IERC20(_underlying()).balanceOf(address(this));
    uint _strategiesBalancesSum = _underlyingBalance;
    for (uint i = 0; i < strategies.length; i++) {
      _strategiesBalancesSum += IStrategy(strategies[i]).investedUnderlyingBalance();
    }
    if (_strategiesBalancesSum == 0) {
      return;
    }
    // rebalance only strategies requires withdraw
    // it will move necessary amount to this contract
    for (uint i = 0; i < strategies.length; i++) {
      uint _ratio = strategiesRatios[strategies[i]] * _PRECISION;
      if (_ratio == 0) {
        continue;
      }
      uint _strategyBalance = IStrategy(strategies[i]).investedUnderlyingBalance();
      uint _currentRatio = _strategyBalance * _PRECISION * STRATEGY_RATIO_DENOMINATOR / _strategiesBalancesSum;
      if (_currentRatio > _ratio) {
        // not necessary update underlying balance for withdraw
        _rebalanceCall(strategies[i], _strategiesBalancesSum, _strategyBalance, _ratio);
      }
    }

    // rebalance only strategies requires deposit
    for (uint i = 0; i < strategies.length; i++) {
      uint _ratio = strategiesRatios[strategies[i]] * _PRECISION;
      if (_ratio == 0) {
        continue;
      }
      uint _strategyBalance = IStrategy(strategies[i]).investedUnderlyingBalance();
      uint _currentRatio = _strategyBalance * _PRECISION * STRATEGY_RATIO_DENOMINATOR / _strategiesBalancesSum;
      if (_currentRatio < _ratio) {
        _rebalanceCall(
          strategies[i],
          _strategiesBalancesSum,
          _strategyBalance,
          _ratio
        );
      }
    }
    emit RebalanceAll(_underlyingBalance, _strategiesBalancesSum);
  }

  /// @dev External function for calling rebalance for exact strategy
  ///      Strategies that need withdraw action should be called first
  function rebalance(address _strategy) external hardWorkers {
    require(_onPause() == 0, "SS: Paused");
    _setNeedRebalance(0);
    _rebalance(_strategy);
    emit Rebalance(_strategy);
  }

  /// @dev Deposit or withdraw from given strategy according the strategy ratio
  ///      Should be called from EAO with multiple off-chain steps
  function _rebalance(address _strategy) internal {
    // normalize ratio to 18 decimals
    uint _ratio = strategiesRatios[_strategy] * _PRECISION;
    // in case of unknown strategy will be reverted here
    require(_ratio != 0, "SS: Zero ratio strategy");
    uint _strategyBalance;
    uint _strategiesBalancesSum = IERC20(_underlying()).balanceOf(address(this));
    // collect strategies balances sum with some tricks for gas optimisation
    for (uint i = 0; i < strategies.length; i++) {
      uint balance = IStrategy(strategies[i]).investedUnderlyingBalance();
      if (strategies[i] == _strategy) {
        _strategyBalance = balance;
      }
      _strategiesBalancesSum += balance;
    }

    _rebalanceCall(_strategy, _strategiesBalancesSum, _strategyBalance, _ratio);
  }

  ///@dev Deposit or withdraw from strategy
  function _rebalanceCall(
    address _strategy,
    uint _strategiesBalancesSum,
    uint _strategyBalance,
    uint _ratio
  ) internal {
    uint _currentRatio = _strategyBalance * _PRECISION * STRATEGY_RATIO_DENOMINATOR / _strategiesBalancesSum;
    if (_currentRatio < _ratio) {
      // Need to deposit to the strategy.
      // We are calling investAllUnderlying() because we anyway will spend similar gas
      // in case of withdraw, and we can't predict what will need.
      uint needToDeposit = _strategiesBalancesSum * (_ratio - _currentRatio) / (STRATEGY_RATIO_DENOMINATOR * _PRECISION);
      uint _underlyingBalance = IERC20(_underlying()).balanceOf(address(this));
      needToDeposit = Math.min(needToDeposit, _underlyingBalance);
      //      require(_underlyingBalance >= needToDeposit, "SS: Not enough splitter balance");
      if (needToDeposit > _MIN_OP) {
        IERC20(_underlying()).safeTransfer(_strategy, needToDeposit);
        IStrategy(_strategy).investAllUnderlying();
      }
    } else if (_currentRatio > _ratio) {
      // withdraw from strategy excess value
      uint needToWithdraw = _strategiesBalancesSum * (_currentRatio - _ratio) / (STRATEGY_RATIO_DENOMINATOR * _PRECISION);
      needToWithdraw = Math.min(needToWithdraw, _strategyBalance);
      //      require(_strategyBalance >= needToWithdraw, "SS: Not enough strat balance");
      if (needToWithdraw > _MIN_OP) {
        IStrategy(_strategy).withdrawToVault(needToWithdraw);
      }
    }
  }

  /// @dev Change rebalance marker
  function setNeedRebalance(uint _value) external hardWorkers {
    require(_value < 2, "SS: Wrong value");
    _setNeedRebalance(_value);
  }

  /// @dev Stop deposit to strategies
  function pauseInvesting() external override restricted {
    _setOnPause(1);
  }

  /// @dev Continue deposit to strategies
  function continueInvesting() external override restricted {
    _setOnPause(0);
  }

  function transferAllUnderlyingToVault() internal {
    uint balance = IERC20(_underlying()).balanceOf(address(this));
    if (balance > 0) {
      IERC20(_underlying()).safeTransfer(_vault(), balance);
    }
  }

  // **************** VIEWS ***************

  /// @dev Return array of reward tokens collected across all strategies.
  ///      Has random sorting
  function strategyRewardTokens() external view override returns (address[] memory) {
    return _strategyRewardTokens();
  }

  function _strategyRewardTokens() internal view returns (address[] memory) {
    address[] memory rts = new address[](20);
    uint size = 0;
    for (uint i = 0; i < strategies.length; i++) {
      address[] memory strategyRts;
      if (IStrategy(strategies[i]).platform() == IStrategy.Platform.STRATEGY_SPLITTER) {
        strategyRts = IStrategySplitter(strategies[i]).strategyRewardTokens();
      } else {
        strategyRts = IStrategy(strategies[i]).rewardTokens();
      }
      for (uint j = 0; j < strategyRts.length; j++) {
        address rt = strategyRts[j];
        bool exist = false;
        for (uint k = 0; k < rts.length; k++) {
          if (rts[k] == rt) {
            exist = true;
            break;
          }
        }
        if (!exist) {
          rts[size] = rt;
          size++;
        }
      }
    }
    address[] memory result = new address[](size);
    for (uint i = 0; i < size; i++) {
      result[i] = rts[i];
    }
    return result;
  }

  /// @dev Underlying token. Should be the same for all controlled strategies
  function underlying() external view override returns (address) {
    return _underlying();
  }

  /// @dev Splitter underlying balance
  function underlyingBalance() external view override returns (uint256){
    return IERC20(_underlying()).balanceOf(address(this));
  }

  /// @dev Return strategies balances. Doesn't include splitter underlying balance
  function rewardPoolBalance() external view override returns (uint256) {
    uint balance;
    for (uint i = 0; i < strategies.length; i++) {
      balance += IStrategy(strategies[i]).investedUnderlyingBalance();
    }
    return balance;
  }

  /// @dev Return average buyback ratio
  function buyBackRatio() external view override returns (uint256) {
    uint bbRatio = 0;
    for (uint i = 0; i < strategies.length; i++) {
      bbRatio += IStrategy(strategies[i]).buyBackRatio();
    }
    bbRatio = bbRatio / strategies.length;
    return bbRatio;
  }

  /// @dev Check unsalvageable tokens across all strategies
  function unsalvageableTokens(address token) external view override returns (bool) {
    for (uint i = 0; i < strategies.length; i++) {
      if (IStrategy(strategies[i]).unsalvageableTokens(token)) {
        return true;
      }
    }
    return false;
  }

  /// @dev Connected vault to this splitter
  function vault() external view override returns (address) {
    return _vault();
  }

  /// @dev Return a sum of all balances under control. Should be accurate - it will be used in the vault
  function investedUnderlyingBalance() external view override returns (uint256) {
    return _investedUnderlyingBalance();
  }

  function _investedUnderlyingBalance() internal view returns (uint256) {
    uint balance = IERC20(_underlying()).balanceOf(address(this));
    for (uint i = 0; i < strategies.length; i++) {
      balance += IStrategy(strategies[i]).investedUnderlyingBalance();
    }
    return balance;
  }

  /// @dev Splitter has specific hardcoded platform
  function platform() external pure override returns (Platform) {
    return Platform.STRATEGY_SPLITTER;
  }

  /// @dev Assume that we will use this contract only for single token vaults
  function assets() external view override returns (address[] memory) {
    address[] memory result = new address[](1);
    result[0] = _underlying();
    return result;
  }

  /// @dev Paused investing in strategies
  function pausedInvesting() external view override returns (bool) {
    return _onPause() == 1;
  }

  /// @dev Return ready to claim rewards array
  function readyToClaim() external view override returns (uint256[] memory) {
    uint[] memory rewards = new uint[](20);
    address[] memory rts = new address[](20);
    uint size = 0;
    for (uint i = 0; i < strategies.length; i++) {
      address[] memory strategyRts;
      if (IStrategy(strategies[i]).platform() == IStrategy.Platform.STRATEGY_SPLITTER) {
        strategyRts = IStrategySplitter(strategies[i]).strategyRewardTokens();
      } else {
        strategyRts = IStrategy(strategies[i]).rewardTokens();
      }

      uint[] memory strategyReadyToClaim = IStrategy(strategies[i]).readyToClaim();
      // don't count, better to skip than ruin
      if (strategyRts.length != strategyReadyToClaim.length) {
        continue;
      }
      for (uint j = 0; j < strategyRts.length; j++) {
        address rt = strategyRts[j];
        bool exist = false;
        for (uint k = 0; k < rts.length; k++) {
          if (rts[k] == rt) {
            exist = true;
            rewards[k] += strategyReadyToClaim[j];
            break;
          }
        }
        if (!exist) {
          rts[size] = rt;
          rewards[size] = strategyReadyToClaim[j];
          size++;
        }
      }
    }
    uint[] memory result = new uint[](size);
    for (uint i = 0; i < size; i++) {
      result[i] = rewards[i];
    }
    return result;
  }

  /// @dev Return sum of strategies poolTotalAmount values
  function poolTotalAmount() external view override returns (uint256) {
    uint balance = 0;
    for (uint i = 0; i < strategies.length; i++) {
      balance += IStrategy(strategies[i]).poolTotalAmount();
    }
    return balance;
  }

  /// @dev Positive value indicate that this splitter should be rebalanced.
  function needRebalance() external view override returns (uint) {
    return _needRebalance();
  }

  /// @dev Sum of users requested values
  function wantToWithdraw() external view override returns (uint) {
    return _wantToWithdraw();
  }

  /// @dev Return maximum available balance to withdraw without calling more than 1 strategy
  function maxCheapWithdraw() external view override returns (uint) {
    uint strategyBalance;
    if (strategies.length != 0) {
      if (IStrategy(strategies[0]).platform() == IStrategy.Platform.STRATEGY_SPLITTER) {
        strategyBalance = IStrategySplitter(strategies[0]).maxCheapWithdraw();
      } else {
        strategyBalance = IStrategy(strategies[0]).investedUnderlyingBalance();
      }
    }
    return strategyBalance
    + IERC20(_underlying()).balanceOf(address(this))
    + IERC20(_underlying()).balanceOf(_vault());
  }

  /// @dev Length of strategy array
  function strategiesLength() external view override returns (uint) {
    return strategies.length;
  }

  /// @dev Returns strategy array
  function allStrategies() external view override returns (address[] memory) {
    return strategies;
  }

  // **********************************************
  // *********** VAULT FUNCTIONS ******************
  // ****** Simulate vault behaviour **************
  // **********************************************

  /// @dev Transfer tokens from sender and call the vault notify function.
  function notifyTargetRewardAmount(address _rewardToken, uint _amount) external {
    require(IController(controller()).isRewardDistributor(msg.sender), "SS: Only distributor");
    IERC20(_rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
    IERC20(_rewardToken).safeApprove(_vault(), 0);
    IERC20(_rewardToken).safeApprove(_vault(), _amount);
    return ISmartVault(_vault()).notifyTargetRewardAmount(_rewardToken, _amount);
  }

  /// @dev Simulate vault behaviour - returns PPFS for of the vault
  function getPricePerFullShare() external view returns (uint256) {
    return ISmartVault(_vault()).getPricePerFullShare();
  }

  /// @dev Simulate vault behaviour - returns vault underlying uint
  function underlyingUnit() external view returns (uint256) {
    return ISmartVault(_vault()).underlyingUnit();
  }

  /// @dev Simulate vault behaviour - returns vault total supply
  function totalSupply() external view returns (uint256) {
    return IERC20(_vault()).totalSupply();
  }

  /// @dev !!! THIS FUNCTION HAS CONFLICT WITH STRATEGY INTERFACE !!!
  ///      We are implementing vault functionality. Don't use strategy rewardTokens() anywhere
  function rewardTokens() external view override returns (address[] memory) {
    return ISmartVault(_vault()).rewardTokens();
  }

  /// @dev Simulate vault behaviour - returns the whole balance of the vault
  function underlyingBalanceWithInvestment() external view returns (uint256) {
    return ISmartVault(_vault()).underlyingBalanceWithInvestment();
  }

  /// @dev Simulate vault behaviour - returns the whole user balance in underlying units
  function underlyingBalanceWithInvestmentForHolder(address holder)
  external view returns (uint256) {
    return ISmartVault(_vault()).underlyingBalanceWithInvestmentForHolder(holder);
  }

}