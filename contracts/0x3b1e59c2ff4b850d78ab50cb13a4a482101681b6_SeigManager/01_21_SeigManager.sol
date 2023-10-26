// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IRefactor } from "../interfaces/IRefactor.sol";
import { DSMath } from "../../libraries/DSMath.sol";
import { RefactorCoinageSnapshotI } from "../interfaces/RefactorCoinageSnapshotI.sol";
import { CoinageFactoryI } from "../../dao/interfaces/CoinageFactoryI.sol";
import { IWTON } from "../../dao/interfaces/IWTON.sol";
import { Layer2I } from "../../dao/interfaces/Layer2I.sol";
import { SeigManagerI } from "../interfaces/SeigManagerI.sol";

import "../../proxy/ProxyStorage.sol";
import { AuthControlSeigManager } from "../../common/AuthControlSeigManager.sol";
import { SeigManagerStorage } from "./SeigManagerStorage.sol";

interface MinterRoleRenounceTarget {
  function renounceMinter() external;
}

interface PauserRoleRenounceTarget {
  function renouncePauser() external;
}

interface OwnableTarget {
  function renounceOwnership() external;
  function transferOwnership(address newOwner) external;
}

interface IILayer2Registry {
  function layer2s(address layer2) external view returns (bool);
  function numLayer2s() external view  returns (uint256);
  function layer2ByIndex(uint256 index) external view returns (address);
}

interface IPowerTON {
  function updateSeigniorage(uint256 amount) external;
}

interface ITON {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
}

interface IRefactorCoinageSnapshot {
  function snapshot() external returns (uint256 id);
}

interface ICandidate {
  function updateSeigniorage() external returns (bool);
}
/**
 * @dev SeigManager gives seigniorage to operator and WTON holders.
 * For each commit by operator, operator (or user) will get seigniorage
 * in propotion to the staked (or delegated) amount of WTON.
 *
 * [Tokens]
 * - {tot} tracks total staked or delegated WTON of each Layer2 contract (and depositor?).
 * - {coinages[layer2]} tracks staked or delegated WTON of user or operator to a Layer2 contract.
 *
 * For each commit by operator,
 *  1. increases all layer2's balance of {tot} by (the staked amount of WTON) /
 *     (total supply of TON and WTON) * (num blocks * seigniorage per block).
 *  2. increases all depositors' blanace of {coinages[layer2]} in proportion to the staked amount of WTON,
 *     up to the increased amount in step (1).
 *  3. set the layer2's balance of {committed} as the layer2's {tot} balance.
 *
 * For each stake or delegate with amount of {v} to a Layer2,
 *  1. mint {v} {coinages[layer2]} tokens to the account
 *  2. mint {v} {tot} tokens to the layer2 contract
 *
 * For each unstake or undelegate (or get rewards) with amount of {v} to a Layer2,
 *  1. burn {v} {coinages[layer2]} tokens from the account
 *  2. burn {v + ⍺} {tot} tokens from the layer2 contract,
 *   where ⍺ = SEIGS * staked ratio of the layer2 * withdrawal ratio of the account
 *     - SEIGS                              = tot total supply - tot total supply at last commit from the layer2
 *     - staked ratio of the layer2     = tot balance of the layer2 / tot total supply
 *     - withdrawal ratio of the account  = amount to withdraw / total supply of coinage
 *
 */
