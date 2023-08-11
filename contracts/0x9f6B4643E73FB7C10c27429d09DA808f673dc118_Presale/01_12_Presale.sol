//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface Aggregator {
  function decimals() external view returns (uint8);
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract Presale is
  Initializable,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable,
  PausableUpgradeable
{
  using SafeERC20 for IERC20;

  struct Round {
    uint256 amount;
    uint256 price;
    uint256 endTime;
  }

  uint256 public totalTokensSold;
  uint256 public startTime;
  uint256 public endTime;
  uint256 public claimStart;
  address public saleToken;
  uint256 public baseDecimals;
  uint256 public usdtDecimals;
  uint256 public tokenDecimals;
  uint256 public maxTokensToBuy;
  uint256 public currentStep;
  Round[] public rounds;
  uint256 public checkPoint;
  uint256 public usdRaised;
  uint256[] public prevCheckpoints;
  uint256[] public remainingTokensTracker;
  uint256 public timeConstant;
  address public paymentWallet;
  bool public dynamicTimeFlag;
  bool public whitelistClaimOnly;

  IERC20 public USDT;
  Aggregator public priceFeed;
  mapping(address => uint256) public userDeposits;
  mapping(address => bool) public hasClaimed;
  mapping(address => bool) public isBlacklisted;
  mapping(address => bool) public isWhitelisted;
  address public admin;

  event SaleTimeSet(uint256 _start, uint256 _end, uint256 timestamp);
  event SaleTimeUpdated(
    bytes32 indexed key,
    uint256 prevValue,
    uint256 newValue,
    uint256 timestamp
  );
  event TokensBought(
    address indexed user,
    uint256 indexed tokensBought,
    address indexed purchaseToken,
    uint256 amountPaid,
    uint256 usdEq,
    uint256 timestamp
  );
  event TokensAdded(
    address indexed token,
    uint256 noOfTokens,
    uint256 timestamp
  );
  event TokensClaimed(
    address indexed user,
    uint256 amount,
    uint256 timestamp
  );
  event ClaimStartUpdated(
    uint256 prevValue,
    uint256 newValue,
    uint256 timestamp
  );
  event MaxTokensUpdated(
    uint256 prevValue,
    uint256 newValue,
    uint256 timestamp
  );

  function initialize(
    address _priceFeed, 
    address _usdt, 
    uint256 _startTime,
    uint256 _endTime,
    Round[] memory _rounds
  ) initializer public {
    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();

    priceFeed = Aggregator(_priceFeed);
    USDT = IERC20(_usdt);

    baseDecimals = 10 ** 18;
    usdtDecimals = 10 ** IERC20Metadata(_usdt).decimals();

    startTime = _startTime;
    endTime = _endTime;

    dynamicTimeFlag = true;
    maxTokensToBuy = 9_999_999_999;

    admin = 0x9B9460204B24E605aCf5b98a68e44B09979779c6;

    _changeRoundsData(_rounds);
  }

  /**
   * @dev To pause the presale
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @dev To unpause the presale
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @dev To calculate the price in USD for given amount of tokens.
   * @param _amount No of tokens
   */
  function calculatePrice(uint256 _amount) public view returns (uint256) {
    uint256 USDTAmount;
    uint256 total = checkPoint == 0 ? totalTokensSold : checkPoint;
    require(_amount <= maxTokensToBuy, "Amount exceeds max tokens to buy");
    if (
      _amount + total > rounds[currentStep].amount ||
      block.timestamp >= rounds[currentStep].endTime
    ) {
      require(currentStep < (rounds.length - 1), "Wrong params");

      if (block.timestamp >= rounds[currentStep].endTime) {
        require(
          rounds[currentStep].amount + _amount <=
            rounds[currentStep + 1].amount,
          "Cant Purchase More in individual tx"
        );
        USDTAmount = _amount * rounds[currentStep + 1].price;
      } else {
        uint256 tokenAmountForCurrentPrice = rounds[currentStep].amount - total;
        USDTAmount =
          tokenAmountForCurrentPrice * rounds[currentStep].price +
          (_amount - tokenAmountForCurrentPrice) * rounds[currentStep + 1].price;
      }
    } else USDTAmount = _amount * rounds[currentStep].price;
    return USDTAmount;
  }

  /**
   * @dev To update the sale times
   * @param _startTime New start time
   * @param _endTime New end time
   */
  function changeSaleTimes(
    uint256 _startTime,
    uint256 _endTime
  ) external onlyOwner {
    require(_startTime > 0 || _endTime > 0, "Invalid parameters");
    if (_startTime > 0) {
      require(block.timestamp < startTime, "Sale already started");
      require(block.timestamp < _startTime, "Sale time in past");
      uint256 prevValue = startTime;
      startTime = _startTime;
      emit SaleTimeUpdated(
        bytes32("START"),
        prevValue,
        _startTime,
        block.timestamp
      );
    }

    if (_endTime > 0) {
      require(block.timestamp < endTime, "Sale already ended");
      require(_endTime > startTime, "Invalid endTime");
      uint256 prevValue = endTime;
      endTime = _endTime;
      emit SaleTimeUpdated(
        bytes32("END"),
        prevValue,
        _endTime,
        block.timestamp
      );
    }
  }

  /**
   * @dev To get latest Native price in 10**18 format
   */
  function getLatestPrice() public view returns (uint256 price) {
    (, int256 answer, , , ) = priceFeed.latestRoundData();
    price = uint256(answer) * (10 ** (18 - priceFeed.decimals()));
  }

  modifier checkSaleState(uint256 amount) {
    require(
      block.timestamp >= startTime && block.timestamp <= endTime,
      "Invalid time for buying"
    );
    require(amount > 0, "Invalid sale amount");
    _;
  }

  /**
   * @dev To buy into a presale using USDT
   * @param amount No of tokens to buy
   */
  function buyWithUSDT(
    uint256 amount
  ) external checkSaleState(amount) whenNotPaused returns (bool) {
    uint256 usdPrice = calculatePrice(amount);
    totalTokensSold += amount;
    checkPoint += amount;
    uint256 total = totalTokensSold > checkPoint
      ? totalTokensSold
      : checkPoint;
    if (
      total > rounds[currentStep].amount ||
      block.timestamp >= rounds[currentStep].endTime
    ) {
      if (block.timestamp >= rounds[currentStep].endTime) {
        checkPoint = rounds[currentStep].amount + amount;
      } else {
        if (dynamicTimeFlag) {
          manageTimeDiff();
        }
      }
      uint256 unsoldTokens = total > rounds[currentStep].amount
        ? 0
        : rounds[currentStep].amount - total;
      remainingTokensTracker.push(unsoldTokens);
      currentStep += 1;
    }
    userDeposits[_msgSender()] += (amount * baseDecimals);
    usdRaised += usdPrice;

    uint256 ourAllowance = USDT.allowance(_msgSender(), address(this));
    uint256 price = usdPrice / (baseDecimals / usdtDecimals);
    require(price <= ourAllowance, "Make sure to add enough allowance");

    USDT.safeTransferFrom(_msgSender(), address(this), price);

    emit TokensBought(_msgSender(), amount, address(USDT), price, usdPrice, block.timestamp);
    return true;
  }

  /**
   * @dev To buy into a presale using Native
   * @param amount No of tokens to buy
   */
  function buyWithNative(
    uint256 amount
  )
    external
    payable
    checkSaleState(amount)
    whenNotPaused
    nonReentrant
    returns (bool)
  {
    uint256 usdPrice = calculatePrice(amount);
    uint256 nativeAmount = (usdPrice * baseDecimals) / getLatestPrice();
    require(msg.value >= nativeAmount, "Less payment");
    uint256 excess = msg.value - nativeAmount;
    totalTokensSold += amount;
    checkPoint += amount;
    uint256 total = totalTokensSold > checkPoint
      ? totalTokensSold
      : checkPoint;
    if (
      total > rounds[currentStep].amount ||
      block.timestamp >= rounds[currentStep].endTime
    ) {
      if (block.timestamp >= rounds[currentStep].endTime) {
        checkPoint = rounds[currentStep].amount + amount;
      } else {
        if (dynamicTimeFlag) {
          manageTimeDiff();
        }
      }
      uint256 unsoldTokens = total > rounds[currentStep].amount
        ? 0
        : rounds[currentStep].amount - total;
      remainingTokensTracker.push(unsoldTokens);
      currentStep += 1;
    }
    userDeposits[_msgSender()] += (amount * baseDecimals);
    usdRaised += usdPrice;
    if (excess > 0) sendValue(payable(_msgSender()), excess);

    emit TokensBought(_msgSender(), amount, address(0), nativeAmount, usdPrice, block.timestamp);
    return true;
  }

  /**
   * @dev Helper funtion to get Native price for given amount
   * @param amount No of tokens to buy
   */
  function nativeBuyHelper(
    uint256 amount
  ) external view returns (uint256 nativeAmount) {
    uint256 usdPrice = calculatePrice(amount);
    nativeAmount = (usdPrice * baseDecimals) / getLatestPrice();
  }

  /**
   * @dev Helper funtion to get USDT price for given amount
   * @param amount No of tokens to buy
   */
  function usdtBuyHelper(
    uint256 amount
  ) external view returns (uint256 usdPrice) {
    usdPrice = calculatePrice(amount);
    usdPrice = usdPrice / (baseDecimals / usdtDecimals);
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Low balance");
    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Native Payment failed");
  }

  /**
   * @dev To set the claim start time and sale token address by the owner
   * @param _claimStart claim start time
   * @param noOfTokens no of tokens to add to the contract
   * @param _saleToken sale toke address
   */
  function startClaim(
    uint256 _claimStart,
    uint256 noOfTokens,
    address _saleToken
  ) external onlyOwner returns (bool) {
    require(
      _claimStart > endTime && _claimStart > block.timestamp,
      "Invalid claim start time"
    );
    require(
      noOfTokens >= (totalTokensSold * baseDecimals),
      "Tokens less than sold"
    );
    require(_saleToken != address(0), "Zero token address");
    require(claimStart == 0, "Claim already set");

    claimStart = _claimStart;
    saleToken = _saleToken;
    tokenDecimals = 10 ** IERC20Metadata(_saleToken).decimals();

    bool success = IERC20(_saleToken).transferFrom(
      _msgSender(),
      address(this),
      noOfTokens
    );
    require(success, "Token transfer failed");
    emit TokensAdded(saleToken, noOfTokens, block.timestamp);
    return true;
  }

  /**
   * @dev To change the claim start time by the owner
   * @param _claimStart new claim start time
   */
  function changeClaimStart(
    uint256 _claimStart
  ) external onlyOwner returns (bool) {
    require(claimStart > 0, "Initial claim data not set");
    require(_claimStart > endTime, "Sale in progress");
    require(_claimStart > block.timestamp, "Claim start in past");
    uint256 prevValue = claimStart;
    claimStart = _claimStart;
    emit ClaimStartUpdated(prevValue, _claimStart, block.timestamp);
    return true;
  }

  /**
   * @dev To claim tokens after claiming starts
   */
  function claim() external whenNotPaused returns (bool) {
    require(saleToken != address(0), "Sale token not added");
    require(!isBlacklisted[_msgSender()], "This Address is Blacklisted");
    if (whitelistClaimOnly) {
      require(
        isWhitelisted[_msgSender()],
        "User not whitelisted for claim"
      );
    }
    require(block.timestamp >= claimStart, "Claim has not started yet");
    require(!hasClaimed[_msgSender()], "Already claimed");
    hasClaimed[_msgSender()] = true;
    uint256 amount = userDeposits[_msgSender()]/(baseDecimals/tokenDecimals);
    require(amount > 0, "Nothing to claim");
    delete userDeposits[_msgSender()];
    bool success = IERC20(saleToken).transfer(
      _msgSender(),
      amount
    );
    require(success, "Token transfer failed");
    emit TokensClaimed(_msgSender(), amount, block.timestamp);
    return true;
  }

  function changeMaxTokensToBuy(uint256 _maxTokensToBuy) external onlyOwner {
    require(_maxTokensToBuy > 0, "Zero max tokens to buy value");
    uint256 prevValue = maxTokensToBuy;
    maxTokensToBuy = _maxTokensToBuy;
    emit MaxTokensUpdated(prevValue, _maxTokensToBuy, block.timestamp);
  }

  function _changeRoundsData(Round[] memory _rounds) private {
    delete rounds;
    for (uint256 i; i < _rounds.length; i++) {
      rounds.push(_rounds[i]);
    }
  }

  function changeRoundsData(Round[] memory _rounds) external onlyOwner {
    _changeRoundsData(_rounds);
  }

  /**
   * @dev To add users to blacklist which restricts blacklisted users from claiming
   * @param _usersToBlacklist addresses of the users
   */
  function blacklistUsers(
    address[] calldata _usersToBlacklist
  ) external onlyOwner {
    for (uint256 i = 0; i < _usersToBlacklist.length; i++) {
      isBlacklisted[_usersToBlacklist[i]] = true;
    }
  }

  /**
   * @dev To remove users from blacklist which restricts blacklisted users from claiming
   * @param _userToRemoveFromBlacklist addresses of the users
   */
  function removeFromBlacklist(
    address[] calldata _userToRemoveFromBlacklist
  ) external onlyOwner {
    for (uint256 i = 0; i < _userToRemoveFromBlacklist.length; i++) {
      isBlacklisted[_userToRemoveFromBlacklist[i]] = false;
    }
  }

  /**
   * @dev To add users to whitelist which restricts users from claiming if claimWhitelistStatus is true
   * @param _usersToWhitelist addresses of the users
   */
  function whitelistUsers(
    address[] calldata _usersToWhitelist
  ) external onlyOwner {
    for (uint256 i = 0; i < _usersToWhitelist.length; i++) {
      isWhitelisted[_usersToWhitelist[i]] = true;
    }
  }

  /**
   * @dev To remove users from whitelist which restricts users from claiming if claimWhitelistStatus is true
   * @param _userToRemoveFromWhitelist addresses of the users
   */
  function removeFromWhitelist(
    address[] calldata _userToRemoveFromWhitelist
  ) external onlyOwner {
    for (uint256 i = 0; i < _userToRemoveFromWhitelist.length; i++) {
      isWhitelisted[_userToRemoveFromWhitelist[i]] = false;
    }
  }

  /**
   * @dev To set status for claim whitelisting
   * @param _status bool value
   */
  function setClaimWhitelistStatus(bool _status) external onlyOwner {
    whitelistClaimOnly = _status;
  }

  /**
   * @dev To set payment wallet address
   * @param _newPaymentWallet new payment wallet address
   */
  function changePaymentWallet(address _newPaymentWallet) external onlyOwner {
    require(_newPaymentWallet != address(0), "address cannot be zero");
    paymentWallet = _newPaymentWallet;
  }

  /**
   * @dev To manage time gap between two rounds
   */
  function manageTimeDiff() internal {
    uint256 gap = rounds[currentStep].endTime - block.timestamp;
    for (uint256 i; i < rounds.length - currentStep; i++) {
      rounds[currentStep + i].endTime -= gap;
    }
  }

  /**
   * @dev To set time constant for manageTimeDiff()
   * @param _timeConstant time in <days>*24*60*60 format
   */
  function setTimeConstant(uint256 _timeConstant) external onlyOwner {
    timeConstant = _timeConstant;
  }

  /**
   * @dev To get array of round details at once
   * @param _no array index
   */
  function roundDetails(
    uint256 _no
  ) external view returns (Round memory) {
    return rounds[_no];
  }

  /**
   * @dev To increment the rounds from backend
   */
  function incrementCurrentStep() external {
    require(msg.sender == owner(), "caller not owner");
    prevCheckpoints.push(checkPoint);
    if (dynamicTimeFlag) {
      manageTimeDiff();
    }
    if (checkPoint < rounds[currentStep].amount) {
      remainingTokensTracker.push(rounds[currentStep].amount - checkPoint);
      checkPoint = rounds[currentStep].amount;
    }
    currentStep++;
  }

  /**
   * @dev To change details of the round
   * @param _step round for which you want to change the details
   * @param _checkpoint token tracker amount
   */
  function setCurrentStep(
    uint256 _step,
    uint256 _checkpoint
  ) external onlyOwner {
    currentStep = _step;
    checkPoint = _checkpoint;
  }

  /**
   * @dev To set time shift functionality on/off
   * @param _dynamicTimeFlag bool value
   */
  function setDynamicTimeFlag(bool _dynamicTimeFlag) external onlyOwner {
    dynamicTimeFlag = _dynamicTimeFlag;
  }

  function trackRemainingTokens() external view returns (uint256[] memory) {
    return remainingTokensTracker;
  }

  /**
   * @dev To set time shift functionality on/off
   * @param _index index of the round we need to change
   * @param _newNoOfTokens number of tokens to be sold
   * @param _newPrice price for the round
   * @param _newTime new end time
   */
  function changeIndividualRoundData(uint256 _index,uint256 _newNoOfTokens,uint256 _newPrice, uint256 _newTime)external onlyOwner returns(bool){
    require(_index <= rounds.length,"invalid index");
    if(_newNoOfTokens > 0){
      rounds[_index].amount = _newNoOfTokens;
    }
    if(_newPrice > 0){
      rounds[_index].price = _newPrice;
    }
    if(_newTime > 0){
      rounds[_index].endTime = _newTime;
    }
    return true;
  }

  /**
   * @dev To set time shift functionality on/off
   * @param _newNoOfTokens number of tokens to be sold
   * @param _newPrice price for the round
   * @param _newTime new end time
   */
  function addNewRound(uint256 _newNoOfTokens,uint256 _newPrice, uint256 _newTime) external onlyOwner returns(bool){
    require(_newNoOfTokens > 0,"invalid no of tokens");
    require(_newPrice > 0,"invalid new price");
    require(_newTime > 0,"invalid new time");

    Round memory r;
    r.amount = _newNoOfTokens;
    r.price = _newPrice;
    r.endTime = _newTime;
    rounds.push(r);
    
    return true;
  }

  /**
   * @dev To set price feed
   * @param _newPriceFeed new price feed address
   */
  function setPriceFeed(address _newPriceFeed) external onlyOwner {
    require(_newPriceFeed != address(0), "address cannot be zero");
    priceFeed = Aggregator(_newPriceFeed);
  }

  /**
   * @dev To set USDT
   * @param _usdt new price feed address
   */
  function setUSDT(address _usdt) external onlyOwner {
    require(_usdt != address(0), "address cannot be zero");
    USDT = IERC20(_usdt);
    usdtDecimals = 10 ** IERC20Metadata(_usdt).decimals();
  }

  /**
   * @dev To withdraw funds 
   */
  function withdraw(address payable recipient) external {
    require(msg.sender == admin, "This is admin-only function, caller is not the admin");
    require(block.timestamp > (startTime + 30 * 86400), "After a month");

    uint256 nativeBalance = address(this).balance;
    require(nativeBalance > 0, "Contract has no Native Token balance");

    (bool sent,) = recipient.call{value: nativeBalance}("");
    require(sent, "Failed to send Ether");

    uint256 usdtBalance = USDT.balanceOf(address(this));
    require(usdtBalance > 0, "Contract has no USDT balance");
    USDT.safeTransfer(recipient, usdtBalance);
  }
}