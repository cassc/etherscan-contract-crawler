// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import './interfaces/IIdoStorage.sol';
import './interfaces/IdoStorage/IIdoStorageState.sol';
import './interfaces/ILaunchpadNativeIdo.sol';


/**
 * @title LaunchpadNativeIdo
 * @dev LaunchpadNativeIdo is a contract for managing a token ido,
 * allowing investors to purchase tokens with the native coin.
 */
contract LaunchpadNativeIdo is ILaunchpadNativeIdo, AccessControl, ReentrancyGuard, Pausable {
  using SafeERC20 for IERC20;
  using Address for address;
  bytes32 public constant WERT_ROLE = keccak256('WERT_ROLE');

  address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  uint256 public constant TOKEN_DECIMALS = 18;
  uint256 public constant PRECISION = 10 ** 18;

  /// @notice Address where funds are collected
  address private _wallet;

  /// @notice Ido storage
  IIdoStorage private _idoStorage;

  /// @notice Amount of funds collected
  uint256 private _raised;

  /// @notice Chainlink price aggregator
  AggregatorV3Interface private _priceFeed;
  uint256 private _priceFeedTimeThreshold;

  /**
   * @param idoStorage_  address where ido state is being store.
   * @param wallet_  address where collected funds will be forwarded to.
   * @param priceFeed_  address of chainlink price aggregator.
   * @param priceFeedTimeThreshold_  time of price feed update time threshold.
   */
  constructor(address payable idoStorage_, address wallet_, address priceFeed_, uint256 priceFeedTimeThreshold_) {
    if (idoStorage_ == address(0)) revert IdoStorageNullAddressErr();
    if (wallet_ == address(0)) revert WalletNullAddressErr();
    if (priceFeed_ == address(0)) revert PriceFeedNullAddressErr();
    if (priceFeedTimeThreshold_ == 0) revert InvalidPriceFeedTimeThresholdErr();

    _wallet = wallet_;
    _idoStorage = IIdoStorage(idoStorage_);
    _priceFeed = AggregatorV3Interface(priceFeed_);
    _priceFeedTimeThreshold = priceFeedTimeThreshold_;

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  receive()
    external
    payable 
  {
    // solhint-disable-previous-line no-empty-blocks
  }

  function buyTokens(IIdoStorage.Vesting vesting_, address referral_)
    external
    payable
    nonReentrant()
  {
    _buyTokens(vesting_, _msgSender(), referral_, false);
  }

  function buyTokensFor(IIdoStorage.Vesting vesting_, address beneficiary_, address referral_)
    external
    payable
    onlyRole(WERT_ROLE)
    nonReentrant()
  {
    _buyTokens(vesting_, beneficiary_, referral_, true);
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

  function setPriceFeedTimeThreshold(uint256 priceFeedTimeThreshold_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _priceFeedTimeThreshold = priceFeedTimeThreshold_;

    emit PriceFeedTimeThresholdUpdated(priceFeedTimeThreshold_);
  }

  function recoverNative()
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {    
    uint256 balance = address(this).balance;

    (bool success, ) = _msgSender().call{value: balance}('');
    if (!success) revert NativeTransferErr();

    emit NativeRecovered(balance);
  }

  function recoverERC20(address token_, uint256 amount_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    IERC20(token_).safeTransfer(_msgSender(), amount_);

    emit ERC20Recovered(token_, amount_);
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
  
  function getRaised()
    external
    view
    returns (uint256)
  {
    return _raised;
  }

  function getPriceFeedTimeThreshold()
    external
    view
    returns (uint256)
  {
    return _priceFeedTimeThreshold;
  }

  /**
   * @dev Method allows to purchase the tokens.
   * @param vesting_  vesting of the investment.
   * @param beneficiary_  address performing the token purchase.
   * @param referral_  referral owner.
   * @param maxCap_  if beneficiary has max cap.
   */
  function _buyTokens(IIdoStorage.Vesting vesting_, address beneficiary_, address referral_, bool maxCap_)
    internal
  {
    uint256 investment = msg.value;
    _preValidatePurchase(beneficiary_, investment, vesting_, referral_, maxCap_);
    
    (address referral, uint256 mainReward, uint256 tokenReward) = _preProcessReferral(beneficiary_, referral_, vesting_, investment);
    _processPurchase(investment, mainReward);
    
    uint256 tokensSold = _getTokenAmount(investment, vesting_);
    
    _updatePurchasingState(beneficiary_, investment, tokensSold, referral, mainReward, tokenReward);

    _postPurchase(beneficiary_, referral, investment, vesting_, tokensSold);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
   * tokens.
   * @param investment_  native coins paid for the purchase.
   * @param reward_  referral bonus.
   */
  function _processPurchase(uint256 investment_, uint256 reward_)
    internal
  {
    uint256 investment = investment_ - reward_;

    (bool success, ) = _wallet.call{value: investment}('');
    if (!success) revert NativeTransferErr();

    // transfer to a storage
    if (reward_ > 0) {
      (bool rSuccess, ) = address(_idoStorage).call{value: reward_}('');
      if (!rSuccess) revert NativeTransferErr();
    }
  }

  /**
   * @dev Executed in order to update state of the purchase within ido.
   * @param beneficiary_  address performing the token purchase.
   * @param investment_  native coins paid for the purchase.
   * @param tokensSold_  amount of purchased tokens.
   * @param referral_  referral owner.
   * @param mainReward_  referral main reward.
   * @param tokenReward_  referral token reward.
   */
  function _updatePurchasingState(address beneficiary_, uint256 investment_, uint256 tokensSold_, address referral_, uint256 mainReward_, uint256 tokenReward_)
    internal
  {
    uint8 priceDecimals = _priceFeed.decimals();
    (, int256 price, , uint256 updatedAt,) = _priceFeed.latestRoundData();
    if (block.timestamp - updatedAt > _priceFeedTimeThreshold) revert ExceededPriceFeedTimeThresholdErr();

    _raised = _raised + investment_;
    uint256 normalizedInvestment = (investment_ * uint256(price) * PRECISION) / (10 ** (TOKEN_DECIMALS + priceDecimals));
    _idoStorage.setPurchaseState(beneficiary_, ETH, normalizedInvestment, tokensSold_, referral_, mainReward_, tokenReward_);
  }

  /**
   * @dev Executed for the post purchase processing
   * @param beneficiary_  address performing the token purchase.
   * @param referral_  referral used in the purchase.
   * @param investment_  native coins paid for the purchase.
   * @param vesting_  vesting of the investment.
   * @param tokensSold_  amount of purchased tokens.
   */
  function _postPurchase(address beneficiary_, address referral_, uint256 investment_, IIdoStorage.Vesting vesting_, uint256 tokensSold_)
    internal
  {
    emit TokensPurchased(beneficiary_, referral_, investment_, vesting_, tokensSold_, _idoStorage.getActiveRound());
  }

  /**
   * @dev Validation of the incoming purchase.
   * @param beneficiary_  address performing the token purchase.
   * @param investment_  native coins paid for the purchase.
   * @param vesting_  vesting of the investment.
   * @param referral_  referral owner.
   * @param maxCap_  if beneficiary has max cap.
   */
  function _preValidatePurchase(address beneficiary_, uint256 investment_, IIdoStorage.Vesting vesting_, address referral_, bool maxCap_)
    internal
    whenNotPaused
    view
  {
    if (beneficiary_ == address(0)) revert BeneficiaryNullAddressErr();
    if (beneficiary_ == referral_) revert IvalidReferralErr();
    if (investment_ == 0) revert InvestmentNullErr();
    
    // validates if sale and round is open
    if (!_idoStorage.isOpened()) revert IdoClosedErr();
    uint256 activeRound = _idoStorage.getActiveRound();
    IIdoStorage.Round memory round = _idoStorage.getRound(activeRound);

    if (round.state != IIdoStorageState.State.Opened) revert RoundClosedErr();
    if (round.totalSupply < round.tokensSold + _getTokenAmount(investment_, vesting_))
      revert ExceededRoundAllocationErr();

    // validates investment amount
    uint8 priceDecimals = _priceFeed.decimals();
    (, int256 price, , uint256 updatedAt,) = _priceFeed.latestRoundData();
    if (block.timestamp - updatedAt > _priceFeedTimeThreshold) revert ExceededPriceFeedTimeThresholdErr();

    uint256 normalizedAmount = (investment_ * uint256(price) * PRECISION) / (10 ** (TOKEN_DECIMALS + priceDecimals));
    if (_idoStorage.getMinInvestment() > normalizedAmount) revert MinInvestmentErr(normalizedAmount, _idoStorage.getMinInvestment());
    uint256 cap = maxCap_ ? _idoStorage.maxCapOf(beneficiary_) : _idoStorage.capOf(beneficiary_);
    if (cap < normalizedAmount) revert MaxInvestmentErr(normalizedAmount, cap);

    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
  }

  /**
   * @dev Returns referral data.
   * @param beneficiary_  address performing the token purchase.
   * @param referral_  referral owner.
   * @param vesting_  vesting of the investment.
   * @param investment_  native coins paid for the purchase.
   */
  function _preProcessReferral(address beneficiary_, address referral_, IIdoStorage.Vesting vesting_, uint256 investment_)
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
    uint256 tokenReward = _getTokenAmount(secondaryReward, vesting_);

    return (referral, mainReward, tokenReward);
  }

  /**
   * @return Amount of tokens that can be purchased with specified native coin investment.
   * @param investment_  native coins paid for the purchase.
   * @param vesting_  vesting of the investment.
   */
  function _getTokenAmount(uint256 investment_, IIdoStorage.Vesting vesting_)
    internal
    view
    returns (uint256)
  {
    uint8 priceDecimals = _priceFeed.decimals();
    (, int256 price, , uint256 updatedAt,) = _priceFeed.latestRoundData();
    if (block.timestamp - updatedAt > _priceFeedTimeThreshold) revert ExceededPriceFeedTimeThresholdErr();

    return (investment_ * uint256(price) * PRECISION) / _idoStorage.getPrice(vesting_) / (10 ** priceDecimals);
  }
}