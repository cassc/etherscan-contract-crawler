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

interface StakingManager {
  function depositByPresale(address _user, uint256 _amount) external;
}

interface IRouter {
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract PresaleV3 is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable {
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
  address public admin;

  IERC20Upgradeable public USDTInterface;
  Aggregator public aggregatorInterface;
  mapping(address => uint256) public userDeposits;
  mapping(address => bool) public hasClaimed;
  mapping(address => bool) public isBlacklisted;
  mapping(address => bool) public isWhitelisted;
  mapping(address => bool) public wertWhitelisted;
  StakingManager public stakingManagerInterface;
  address public stakingContract;
  bool public stakeingWhitelistStatus;
  bool public dynamicSaleState;
  uint256 public percent;
  uint256 public directTotalTokensSold;
  uint256 public maxTokensToSell;
  IRouter public router;

  event SaleTimeSet(uint256 _start, uint256 _end, uint256 timestamp);
  event SaleTimeUpdated(bytes32 indexed key, uint256 prevValue, uint256 newValue, uint256 timestamp);
  event TokensBought(address indexed user, uint256 indexed tokensBought, address indexed purchaseToken, uint256 amountPaid, uint256 usdEq, uint256 timestamp);
  event TokensAdded(address indexed token, uint256 noOfTokens, uint256 timestamp);
  event TokensClaimed(address indexed user, uint256 amount, uint256 timestamp);
  event ClaimStartUpdated(uint256 prevValue, uint256 newValue, uint256 timestamp);
  event MaxTokensUpdated(uint256 prevValue, uint256 newValue, uint256 timestamp);
  event TokensClaimedAndStaked(address indexed user, uint256 amount, uint256 timestamp);

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
   * @dev To update the sale times
   * @param _startTime New start time
   * @param _endTime New end time
   */
  function changeSaleTimes(uint256 _startTime, uint256 _endTime) external onlyOwner {
    require(_startTime > 0 || _endTime > 0, 'Invalid parameters');
    if (_startTime > 0) {
      require(block.timestamp < startTime, 'Sale already started');
      require(block.timestamp < _startTime, 'Sale time in past');
      uint256 prevValue = startTime;
      startTime = _startTime;
      emit SaleTimeUpdated(bytes32('START'), prevValue, _startTime, block.timestamp);
    }

    if (_endTime > 0) {
      require(block.timestamp < endTime, 'Sale already ended');
      require(_endTime > startTime, 'Invalid endTime');
      uint256 prevValue = endTime;
      endTime = _endTime;
      emit SaleTimeUpdated(bytes32('END'), prevValue, _endTime, block.timestamp);
    }
  }

  modifier checkSaleState(uint256 amount) {
    require(block.timestamp >= startTime && block.timestamp <= endTime, 'Invalid time for buying');
    require(amount > 0, 'Invalid sale amount');
    _;
  }

  /**
   * @dev To set the claim start time and sale token address by the owner
   * @param _claimStart claim start time
   * @param noOfTokens no of tokens to add to the contract
   * @param _saleToken sale toke address
   */
  function startClaim(uint256 _claimStart, uint256 noOfTokens, address _saleToken, address _stakingManagerAddress) external onlyOwner returns (bool) {
    require(noOfTokens >= (totalTokensSold * baseDecimals), 'Tokens less than sold');
    require(_saleToken != address(0), 'Zero token address');
    require(claimStart == 0, 'Claim already set');
    claimStart = _claimStart;
    saleToken = _saleToken;
    stakingContract = _stakingManagerAddress;
    whitelistClaimOnly = true;
    stakeingWhitelistStatus = true;
    stakingManagerInterface = StakingManager(_stakingManagerAddress);
    IERC20Upgradeable(saleToken).approve(stakingContract, type(uint256).max);
    bool success = IERC20Upgradeable(_saleToken).transferFrom(_msgSender(), address(this), noOfTokens);
    require(success, 'Token transfer failed');
    emit TokensAdded(saleToken, noOfTokens, block.timestamp);
    return true;
  }

  /**
   * @dev To change the claim start time by the owner
   * @param _claimStart new claim start time
   */
  function changeClaimStart(uint256 _claimStart) external onlyOwner returns (bool) {
    require(claimStart > 0, 'Initial claim data not set');
    require(_claimStart > endTime, 'Sale in progress');
    require(_claimStart > block.timestamp, 'Claim start in past');
    uint256 prevValue = claimStart;
    claimStart = _claimStart;
    emit ClaimStartUpdated(prevValue, _claimStart, block.timestamp);
    return true;
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

  function claimAndStake() external whenNotPaused returns (bool) {
    require(saleToken != address(0), 'Sale token not added');
    require(!isBlacklisted[_msgSender()], 'This Address is Blacklisted');
    if (stakeingWhitelistStatus) {
      require(isWhitelisted[_msgSender()], 'User not whitelisted for claim');
    }
    require(!hasClaimed[_msgSender()], 'Already claimed');
    hasClaimed[_msgSender()] = true;
    uint256 amount = userDeposits[_msgSender()];
    require(amount > 0, 'Nothing to claim');
    stakingManagerInterface.depositByPresale(_msgSender(), amount);
    delete userDeposits[_msgSender()];
    emit TokensClaimedAndStaked(_msgSender(), amount, block.timestamp);
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
   * @dev To add users to whitelist which restricts users from claiming if claimWhitelistStatus is true
   * @param _usersToWhitelist addresses of the users
   */
  function whitelistUsers(address[] calldata _usersToWhitelist) external onlyOwner {
    for (uint256 i = 0; i < _usersToWhitelist.length; i++) {
      isWhitelisted[_usersToWhitelist[i]] = true;
    }
  }

  /**
   * @dev To remove users from whitelist which restricts users from claiming if claimWhitelistStatus is true
   * @param _userToRemoveFromWhitelist addresses of the users
   */
  function removeFromWhitelist(address[] calldata _userToRemoveFromWhitelist) external onlyOwner {
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
   * @dev To set status for claim whitelisting
   * @param _status bool value
   */
  function setStakeingWhitelistStatus(bool _status) external onlyOwner {
    stakeingWhitelistStatus = _status;
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
   * @dev to update userDeposits for purchases made on BSC
   * @param _users array of users
   * @param _userDeposits array of userDeposits associated with users
   */
  function updateFromBSC(address[] calldata _users, uint256[] calldata _userDeposits) external onlyOwner {
    require(_users.length == _userDeposits.length, 'Length mismatch');
    for (uint256 i = 0; i < _users.length; i++) {
      userDeposits[_users[i]] += _userDeposits[i];
    }
  }

  /**
   * @dev to initialize staking manager with new addredd
   * @param _stakingManagerAddress address of the staking smartcontract
   */
  function setStakingManager(address _stakingManagerAddress) external onlyOwner {
    stakingManagerInterface = StakingManager(_stakingManagerAddress);
    stakingContract = _stakingManagerAddress;
  }

  function buyWithEth(uint256 amount) external payable whenNotPaused nonReentrant returns (bool) {
    require(dynamicSaleState, 'dynamic sale not active');
    require(amount <= maxTokensToSell - directTotalTokensSold, 'amount exceeds max tokens to be sold');
    directTotalTokensSold += amount;
    uint256 ethAmount = fetchPrice(amount * baseDecimals);
    require(msg.value >= ethAmount, 'Less payment');
    uint256 excess = msg.value - ethAmount;
    stakingManagerInterface.depositByPresale(_msgSender(), amount * baseDecimals);
    emit TokensBought(_msgSender(), amount, address(0), ethAmount, 0, block.timestamp);
    sendValue(payable(paymentWallet), ethAmount);
    if (excess > 0) sendValue(payable(_msgSender()), excess);
    return true;
  }

  function buyWithUSDT(uint256 amount) external whenNotPaused returns (bool) {
    require(dynamicSaleState, 'dynamic sale not active');
    require(amount <= maxTokensToSell - directTotalTokensSold, 'amount exceeds max tokens to be sold');
    directTotalTokensSold += amount;
    uint256 ethAmount = fetchPrice(amount * baseDecimals);
    uint256 usdPrice = (ethAmount * getLatestPrice()) / baseDecimals;
    uint256 price = usdPrice / (10 ** 12);
    (bool success, ) = address(USDTInterface).call(abi.encodeWithSignature('transferFrom(address,address,uint256)', _msgSender(), paymentWallet, price));
    require(success, 'Token payment failed');
    stakingManagerInterface.depositByPresale(_msgSender(), amount * baseDecimals);
    emit TokensBought(_msgSender(), amount, address(USDTInterface), price, usdPrice, block.timestamp);
    return true;
  }

  function setDynamicSaleState(bool _state) external onlyOwner {
    dynamicSaleState = _state;
  }

  function setMaxTokensToSell(uint256 _tokensToSell) external onlyOwner {
    maxTokensToSell = _tokensToSell;
  }

  function setRouter(address _router) external onlyOwner {
    router = IRouter(_router);
  }

  function fetchPrice(uint256 amountOut) public view returns (uint256) {
    address[] memory path = new address[](2);
    path[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    path[1] = 0xE86DF1970055e9CaEe93Dae9B7D5fD71595d0e18;
    uint256[] memory amounts = router.getAmountsIn(amountOut, path);
    return amounts[0] + ((amounts[0] * percent) / 100);
  }

  function setPercent(uint256 _percent) external onlyOwner {
    percent = _percent;
  }
}