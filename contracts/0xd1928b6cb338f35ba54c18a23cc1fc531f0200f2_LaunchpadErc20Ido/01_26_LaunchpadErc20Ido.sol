// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import './interfaces/IIdoStorage.sol';
import './interfaces/IdoStorage/IIdoStorageState.sol';
import './interfaces/ILaunchpadErc20Ido.sol';


/**
 * @title LaunchpadErc20Ido
 * @dev LaunchpadErc20Ido is a contract for managing token ido,
 * allowing investors to purchase the tokens with ERC20 collateral.
 */
contract LaunchpadErc20Ido is ILaunchpadErc20Ido, AccessControl, ReentrancyGuard, Pausable {
  using SafeERC20 for IERC20;
  using Address for address;
  bytes32 public constant WERT_ROLE = keccak256('WERT_ROLE');

  uint256 public constant TOKEN_DECIMALS = 18;
  uint256 public constant PRECISION = 10 ** 18;

  /// @notice Address where funds are collected
  address private _wallet;

  /// @notice Ido storage
  IIdoStorage private _idoStorage;

  /// @notice Collateral tokens used as a payment
  mapping(address => Collateral) private _collaterals;

  /**
   * @param idoStorage_  address where ido state is being store.
   * @param wallet_  address where collected funds will be forwarded to.
   * @param collaterals_  addresses of the collateral tokens.
   */
  constructor(address payable idoStorage_, address wallet_, address[] memory collaterals_) {
    if (idoStorage_ == address(0)) revert IdoStorageNullAddressErr();
    if (wallet_ == address(0)) revert WalletNullAddressErr();

    for(uint256 index = 0; index < collaterals_.length; index++) {
      if (collaterals_[index] == address(0)) revert CollateralNullAddressErr();
      _collaterals[collaterals_[index]] = Collateral({
        defined: true,
        raised: 0
      });
    }
    _wallet = wallet_;
    _idoStorage = IIdoStorage(idoStorage_);

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  /**
   * @dev Method allows to purchase the tokens
   * @param collateral_  addresses of the collateral token.
   * @param investment_  amount of collateral token investment.
   * @param vesting_  vesting of the investment.
   * @param referral_  referral owner.
   */
  function buyTokens(address collateral_, uint256 investment_, IIdoStorage.Vesting vesting_, address referral_)
    external
    nonReentrant()
  {
    address beneficiary = _msgSender();
    _preValidatePurchase(beneficiary, collateral_, investment_, vesting_, referral_, false);
    (address referral, uint256 mainReward, uint256 tokenReward) = _preProcessReferral(beneficiary, collateral_, referral_, vesting_, investment_);
    _processPurchase(beneficiary, collateral_, investment_, mainReward);
    // calculates token amount to be sold
    uint256 tokensSold = _getTokenAmount(collateral_, investment_, vesting_);
    _updatePurchasingState(beneficiary, collateral_, investment_, tokensSold, referral, mainReward, tokenReward);
    _postPurchase(beneficiary, collateral_, referral, investment_, vesting_, tokensSold);
  }

  function buyTokensFor(
    address collateral_,
    uint256 investment_,
    IIdoStorage.Vesting vesting_,
    address beneficiary_,
    address referral_
  )
    external
    nonReentrant()
    onlyRole(WERT_ROLE)
  {
    _preValidatePurchase(beneficiary_, collateral_, investment_, vesting_, referral_, true);
    (address referral, uint256 mainReward, uint256 tokenReward) = _preProcessReferral(beneficiary_, collateral_, referral_, vesting_, investment_);
    _processPurchase(_msgSender(), collateral_, investment_, mainReward);
    // calculates token amount to be sold
    uint256 tokensSold = _getTokenAmount(collateral_, investment_, vesting_);
    _updatePurchasingState(beneficiary_, collateral_, investment_, tokensSold, referral, mainReward, tokenReward);
    _postPurchase(beneficiary_, collateral_, referral, investment_, vesting_, tokensSold);
  }

  function pause() 
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _pause();
  }

  function unpause() 
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _unpause();
  }

  function recoverERC20(address token_, uint256 amount_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    IERC20(token_).safeTransfer(_msgSender(), amount_);

    emit ERC20Recovered(token_, amount_);
  }

  function isCollateral(address collateral_)
    external
    view
    returns (bool)
  {
    return _collaterals[collateral_].defined;
  }

  function getWallet()
    external
    view
    returns (address)
  {
    return _wallet;
  }

  function getIdoStorage()
    external
    view
    returns (address)
  {
    return address(_idoStorage);
  }

  function getRaised(address collateral_)
    external
    view
    returns (uint256)
  {
    return _collaterals[collateral_].raised;
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
   * tokens.
   * @param beneficiary_  address performing the token purchase.
   * @param collateral_  addresses of the collateral token.
   * @param investment_  amount of collateral token investment.
   * @param reward_  referral bonus.
   */
  function _processPurchase(
    address beneficiary_,
    address collateral_,
    uint256 investment_,
    uint256 reward_
  )
    internal
  {
    // transfer collateral tokens to wallet
    uint256 investment = investment_ - reward_;
    IERC20(collateral_).safeTransferFrom(beneficiary_, _wallet, investment);

    // transfer collateral tokens to a storage
    if (reward_ > 0) {
      IERC20(collateral_).safeTransferFrom(beneficiary_, address(_idoStorage), reward_);
    }
  }

  /**
   * @dev Executed in order to update state of the purchase within ido.
   * @param beneficiary_  address performing the token purchase.
   * @param collateral_  addresses of the collateral token.
   * @param investment_  amount of collateral token investment.
   * @param tokensSold_  amount of purchased tokens.
   * @param referral_  referral owner.
   * @param mainReward_  referral main reward.
   * @param tokenReward_  referral token reward.
   */
  function _updatePurchasingState(
    address beneficiary_,
    address collateral_,
    uint256 investment_,
    uint256 tokensSold_,
    address referral_,
    uint256 mainReward_,
    uint256 tokenReward_
  )
    internal
  {
    _collaterals[collateral_].raised = _collaterals[collateral_].raised + investment_;
    uint256 decimals = IERC20Metadata(collateral_).decimals();
    uint256 normalizedAmount = (investment_ * PRECISION) / (10 ** decimals);
    _idoStorage.setPurchaseState(beneficiary_, collateral_, normalizedAmount, tokensSold_, referral_, mainReward_, tokenReward_);
  }

  /**
   * @dev Executed for the post purchase processing
   * @param beneficiary_  address performing the token purchase.
   * @param collateral_  addresses of the collateral token.
   * @param referral_  referral used in the purchase.
   * @param investment_  amount of collateral token investment.
   * @param vesting_  vesting option.
   * @param tokensSold_  amount of purchased tokens.
   */
  function _postPurchase(address beneficiary_, address collateral_, address referral_, uint256 investment_, IIdoStorage.Vesting vesting_, uint256 tokensSold_)
    internal
  {
    emit TokensPurchased(beneficiary_, collateral_, referral_, investment_, vesting_, tokensSold_, _idoStorage.getActiveRound());
  }

  /**
   * @dev Validation of the incoming purchase.
   * @param beneficiary_  address performing the token purchase.
   * @param collateral_  addresses of the collateral token.
   * @param investment_  amount of collateral token investment.
   * @param vesting_  vesting of the investment.
   * @param referral_  referral owner.
   * @param maxCap_  if beneficiary has max cap.
   */
  function _preValidatePurchase(address beneficiary_, address collateral_, uint256 investment_, IIdoStorage.Vesting vesting_, address referral_, bool maxCap_)
    internal
    whenNotPaused
    view
  {
    if (beneficiary_ == address(0)) revert BeneficiaryNullAddressErr();
    if (beneficiary_ == referral_) revert IvalidReferralErr();
    if (investment_ == 0) revert InvestmentNullErr();

    // validates if collateral supported
    if (!_collaterals[collateral_].defined) revert CollateralUndefinedErr();
    
    // validates if sale and round is open
    if (!_idoStorage.isOpened()) revert IdoClosedErr();
    uint256 activeRound = _idoStorage.getActiveRound();
    IIdoStorage.Round memory round = _idoStorage.getRound(activeRound);

    if (round.state != IIdoStorageState.State.Opened) revert RoundClosedErr();
    if (round.totalSupply < round.tokensSold + _getTokenAmount(collateral_, investment_, vesting_))
      revert ExceededRoundAllocationErr();

    // validates investment amount
    uint256 decimals = IERC20Metadata(collateral_).decimals();
    uint256 normalizedAmount = (investment_ * PRECISION) / (10 ** decimals);

    if (_idoStorage.getMinInvestment() > normalizedAmount) revert MinInvestmentErr(normalizedAmount, _idoStorage.getMinInvestment());
    uint256 cap = maxCap_ ? _idoStorage.maxCapOf(beneficiary_) : _idoStorage.capOf(beneficiary_);
    if (cap < normalizedAmount) revert MaxInvestmentErr(normalizedAmount, cap);
    
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
  }

  /**
   * @dev Returns referral data.
   * @param beneficiary_  address performing the token purchase.
   * @param collateral_  addresses of the collateral token.
   * @param referral_  referral owner.
   * @param vesting_  vesting of the investment.
   * @param investment_  amount of collateral token investment.
   */
  function _preProcessReferral(address beneficiary_, address collateral_, address referral_, IIdoStorage.Vesting vesting_, uint256 investment_)
    internal
    view
    returns (address, uint256, uint256)
  {
    address referral = _idoStorage.getReferral(beneficiary_, referral_);
    if (referral == address(0)) {
      return (referral, 0, 0);
    }
    (uint256 mainReward_, uint256 secondaryReward_) = _idoStorage.getReferralReward(referral);
    uint256 mainReward = investment_ * mainReward_ / 1000;
    uint256 secondaryReward = investment_ * secondaryReward_ / 1000;
    uint256 tokenReward = _getTokenAmount(collateral_, secondaryReward, vesting_);

    return (referral, mainReward, tokenReward);
  }

  /**
   * @return Amount of tokens that can be purchased with specified collateral investment.
   * @param collateral_  addresses of the collateral token.
   * @param investment_  amount of collateral token investment.
   * @param vesting_  vesting of the investment.
   */
  function _getTokenAmount(address collateral_, uint256 investment_, IIdoStorage.Vesting vesting_)
    internal
    view
    returns (uint256)
  {
    uint8 decimals = IERC20Metadata(collateral_).decimals();
    return (investment_ * 10 ** TOKEN_DECIMALS * PRECISION / 10 ** decimals) / _idoStorage.getPrice(vesting_);
  }
}