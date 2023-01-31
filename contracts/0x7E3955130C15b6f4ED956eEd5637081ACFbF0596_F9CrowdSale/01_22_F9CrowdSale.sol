//SPDX-License-Identifier: Unlicense
pragma solidity 0.5.16;
// import "openzeppelin-solidity2/contracts/crowdsale/Crowdsale.sol";
// import "openzeppelin-solidity2/contracts/crowdsale/distribution/PostDeliveryCrowdsale.sol";
// import "openzeppelin-solidity2/contracts/crowdsale/validation/TimedCrowdsale.sol";
// import "openzeppelin-solidity2/contracts/math/SafeMath.sol";
// import "openzeppelin-solidity2/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity2/crowdsale/Crowdsale.sol";
import "openzeppelin-solidity2/crowdsale/distribution/PostDeliveryCrowdsale.sol";
import "openzeppelin-solidity2/crowdsale/validation/TimedCrowdsale.sol";
import "openzeppelin-solidity2/math/SafeMath.sol";
import "openzeppelin-solidity2/ownership/Ownable.sol";
import "./Staker.sol";
import "./stakingToken.sol";

contract ERC20IDO is IERC20 {
  function setStartTimestamp(uint256 _newStart) external;
}

contract F9CrowdSale is Crowdsale, TimedCrowdsale, PostDeliveryCrowdsale, Ownable {
  using SafeMath for uint256;

  Staker public stakingContract;
  address public f9TokenAddress;
  address public shibaTokenAddress;
  IERC20 public tokenInstance;

  // Have minimum and maximum contributions
  uint256 public investorMinCap = .02 * 10**18;
  uint256 public investorHardCap = 1 * 10**18;
  enum SalePhase {
    PREREGISTRATION,
    F9REGISTRATION,
    SHIBAREGISTRATION,
    OPENSALE
  }
  SalePhase phase = SalePhase.PREREGISTRATION;

  // Track investor contributions
  mapping(address => uint256) private contributions;
  // Track registrants
  mapping(address => uint256) private multiplier;

  bool public salesOpen = false;
  uint256 public tokenBalance;
  uint256 public IDOrate;
  uint256[3] public shibTier = [9999 * 10**18, 49999 * 10**18, 99999 * 10**18];

  event TokensPurchasedTimestamp(uint256 date, address indexed beneficiary, uint256 amount);

  event Registered(uint256 date, address indexed beneficiary, uint256 allocationMultiple);
  event withdrawRemaining(uint256 amount, uint256 timestamp);
  event emergencyWithdrawal(uint256 amount, uint256 timestamp);
  event updateShibaTierLevels(
    uint256 lowTier,
    uint256 middleTier,
    uint256 highTier,
    uint256 timestamp
  );
  event changeSalePhase(SalePhase newPhase, uint256 timestamp);
  event changeSaleOpen(bool salesOpen, uint256 timestamp);
  event changeRate(uint256 newRate, uint256 timestamp);
  event changeMinCap(uint256 newMinCap, uint256 timestamp);
  event changeMaxCap(uint256 newMaxCap, uint256 timestamp);
  event changeSaleEnd(uint256 newSaleEnd, uint256 timestamp);

  constructor(
    uint256 _rate,
    address payable _wal,
    IERC20 _token,
    uint256 _openingTime,
    uint256 _closingTime,
    Staker _stakingContract,
    address _f9Token,
    address _shibaToken
  )
    public
    Crowdsale(_rate, _wal, _token)
    TimedCrowdsale(_openingTime, _closingTime)
    PostDeliveryCrowdsale()
    Ownable()
  {
    IDOrate = _rate;
    tokenInstance = _token;
    stakingContract = _stakingContract;
    f9TokenAddress = _f9Token;
    shibaTokenAddress = _shibaToken;
  }

  function() external payable {
    revert();
  }

  /**
   * @dev Deposit tokens to be sold in IDO
   * @param tokens number of tokens deposited into contract
   */
  function depositTokens(uint256 tokens) external {
    uint256 amountBefore = tokenInstance.balanceOf(address(this));

    if (amountBefore > tokenBalance) {
      tokenBalance = amountBefore; //update token deposit made through direct transfers
    }

    if (tokens != 0) {
      // Only the sale token specified in the constructor can be deposited
      tokenInstance.transferFrom(_msgSender(), address(this), tokens);
      uint256 amountAfter = tokenInstance.balanceOf(address(this));
      uint256 _amount = amountAfter.sub(amountBefore);
      tokenBalance = tokenBalance.add(_amount);
    }
  }

  /**
   * @dev Owner can withdraw unsold tokens
   */
  function sweepTokens() external onlyOwner {
    uint256 withdrawalAmount = tokenBalance;
    tokenBalance = 0;
    tokenInstance.transfer(_msgSender(), withdrawalAmount);
    emit withdrawRemaining(withdrawalAmount, now);
  }

  /**
   * @dev Failsafe to withdraw in case tokenBalance state variable becomes corrupted
   */
  function emergencyWithdraw() external onlyOwner {
    uint256 withdrawalAmount = tokenInstance.balanceOf(address(this));
    tokenInstance.transfer(_msgSender(), withdrawalAmount);
    emit emergencyWithdrawal(withdrawalAmount, now);
  }

  /**
   * @dev Owner can update the amount of Shiba tokens required for each tier
   */
  function updateShibaTiers(
    uint256 lowTier,
    uint256 middleTier,
    uint256 upperTier
  ) public onlyOwner {
    shibTier = [lowTier, middleTier, upperTier];
    stakingContract.updateShibaTiers(lowTier, middleTier, upperTier);
    emit updateShibaTierLevels(lowTier, middleTier, upperTier, now);
  }

  /**
   * @dev Called by user to register for the IDO.
   * 	Determines allocation multiplier, and locks'
   * 	users stake for 12960 minutes
   * @param _token address of token which user is staking
   * 	to participate
   */
  function registerIDO(address _token) external {
    uint256 stakedBalance = stakingContract.stakedBalance(IERC20(_token), _msgSender());
    require(stakedBalance > 0, "IDO: No staked tokens to register");
    if (_token == shibaTokenAddress) {
      require(phase == SalePhase.SHIBAREGISTRATION, "IDO: Not Shiba Inu Registration");
      if (stakedBalance >= shibTier[2]) {
        multiplier[_msgSender()] = 10;
      } else if (stakedBalance >= shibTier[1]) {
        multiplier[_msgSender()] = 5;
      } else if (stakedBalance >= shibTier[0]) {
        multiplier[_msgSender()] = 1;
      } else {
        revert("IDO: Insufficient Shiba Inu stake");
      }
    } else if (_token == f9TokenAddress) {
      require(phase == SalePhase.F9REGISTRATION, "IDO: Not F9 Registration");
      if (stakedBalance >= 4206969 * 10**9) {
        multiplier[_msgSender()] = 420;
      } else if (stakedBalance >= 999999 * 10**9) {
        multiplier[_msgSender()] = 100;
      } else if (stakedBalance >= 499999 * 10**9) {
        multiplier[_msgSender()] = 50;
      } else if (stakedBalance >= 99999 * 10**9) {
        multiplier[_msgSender()] = 10;
      } else if (stakedBalance >= 9999 * 10**9) {
        multiplier[_msgSender()] = 1;
      } else {
        revert("IDO: Insufficient F9 stake");
      }
    }
    emit Registered(now, _msgSender(), multiplier[_msgSender()]);
    stakingContract.lock(_msgSender(), now + 12960 minutes);
  }

  /**
   * @dev Owner can set sale phase.
   *
   * Note that sales are ALSO halted/unhalted by the openSalePeriod() function
   *
   * SalePhase is an enum with three possible values:
   *  PREREGISTRATION (CLOSED) : 0
   * 	F9REGISTRATION : 1
   *  SHIBAREGISTRATION : 2
   *  OPENSALE : 3
   *
   * The contract sets the phase to 0 upon deployment and _salesOpen to false.
   *
   * @param _phase current sale phase
   *
   */
  function advanceSalePhase(SalePhase _phase) external onlyOwner {
    phase = _phase;
    emit changeSalePhase(_phase, now);
  }

  function getSalePhase() external view returns (SalePhase) {
    return phase;
  }

  /**
   * @dev Owner can open or close sale period
   * @param _salesOpen boolean true/false: sale period is open
   */
  function openSalePeriod(bool _salesOpen) external onlyOwner {
    salesOpen = _salesOpen;
    emit changeSaleOpen(_salesOpen, now);
  }

  /**
   * @dev Owner can update rate
   * @param _rate uint New Token rate
   */
  function setRate(uint256 _rate) external onlyOwner {
    IDOrate = _rate;
    emit changeRate(_rate, now);
  }

  function rate() public view returns (uint256) {
    return IDOrate;
  }

  /**
   * @dev Owner can update investor minimum
   * @param _minCap uint Minimum individual purchase
   */
  function setMinCap(uint256 _minCap) external onlyOwner {
    investorMinCap = _minCap;
    emit changeMinCap(_minCap, now);
  }

  /**
   * @dev Owner can update investor maximum
   * @param _maxCap uint Maximum individual purchase
   */
  function setMaxCap(uint256 _maxCap) external onlyOwner {
    investorHardCap = _maxCap;
    emit changeMaxCap(_maxCap, now);
  }

  /**
   *  @dev Returns the amount contributed so far by a specific user.
   *  @param _beneficiary Address of contributor
   *  @return User contribution so far
   */
  function getUserContribution(address _beneficiary) public view returns (uint256) {
    return contributions[_beneficiary];
  }

  /**
   * @dev Returns the allocation multiplier for a given registrant
   * @param _registrant address of registrant
   */
  function getMultiplier(address _registrant) external view returns (uint256) {
    return multiplier[_registrant];
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect investor min/max funding cap.
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view salePeriod {
    require(phase == SalePhase.OPENSALE, "IDO: Not open sale period");
    require(_beneficiary == _msgSender(), "IDO: User may only purchase tokens for themself");
    require(multiplier[_beneficiary] > 0, "IDO: User did not register successfully");
    // Check that contribution respects minimum and maximum caps
    uint256 _existingContribution = contributions[_beneficiary];
    uint256 _newContribution = _existingContribution.add(_weiAmount);
    require(_newContribution >= investorMinCap, "IDO: Must meet minimum investment requirement");
    require(
      _newContribution <= investorHardCap.mul(multiplier[_beneficiary]),
      "IDO: Must not exceed individual allocation"
    );
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

  /**
   * @dev Updates beneficiary contribution and contract eth balance
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    uint256 _existingContribution = contributions[_beneficiary];
    uint256 _newContribution = _existingContribution.add(_weiAmount);
    contributions[_beneficiary] = _newContribution;
    super._updatePurchasingState(_beneficiary, _weiAmount);
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
    return weiAmount.mul(IDOrate);
  }

  /**
   * @dev Delivers tokens after a sale is completed
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(tokenBalance >= _tokenAmount, "Not enough token balance");
    tokenBalance = tokenBalance.sub(_tokenAmount);
    tokenInstance.transfer(_beneficiary, _tokenAmount);
    emit TokensPurchasedTimestamp(now, _beneficiary, _tokenAmount);
  }

  /**
   * @dev Dev can extend length of sale if it has not already ended
   * @param _newTime new end-of-sale timestamp
   */
  function extendTime(uint256 _newTime) external onlyOwner {
    _extendTime(_newTime);
    ERC20IDO(address(tokenInstance)).setStartTimestamp(_newTime);
    emit changeSaleEnd(_newTime, now);
  }

  modifier salePeriod() {
    require(salesOpen, "IDO: Not sale period");
    _;
  }
}