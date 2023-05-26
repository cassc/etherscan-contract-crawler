// SPDX-License-Identifier: MIT
pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import { SafeMath } from '@openzeppelin/contracts/math/SafeMath.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import { IAction } from '../interfaces/IAction.sol';
import { ICurve } from '../interfaces/ICurve.sol';
import { ICurveZap } from '../interfaces/ICurveZap.sol';
import { IStakeDao } from '../interfaces/IStakeDao.sol';

import "hardhat/console.sol";

/**
 * Error Codes
 * O1: actions for the vault have not been initialized
 * O2: cannot execute transaction, vault is in emergency state
 * O3: cannot call setActions, actions have already been initialized
 * O4: action being set is using an invalid address
 * O5: action being set is a duplicated action
 * O6: deposited wantedAsset (msg.value) must be greater than 0
 * O7: cannot accept wantedAsset deposit, total sdToken controlled by the vault would exceed vault cap
 * O8: unable to withdraw wantedAsset, sdToken to withdraw would exceed or be equal to the current vault sdToken balance
 * O9: unable to withdraw wantedAsset, wantedAsset fee transfer to fee recipient (feeRecipient) failed
 * O10: unable to withdraw wantedAsset, wantedAsset withdrawal to user (msg.sender) failed
 * O11: cannot close vault positions, vault is not in locked state (VaultState.Locked)
 * O12: unable to rollover vault, length of allocation percentages (_allocationPercentages) passed is not equal to the initialized actions length
 * O13: unable to rollover vault, vault is not in unlocked state (VaultState.Unlocked)
 * O14: unable to rollover vault, the calculated percentage sum (sumPercentage) is greater than the base (BASE)
 * O15: unable to rollover vault, the calculated percentage sum (sumPercentage) is not equal to the base (BASE)
 * O16: withdraw reserve percentage must be less than 50% (5000)
 * O17: cannot call emergencyPause, vault is already in emergency state
 * O18: cannot call resumeFromPause, vault is not in emergency state
 * O19: cannot receive wantedAsset from any address other than the curve pool address (curveMetaZap)
 */

/** 
 * @title OpynPerpVault
 * @author Opyn Team
 * @dev implementation of the Opyn Perp Vault contract that works with stakedao's wantedAsset strategy. 
 * Note that this implementation is meant to only specifically work for the stakedao wantedAsset strategy and is not 
 * a generalized contract. Stakedao's wantedAsset strategy currently accepts curveMetaZap LP tokens called curveLPToken from the 
 * wantedAsset curve pool. This strategy allows users to convert their wantedAsset into yield earning sdToken tokens
 * and use the sdToken tokens as collateral to sell wantedAsset call options on Opyn. 
 */