contract SeigManager is ProxyStorage, AuthControlSeigManager, SeigManagerStorage, SeigManagerI, DSMath {

  //////////////////////////////
  // Modifiers
  //////////////////////////////

  modifier onlyRegistry() {
    require(msg.sender == _registry, "not onlyRegistry");
    _;
  }

  modifier onlyRegistryOrOperator(address layer2) {
    require(msg.sender == _registry || msg.sender == Layer2I(layer2).operator(), "not onlyRegistryOrOperator");
    _;
  }

  modifier onlyDepositManager() {
    require(msg.sender == _depositManager, "not onlyDepositManager");
    _;
  }

  modifier onlyLayer2(address layer2) {
    require(IILayer2Registry(_registry).layer2s(layer2), "not onlyLayer2");
    _;
  }

  modifier checkCoinage(address layer2) {
    require(address(_coinages[layer2]) != address(0), "SeigManager: coinage has not been deployed yet");
    _;
  }

  modifier whenNotPaused() {
      require(!paused, "Pausable: paused");
      _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
      require(paused, "Pausable: not paused");
      _;
  }


  //////////////////////////////
  // Events
  //////////////////////////////

  event CoinageCreated(address indexed layer2, address coinage);
  event SeigGiven(address indexed layer2, uint256 totalSeig, uint256 stakedSeig, uint256 unstakedSeig, uint256 powertonSeig, uint256 daoSeig, uint256 pseig);
  event Comitted(address indexed layer2);
  event CommissionRateSet(address indexed layer2, uint256 previousRate, uint256 newRate);
  event Paused(address account);
  event Unpaused(address account);

  // DEV ONLY
  event UnstakeLog(uint coinageBurnAmount, uint totBurnAmount);
  event AddedSeigAtLayer(address layer2, uint256 seigs, uint256 operatorSeigs, uint256 nextTotalSupply, uint256 prevTotalSupply);
  event OnSnapshot(uint256 snapshotId);

  event SetPowerTONSeigRate(uint256 powerTONSeigRate);
  event SetDaoSeigRate(uint256 daoSeigRate);
  event SetPseigRate(uint256 pseigRate);
  //////////////////////////////
  // Constuctor
  //////////////////////////////

  function initialize (
    address ton_,
    address wton_,
    address registry_,
    address depositManager_,
    uint256 seigPerBlock_,
    address factory_,
    uint256 lastSeigBlock_
  ) external {
    require(_ton == address(0) && _lastSeigBlock == 0, "already initialized");

    _ton = ton_;
    _wton = wton_;
    _registry = registry_;
    _depositManager = depositManager_;
    _seigPerBlock = seigPerBlock_;

    factory = factory_;
    address c = CoinageFactoryI(factory).deploy();
    require(c != address(0), "zero tot");
    _tot = RefactorCoinageSnapshotI(c);

    _lastSeigBlock = lastSeigBlock_;
  }

  //////////////////////////////
  // Pausable
  //////////////////////////////

  function pause() public onlyPauser whenNotPaused {
    _pausedBlock = block.number;
    paused = true;
    emit Paused(msg.sender);
  }

  /**
   * @dev Called by a pauser to unpause, returns to normal state.
   */
  function unpause() public onlyPauser whenPaused {
    _unpausedBlock = block.number;
    paused = false;
    emit Unpaused(msg.sender);
  }


  //////////////////////////////
  // onlyOwner
  //////////////////////////////

  function setData(
      address powerton_,
      address daoAddress,
      uint256 powerTONSeigRate_,
      uint256 daoSeigRate_,
      uint256 relativeSeigRate_,
      uint256 adjustDelay_,
      uint256 minimumAmount_
  ) external onlyOwner {
    require(
      powerTONSeigRate + daoSeigRate + relativeSeigRate <= RAY, "exceeded seigniorage rate"
    );
    _powerton = powerton_;
    dao = daoAddress;
    powerTONSeigRate = powerTONSeigRate_;
    daoSeigRate = daoSeigRate_;
    relativeSeigRate = relativeSeigRate_;
    adjustCommissionDelay = adjustDelay_;
    minimumAmount = minimumAmount_;

    emit SetPowerTONSeigRate (powerTONSeigRate_);
    emit SetDaoSeigRate (daoSeigRate_) ;
    emit SetDaoSeigRate (daoSeigRate_) ;
  }

  function setPowerTON(address powerton_) external onlyOwner {
    _powerton = powerton_;
  }

  function setDao(address daoAddress) external onlyOwner {
    dao = daoAddress;
  }

  function setPowerTONSeigRate(uint256 powerTONSeigRate_) external onlyOwner {
    require(powerTONSeigRate_ + daoSeigRate + relativeSeigRate <= RAY, "exceeded seigniorage rate");
    powerTONSeigRate = powerTONSeigRate_;
    emit SetPowerTONSeigRate (powerTONSeigRate_);
  }

  function setDaoSeigRate(uint256 daoSeigRate_) external onlyOwner {
    require(powerTONSeigRate + daoSeigRate_ + relativeSeigRate <= RAY, "exceeded seigniorage rate");
    daoSeigRate = daoSeigRate_;
    emit SetDaoSeigRate (daoSeigRate_) ;
  }

  function setPseigRate(uint256 pseigRate_) external onlyOwner {
    require(powerTONSeigRate + daoSeigRate + pseigRate_ <= RAY, "exceeded seigniorage rate");
    relativeSeigRate = pseigRate_;
    emit SetPseigRate (pseigRate_);
  }

  function setCoinageFactory(address factory_) external onlyOwner {
    factory = factory_;
  }

  function transferCoinageOwnership(address newSeigManager, address[] calldata coinages_) external onlyOwner {
    for (uint256 i = 0; i < coinages_.length; i++) {
      RefactorCoinageSnapshotI c = RefactorCoinageSnapshotI(coinages_[i]);
      c.addMinter(newSeigManager);
      c.renounceMinter();
      c.transferOwnership(newSeigManager);
    }
  }

  function renounceWTONMinter() external onlyOwner {
    IWTON(_wton).renounceMinter();
  }

  function setAdjustDelay(uint256 adjustDelay_) external onlyOwner {
    adjustCommissionDelay = adjustDelay_;
  }

  function setMinimumAmount(uint256 minimumAmount_) external onlyOwner {
    minimumAmount = minimumAmount_;
  }


  //////////////////////////////
  // onlyRegistry
  //////////////////////////////

  /**
   * @dev deploy coinage token for the layer2.
   */
  function deployCoinage(address layer2) external onlyRegistry returns (bool) {
    // create new coinage token for the layer2 contract
    if (address(_coinages[layer2]) == address(0)) {
      address c = CoinageFactoryI(factory).deploy();
      _lastCommitBlock[layer2] = block.number;
      // addChallenger(layer2);
      _coinages[layer2] = RefactorCoinageSnapshotI(c);
      emit CoinageCreated(layer2, c);
    }

    return true;
  }

  function setCommissionRate(
    address layer2,
    uint256 commissionRate,
    bool isCommissionRateNegative_
  )
    external
    onlyRegistryOrOperator(layer2)
    returns (bool)
  {
    // check commission range
    require(
      (commissionRate == 0) ||
      (MIN_VALID_COMMISSION <= commissionRate && commissionRate <= MAX_VALID_COMMISSION),
      "SeigManager: commission rate must be 0 or between 1 RAY and 0.01 RAY"
    );

    uint256 previous = _commissionRates[layer2];
    if (adjustCommissionDelay == 0) {
      _commissionRates[layer2] = commissionRate;
      _isCommissionRateNegative[layer2] = isCommissionRateNegative_;
    } else {
      delayedCommissionBlock[layer2] = block.number + adjustCommissionDelay;
      delayedCommissionRate[layer2] = commissionRate;
      delayedCommissionRateNegative[layer2] = isCommissionRateNegative_;
    }

    emit CommissionRateSet(layer2, previous, commissionRate);

    return true;
  }

  // No implementation in registry.
  // function addChallenger(address account) public onlyRegistry {
  //   grantRole(CHALLENGER_ROLE, account);
  // }

  // No implementation in layer2 (candidate).
  function slash(address layer2, address challenger) external onlyChallenger checkCoinage(layer2) returns (bool) {
    Layer2I(layer2).changeOperator(challenger);

    return true;
  }

  //////////////////////////////
  // onlyDepositManager
  //////////////////////////////

  /**
   * @dev Callback for a new deposit
   */
  function onDeposit(address layer2, address account, uint256 amount)
    external
    onlyDepositManager
    checkCoinage(layer2)
    returns (bool)
  {
    if (_isOperator(layer2, account)) {
      uint256 newAmount = _coinages[layer2].balanceOf(account) + amount;
      require(newAmount >= minimumAmount, "minimum amount is required");
    }
    _tot.mint(layer2, amount);
    _coinages[layer2].mint(account, amount);

    return true;
  }

  function onWithdraw(address layer2, address account, uint256 amount)
    external
    onlyDepositManager
    checkCoinage(layer2)
    returns (bool)
  {
    require(_coinages[layer2].balanceOf(account) >= amount, "SeigManager: insufficiant balance to unstake");

    if (_isOperator(layer2, account)) {
      uint256 newAmount = _coinages[layer2].balanceOf(account) - amount;
      require(newAmount >= minimumAmount, "minimum amount is required");
    }

    // burn {v + ⍺} {tot} tokens to the layer2 contract,
    uint256 totAmount = _additionalTotBurnAmount(layer2, account, amount);
    _tot.burnFrom(layer2, amount+totAmount);

    // burn {v} {coinages[layer2]} tokens to the account
    _coinages[layer2].burnFrom(account, amount);

    emit UnstakeLog(amount, totAmount);

    return true;
  }


  //////////////////////////////
  // checkCoinage
  //////////////////////////////

  /**
   * @dev Callback for a new commit
   */
  function updateSeigniorage()
    public
    checkCoinage(msg.sender)
    returns (bool)
  {
    // short circuit if paused
    if (paused) {
      return true;
    }
    require(block.number > _lastSeigBlock, "last seig block is not past");

    uint256 operatorAmount = getOperatorAmount(msg.sender);
    require(operatorAmount >= minimumAmount, "minimumAmount is insufficient");

    RefactorCoinageSnapshotI coinage = _coinages[msg.sender];

    _increaseTot();

    _lastCommitBlock[msg.sender] = block.number;

    // 2. increase total supply of {coinages[layer2]}
    // RefactorCoinageSnapshotI coinage = _coinages[msg.sender];

    uint256 prevTotalSupply = coinage.totalSupply();
    uint256 nextTotalSupply = _tot.balanceOf(msg.sender);

    // short circuit if there is no seigs for the layer2
    if (prevTotalSupply >= nextTotalSupply) {
      emit Comitted(msg.sender);
      return true;
    }

    uint256 seigs = nextTotalSupply - prevTotalSupply;
    address operator = Layer2I(msg.sender).operator();
    uint256 operatorSeigs;

    // calculate commission amount
    bool isCommissionRateNegative_ = _isCommissionRateNegative[msg.sender];

    (nextTotalSupply, operatorSeigs) = _calcSeigsDistribution(
      msg.sender,
      coinage,
      prevTotalSupply,
      seigs,
      isCommissionRateNegative_,
      operator
    );

    // gives seigniorages to the layer2 as coinage
    coinage.setFactor(
      _calcNewFactor(
        prevTotalSupply,
        nextTotalSupply,
        coinage.factor()
      )
    );

    // give commission to operator or delegators
    if (operatorSeigs != 0) {
      if (isCommissionRateNegative_) {
        // TODO: adjust arithmetic error
        // burn by 𝜸
        coinage.burnFrom(operator, operatorSeigs);
      } else {
        coinage.mint(operator, operatorSeigs);
      }
    }

    IWTON(_wton).mint(address(_depositManager), seigs);

    emit Comitted(msg.sender);
    emit AddedSeigAtLayer(msg.sender, seigs, operatorSeigs, nextTotalSupply, prevTotalSupply);

    return true;
  }


  //////////////////////////////
  // External functions
  //////////////////////////////

  function getOperatorAmount(address layer2) public view returns (uint256) {
    address operator = Layer2I(msg.sender).operator();
    return _coinages[layer2].balanceOf(operator);
  }

  /**
   * @dev Callback for a token transfer
   */
  function onTransfer(address sender, address recipient, uint256 amount) external returns (bool) {
    require(msg.sender == address(_ton) || msg.sender == address(_wton),
      "SeigManager: only TON or WTON can call onTransfer");

    if (!paused) {
      _increaseTot();
    }

    return true;
  }


  function additionalTotBurnAmount(address layer2, address account, uint256 amount)
    external
    view
    returns (uint256 totAmount)
  {
    return _additionalTotBurnAmount(layer2, account, amount);
  }


  function uncomittedStakeOf(address layer2, address account) external view returns (uint256) {
    RefactorCoinageSnapshotI coinage = RefactorCoinageSnapshotI(_coinages[layer2]);

    uint256 prevFactor = coinage.factor();
    uint256 prevTotalSupply = coinage.totalSupply();
    uint256 nextTotalSupply = _tot.balanceOf(layer2);
    uint256 newFactor = _calcNewFactor(prevTotalSupply, nextTotalSupply, prevFactor);

    uint256 uncomittedBalance = rmul(
      rdiv(coinage.balanceOf(account), prevFactor),
      newFactor
    );

    return (uncomittedBalance - _coinages[layer2].balanceOf(account));
  }

  function stakeOf(address layer2, address account) public view returns (uint256) {
    return _coinages[layer2].balanceOf(account);
  }

  function stakeOfAt(address layer2, address account, uint256 snapshotId) external view returns (uint256 amount) {
    return _coinages[layer2].balanceOfAt(account, snapshotId);
  }

  function stakeOf(address account) external view returns (uint256 amount) {
    uint256 num = IILayer2Registry(_registry).numLayer2s();
    // amount = 0;
    for (uint256 i = 0 ; i < num; i++){
      address layer2 = IILayer2Registry(_registry).layer2ByIndex(i);
      amount += _coinages[layer2].balanceOf(account);
    }
  }

  function stakeOfAt(address account, uint256 snapshotId) external view returns (uint256 amount) {
    uint256 num = IILayer2Registry(_registry).numLayer2s();
    // amount = 0;
    for (uint256 i = 0 ; i < num; i++){
      address layer2 = IILayer2Registry(_registry).layer2ByIndex(i);
      amount += _coinages[layer2].balanceOfAt(account, snapshotId);
    }
  }

  function stakeOfTotal() external view returns (uint256 amount) {
    amount = _tot.totalSupply();
  }

  function stakeOfTotalAt(uint256 snapshotId) external view returns (uint256 amount) {
    amount = _tot.totalSupplyAt(snapshotId);
  }

  function onSnapshot() external returns (uint256 snapshotId) {
    snapshotId = lastSnapshotId;
    emit OnSnapshot(snapshotId);
    lastSnapshotId++;
  }

  function updateSeigniorageLayer(address layer2) external returns (bool){
    require(ICandidate(layer2).updateSeigniorage(), "fail updateSeigniorage");
    return true;
  }

  //////////////////////////////
  // Public functions
  //////////////////////////////


  //////////////////////////////
  // Internal functions
  //////////////////////////////

  // return ⍺, where ⍺ = (tot.balanceOf(layer2) - coinages[layer2].totalSupply()) * (amount / coinages[layer2].totalSupply())
  function _additionalTotBurnAmount(address layer2, address account, uint256 amount)
    internal
    view
    returns (uint256 totAmount)
  {
    uint256 coinageTotalSupply = _coinages[layer2].totalSupply();
    uint256 totBalalnce = _tot.balanceOf(layer2);

    // NOTE: arithamtic operations (mul and div) make some errors, so we gonna adjust them under 1e-9 WTON.
    //       note that coinageTotalSupply and totBalalnce are RAY values.
    if (coinageTotalSupply >= totBalalnce && coinageTotalSupply - totBalalnce < WAD_) {
      return 0;
    }

    return rdiv(
      rmul(
        totBalalnce - coinageTotalSupply,
        amount
      ),
      coinageTotalSupply
    );
  }


  function _calcSeigsDistribution(
    address layer2,
    RefactorCoinageSnapshotI coinage,
    uint256 prevTotalSupply,
    uint256 seigs,
    bool isCommissionRateNegative_,
    address operator
  ) internal returns (
    uint256 nextTotalSupply,
    uint256 operatorSeigs
  ) {
    if (block.number >= delayedCommissionBlock[layer2] && delayedCommissionBlock[layer2] != 0) {
      _commissionRates[layer2] = delayedCommissionRate[layer2];
      _isCommissionRateNegative[layer2] = delayedCommissionRateNegative[layer2];
      delayedCommissionBlock[layer2] = 0;
    }

    uint256 commissionRate = _commissionRates[msg.sender];

    nextTotalSupply = prevTotalSupply + seigs;

    // short circuit if there is no commission rate
    if (commissionRate == 0) {
      return (nextTotalSupply, operatorSeigs);
    }

    // if commission rate is possitive
    if (!isCommissionRateNegative_) {
      operatorSeigs = rmul(seigs, commissionRate); // additional seig for operator
      nextTotalSupply = nextTotalSupply - operatorSeigs;
      return (nextTotalSupply, operatorSeigs);
    }

    // short circuit if there is no previous total deposit (meanning, there is no deposit)
    if (prevTotalSupply == 0) {
      return (nextTotalSupply, operatorSeigs);
    }

    // See negative commission distribution formular here: TBD
    uint256 operatorBalance = coinage.balanceOf(operator);

    // short circuit if there is no operator deposit
    if (operatorBalance == 0) {
      return (nextTotalSupply, operatorSeigs);
    }

    uint256 operatorRate = rdiv(operatorBalance, prevTotalSupply);

    // ɑ: insufficient seig for operator
    operatorSeigs = rmul(
      rmul(seigs, operatorRate), // seigs for operator
      commissionRate
    );

    // β:
    uint256 delegatorSeigs = operatorRate == RAY
      ? operatorSeigs
      : rdiv(operatorSeigs, RAY - operatorRate);

    // 𝜸:
    operatorSeigs = operatorRate == RAY
      ? operatorSeigs
      : operatorSeigs + rmul(delegatorSeigs, operatorRate);

    nextTotalSupply = nextTotalSupply + delegatorSeigs;

    return (nextTotalSupply, operatorSeigs);
  }

  function _calcNewFactor(uint256 source, uint256 target, uint256 oldFactor) internal pure returns (uint256) {
    return rdiv(rmul(target, oldFactor), source);
  }


  function _calcNumSeigBlocks() internal view returns (uint256) {
    require(!paused);

    uint256 span = block.number - _lastSeigBlock;
    if (_unpausedBlock < _lastSeigBlock) {
      return span;
    }

    return span - (_unpausedBlock - _pausedBlock);
  }

  function _isOperator(address layer2, address operator) internal view returns (bool) {
    return operator == Layer2I(layer2).operator();
  }


  function _increaseTot() internal returns (bool) {
    // short circuit if already seigniorage is given.
    if (block.number <= _lastSeigBlock) {
      return false;
    }

    if (RefactorCoinageSnapshotI(_tot).totalSupply() == 0) {
      _lastSeigBlock = block.number;
      return false;
    }

    uint256 prevTotalSupply;
    uint256 nextTotalSupply;

    // 1. increase total supply of {tot} by maximum seigniorages * staked rate
    //    staked rate = total staked amount / total supply of (W)TON

    prevTotalSupply = _tot.totalSupply();

    // maximum seigniorages
    uint256 maxSeig = _calcNumSeigBlocks() * _seigPerBlock;

    // total supply of (W)TON
    uint256 tos = (
      (ITON(_ton).totalSupply() - ITON(_ton).balanceOf(_wton) - ITON(_ton).balanceOf(address(0)) - ITON(_ton).balanceOf(address(1))
    ) * (10 ** 9)) + _tot.totalSupply();  // consider additional TOT balance as total supply

    // maximum seigniorages * staked rate
    uint256 stakedSeig = rdiv(
      rmul(
        maxSeig,
        // total staked amount
        _tot.totalSupply()
      ),
      tos
    );

    // pseig
    uint256 totalPseig = rmul(maxSeig - stakedSeig, relativeSeigRate);

    nextTotalSupply = prevTotalSupply + stakedSeig + totalPseig;
    _lastSeigBlock = block.number;

    _tot.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, _tot.factor()));

    uint256 unstakedSeig = maxSeig - stakedSeig;
    uint256 powertonSeig;
    uint256 daoSeig;
    uint256 relativeSeig;

    if (address(_powerton) != address(0)) {
      powertonSeig = rmul(unstakedSeig, powerTONSeigRate);
      IWTON(_wton).mint(address(_powerton), powertonSeig);
      IPowerTON(_powerton).updateSeigniorage(powertonSeig);
    }

    if (dao != address(0)) {
      daoSeig = rmul(unstakedSeig, daoSeigRate);
      IWTON(_wton).mint(address(dao), daoSeig);
    }

    if (relativeSeigRate != 0) {
      relativeSeig = totalPseig;
      accRelativeSeig = accRelativeSeig + relativeSeig;
    }

    emit SeigGiven(msg.sender, maxSeig, stakedSeig, unstakedSeig, powertonSeig, daoSeig, relativeSeig);

    return true;
  }


  //////////////////////////////
  // Storage getters
  //////////////////////////////

  // solium-disable
  function registry() external view returns (address) { return address(_registry); }
  function depositManager() external view returns (address) { return address(_depositManager); }
  function ton() external view returns (address) { return address(_ton); }
  function wton() external view returns (address) { return address(_wton); }
  function powerton() external view returns (address) { return address(_powerton); }
  function tot() external view returns (address) { return address(_tot); }
  function coinages(address layer2) external view returns (address) { return address(_coinages[layer2]); }
  function commissionRates(address layer2) external view returns (uint256) { return _commissionRates[layer2]; }
  function isCommissionRateNegative(address layer2) external view returns (bool) { return _isCommissionRateNegative[layer2]; }

  function lastCommitBlock(address layer2) external view returns (uint256) { return _lastCommitBlock[layer2]; }
  function seigPerBlock() external view returns (uint256) { return _seigPerBlock; }
  function lastSeigBlock() external view returns (uint256) { return _lastSeigBlock; }
  function pausedBlock() external view returns (uint256) { return _pausedBlock; }
  function unpausedBlock() external view returns (uint256) { return _unpausedBlock; }

  function DEFAULT_FACTOR() external pure returns (uint256) { return _DEFAULT_FACTOR; }
  // solium-enable


  //====
  function renounceMinter(address target) public onlyOwner {
    MinterRoleRenounceTarget(target).renounceMinter();
  }

  function renouncePauser(address target) public onlyOwner {
    PauserRoleRenounceTarget(target).renouncePauser();
  }

  function renounceOwnership(address target) public onlyOwner {
    OwnableTarget(target).renounceOwnership();
  }

  function transferOwnership(address target, address newOwner) public onlyOwner {
    OwnableTarget(target).transferOwnership(newOwner);
  }

  //=====

  function progressSnapshotId() public view returns (uint256) {
      return lastSnapshotId;
  }

}