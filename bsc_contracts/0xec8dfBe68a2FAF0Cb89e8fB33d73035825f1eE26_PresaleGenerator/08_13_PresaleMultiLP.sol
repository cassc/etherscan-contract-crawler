// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./libraries/TransferHelper.sol";
import "./libraries/EnumerableSet.sol";
import "./libraries/SafeMath.sol";
import "./libraries/ReentrancyGuard.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IPresaleLockForwarder.sol";
import "./interfaces/IPresaleSettings.sol";

contract PresaleMultiLP is ReentrancyGuard {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;
  
  /// @notice Presale Contract Version, used to choose the correct ABI to decode the contract
  uint256 public CONTRACT_VERSION = 1;
  
  struct PresaleInfo {
    address payable PRESALE_OWNER;
    IERC20 S_TOKEN; // sale token
    IERC20 B_TOKEN; // base token // usually WETH (ETH)
    uint256 TOKEN_PRICE; // 1 base token = ? s_tokens, fixed price
    uint256 MIN_SPEND_PER_BUYER; // minimum base token BUY amount per account
    uint256 MAX_SPEND_PER_BUYER; // maximum base token BUY amount per account
    uint256 AMOUNT; // the amount of presale tokens up for presale
    uint256 HARDCAP;
    uint256 SOFTCAP;
    uint256 LIQUIDITY_PERCENT_PYE; // divided by 1000
    uint256 LIQUIDITY_PERCENT_CAKE; // divided by 1000
    uint256 LISTING_RATE; // fixed rate at which the token will list on PYESwap
    uint256 START_TIMESTAMP;
    uint256 END_TIMESTAMP;
    uint256 LOCK_PERIOD; // unix timestamp -> e.g. 2 weeks
    bool PRESALE_IN_ETH; // if this flag is true the presale is raising ETH, otherwise an ERC20 token such as BUSD
  }
  
  struct PresaleFeeInfo {
    uint256 PYE_LAB_BASE_FEE; // divided by 1000
    uint256 PYE_LAB_TOKEN_FEE; // divided by 1000
    uint256 REFERRAL_FEE; // divided by 1000
    address payable BASE_FEE_ADDRESS;
    address payable TOKEN_FEE_ADDRESS;
    address payable REFERRAL_FEE_ADDRESS; // if this is not address(0), there is a valid referral
  }
  
  struct PresaleStatus {
    bool ALLOWLIST_ONLY; // if set to true only allowlisted members may participate
    bool LP_GENERATION_COMPLETE; // final flag required to end a presale and enable withdrawls
    bool FORCE_FAILED; // set this flag to force fail the presale
    uint256 TOTAL_BASE_COLLECTED; // total base currency raised (usually ETH)
    uint256 TOTAL_TOKENS_SOLD; // total presale tokens sold
    uint256 TOTAL_TOKENS_WITHDRAWN; // total tokens withdrawn post successful presale
    uint256 TOTAL_BASE_WITHDRAWN; // total base tokens withdrawn on presale failure
    uint256 LEVEL_4_ROUND_LENGTH; // length of round level4 in seconds
    uint256 LEVEL_3_ROUND_LENGTH; // length of round level3 in seconds
    uint256 LEVEL_2_ROUND_LENGTH; // length of round level2 in seconds
    uint256 LEVEL_1_ROUND_LENGTH; // length of round level1 in seconds
    uint256 NUM_BUYERS; // number of unique participants
  }

  struct BuyerInfo {
    uint256 baseDeposited; // total base token (usually ETH) deposited by user, can be withdrawn on presale failure
    uint256 tokensOwed; // num presale tokens a user is owed, can be withdrawn on presale success
  }
  
  PresaleInfo public PRESALE_INFO;
  PresaleFeeInfo public PRESALE_FEE_INFO;
  PresaleStatus public STATUS;
  address public PRESALE_GENERATOR;
  IPresaleLockForwarder public PRESALE_LOCK_FORWARDER_PYE;
  IPresaleLockForwarder public PRESALE_LOCK_FORWARDER_CAKE;
  IPresaleSettings public PRESALE_SETTINGS;
  address PYE_LAB_FEE_ADDRESS;
  IWETH public WETH;
  mapping(address => BuyerInfo) public BUYERS;
  EnumerableSet.AddressSet private ALLOWLIST;
  uint256 public EARLY_ACCESS_ALLOWANCE; // the amount allowed for early access token holders

  uint256 private COOL_DOWN_TIME;

  mapping(address => bool) private BOTS;
  mapping(address => uint256) private BUY_COOL_DOWN;

  constructor(address _presaleGenerator) {
    PRESALE_GENERATOR = _presaleGenerator;
    WETH = IWETH(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    PRESALE_SETTINGS = IPresaleSettings(0x072c1b341FCE2D2193aD40d7DdC20533c4E590A7);
    PRESALE_LOCK_FORWARDER_PYE = IPresaleLockForwarder(0xCF4516E3aBAc05F6212c602572D071BE026B2218);
    PRESALE_LOCK_FORWARDER_CAKE = IPresaleLockForwarder(0x17ddC1b2c6a0f90967BD75feA3b94a56cFEB439D);
    PYE_LAB_FEE_ADDRESS = 0xd51c85e6b4C44883e1E05F7D74113315e0862971;
  }
  
  function init1(
    address payable _presaleOwner, 
    uint256 _amount,
    uint256 _tokenPrice, 
    uint256 _minEthPerBuyer, 
    uint256 _maxEthPerBuyer, 
    uint256 _hardcap, 
    uint256 _softcap,
    uint256 _liquidityPercentPYE,
    uint256 _liquidityPercentCAKE,
    uint256 _listingRate,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _lockPeriod
    ) external {
          
      require(msg.sender == PRESALE_GENERATOR, 'FORBIDDEN');
      PRESALE_INFO.PRESALE_OWNER = _presaleOwner;
      PRESALE_INFO.AMOUNT = _amount;
      PRESALE_INFO.TOKEN_PRICE = _tokenPrice;
      PRESALE_INFO.MIN_SPEND_PER_BUYER = _minEthPerBuyer;
      PRESALE_INFO.MAX_SPEND_PER_BUYER = _maxEthPerBuyer;
      PRESALE_INFO.HARDCAP = _hardcap;
      PRESALE_INFO.SOFTCAP = _softcap;
      PRESALE_INFO.LIQUIDITY_PERCENT_PYE = _liquidityPercentPYE;
      PRESALE_INFO.LIQUIDITY_PERCENT_CAKE = _liquidityPercentCAKE;

      PRESALE_INFO.LISTING_RATE = _listingRate;
      PRESALE_INFO.START_TIMESTAMP = _startTime;
      PRESALE_INFO.END_TIMESTAMP = _endTime;
      PRESALE_INFO.LOCK_PERIOD = _lockPeriod;
  }
  
  function init2(
    IERC20 _baseToken,
    IERC20 _presaleToken,
    uint256 _pyeLABBaseFee,
    uint256 _pyeLABTokenFee,
    uint256 _referralFee,
    address payable _baseFeeAddress,
    address payable _tokenFeeAddress,
    address payable _referralAddress
    ) external {
          
      require(msg.sender == PRESALE_GENERATOR, 'FORBIDDEN');
      
      PRESALE_INFO.PRESALE_IN_ETH = address(_baseToken) == address(WETH);
      PRESALE_INFO.S_TOKEN = _presaleToken;
      PRESALE_INFO.B_TOKEN = _baseToken;
      PRESALE_FEE_INFO.PYE_LAB_BASE_FEE = _pyeLABBaseFee;
      PRESALE_FEE_INFO.PYE_LAB_TOKEN_FEE = _pyeLABTokenFee;
      PRESALE_FEE_INFO.REFERRAL_FEE = _referralFee;
      
      PRESALE_FEE_INFO.BASE_FEE_ADDRESS = _baseFeeAddress;
      PRESALE_FEE_INFO.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
      PRESALE_FEE_INFO.REFERRAL_FEE_ADDRESS = _referralAddress;
      STATUS.LEVEL_4_ROUND_LENGTH = PRESALE_SETTINGS.getLevel4RoundLength();
      STATUS.LEVEL_3_ROUND_LENGTH = PRESALE_SETTINGS.getLevel3RoundLength();
      STATUS.LEVEL_2_ROUND_LENGTH = PRESALE_SETTINGS.getLevel2RoundLength();
      STATUS.LEVEL_1_ROUND_LENGTH = PRESALE_SETTINGS.getLevel1RoundLength();
  }

  function initEarlyAllowance(uint256 _earlyAllowanceRate) external {  
      require(msg.sender == PRESALE_GENERATOR, 'FORBIDDEN');
      EARLY_ACCESS_ALLOWANCE = _earlyAllowanceRate.mul(PRESALE_INFO.HARDCAP).div(10000);
  }
  
  modifier onlyPresaleOwner() {
    require(PRESALE_INFO.PRESALE_OWNER == msg.sender, "NOT PRESALE OWNER");
    _;
  }
  
  function presaleStatus() public view returns (uint256) {
    if (STATUS.FORCE_FAILED) {
      return 3; // FAILED - force fail
    }
    if ((block.timestamp > PRESALE_INFO.END_TIMESTAMP) && (STATUS.TOTAL_BASE_COLLECTED < PRESALE_INFO.SOFTCAP)) {
      return 3; // FAILED - softcap not met by end time
    }
    if (STATUS.TOTAL_BASE_COLLECTED >= PRESALE_INFO.HARDCAP) {
      return 2; // SUCCESS - hardcap met
    }
    if ((block.timestamp > PRESALE_INFO.END_TIMESTAMP) && (STATUS.TOTAL_BASE_COLLECTED >= PRESALE_INFO.SOFTCAP)) {
      return 2; // SUCCESS - end time and soft cap reached
    }
    if ((block.timestamp >= PRESALE_INFO.START_TIMESTAMP - STATUS.LEVEL_4_ROUND_LENGTH) && (block.timestamp <= PRESALE_INFO.END_TIMESTAMP)) {
      return 1; // ACTIVE - deposits enabled
    }
    return 0; // QUEUED - awaiting start time
  }

  function checkAllowed(address account) public view returns (bool) {
    if (block.timestamp >= PRESALE_INFO.START_TIMESTAMP) {
      if(STATUS.ALLOWLIST_ONLY) require(ALLOWLIST.contains(msg.sender), 'NOT ALLOWLISTED');
      return true;
    } else if (block.timestamp >= PRESALE_INFO.START_TIMESTAMP - STATUS.LEVEL_4_ROUND_LENGTH && ALLOWLIST.contains(account) && !STATUS.ALLOWLIST_ONLY) {
      return true;
    }

    bool allowed = false;
    uint8 accessLevel = PRESALE_SETTINGS.userAllowlistLevel(account);
    if (STATUS.TOTAL_BASE_COLLECTED < EARLY_ACCESS_ALLOWANCE){
      if (block.timestamp >= PRESALE_INFO.START_TIMESTAMP - STATUS.LEVEL_1_ROUND_LENGTH) {
        allowed = accessLevel >= 1;
      } else if (block.timestamp >= PRESALE_INFO.START_TIMESTAMP - STATUS.LEVEL_2_ROUND_LENGTH) {
        allowed = accessLevel >= 2;
      } else if (block.timestamp >= PRESALE_INFO.START_TIMESTAMP - STATUS.LEVEL_3_ROUND_LENGTH) {
        allowed = accessLevel >= 3;
      } else if (block.timestamp >= PRESALE_INFO.START_TIMESTAMP - STATUS.LEVEL_4_ROUND_LENGTH) {
        allowed = accessLevel == 4;
      }
    }
    return allowed;

  }

  function checkTokenFeeExempt() public returns (bool) {
    uint256 balanceBefore = IERC20(PRESALE_INFO.S_TOKEN).balanceOf(address(this));
    TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), address(this), 100);
    uint256 balanceAfter = IERC20(PRESALE_INFO.S_TOKEN).balanceOf(address(this));

    if(balanceBefore == balanceAfter) {
      return true;
    } else {
      return false;
    }
  }
  
  // accepts msg.value for eth or _amount for ERC20 tokens
  function userDeposit(uint256 _amount) external payable nonReentrant {
    bool allowed = checkAllowed(msg.sender);
    require(allowed, 'NOT ACTIVE'); // ACTIVE
    _beforeUserDeposit(msg.sender);

    if (STATUS.ALLOWLIST_ONLY) {
      require(ALLOWLIST.contains(msg.sender), 'NOT ALLOWLISTED');
    }
    BuyerInfo storage buyer = BUYERS[msg.sender];
    require(PRESALE_INFO.MIN_SPEND_PER_BUYER <= _amount.add(buyer.baseDeposited), 'Amount does not meet minimum spend');
    uint256 amount_in = PRESALE_INFO.PRESALE_IN_ETH ? msg.value : _amount;
    uint256 allowance = PRESALE_INFO.MAX_SPEND_PER_BUYER.sub(buyer.baseDeposited);
    uint256 remaining = PRESALE_INFO.HARDCAP - STATUS.TOTAL_BASE_COLLECTED;
    allowance = allowance > remaining ? remaining : allowance;
    if (amount_in > allowance) {
      amount_in = allowance;
    }
    uint256 tokensSold = amount_in.mul(PRESALE_INFO.TOKEN_PRICE).div(10 ** uint256(PRESALE_INFO.B_TOKEN.decimals()));
    require(tokensSold > 0, 'ZERO TOKENS');
    if (buyer.baseDeposited == 0) {
        STATUS.NUM_BUYERS++;
    }
    buyer.baseDeposited = buyer.baseDeposited.add(amount_in);
    buyer.tokensOwed = buyer.tokensOwed.add(tokensSold);
    STATUS.TOTAL_BASE_COLLECTED = STATUS.TOTAL_BASE_COLLECTED.add(amount_in);
    STATUS.TOTAL_TOKENS_SOLD = STATUS.TOTAL_TOKENS_SOLD.add(tokensSold);
    
    // return unused ETH
    if (PRESALE_INFO.PRESALE_IN_ETH && amount_in < msg.value) {
      payable(msg.sender).transfer(msg.value.sub(amount_in));
    }
    // deduct non ETH token from user
    if (!PRESALE_INFO.PRESALE_IN_ETH) {
      TransferHelper.safeTransferFrom(address(PRESALE_INFO.B_TOKEN), msg.sender, address(this), amount_in);
    }
  }

  // emergency withdraw base token while presale active
  // percentile withdrawls allows fee on transfer or rebasing tokens to still work
  function userEmergencyWithdraw() external nonReentrant {
    require(presaleStatus() == 1, 'NOT ACTIVE'); // ACTIVE
    BuyerInfo storage buyer = BUYERS[msg.sender];
    uint256 remainingBaseBalance = PRESALE_INFO.PRESALE_IN_ETH ? address(this).balance : PRESALE_INFO.B_TOKEN.balanceOf(address(this));
    uint256 tokensOwed = remainingBaseBalance.mul(buyer.baseDeposited).div(STATUS.TOTAL_BASE_COLLECTED);
    require(tokensOwed > 0, 'NOTHING TO WITHDRAW');
    STATUS.TOTAL_BASE_COLLECTED = STATUS.TOTAL_BASE_COLLECTED.sub(tokensOwed);
    STATUS.TOTAL_TOKENS_SOLD = STATUS.TOTAL_TOKENS_SOLD.sub(buyer.tokensOwed);
    buyer.baseDeposited = 0;
    buyer.tokensOwed = 0;
    STATUS.NUM_BUYERS--;
    TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), payable(msg.sender), tokensOwed, !PRESALE_INFO.PRESALE_IN_ETH);
  }
  
  // withdraw presale tokens
  // percentile withdrawls allows fee on transfer or rebasing tokens to still work
  function userWithdrawTokens() external nonReentrant {
    require(STATUS.LP_GENERATION_COMPLETE, 'AWAITING LP GENERATION');
    BuyerInfo storage buyer = BUYERS[msg.sender];
    uint256 tokensRemainingDenominator = STATUS.TOTAL_TOKENS_SOLD.sub(STATUS.TOTAL_TOKENS_WITHDRAWN);
    uint256 tokensOwed = PRESALE_INFO.S_TOKEN.balanceOf(address(this)).mul(buyer.tokensOwed).div(tokensRemainingDenominator);
    require(tokensOwed > 0, 'NOTHING TO WITHDRAW');
    STATUS.TOTAL_TOKENS_WITHDRAWN = STATUS.TOTAL_TOKENS_WITHDRAWN.add(buyer.tokensOwed);
    buyer.tokensOwed = 0;
    TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), msg.sender, tokensOwed);
  }
  
  // on presale failure
  // percentile withdrawls allows fee on transfer or rebasing tokens to still work
  function userWithdrawBaseTokens() external nonReentrant {
    require(presaleStatus() == 3, 'NOT FAILED'); // FAILED
    BuyerInfo storage buyer = BUYERS[msg.sender];
    uint256 baseRemainingDenominator = STATUS.TOTAL_BASE_COLLECTED.sub(STATUS.TOTAL_BASE_WITHDRAWN);
    uint256 remainingBaseBalance = PRESALE_INFO.PRESALE_IN_ETH ? address(this).balance : PRESALE_INFO.B_TOKEN.balanceOf(address(this));
    uint256 tokensOwed = remainingBaseBalance.mul(buyer.baseDeposited).div(baseRemainingDenominator);
    require(tokensOwed > 0, 'NOTHING TO WITHDRAW');
    STATUS.TOTAL_BASE_WITHDRAWN = STATUS.TOTAL_BASE_WITHDRAWN.add(tokensOwed);
    buyer.baseDeposited = 0;
    TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), payable(msg.sender), tokensOwed, !PRESALE_INFO.PRESALE_IN_ETH);
  }
  
  // on presale failure
  // allows the owner to withdraw the tokens they sent for presale & initial liquidity
  function ownerWithdrawTokens() external onlyPresaleOwner {
    require(presaleStatus() == 3); // FAILED
    TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), PRESALE_INFO.PRESALE_OWNER, PRESALE_INFO.S_TOKEN.balanceOf(address(this)));
  }
  

  // Can be called at any stage before or during the presale to cancel it before it ends.
  // If the pair already exists on PYESwap and it contains the presale token as liquidity
  // the final stage of the presale 'addLiquidity()' will fail. This function 
  // allows anyone to end the presale prematurely to release funds in such a case.
  function forceFailIfPairExists() external {
    require(!STATUS.LP_GENERATION_COMPLETE && !STATUS.FORCE_FAILED);
    if (PRESALE_LOCK_FORWARDER_PYE.PYELabPairIsInitialised(address(PRESALE_INFO.S_TOKEN), address(PRESALE_INFO.B_TOKEN)) &&
        PRESALE_LOCK_FORWARDER_CAKE.PYELabPairIsInitialised(address(PRESALE_INFO.S_TOKEN), address(PRESALE_INFO.B_TOKEN))) {
        STATUS.FORCE_FAILED = true;
    }
  }
  
  // if something goes wrong in LP generation
  function forceFailByPYELab() external {
      require(msg.sender == PYE_LAB_FEE_ADDRESS);
      STATUS.FORCE_FAILED = true;
  }

  // if presale owner needs to cancel presale
  function forceFailByOwner() onlyPresaleOwner external {
      require(!STATUS.LP_GENERATION_COMPLETE && !STATUS.FORCE_FAILED);
      STATUS.FORCE_FAILED = true;
  }
  
  // on presale success, this is the final step to end the presale, lock liquidity and enable withdrawls of the sale token.
  // This function does not use percentile distribution. Rebasing mechanisms, fee on transfers, or any deflationary logic
  // are not taken into account at this stage to ensure stated liquidity is locked and the pool is initialised according to 
  // the presale parameters and fixed prices.
  function addLiquidity() external onlyPresaleOwner nonReentrant {
    require(!STATUS.LP_GENERATION_COMPLETE, 'GENERATION COMPLETE');
    require(presaleStatus() == 2, 'NOT SUCCESS'); // SUCCESS
    // Fail the presale if the pair exists and contains presale token liquidity
    if (PRESALE_LOCK_FORWARDER_PYE.PYELabPairIsInitialised(address(PRESALE_INFO.S_TOKEN), address(PRESALE_INFO.B_TOKEN)) && 
        PRESALE_LOCK_FORWARDER_CAKE.PYELabPairIsInitialised(address(PRESALE_INFO.S_TOKEN), address(PRESALE_INFO.B_TOKEN))) {
        STATUS.FORCE_FAILED = true;
        return;
      }
    
    uint256 pyeLABBaseFee = STATUS.TOTAL_BASE_COLLECTED.mul(PRESALE_FEE_INFO.PYE_LAB_BASE_FEE).div(1000);

    
    // PYESwap Liquidity
    // base token liquidity
    uint256 baseLiquidityPYE = STATUS.TOTAL_BASE_COLLECTED.sub(pyeLABBaseFee).mul(PRESALE_INFO.LIQUIDITY_PERCENT_PYE).div(1000);
    if (PRESALE_INFO.PRESALE_IN_ETH) {
        WETH.deposit{value : baseLiquidityPYE}();
    }
    TransferHelper.safeApprove(address(PRESALE_INFO.B_TOKEN), address(PRESALE_LOCK_FORWARDER_PYE), baseLiquidityPYE);
    
    // sale token liquidity
    uint256 tokenLiquidityPYE = baseLiquidityPYE.mul(PRESALE_INFO.LISTING_RATE).div(10 ** uint256(PRESALE_INFO.B_TOKEN.decimals()));
    TransferHelper.safeApprove(address(PRESALE_INFO.S_TOKEN), address(PRESALE_LOCK_FORWARDER_PYE), tokenLiquidityPYE);
    
    PRESALE_LOCK_FORWARDER_PYE.lockLiquidity(PRESALE_INFO.B_TOKEN, PRESALE_INFO.S_TOKEN, baseLiquidityPYE, tokenLiquidityPYE, block.timestamp + PRESALE_INFO.LOCK_PERIOD, PRESALE_INFO.PRESALE_OWNER);

    

    // PancakeSwap Liquidity
    // base token liquidity
    uint256 baseLiquidityCAKE = STATUS.TOTAL_BASE_COLLECTED.sub(pyeLABBaseFee).mul(PRESALE_INFO.LIQUIDITY_PERCENT_CAKE).div(1000);
    if (PRESALE_INFO.PRESALE_IN_ETH) {
        WETH.deposit{value : baseLiquidityCAKE}();
    }
    TransferHelper.safeApprove(address(PRESALE_INFO.B_TOKEN), address(PRESALE_LOCK_FORWARDER_CAKE), baseLiquidityCAKE);
    
    // sale token liquidity
    uint256 tokenLiquidityCAKE = baseLiquidityCAKE.mul(PRESALE_INFO.LISTING_RATE).div(10 ** uint256(PRESALE_INFO.B_TOKEN.decimals()));
    TransferHelper.safeApprove(address(PRESALE_INFO.S_TOKEN), address(PRESALE_LOCK_FORWARDER_CAKE), tokenLiquidityCAKE);
    
    PRESALE_LOCK_FORWARDER_CAKE.lockLiquidity(PRESALE_INFO.B_TOKEN, PRESALE_INFO.S_TOKEN, baseLiquidityCAKE, tokenLiquidityCAKE, block.timestamp + PRESALE_INFO.LOCK_PERIOD, PRESALE_INFO.PRESALE_OWNER);
    
    

    // transfer fees
    uint256 pyeLABTokenFee = STATUS.TOTAL_TOKENS_SOLD.mul(PRESALE_FEE_INFO.PYE_LAB_TOKEN_FEE).div(1000);
    // referrals are checked for validity in the presale generator
    if (PRESALE_FEE_INFO.REFERRAL_FEE_ADDRESS != address(0)) {
        // Base token fee
        uint256 referralBaseFee = pyeLABBaseFee.mul(PRESALE_FEE_INFO.REFERRAL_FEE).div(1000);
        TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), PRESALE_FEE_INFO.REFERRAL_FEE_ADDRESS, referralBaseFee, !PRESALE_INFO.PRESALE_IN_ETH);
        pyeLABBaseFee = pyeLABBaseFee.sub(referralBaseFee);
    }
    TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), PRESALE_FEE_INFO.BASE_FEE_ADDRESS, pyeLABBaseFee, !PRESALE_INFO.PRESALE_IN_ETH);
    TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), PRESALE_FEE_INFO.TOKEN_FEE_ADDRESS, pyeLABTokenFee);
    
    // burn unsold tokens
    uint256 remainingSBalance = PRESALE_INFO.S_TOKEN.balanceOf(address(this));
    if (remainingSBalance > STATUS.TOTAL_TOKENS_SOLD) {
        uint256 burnAmount = remainingSBalance.sub(STATUS.TOTAL_TOKENS_SOLD);
        TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), 0x000000000000000000000000000000000000dEaD, burnAmount);
    }
    
    // send remaining base tokens to presale owner
    uint256 remainingBaseBalance = PRESALE_INFO.PRESALE_IN_ETH ? address(this).balance : PRESALE_INFO.B_TOKEN.balanceOf(address(this));
    TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), PRESALE_INFO.PRESALE_OWNER, remainingBaseBalance, !PRESALE_INFO.PRESALE_IN_ETH);
    
    STATUS.LP_GENERATION_COMPLETE = true;
  }
  
  function updateSpendLimit(uint256 _minSpend, uint256 _maxSpend) external onlyPresaleOwner {
    PRESALE_INFO.MIN_SPEND_PER_BUYER = _minSpend;
    PRESALE_INFO.MAX_SPEND_PER_BUYER = _maxSpend;
  }
  
  // postpone or bring a presale forward, this will only work when a presale is inactive.
  // i.e. current start time > block.timestamp
  function updateBlocks(uint256 _startTime, uint256 _endTime) external onlyPresaleOwner {
    require(PRESALE_INFO.START_TIMESTAMP > block.timestamp);
    require(_endTime.sub(_startTime) <= PRESALE_SETTINGS.getMaxPresaleLength());
    PRESALE_INFO.START_TIMESTAMP = _startTime;
    PRESALE_INFO.END_TIMESTAMP = _endTime;
  }

  // update the amount of hardcap that is allowed to early access token holders. Entered as a numerator with a constant denominator of 10000
  // i.e. 5000 = 50% , 7500 = 75%, etc. Must be greater than the minimum rate set by PYELab
  function updateEarlyAllowance(uint256 _earlyAllowanceRate) external onlyPresaleOwner {  
      require(_earlyAllowanceRate >= PRESALE_SETTINGS.getMinEarlyAllowance(), 'Invalid Early Access Allowance');
      EARLY_ACCESS_ALLOWANCE = _earlyAllowanceRate.mul(PRESALE_INFO.HARDCAP).div(10000);
  }

  // editable at any stage of the presale
  function setAllowlistFlag(bool _flag) external onlyPresaleOwner {
    STATUS.ALLOWLIST_ONLY = _flag;
  }

  // editable at any stage of the presale
  function editAllowlist(address[] memory _users, bool _add) external onlyPresaleOwner {
    if (_add) {
        for (uint i = 0; i < _users.length; i++) {
          ALLOWLIST.add(_users[i]);
        }
    } else {
        for (uint i = 0; i < _users.length; i++) {
          ALLOWLIST.remove(_users[i]);
        }
    }
  }

  // allowlist getters
  function getAllowlistedUsersLength() external view returns (uint256) {
    return ALLOWLIST.length();
  }
  
  function getAllowlistedUserAtIndex(uint256 _index) external view returns (address) {
    return ALLOWLIST.at(_index);
  }
  
  function getUserAllowlistStatus(address _user) external view returns (bool) {
    return ALLOWLIST.contains(_user);
  }

  function refreshRoundLengths() external {
    STATUS.LEVEL_4_ROUND_LENGTH = PRESALE_SETTINGS.getLevel4RoundLength();
    STATUS.LEVEL_3_ROUND_LENGTH = PRESALE_SETTINGS.getLevel3RoundLength();
    STATUS.LEVEL_2_ROUND_LENGTH = PRESALE_SETTINGS.getLevel2RoundLength();
    STATUS.LEVEL_1_ROUND_LENGTH = PRESALE_SETTINGS.getLevel1RoundLength();
  }

  // Anti-Bot Mechanisms

  function isContract(address account) internal view returns (bool) {
      uint256 size;
      assembly { size := extcodesize(account) }
      return size > 0;
  }

  function _beforeUserDeposit(address _buyer) internal {
      if (_buyer != PRESALE_INFO.PRESALE_OWNER) {
          require(!isContract(_buyer), "PYELab Bot Protector: Contracts are not allowed to deposit");
          require(_buyer == tx.origin, "PYELab Bot Protector: Proxy contract not allowed");
          require(!BOTS[_buyer], "PYELab Bot Protector: address is denylisted");
          require(BUY_COOL_DOWN[_buyer] < block.timestamp, "PYELab Bot Protector: can't buy until cool down");

          BUY_COOL_DOWN[_buyer] = block.timestamp + COOL_DOWN_TIME;
      }
  }

  function addBot(address _bot) external onlyPresaleOwner {
      BOTS[_bot] = true;
  }

  function removeBot(address _account) external onlyPresaleOwner {
      BOTS[_account] = false;
  }

  function setCoolDownTime(uint256 _amount) external onlyPresaleOwner {
      COOL_DOWN_TIME = _amount;
  }

  function isBot(address _account) external view returns (bool) {
      return BOTS[_account];
  }
}