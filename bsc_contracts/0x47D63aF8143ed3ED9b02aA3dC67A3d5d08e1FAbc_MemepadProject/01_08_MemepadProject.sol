// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./utils/EmergencyWithdraw.sol";

contract MemepadProject is OwnableUpgradeable, EmergencyWithdraw, ReentrancyGuardUpgradeable {
  struct WhitelistInput {
    address wallet;
    uint256 maxPayableAmount;
  }

  struct Whitelist {
    address wallet;
    uint256 amount;
    uint256 maxPayableAmount;
    uint256 rewardedAmount;
    bool whitelist;
    bool redeemed;
    uint256 redeemedAmount;
  }

  struct VestInfo {
    uint rate;
    uint timestamp;
  }

  // Percentage nominator: 1% = 100
  uint256 private constant _RATE_NOMINATOR = 100e2;

  // Private
  IERC20Metadata private _token;

  // Whitelist map
  mapping(address => Whitelist) private whitelist;
  address[] public whitelistUsers;

  // Vesting config
  VestInfo[] private _vestConfig;

  // Public
  uint256 public startTime;
  uint256 public tokenRate;
  uint256 public soldAmount;
  uint256 public totalRaise;
  uint256 public totalParticipant;
  uint256 public totalRedeemed;
  uint256 public totalRewardTokens;
  bool public isFinished;
  bool public isClosed;
  bool public isFailedSale;
  uint256 public maxPublicPayableAmount;
  mapping(address => bool) public publicSaleList;
  mapping(address => bool) public refundedList;
  uint256 public publicTime;
  uint256 public publicTimeHolder;
  uint256 public reduceTokenAmount;

  // Events
  event ESetAcceptedTokenAddress(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply);
  event ESetTokenAddress(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply);
  event ESetTokenRate(uint256 _tokenRate);
  event EOpenSale(uint256 _startTime, bool _isStart);
  event EBuyTokens(
    address _sender,
    uint256 _value,
    uint256 _totalToken,
    uint256 _rewardedAmount,
    uint256 _senderTotalAmount,
    uint256 _senderTotalRewardedAmount,
    uint256 _senderSoldAmount,
    uint256 _senderTotalRise,
    uint256 _totalParticipant,
    uint256 _totalRedeemed
  );
  event ECloseSale(bool _isClosed);
  event EFinishSale(bool _isFinished);
  event ERedeemTokens(address _wallet, uint256 _rewardedAmount);
  event ERefundBNB(address _wallet, uint256 _refundedAmount);
  event EAddWhiteList(WhitelistInput[] _addresses);
  event ERemoveWhiteList(address[] _addresses);
  event EWithdrawBNBBalance(address _sender, uint256 _balance);
  event EWithdrawRemainingTokens(address _sender, uint256 _remainingAmount);
  event EAddRewardTokens(address _sender, uint256 _amount, uint256 _remaingRewardTokens);

  /**
   * @dev Upgradable initializer
   */
  function __MemepadProject_init() public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    // Default token rate is 0.01
    tokenRate = 1e16;
  }

  // Read: Get token address
  function getTokenAddress() public view returns (address tokenAddress) {
    return address(_token);
  }

  function isInitialized() public view returns (bool) {
    return startTime != 0;
  }

  // Read: Is Sale Start
  function isStart() public view returns (bool) {
    return isInitialized() && startTime > 0 && block.timestamp >= startTime;
  }

  //read token in BNB
  function getTokenInBNB(uint256 tokens) public view returns (uint256) {
    uint256 tokenDecimal = 10**uint256(_token.decimals());
    return (tokens * tokenRate) / tokenDecimal;
  }

  // Read: Calculate Token
  function calculateAmount(uint256 acceptedAmount) public view returns (uint256) {
    uint256 tokenDecimal = 10**uint256(_token.decimals());
    return (acceptedAmount * tokenDecimal) / tokenRate;
  }

  // Read: Get max payable amount against whitelisted address
  function getMaxPayableAmount(address _address) public view returns (uint256) {
    Whitelist memory whitelistWallet = whitelist[_address];
    return whitelistWallet.maxPayableAmount;
  }

  // Read: Get whitelist wallet
  function getWhitelist(address _address)
    public
    view
    returns (
      address _wallet,
      uint256 _amount,
      uint256 _maxPayableAmount,
      uint256 _rewardedAmount,
      bool _redeemed,
      bool _whitelist,
      uint256 _redeemedAmount
    )
  {
    Whitelist memory whitelistWallet = whitelist[_address];
    return (
      _address,
      whitelistWallet.amount,
      whitelistWallet.maxPayableAmount,
      whitelistWallet.rewardedAmount,
      whitelistWallet.redeemed,
      whitelistWallet.whitelist,
      whitelistWallet.redeemedAmount
    );
  }

  //Read return remaining reward
  function getRemainingReward() public view returns (uint256) {
    return totalRewardTokens - soldAmount - reduceTokenAmount;
  }

  // Read return whitelistUsers length
  function getWhitelistUsersLength() external view returns (uint256) {
    return whitelistUsers.length;
  }

  //Read return whitelist paging
  function getUsersPaging(uint _offset, uint _limit)
    public
    view
    returns (
      Whitelist[] memory users,
      uint nextOffset,
      uint total
    )
  {
    uint totalUsers = whitelistUsers.length;
    if (_limit == 0) {
      _limit = 1;
    }

    if (_limit > totalUsers - _offset) {
      _limit = totalUsers - _offset;
    }

    Whitelist[] memory values = new Whitelist[](_limit);
    for (uint i = 0; i < _limit; i++) {
      values[i] = whitelist[whitelistUsers[_offset + i]];
    }

    return (values, _offset + _limit, totalUsers);
  }

  /*
   * @dev Set new vest config
   */
  function setVestConfig(VestInfo[] memory _config) external onlyOwner {
    delete _vestConfig;

    // 100%
    uint256 totalRate_ = _RATE_NOMINATOR;
    for (uint i = 0; i < _config.length; i++) {
      totalRate_ -= _config[i].rate;
      require(_config[i].rate >= 0, "Rate must not zero");
      require(totalRate_ >= 0, "Invalid total rate");
      _vestConfig.push(VestInfo(_config[i].rate, _config[i].timestamp));
    }
    require(totalRate_ == 0, "Total rate must be 100");
  }

  /*
   * @dev Get vest config
   */
  function getVestConfig() external view returns (VestInfo[] memory) {
    return _vestConfig;
  }

  /*
   * @dev Get redeemable amount
   */
  function getTotalRedeemable(address _user) public view returns (uint256) {
    uint256 validRate_ = 0;
    for (uint i = 0; i < _vestConfig.length; i++) {
      if (block.timestamp < _vestConfig[i].timestamp) break;
      else {
        validRate_ += _vestConfig[i].rate;
      }
    }
    return (validRate_ * whitelist[_user].rewardedAmount) / _RATE_NOMINATOR;
  }

  // Write: Token Address. Should be set before/closed sale
  function setTokenAddress(IERC20Metadata token) external onlyOwner {
    _token = token;
    // Emit event
    emit ESetTokenAddress(token.name(), token.symbol(), token.decimals(), token.totalSupply());
  }

  // Write: Owner set exchange rate
  function setTokenRate(uint256 _tokenRate) external onlyOwner {
    require(!isInitialized(), "Initialized");
    require(_tokenRate > 0, "Not zero");

    tokenRate = _tokenRate;
    // Emit event
    emit ESetTokenRate(tokenRate);
  }

  // Write: Open sale
  // Ex _startTime = 1618835669
  function openSale(uint256 _startTime) external onlyOwner {
    require(!isInitialized(), "Initialized");
    require(_startTime >= block.timestamp, "Must >= current time");
    require(getTokenAddress() != address(0), "Token address is empty");
    require(totalRewardTokens > 0, "Total token != zero");

    startTime = _startTime;
    isClosed = false;
    isFinished = false;
    // Emit event
    emit EOpenSale(startTime, isStart());
  }

  // Enable public sale with max amount
  function setMaxPublicPayableAmount(uint256 _maxAmount) external onlyOwner {
    maxPublicPayableAmount = _maxAmount;
  }

  // Set reduce token amount on total reward tokens
  function setReduceTokenAmount(uint256 _amount) external onlyOwner {
    require(_amount <= (totalRewardTokens - soldAmount), "Wrong amount");
    reduceTokenAmount = _amount;
  }

  // Set public sale time.
  // - For holder duration = _publicTimeHolder - _publicTime
  // - For everyone: after _publicTimeHolder
  function setPublicTime(uint256 _publicTime, uint256 _publicTimeHolder) external onlyOwner {
    publicTime = _publicTime;
    publicTimeHolder = _publicTimeHolder;
  }

  // Check public sale
  function isPublicSale() public view returns (bool) {
    return maxPublicPayableAmount > 0 && block.timestamp >= publicTime;
  }

  // Check ico is raise
  function isICORaising() external view returns (bool) {
    return isStart() && !isClosed && !isFinished && !isPublicSale();
  }

  ///////////////////////////////////////////////////
  // IN SALE
  // Write: User buy token by sending BNB
  // Convert Accepted bnb to Sale token
  function buyTokens() external payable nonReentrant {
    address payable senderAddress = payable(_msgSender());
    uint256 acceptedAmount = msg.value;
    Whitelist memory whitelistSnapshot = whitelist[senderAddress];

    // Asserts
    require(isStart(), "Sale is not started yet");
    require(!isClosed, "Sale is closed");
    require(!isFinished, "Sale is finished");

    // Public sale after 24hrs
    bool isPublicSale_ = isPublicSale();

    // First hours of public sale is just for holder
    if (isPublicSale_ && block.timestamp <= publicTimeHolder) {
      require(whitelistSnapshot.whitelist, "Mempad holder first");
    }

    if (!isPublicSale_) {
      require(!publicSaleList[senderAddress], "Not for public sale");
    } else if (whitelistSnapshot.wallet == address(0)) {
      publicSaleList[senderAddress] = true;
      whitelistUsers.push(senderAddress);
      whitelistSnapshot.wallet = senderAddress;
      whitelistSnapshot.maxPayableAmount = maxPublicPayableAmount;
      whitelistSnapshot.whitelist = true;
      whitelist[senderAddress] = whitelistSnapshot;
    }

    require(whitelistSnapshot.whitelist, "You are not in whitelist");
    require(acceptedAmount > 0, "Pay some BNB to get tokens");

    uint256 rewardedAmount = calculateAmount(acceptedAmount);
    // In public sale mode, just check with maxPublicPayableAmount
    if (!isPublicSale_) {
      require(
        whitelistSnapshot.maxPayableAmount >= whitelistSnapshot.rewardedAmount + rewardedAmount,
        "max payable amount reached"
      );
    } else {
      require(
        maxPublicPayableAmount >= whitelistSnapshot.rewardedAmount + rewardedAmount,
        "max public payable reached"
      );
    }

    uint256 unsoldTokens = getRemainingReward();
    uint256 tokenValueInBNB = getTokenInBNB(unsoldTokens);

    if (acceptedAmount >= tokenValueInBNB) {
      //refund excess amount
      uint256 excessAmount = acceptedAmount - tokenValueInBNB;
      //remaining amount
      acceptedAmount = acceptedAmount - excessAmount;
      //close the sale
      isClosed = true;
      rewardedAmount = calculateAmount(acceptedAmount);
      emit ECloseSale(isClosed);
      // solhint-disable
      if (excessAmount > 0) {
        senderAddress.transfer(excessAmount);
      }
    }

    require(rewardedAmount > 0, "Zero rewarded amount");

    // Update total participant
    // Check if current whitelist amount is zero and will be deposit
    // then increase totalParticipant variable
    if (whitelistSnapshot.amount == 0 && acceptedAmount > 0) {
      totalParticipant = totalParticipant + 1;
    }
    // Update whitelist detail info
    whitelist[senderAddress].amount = whitelistSnapshot.amount + acceptedAmount;
    whitelist[senderAddress].rewardedAmount = whitelistSnapshot.rewardedAmount + rewardedAmount;
    // Update global info
    soldAmount = soldAmount + rewardedAmount;
    totalRaise = totalRaise + acceptedAmount;

    // Emit buy event
    emit EBuyTokens(
      senderAddress,
      acceptedAmount,
      totalRewardTokens,
      rewardedAmount,
      whitelist[senderAddress].amount,
      whitelist[senderAddress].rewardedAmount,
      soldAmount,
      totalRaise,
      totalParticipant,
      totalRedeemed
    );
  }

  // Write: Finish sale
  function finishSale(bool _status) external onlyOwner returns (bool) {
    isFinished = _status;
    // Emit event
    emit EFinishSale(isFinished);
    return isFinished;
  }

  ///////////////////////////////////////////////////
  // AFTER SALE
  // Write: Redeem Rewarded Tokens
  function redeemTokens() external nonReentrant {
    address senderAddress = _msgSender();

    require(whitelist[senderAddress].whitelist, "Sender is not in whitelist");

    Whitelist memory whitelistWallet = whitelist[senderAddress];

    require(isFinished, "Sale is not finalized yet");
    require(!isFailedSale, "Sale is failed");
    require(!whitelistWallet.redeemed, "Redeemed already");

    uint256 totalRedeemable_ = getTotalRedeemable(senderAddress);
    uint256 redeemableAmount_ = totalRedeemable_ - whitelistWallet.redeemedAmount;
    require(redeemableAmount_ > 0, "Vesting time");
    whitelist[senderAddress].redeemedAmount = totalRedeemable_;

    if (totalRedeemable_ >= whitelistWallet.rewardedAmount) {
      whitelist[senderAddress].redeemed = true;
    }

    _token.transfer(whitelistWallet.wallet, redeemableAmount_);

    // Update total redeem
    totalRedeemed += redeemableAmount_;

    // Emit event
    emit ERedeemTokens(whitelistWallet.wallet, redeemableAmount_);
  }

  // Write: Allow user withdraw their BNB if the sale is failed
  function refundBNB() external nonReentrant {
    address payable senderAddress = payable(_msgSender());

    require(isClosed, "Sale is not closed yet");
    require(isFailedSale, "Sale is not failed");
    require(whitelist[senderAddress].whitelist, "Sender is not in whitelist");
    require(!refundedList[senderAddress], "Already refunded");
    refundedList[senderAddress] = true;

    Whitelist memory whitelistWallet = whitelist[senderAddress];
    senderAddress.transfer(whitelistWallet.amount);

    // Emit event
    emit ERefundBNB(senderAddress, whitelistWallet.amount);
  }

  ///////////////////////////////////////////////////
  // FREE STATE
  // Write: Add Whitelist
  function addWhitelist(WhitelistInput[] memory inputs) external onlyOwner {
    uint256 addressesLength = inputs.length;

    for (uint256 i = 0; i < addressesLength; i++) {
      WhitelistInput memory input = inputs[i];
      if (whitelist[input.wallet].wallet == address(0)) {
        whitelistUsers.push(input.wallet);
      }
      Whitelist memory _whitelist = Whitelist(input.wallet, 0, input.maxPayableAmount, 0, true, false, 0);

      whitelist[input.wallet] = _whitelist;
    }
    // Emit event
    emit EAddWhiteList(inputs);
  }

  // Write: Remove Whitelist
  function removeWhitelist(address[] memory addresses) external onlyOwner {
    uint256 addressesLength = addresses.length;

    for (uint256 i = 0; i < addressesLength; i++) {
      address _address = addresses[i];
      Whitelist memory _whitelistSnapshot = whitelist[_address];
      whitelist[_address] = Whitelist(
        _address,
        _whitelistSnapshot.amount,
        _whitelistSnapshot.maxPayableAmount,
        _whitelistSnapshot.rewardedAmount,
        false,
        _whitelistSnapshot.redeemed,
        _whitelistSnapshot.redeemedAmount
      );
    }

    // Emit event
    emit ERemoveWhiteList(addresses);
  }

  // Write: Mark failed sale to allow user withdraw their fund
  function markFailedSale(bool status) external onlyOwner {
    isFailedSale = status;
  }

  // Write: Close sale - stop buying
  function closeSale(bool status) external onlyOwner {
    isClosed = status;
    emit ECloseSale(isClosed);
  }

  // Write: owner can withdraw all BNB
  function withdrawBNBBalance() external onlyOwner {
    address payable sender = payable(_msgSender());

    uint256 balance = address(this).balance;
    sender.transfer(balance);

    // Emit event
    emit EWithdrawBNBBalance(sender, balance);
  }

  // Write: Owner withdraw tokens which are not sold
  function withdrawRemainingTokens() external onlyOwner {
    address sender = _msgSender();
    uint256 lockAmount = soldAmount - totalRedeemed;
    uint256 remainingAmount = totalRewardTokens - lockAmount;

    _token.transfer(sender, remainingAmount);

    // Emit event
    emit EWithdrawRemainingTokens(sender, remainingAmount);
  }

  // Write: Owner can add reward tokens
  function addRewardTokens(uint256 _amount) external onlyOwner {
    require(getTokenAddress() != address(0), "Invalid token address");
    require(_amount > 0, "Amount should not be 0");

    address sender = _msgSender();
    _token.transferFrom(sender, address(this), _amount);
    totalRewardTokens = totalRewardTokens + _amount;

    emit EAddRewardTokens(sender, _amount, totalRewardTokens);
  }

  // Write: Correct total reward tokens
  function setTotalRewardTokens(uint256 _amount) external onlyOwner {
    totalRewardTokens = _amount;
  }
}