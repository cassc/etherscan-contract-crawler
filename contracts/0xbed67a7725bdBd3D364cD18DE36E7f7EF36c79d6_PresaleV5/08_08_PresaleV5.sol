//SPDX-License-Identifier: MIT
/*
 $$$$$$$$\ $$$$$$\  $$$$$$\  $$\   $$\ $$$$$$$$\  $$$$$$\  $$\   $$\ $$$$$$$$\ 
 $$  _____|\_$$  _|$$  __$$\ $$ |  $$ |\__$$  __|$$  __$$\ $$ |  $$ |\__$$  __|
 $$ |        $$ |  $$ /  \__|$$ |  $$ |   $$ |   $$ /  $$ |$$ |  $$ |   $$ |   
 $$$$$\      $$ |  $$ |$$$$\ $$$$$$$$ |   $$ |   $$ |  $$ |$$ |  $$ |   $$ |   
 $$  __|     $$ |  $$ |\_$$ |$$  __$$ |   $$ |   $$ |  $$ |$$ |  $$ |   $$ |   
 $$ |        $$ |  $$ |  $$ |$$ |  $$ |   $$ |   $$ |  $$ |$$ |  $$ |   $$ |   
 $$ |      $$$$$$\ \$$$$$$  |$$ |  $$ |   $$ |    $$$$$$  |\$$$$$$  |   $$ |   
 \__|      \______| \______/ \__|  \__|   \__|    \______/  \______/    \__|   
*/

pragma solidity 0.8.9;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

