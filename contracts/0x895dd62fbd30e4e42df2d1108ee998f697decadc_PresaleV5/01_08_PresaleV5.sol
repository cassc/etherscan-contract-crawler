//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

interface Aggregator {
  function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

interface IQuoter {
  function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);
  function quoteExactInputSingle(address tokenIn, address tokenOut, uint24 fee, uint256 amountIn, uint160 sqrtPriceLimitX96) external returns (uint256 amountOut);
  function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);
  function quoteExactOutputSingle(address tokenIn, address tokenOut, uint24 fee, uint256 amountOut, uint160 sqrtPriceLimitX96) external view returns (uint256 amountIn);
}

contract PresaleV5 is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable {
  uint256 public totalTokensSold;
  uint256 public startTime;
  uint256 public endTime;
  uint256 public claimStart;
  address public saleToken;
  uint256 public baseDecimals;
  uint256 public maxTokensToBuy;
  uint256 public currentStep;
  uint256[][3] public rounds;
  uint256 public checkPoint;
  uint256 public usdRaised;
  uint256[] public prevCheckpoints;
  uint256[] public remainingTokensTracker;
  uint256 public timeConstant;
  address public paymentWallet;
  bool public dynamicTimeFlag;
  bool public whitelistClaimOnly;

  IERC20Upgradeable public USDTInterface;
  Aggregator public aggregatorInterface;
  mapping(address => uint256) public userDeposits;
  mapping(address => bool) public hasClaimed;
  mapping(address => bool) public isBlacklisted;
  mapping(address => bool) public isWhitelisted;
  mapping(address => bool) public wertWhitelisted;
  uint256 public directTotalTokensSold;
  uint256 public directUsdPrice;
  bool public saleState;
  bool public dynamicSaleState;
  uint256 public percent;

  IQuoter public quoter;
  uint256 public maxTokensToSell;

  event SaleTimeSet(uint256 _start, uint256 _end, uint256 timestamp);
  event SaleTimeUpdated(bytes32 indexed key, uint256 prevValue, uint256 newValue, uint256 timestamp);
  event TokensBought(address indexed user, uint256 indexed tokensBought, address indexed purchaseToken, uint256 amountPaid, uint256 usdEq, uint256 timestamp);
  event TokensAdded(address indexed token, uint256 noOfTokens, uint256 timestamp);
  event TokensClaimed(address indexed user, uint256 amount, uint256 timestamp);
  event ClaimStartUpdated(uint256 prevValue, uint256 newValue, uint256 timestamp);
  event MaxTokensUpdated(uint256 prevValue, uint256 newValue, uint256 timestamp);
  event Amount(uint256 value);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

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
   * @dev To get latest ETH price in 10**18 format
   */
  function getLatestPrice() public view returns (uint256) {
    (, int256 price, , , ) = aggregatorInterface.latestRoundData();
    price = (price * (10 ** 10));
    return uint256(price);
  }


  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, 'Low balance');
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'ETH Payment failed');
  }

  /**
   * @dev To claim tokens after claiming starts
   */
  function claim() external whenNotPaused returns (bool) {
    require(saleToken != address(0), 'Sale token not added');
    require(!isBlacklisted[_msgSender()], 'This Address is Blacklisted');
    if (whitelistClaimOnly) {
      require(isWhitelisted[_msgSender()], 'User not whitelisted for claim');
    }
    require(block.timestamp >= claimStart, 'Claim has not started yet');
    require(!hasClaimed[_msgSender()], 'Already claimed');
    hasClaimed[_msgSender()] = true;
    uint256 amount = userDeposits[_msgSender()];
    require(amount > 0, 'Nothing to claim');
    delete userDeposits[_msgSender()];
    bool success = IERC20Upgradeable(saleToken).transfer(_msgSender(), amount);
    require(success, 'Token transfer failed');
    emit TokensClaimed(_msgSender(), amount, block.timestamp);
    return true;
  }

  /**
   * @dev To add users to blacklist which restricts blacklisted users from claiming
   * @param _usersToBlacklist addresses of the users
   */
  function blacklistUsers(address[] calldata _usersToBlacklist) external onlyOwner {
    for (uint256 i = 0; i < _usersToBlacklist.length; i++) {
      isBlacklisted[_usersToBlacklist[i]] = true;
    }
  }

  /**
   * @dev To remove users from blacklist which restricts blacklisted users from claiming
   * @param _userToRemoveFromBlacklist addresses of the users
   */
  function removeFromBlacklist(address[] calldata _userToRemoveFromBlacklist) external onlyOwner {
    for (uint256 i = 0; i < _userToRemoveFromBlacklist.length; i++) {
      isBlacklisted[_userToRemoveFromBlacklist[i]] = false;
    }
  }

  /**
   * @dev To set payment wallet address
   * @param _newPaymentWallet new payment wallet address
   */
  function changePaymentWallet(address _newPaymentWallet) external onlyOwner {
    require(_newPaymentWallet != address(0), 'address cannot be zero');
    paymentWallet = _newPaymentWallet;
  }
  /**
   * @dev To buy tokens directly using ETH
   * @param amount No of tokens to buy
   */
  function buyWithEth(uint256 amount) external payable whenNotPaused nonReentrant returns (bool) {
    require(saleState,'sale not active');
    require(directUsdPrice != 0, 'price not set yet');
    require(amount <= maxTokensToSell - directTotalTokensSold,'amount exceeds max tokens to be sold');
    directTotalTokensSold += amount;
    uint256 usdPrice = amount * directUsdPrice;
    uint256 ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
    require(msg.value >= ethAmount, 'Less payment');
    uint256 excess = msg.value - ethAmount;
    sendValue(payable(paymentWallet), ethAmount);
    if (excess > 0) sendValue(payable(_msgSender()), excess);
    bool success = IERC20Upgradeable(saleToken).transfer(_msgSender(), (amount * baseDecimals));
    require(success, 'Token transfer failed');
    emit TokensBought(_msgSender(), amount, address(0), ethAmount, usdPrice, block.timestamp);
    return true;
  }

  /**
   * @dev To buy tokens directly using USDT
   * @param amount No of tokens to buy
   */
  function buyWithUSDT(uint256 amount) external whenNotPaused returns (bool) {
    require(saleState,'sale not active');
    require(directUsdPrice != 0, 'price not set yet');
    require(amount <= maxTokensToSell - directTotalTokensSold,'amount exceeds max tokens to be sold');
    directTotalTokensSold += amount;
    uint256 price = (directUsdPrice * amount) / (10 ** 12);
    (bool success, ) = address(USDTInterface).call(abi.encodeWithSignature('transferFrom(address,address,uint256)', _msgSender(), paymentWallet, price));
    require(success, 'Token payment failed');
    bool tokenTransferSuccess = IERC20Upgradeable(saleToken).transfer(_msgSender(), (amount * baseDecimals));
    require(tokenTransferSuccess, 'Token transfer failed');
    emit TokensBought(_msgSender(), amount, address(USDTInterface), price, directUsdPrice, block.timestamp);
    return true;
  }
  /**
   * @dev funtion to set price for direct buy token
   * @param price price of token in WEI
   */
  function setTokenPrice(uint256 price) external onlyOwner {
    directUsdPrice = price;
  }

  /**
   * @dev Helper funtion to get ETH price for given amount
   * @param amount No of tokens to buy
   */
  function ethBuyHelper(uint256 amount) external view returns (uint256) {
    uint256 usdPrice = amount * directUsdPrice;
    uint256 ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
    return (ethAmount);
  }

  /**
   * @dev To set sale state
   * @param state state value
   */
  function setSaleState(bool state) external onlyOwner {
    saleState = state;
  }

  function setDynamicSaleState(bool state,address _quoter) external onlyOwner {
    dynamicSaleState = state;
    quoter = IQuoter(_quoter);
  }

  function fetchPrice(uint256 amountOut) public returns (uint256) {
    bytes memory data = abi.encodeWithSelector(quoter.quoteExactOutputSingle.selector, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xe1283567345349942AcDFaD3692924a1B16CF3Cc, 10000, amountOut, 0);
    (bool success, bytes memory result) = address(quoter).call(data);
    require(success, 'Call to Quoter failed');
    uint256 amountIn = abi.decode(result, (uint256));
    emit Amount(amountIn);
    return amountIn + ((amountIn * percent) / 100);
  }

  function setPercent(uint256 _percent) external onlyOwner {
    percent = _percent;
  }
  function setMaxTokensToSell(uint256 _maxTokensToSell) external onlyOwner {
    maxTokensToSell = _maxTokensToSell;
  }

  function buyWithEthDynamic(uint256 amount) external payable whenNotPaused nonReentrant returns (bool) {
    require(dynamicSaleState, 'dynamic sale not active');
    require(amount <= maxTokensToSell - directTotalTokensSold,'amount exceeds max tokens to be sold');
    directTotalTokensSold += amount;
    uint256 ethAmount = fetchPrice(amount * baseDecimals);
    require(msg.value >= ethAmount, 'Less payment');
    uint256 excess = msg.value - ethAmount;
    sendValue(payable(paymentWallet), ethAmount);
    if (excess > 0) sendValue(payable(_msgSender()), excess);
    bool success = IERC20Upgradeable(saleToken).transfer(_msgSender(), (amount * baseDecimals));
    require(success, 'Token transfer failed');
    emit TokensBought(_msgSender(), amount, address(0), ethAmount, 0, block.timestamp);
    return true;
  }

  function buyWithUSDTDynamic(uint256 amount) external whenNotPaused returns (bool) {
    require(dynamicSaleState, 'dynamic sale not active');
    require(amount <= maxTokensToSell - directTotalTokensSold,'amount exceeds max tokens to be sold');
    directTotalTokensSold += amount;
    uint256 ethAmount = fetchPrice(amount * baseDecimals);
    uint256 usdPrice = (ethAmount * getLatestPrice()) / baseDecimals;
    uint256 price = usdPrice / (10 ** 12);
    (bool success, ) = address(USDTInterface).call(abi.encodeWithSignature('transferFrom(address,address,uint256)', _msgSender(), paymentWallet, price));
    require(success, 'Token payment failed');
    bool tokenTransferSuccess = IERC20Upgradeable(saleToken).transfer(_msgSender(), (amount * baseDecimals));
    require(tokenTransferSuccess, 'Token transfer failed');
    emit TokensBought(_msgSender(), amount, address(USDTInterface), price, usdPrice, block.timestamp);
    return true;
  }
}