contract OpynPerpVault is ERC20, ReentrancyGuard, Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  enum VaultState {
    Emergency,
    Locked,
    Unlocked
  }

  /// @dev actions that build up this strategy (vault)
  address[] public actions;

  /// @dev address to which all fees are sent
  address public feeRecipient;

  /// @dev address of the wantedAsset address which is earning yields
  address public wantedAsset;

  /// @dev stakedao LP token address
  address public sdTokenAddress;

  uint256 public constant BASE = 10000; // 100%

  /// @dev Cap for the vault.
  uint256 public cap = 100000 ether;

  /// @dev withdrawal fee percentage. 50 being 0.5%
  uint256 public withdrawalFeePercentage = 50;

  /// @dev how many percentage should be reserved in vault for withdraw. 1000 being 10%
  uint256 public withdrawReserve = 0;

  /// @dev curveMetaZap for the corresponding stakedao strategy 
  ICurveZap public curveMetaZap;

  /// @dev the curve LP token address for the particular pool
  ICurve public curveLPToken;

  /// @dev the stakedao strategy contract
  IStakeDao stakedaoStrategy;

  VaultState public state;
  VaultState public stateBeforePause;

   address[3] public BASE_COINS = [
    0x6B175474E89094C44Da98b954EedeAC495271d0F,  // DAI
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,  // USDC
    0xdAC17F958D2ee523a2206206994597C13D831ec7  // USDT
  ];

  /*=====================
   *       Events       *
   *====================*/

  event CapUpdated(uint256 newCap);

  event Deposit(address account, uint256 amountDeposited, uint256 shareMinted);

  event Rollover(uint256[] allocations);

  event StateUpdated(VaultState state);

  event FeeSent(uint256 amount, address feeRecipient);

  event Withdraw(address account, uint256 amountWithdrawn, uint256 shareBurned);

  /*=====================
   *     Modifiers      *
   *====================*/

  /** 
   * @dev can only be called if actions are initialized 
   */
  function actionsInitialized() private view {
    require(actions.length > 0, "O1");
  }
  
  /**
   * @dev can only be executed if vault is not in emergency state
   */
  function notEmergency() private view {
    require(state != VaultState.Emergency, "O2");
  }

  /*=====================
   * external function *
   *====================*/

  constructor (
    address _wantedAsset,
    address _sdTokenAddress,
    address _curveMetaZapAddress,
    address _feeRecipient,
    string memory _tokenName,
    string memory _tokenSymbol
    ) ERC20(_tokenName, _tokenSymbol) {
    wantedAsset = _wantedAsset;
    sdTokenAddress = _sdTokenAddress;
    stakedaoStrategy = IStakeDao(sdTokenAddress);
    curveLPToken = ICurve(address(stakedaoStrategy.token()));
    feeRecipient = _feeRecipient;
    curveMetaZap = ICurveZap(_curveMetaZapAddress);
    state = VaultState.Unlocked;
  }

  function setActions(address[] memory _actions) external onlyOwner {
    require(actions.length == 0, "O3");

    // assign actions
    for(uint256 i = 0 ; i < _actions.length; i++ ) {
      // check all items before actions[i], does not equal to action[i]
      require(_actions[i] != address(0), "O4");

      for(uint256 j = 0; j < i; j++) {
        require(_actions[i] != _actions[j], "O5");
      }

      actions.push(_actions[i]);
    }
  }

  /** 
   * @notice allows owner to change the cap
   */
   function setCap(uint256 _newCap) external onlyOwner {
     cap = _newCap;

     emit CapUpdated(_newCap);
   }

  /**
   * @notice total sdToken controlled by this vault
   */
  function totalStakedaoAsset() public view returns (uint256) {
    uint256 debt = 0;
    uint256 length = actions.length;

    for (uint256 i = 0; i < length; i++) {
      debt = debt.add(IAction(actions[i]).currentValue());
    }

    return _balance().add(debt);
  }

  /**
   * total wantedAsset value of the sdToken controlled by this vault
   */
  function totalUnderlyingControlled() external view returns (uint256) { 
    // hard coded to 36 because curve LP token and sdToken are both 18 decimals. 
    return totalStakedaoAsset().mul(stakedaoStrategy.getPricePerFullShare()).mul(curveLPToken.get_virtual_price()).div(10**36);
  }

  /**
   * @dev return how many sdToken you can get if you burn the number of shares, after charging the fee.
   */
  function getWithdrawAmountByShares(uint256 _shares) external view returns (uint256) {
    uint256 withdrawAmount = _getWithdrawAmountByShares(_shares);
    return withdrawAmount.sub(_getWithdrawFee(withdrawAmount));
  }

  /**
   * @notice Deposits wantedAsset into the contract and mint vault shares. 
   * @dev deposit into the curveMetaZap, then into stakedao, then mint the shares to depositor, and emit the deposit event
   * @param amount amount of wantedAsset to deposit 
   * @param minCrvLPToken minimum amount of curveLPToken to get out from adding liquidity. 
   */
  function depositUnderlying(uint256 amount, uint256 minCrvLPToken, uint256 indexOfAsset) external nonReentrant {
    notEmergency();
    actionsInitialized();
    require(amount > 0, 'O6');

    // the sdToken is already deposited into the contract at this point, need to substract it from total
    uint256[4] memory amounts;
    for(uint256 i=0; i<4; i++) {
      if(indexOfAsset == i) { 
        amounts[i] = amount;
      }
    }

    address assetAddress;
    if(indexOfAsset == 0) { 
      assetAddress = wantedAsset; 
    } else { 
      assetAddress = BASE_COINS[indexOfAsset.sub(1)];
    }
    
    // deposit wantedAsset to curveMetaZap
    IERC20 asset = IERC20(assetAddress);
    asset.safeTransferFrom(msg.sender, address(this), amount);
    asset.safeIncreaseAllowance(address(curveMetaZap), amount);

    curveMetaZap.add_liquidity(address(curveLPToken), amounts, minCrvLPToken);
    _depositToStakedaoAndMint();
  }

  /**
   * @notice Deposits curve LP into the contract and mint vault shares. 
   * @dev deposit into stakedao, then mint the shares to depositor, and emit the deposit event
   * @param amount amount of curveLP to deposit 
   */
  function depositCrvLP(uint256 amount) external nonReentrant {
    notEmergency();
    actionsInitialized();
    require(amount > 0, 'O6');

    // deposit wantedAsset to curveMetaZap
    IERC20(address(curveLPToken)).safeTransferFrom(msg.sender, address(this), amount);
    _depositToStakedaoAndMint();
  }

  /**
   * @notice Withdraws wantedAsset from vault using vault shares
   * @dev burns shares, withdraws curveLPToken from stakdao, withdraws wantedAsset from curveMetaZap
   * @param _share is the number of vault shares to be burned
   */
  function withdrawUnderlying(uint256 _share, uint256 _minUnderlying) external nonReentrant {

    // withdraw from curve 
    IERC20 wantedAssetToken = IERC20(wantedAsset);
    uint256 wantedAssetBalanceBefore = wantedAssetToken.balanceOf(address(this));
    uint256 curveLPTokenBalance = _withdrawFromStakedao(_share);
    curveLPToken.remove_liquidity_one_coin(curveLPTokenBalance, 0, _minUnderlying);
    uint256 wantedAssetBalanceAfter = wantedAssetToken.balanceOf(address(this));
    uint256 wantedAssetOwedToUser = wantedAssetBalanceAfter.sub(wantedAssetBalanceBefore);

    // send wantedAsset to user
    wantedAssetToken.safeTransfer(msg.sender, wantedAssetOwedToUser);

    emit Withdraw(msg.sender, wantedAssetOwedToUser, _share);
  }

  /**
   * @notice Withdraws curveLPToken from stakedao
   * @dev burns shares, withdraws curveLPToken from stakdao
   * @param _share is the number of vault shares to be burned
   */
  function withdrawCrvLp (uint256 _share) external nonReentrant {
     uint256 curveLPTokenBalance = _withdrawFromStakedao(_share);
     IERC20(address(curveLPToken)).safeTransfer(msg.sender, curveLPTokenBalance);

  }

  /**
   * @notice anyone can call this to close out the previous round by calling "closePositions" on all actions. 
   * @dev iterrate through each action, close position and withdraw funds
   */
  function closePositions() public {
    actionsInitialized();
    require(state == VaultState.Locked, "O11");
    state = VaultState.Unlocked;

    address cacheAddress = sdTokenAddress;
    address[] memory cacheActions = actions;
    for (uint256 i = 0; i < cacheActions.length; i = i + 1) {
      // 1. close position. this should revert if any position is not ready to be closed.
      IAction(cacheActions[i]).closePosition();

      // 2. withdraw sdTokens from the action
      uint256 actionBalance = IERC20(cacheAddress).balanceOf(cacheActions[i]);
      if (actionBalance > 0)
        IERC20(cacheAddress).safeTransferFrom(cacheActions[i], address(this), actionBalance);
    }

    emit StateUpdated(VaultState.Unlocked);
  }

  /**
   * @notice can only be called when the vault is unlocked. It sets the state to locked and distributes funds to each action.
   */
  function rollOver(uint256[] calldata _allocationPercentages) external onlyOwner nonReentrant {
    actionsInitialized();
    require(_allocationPercentages.length == actions.length, 'O12');
    require(state == VaultState.Unlocked, "O13");
    state = VaultState.Locked;

    address cacheAddress = sdTokenAddress;
    address[] memory cacheActions = actions;

    uint256 cacheBase = BASE;
    uint256 cacheTotalAsset = totalStakedaoAsset();
    // keep track of total percentage to make sure we're summing up to 100%
    uint256 sumPercentage = withdrawReserve;

    for (uint256 i = 0; i < _allocationPercentages.length; i = i + 1) {
      sumPercentage = sumPercentage.add(_allocationPercentages[i]);
      require(sumPercentage <= cacheBase, 'O14');

      uint256 newAmount = cacheTotalAsset.mul(_allocationPercentages[i]).div(cacheBase);

      if (newAmount > 0) IERC20(cacheAddress).safeTransfer(cacheActions[i], newAmount);
      IAction(cacheActions[i]).rolloverPosition();
    }

    require(sumPercentage == cacheBase, 'O15');

    emit Rollover(_allocationPercentages);
    emit StateUpdated(VaultState.Locked);
  }

  /**
   * @dev set the vault withdrawal fee recipient
   */
  function setWithdrawalFeeRecipient(address _newWithdrawalFeeRecipient) external onlyOwner {
    feeRecipient = _newWithdrawalFeeRecipient;
  }

  /**
   * @dev set the percentage that should be reserved in vault for withdraw
   */
  function setWithdrawalFeePercentage(uint256 _newWithdrawalFeePercentage) external onlyOwner {
    withdrawalFeePercentage = _newWithdrawalFeePercentage;
  }

  /**
   * @dev set the percentage that should be reserved in vault for withdraw
   */
  function setWithdrawReserve(uint256 _reserve) external onlyOwner {
    require(_reserve < 5000, "O16");
    withdrawReserve = _reserve;
  }

  /**
   * @dev set the state to "Emergency", which disable all withdraw and deposit
   */
  function emergencyPause() external onlyOwner {
    require(state != VaultState.Emergency, "O17");

    stateBeforePause = state;
    state = VaultState.Emergency;

    emit StateUpdated(VaultState.Emergency);
  }

  /**
   * @dev set the state from "Emergency", which disable all withdraw and deposit
   */
  function resumeFromPause() external onlyOwner {
    require(state == VaultState.Emergency, "O18");

    state = stateBeforePause;

    emit StateUpdated(stateBeforePause);
  }

   /**
   * @dev return how many shares you can get if you deposit {_amount} sdToken
   * @param _amount amount of token depositing
   */
  function getSharesByDepositAmount(uint256 _amount) external view returns (uint256) {
    return _getSharesByDepositAmount(_amount, totalStakedaoAsset());
  }

  /*=====================
   * Internal functions *
   *====================*/

  function _depositToStakedaoAndMint() internal {
    // keep track of balance before
    uint256 totalSdTokenBalanceBeforeDeposit = totalStakedaoAsset();

    // deposit curveLPToken to stakedao
    uint256 curveLPTokenToDeposit = curveLPToken.balanceOf(address(this));

    IERC20(address(curveLPToken)).safeIncreaseAllowance(sdTokenAddress, curveLPTokenToDeposit);
    stakedaoStrategy.deposit(curveLPTokenToDeposit);

    // mint shares and emit event 
    uint256 totalSdTokenWithDepositedAmount = totalStakedaoAsset();
    require(totalSdTokenWithDepositedAmount < cap, 'O7');
    uint256 sdTokenDeposited = totalSdTokenWithDepositedAmount.sub(totalSdTokenBalanceBeforeDeposit);
    uint256 share = _getSharesByDepositAmount(sdTokenDeposited, totalSdTokenBalanceBeforeDeposit);

    emit Deposit(msg.sender, msg.value, share);

    _mint(msg.sender, share);
  }

  function _withdrawFromStakedao(uint256 _share) internal returns (uint256) {
    notEmergency();
    actionsInitialized();

    uint256 currentSdTokenBalance = _balance();
    uint256 sdTokenToShareOfRecipient = _getWithdrawAmountByShares(_share);
    uint256 fee = _getWithdrawFee(sdTokenToShareOfRecipient);
    uint256 sdTokenToWithdraw = sdTokenToShareOfRecipient.sub(fee);
    require(sdTokenToWithdraw <= currentSdTokenBalance, 'O8');

    // burn shares
    _burn(msg.sender, _share);

    // withdraw from stakedao
    stakedaoStrategy.withdraw(sdTokenToWithdraw);

    // transfer fee to recipient 
    IERC20 stakedaoToken = IERC20(sdTokenAddress);
    stakedaoToken.safeTransfer(feeRecipient, fee);
    emit FeeSent(fee, feeRecipient);

    return curveLPToken.balanceOf(address(this));
  }

  /**
   * @dev returns remaining sdToken balance in the vault.
   */
  function _balance() internal view returns (uint256) {
    return IERC20(sdTokenAddress).balanceOf(address(this));
  }

  /**
   * @dev return how many shares you can get if you deposit {_amount} sdToken
   * @param _amount amount of token depositing
   * @param _totalAssetAmount amont of sdToken already in the pool before deposit
   */
  function _getSharesByDepositAmount(uint256 _amount, uint256 _totalAssetAmount) internal view returns (uint256) {
    uint256 shareSupply = totalSupply();

    // share amount
    return shareSupply == 0 ? _amount : _amount.mul(shareSupply).div(_totalAssetAmount);
  }

  /**
   * @dev return how many sdToken you can get if you burn the number of shares
   */
  function _getWithdrawAmountByShares(uint256 _share) internal view returns (uint256) {
    // withdrawal amount
    return _share.mul(totalStakedaoAsset()).div(totalSupply());
  }

  /**
   * @dev get amount of fee charged based on total amount of wwantedAsset withdrawing.
   */
  function _getWithdrawFee(uint256 _withdrawAmount) internal view returns (uint256) {
    return _withdrawAmount.mul(withdrawalFeePercentage).div(BASE);
  }

}