interface Aggregator {
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

contract PresaleV5 is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable {
  uint256 public totalTokensSold;
  uint256 public totalBonus;
  uint256 public startTime;
  uint256 public endTime;
  uint256 public claimStart;
  address public saleToken;
  uint256 public baseDecimals;
  uint256 public maxTokensToBuy;
  uint256 public currentStep;

  IERC20Upgradeable public USDTInterface;
  Aggregator public aggregatorInterface;
  // https://docs.chain.link/docs/ethereum-addresses/ => (ETH / USD)

  uint256[1][2] public rounds;

  uint256[][2] public token_quantity_bonus;
  uint256 public default_lockup;
  uint256 public MONTH;
  uint256 public initialClaimPercent;

  struct UserDeposits {
    uint256 depositAmount;
    uint256 bonusAmount;
    uint256 initialClaim;
    uint256 claimedAmount;
    uint256 claimTime;
  }

  mapping(address => UserDeposits[]) public userDeposits;
  mapping(uint256 => uint256) public lockup_bonus;
  uint256 public linearStartTime;
  mapping(address => bool) public isBlacklisted;
  mapping(address => bool) public isWhitelisted;
  bool public whitelistClaimOnly;
  uint256 public increment;
  uint256 public linearPriceUsdRaised;
  mapping(address => bool) public wertWhitelisted;
  mapping(address => mapping(uint256 => bool)) public newUser;

  event SaleTimeSet(uint256 _start, uint256 _end, uint256 timestamp);

  event SaleTimeUpdated(bytes32 indexed key, uint256 prevValue, uint256 newValue, uint256 timestamp);

  event TokensBought(address indexed user, uint256 indexed tokensBought, address indexed purchaseToken, uint256 bonus, uint256 amountPaid, uint256 usdEq, uint256 timestamp);

  event TokensAdded(address indexed token, uint256 noOfTokens, uint256 timestamp);
  event TokensClaimed(address indexed user, uint256 indexed id, uint256 amount, uint256 timestamp);

  event ClaimStartUpdated(uint256 prevValue, uint256 newValue, uint256 timestamp);

  event MaxTokensUpdated(uint256 prevValue, uint256 newValue, uint256 timestamp);

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
   * @dev To calculate the price in USD for given amount of tokens.
   * @param _amount No of tokens
   * @notice Since this presale has only one round, current step should not go above 0
   * in case of multiple rounds, current step has to be set accordingly
   */
  function calculatePrice(uint256 _amount) public view returns (uint256 totalValue) {
    uint256 USDTAmount;
    require(_amount <= maxTokensToBuy, 'Amount exceeds max tokens to buy');
    if (_amount + totalTokensSold > rounds[0][currentStep]) {
      require(currentStep < 0, 'Insufficient token amount.');
      uint256 tokenAmountForCurrentPrice = rounds[0][currentStep] - totalTokensSold;
      USDTAmount = tokenAmountForCurrentPrice * rounds[1][currentStep] + (_amount - tokenAmountForCurrentPrice) * rounds[1][currentStep + 1];
    } else {
      if (linearStartTime == 0 || linearStartTime >= block.timestamp) {
        USDTAmount = _amount * rounds[1][currentStep];
      } else {
        uint256 priceStep = (block.timestamp - linearStartTime) / (12 * 60 * 60);
        priceStep += 1;
        USDTAmount = (rounds[1][currentStep] + (priceStep * increment)) * _amount;
      }
    }
    return USDTAmount;
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

  /**
   * @dev To update max tokens to buy
   * @param _maxTokensToBuy New max tokens value
   */
  function changeMaxTokensToBuy(uint256 _maxTokensToBuy) external onlyOwner {
    require(_maxTokensToBuy > 0, 'Zero max tokens to buy value');
    uint256 prevValue = maxTokensToBuy;
    maxTokensToBuy = _maxTokensToBuy;
    emit MaxTokensUpdated(prevValue, _maxTokensToBuy, block.timestamp);
  }

  /**
   * @dev To update rounds info
   * @param _rounds New rounds array
   */
  function changeRoundsData(uint256[1][2] memory _rounds) external onlyOwner {
    rounds = _rounds;
  }

  /**
   * @dev To get latest ethereum price in 10**18 format
   */
  function getLatestPrice() public view returns (uint256) {
    (, int256 price, , , ) = aggregatorInterface.latestRoundData();
    price = (price * (10**10));
    return uint256(price);
  }

  modifier checkSaleState(uint256 amount) {
    require(block.timestamp >= startTime && block.timestamp <= endTime, 'Invalid time for buying');
    require(amount > 0, 'Invalid sale amount');
    _;
  }

  /**
   * @dev To check total amount of bonus tokens user will get for particular amount and months locked
   * @param amount amount of tokens to be locked
   * @param lockup_months number of months tokens will be locked
   */

  function checkBonus(uint256 amount, uint256 lockup_months) public view returns (uint256, uint256) {
    (uint256 lbonus, ) = checkLockupBonus(amount, lockup_months);
    return (checkTokenQuantityBonus(amount), lbonus);
  }

  /**
   * @dev To check amount of bonus tokens user will get for particular amount purchased
   *      compared with equivalent amount of tokens in USDT
   * @param amount amount of tokens to be locked
   */

  function checkTokenQuantityBonus(uint256 amount) public view returns (uint256) {
    uint256 price = calculatePrice(amount) / baseDecimals;
    if (price < token_quantity_bonus[0][0]) return 0;
    if (price >= token_quantity_bonus[0][token_quantity_bonus[0].length - 1]) return ((amount * baseDecimals) * token_quantity_bonus[1][token_quantity_bonus[1].length - 1]) / 10000;

    uint256 bonus;

    for (uint256 i = 0; i < (token_quantity_bonus[0].length); i++) {
      if (price < token_quantity_bonus[0][i]) {
        bonus = (token_quantity_bonus[1][i - 1]);
        break;
      } else if (price == token_quantity_bonus[0][i]) {
        bonus = (token_quantity_bonus[1][i]);
        break;
      }
    }

    return ((amount * baseDecimals) * bonus) / 10000;
  }

  /**
   * @dev To check amount of bonus tokens user will get for particular amount and months locked
   * @param amount amount of tokens to be locked
   * @param lockup_months number of months tokens will be locked
   */
  function checkLockupBonus(uint256 amount, uint256 lockup_months) public view returns (uint256 bonus, uint256 timeLockedFor) {
    if (lockup_bonus[lockup_months] == 0) {
      return (0, 0);
    } else {
      bonus = ((amount * baseDecimals) * lockup_bonus[lockup_months]) / 10000;
      timeLockedFor = lockup_months * MONTH;
    }
  }

  /**
   * @dev To buy into a presale using USDT
   * @param amount No of tokens to buy
   */
  function buyWithUSDT(uint256 amount, uint256 lockup_months) external checkSaleState(amount) whenNotPaused returns (bool) {
    uint256 usdPrice = usdtBuyHelper(amount);
    uint256 usdEq = calculatePrice(amount);
    uint256 newBonus = update(amount, lockup_months, usdEq, _msgSender());
    uint256 ourAllowance = USDTInterface.allowance(_msgSender(), address(this));
    require(usdPrice <= ourAllowance, 'Make sure to add enough allowance');
    (bool success, ) = address(USDTInterface).call(abi.encodeWithSignature('transferFrom(address,address,uint256)', _msgSender(), owner(), usdPrice));
    require(success, 'Token payment failed');
    emit TokensBought(_msgSender(), amount, address(USDTInterface), (newBonus), usdPrice, usdEq, block.timestamp);
    return true;
  }

  /**
   * @dev To buy into a presale using ETH
   * @param amount No of tokens to buy
   */
  function buyWithEth(uint256 amount, uint256 lockup_months) external payable checkSaleState(amount) whenNotPaused nonReentrant returns (bool) {
    uint256 ethAmount = ethBuyHelper(amount);
    uint256 usdEq = calculatePrice(amount);
    require(msg.value >= ethAmount, 'Less payment');
    uint256 excess = msg.value - ethAmount;
    uint256 newBonus = update(amount, lockup_months, usdEq, _msgSender());
    sendValue(payable(owner()), ethAmount);
    if (excess > 0) sendValue(payable(_msgSender()), excess);
    emit TokensBought(_msgSender(), amount, address(0), (newBonus), ethAmount, usdEq, block.timestamp);
    return true;
  }

  /**
   * @dev helper function to calculate LockupBonus & InvestmentBonus
   * @param amount No of tokens user has purchased
   * @param lockup_months number of months tokens will be locked
   */

  function update(
    uint256 amount,
    uint256 lockup_months,
    uint256 _linearPriceUsdRaised,
    address _user
  ) internal returns (uint256) {
    uint256 quantityBonus = checkTokenQuantityBonus(amount);
    (uint256 lockupBonus, uint256 time) = checkLockupBonus(amount, lockup_months);
    totalTokensSold += amount;
    if (totalTokensSold > rounds[0][currentStep]) {
      currentStep += 1;
    }

    uint256 newBonus = quantityBonus + lockupBonus;
    linearPriceUsdRaised += _linearPriceUsdRaised;
    userDeposits[_user].push(UserDeposits(amount * baseDecimals, newBonus, (((amount * baseDecimals) + newBonus) * initialClaimPercent) / 10000, 0, time));
    newUser[_msgSender()][userDeposits[_msgSender()].length - 1] = true;
    totalBonus += (newBonus);
    return newBonus;
  }

  function updateLinearStartTime(uint256 time) external onlyOwner {
    require(linearStartTime == 0, 'Linear time already set');
    linearStartTime = time;
  }

  function updateIncrement(uint256 _increment) external onlyOwner {
    require(increment == 0, 'increment already set');
    increment = _increment;
  }

  /**
   * @dev to update userDeposits for purchases made on BSC
   * @param users array of users
   * @param users array of userDeposits associated with users
   */
  function updateFromBSC(address[] calldata users, UserDeposits[] calldata _userDeposits) external onlyOwner {
    require(users.length == _userDeposits.length, 'Length mismatch');
    for (uint256 i = 0; i < users.length; i++) {
      userDeposits[users[i]].push(_userDeposits[i]);
    }
  }

  /**
   * @dev Helper funtion to get ETH price for given amount
   * @param amount No of tokens to buy
   */
  function ethBuyHelper(uint256 amount) public view returns (uint256 ethAmount) {
    uint256 usdPrice = calculatePrice(amount);
    ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
  }

  /**
   * @dev Helper funtion to get USDT price for given amount
   * @param amount No of tokens to buy
   */
  function usdtBuyHelper(uint256 amount) public view returns (uint256 usdPrice) {
    usdPrice = calculatePrice(amount);
    usdPrice = usdPrice / (10**12);
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, 'Low balance');
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'ETH Payment failed');
  }

  /**
   * @dev To check details of transactions done by the user
   * @param user user's address
   */

  function deposits(address user) external view returns (UserDeposits[] memory) {
    return userDeposits[user];
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
    require(_claimStart > endTime && _claimStart > block.timestamp, 'Invalid claim start time');
    require(noOfTokens >= (totalTokensSold * baseDecimals) + totalBonus, 'Tokens less than sold');
    require(_saleToken != address(0), 'Zero token address');
    require(claimStart == 0, 'Claim already set');
    claimStart = _claimStart;
    saleToken = _saleToken;
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
   * @param _id Id of the transaction
   */
  function claim(uint256 _id) public whenNotPaused returns (bool) {
    require(saleToken != address(0), 'Sale token not added');
    require(!isBlacklisted[_msgSender()], 'This Address is Blacklisted');

    if (whitelistClaimOnly) {
      require(isWhitelisted[_msgSender()], 'User not whitelisted for claim');
    }

    uint256 tokens = getClaimableAmount(_msgSender(), _id);
    require(tokens > 0, 'No claimable tokens available');

    if (!newUser[_msgSender()][_id]) {
      userDeposits[_msgSender()][_id].claimedAmount += tokens - ((tokens * 10) / 100);
    } else {
      userDeposits[_msgSender()][_id].claimedAmount += tokens;
    }

    bool success = IERC20Upgradeable(saleToken).transfer(_msgSender(), tokens);
    require(success, 'Token transfer failed');
    emit TokensClaimed(_msgSender(), _id, tokens, block.timestamp);
    return true;
  }

  /**
   * @dev To claim multiple tokens after claiming starts
   * @param _id array of id's of the transaction
   */
  function claimMultiple(uint256[] memory _id) external whenNotPaused {
    require(_id.length > 0, 'Invalid length');
    for (uint256 i; i < _id.length; i++) {
      require(claim(_id[i]), 'Claiming failed');
    }
  }

  /**
   * @dev Helper funtion to get claimable tokens for a user after claiming starts
   * @param _user Address of the user
   * @param _id Id of the transaction
   */
  function getClaimableAmount(address _user, uint256 _id) public view returns (uint256 claimableAmount) {
    require(claimStart > 0, 'Claim start time not set');
    require(_id < userDeposits[_user].length, 'Invalid Id');
    UserDeposits memory deposit = userDeposits[_user][_id];
    uint256 amount = deposit.depositAmount;
    uint256 bonus = deposit.bonusAmount;
    amount += bonus;
    uint256 claimedAmount = deposit.claimedAmount;
    require(amount > 0, 'Nothing to claim');

    if (amount - claimedAmount == 0) return 0;

    if (block.timestamp < claimStart) return 0;

    if (block.timestamp < (claimStart + deposit.claimTime)) {
      uint256 timePassedRatio = ((block.timestamp - claimStart) * baseDecimals) / ((deposit.claimTime));

      claimableAmount = (((amount - deposit.initialClaim) * timePassedRatio) / baseDecimals) + deposit.initialClaim;
    } else {
      claimableAmount = amount;
    }

    claimableAmount = claimableAmount - claimedAmount;
    if (!newUser[_msgSender()][_id]) {
      claimableAmount += (claimableAmount * 10) / 100;
    }
  }

  /**
   * @dev To update Investment bonus structure
   * @param _tokenQuantity updated values array
   */
  function updateInvestmentBonus(uint256[][2] memory _tokenQuantity) public onlyOwner {
    require(_tokenQuantity[0].length == _tokenQuantity[1].length, 'Mismatch length for token quantity bonus');
    token_quantity_bonus = _tokenQuantity;
  }

  /**
   * @dev To update LockUp bonus structure
   * @param _lockup updated values array
   */
  function updateLockUpBonus(uint256[][] memory _lockup) public onlyOwner {
    require(_lockup[0].length == _lockup[1].length, 'Mismatch length for token lockup bonus');
    for (uint256 i; i < _lockup[0].length; i++) {
      lockup_bonus[_lockup[0][i]] = _lockup[1][i];
    }
  }

  /**
   * @dev To buy ETH directly from wert .*wert contract address should be whitelisted if wertBuyRestrictionStatus is set true
   * @param user address of the user
   * @param amount No of ETH to buy
   */
  function buyWithETHWert(
    address user,
    uint256 amount,
    uint256 lockup_months
  ) external payable checkSaleState(amount) whenNotPaused nonReentrant returns (bool) {
    require(wertWhitelisted[_msgSender()], 'User not whitelisted for this tx');
    uint256 ethAmount = ethBuyHelper(amount);
    uint256 usdEq = calculatePrice(amount);
    require(msg.value >= ethAmount, 'Less payment');
    uint256 excess = msg.value - ethAmount;
    uint256 newBonus = update(amount, lockup_months, usdEq, user);

    sendValue(payable(owner()), ethAmount);
    if (excess > 0) sendValue(payable(user), excess);
    emit TokensBought(user, amount, address(0), (newBonus), ethAmount, usdEq, block.timestamp);
    return true;
  }

  /**
   * @dev To add wert contract addresses to whitelist
   * @param _addressesToWhitelist addresses of the contract
   */
  function whitelistUsersForWERT(address[] calldata _addressesToWhitelist) external onlyOwner {
    for (uint256 i = 0; i < _addressesToWhitelist.length; i++) {
      wertWhitelisted[_addressesToWhitelist[i]] = true;
    }
  }

  /**
   * @dev To remove wert contract addresses to whitelist
   * @param _addressesToRemoveFromWhitelist addresses of the contracts
   */
  function removeFromWhitelistForWERT(address[] calldata _addressesToRemoveFromWhitelist) external onlyOwner {
    for (uint256 i = 0; i < _addressesToRemoveFromWhitelist.length; i++) {
      wertWhitelisted[_addressesToRemoveFromWhitelist[i]] = false;
    }
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
}