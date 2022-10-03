// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract BitcoinBingo is Ownable {
  AggregatorV3Interface public priceFeed;
  IERC20 public prizeToken;

  uint256 public prizeFee;
  uint256 public feeDecimal;
  uint8 public bingoDecimal;
  uint256 public bufferSeconds;
  uint256 public intervalLockSeconds; // interval in seconds till Friday midnight
  uint256 public intervalCloseSeconds; // interval in seconds till Sunday midnight

  address public operatorAddress; // address of the operator

  uint256 public currentEpoch; // current epoch for prediction round
  uint256 public oracleLatestRoundId; // converted from uint80 (Chainlink)
  uint256 public oracleUpdateAllowance = 300; // seconds

  uint256 public companyPrize = 1000_00_0000_0000_0000_0000; // 1000 * 10e18
  uint256 public bingoAmount = 1_00_0000_0000_0000_0000; // 1 * 10e18
  uint256 public treasuryAmount;

  struct Round {
    uint256 epoch;
    uint256 startTimestamp;
    uint256 lockTimestamp;
    uint256 closeTimestamp;
    int256 closePrice;
    uint256 closeOracleId;
    uint256 totalAmount;
    uint256 rewardAmount;
    bool bingoLocked; // default false
    bool oracleCalled; // default false
  }

  struct BingoInfo {
    int256 price;
    bool exist;
    bool claimed; // default false
  }

  // epoch => account => id => BingoInfo
  mapping(uint256 => mapping(address => mapping(uint8 => BingoInfo))) public ledger;
  // epoch => Round
  mapping(uint256 => Round) public rounds;
  // account => epoch => number of bingo
  mapping(address => mapping(uint256 => uint8)) public userRounds;
  mapping(address => mapping(uint256 => bool)) public userFreeRounds;
  mapping(address => mapping(uint256 => uint8)) public userRoundsAvailable;
  mapping(address => uint256[]) public userRoundLists;
  // epoch => price => accounts
  mapping(uint256 => mapping(int256 => address[])) public priceRounds;

  mapping(address => bool) public communityMembers;
  mapping(address => bool) public tvlMembers;
  
  event StartRound(uint256 indexed epoch);
  event EndRound(uint256 indexed epoch);
  event LockRound(uint256 indexed epoch, uint256 indexed roundId, int256 price);

  modifier onlyOperator() {
    require(msg.sender == operatorAddress, "Not operator");
    _;
  }

  modifier notContract() {
    require(!_isContract(msg.sender), "Contract not allowed");
    require(msg.sender == tx.origin, "Proxy contract not allowed");
    _;
  }

  constructor(address _priceFeed, address _prizeToken) {
    priceFeed = AggregatorV3Interface(_priceFeed);
    prizeToken = IERC20(_prizeToken);

    prizeFee = 300;
    feeDecimal = 1000;
    bingoDecimal = 6;
    
    bufferSeconds = 30;
    intervalLockSeconds = 432000;
    intervalCloseSeconds = 604800;

    operatorAddress = msg.sender;

    _startRound();
  }

  function bingoBTC(uint256 epoch, int256[] memory prices) external notContract {
    require(epoch == currentEpoch, "Bet is too early/late");
    require(_bettable(epoch), "Round not bettable");

    uint256[3] memory betPrices = [
      bingoAmount,
      bingoAmount / 2,
      bingoAmount / 2
    ];
    uint256 bingoBetAmount = 0;
    uint256 bingoStep = 0;
    uint256 bingoLen = prices.length;
    for (uint256 i=0; i<bingoLen; i++) {
      if (prices[i] != 0 && userRounds[msg.sender][epoch] + bingoStep < 3) {
        bingoStep ++;
        bingoBetAmount += betPrices[userRounds[msg.sender][epoch] + bingoStep];
      }
    }

    require(userRounds[msg.sender][epoch] + bingoStep <= 3, "Btcbingo: You can do only 3 times bingo");

    require(IERC20(prizeToken).allowance(msg.sender, address(this)) >= bingoBetAmount, 'Btcbingo: Bingo token is not approved');
    IERC20(prizeToken).transferFrom(msg.sender, address(this), bingoBetAmount);
    Round storage round = rounds[epoch];
    round.totalAmount = round.totalAmount + bingoBetAmount;

    userRounds[msg.sender][epoch] += uint8(bingoStep);
    
    for (uint256 i=0; i<bingoStep; i++) {
      if (prices[i] != 0) continue;
      int256 price = prices[i];
      userRoundLists[msg.sender].push(epoch);
      ledger[epoch][msg.sender][userRounds[msg.sender][epoch]] = BingoInfo(price, true, false);
      priceRounds[epoch][price].push(msg.sender);
    }
  }

  function bingoBTCViaOperator(uint256 epoch, int256 price, address account) external onlyOperator {
    require(epoch == currentEpoch, "Bet is too early/late");
    require(_bettable(epoch), "Round not bettable");
    
    require(userFreeRounds[account][epoch] == false, "Btcbingo: You can do only once bingo");

    userFreeRounds[account][epoch] = true;
    userRoundLists[account].push(epoch);

    ledger[epoch][account][userRounds[account][epoch]] = BingoInfo(price, true, false);

    priceRounds[epoch][price].push(account);
  }

  /**
    * @notice Claim reward for an array of epochs
    * @param epochs: array of epochs
    */
  function claim(uint256[] calldata epochs) external notContract {
    uint256 prizeAmount = 0;
    uint256 epochLen = epochs.length;

    for (uint256 i=0; i<epochLen; i++) {
      uint8 numberClamable = claimable(epochs[i], msg.sender);
      Round memory round = rounds[epochs[i]];

      if (numberClamable > 0) {
        prizeAmount = prizeAmount + round.rewardAmount * numberClamable / priceRounds[epochs[i]][round.closePrice].length;
      }
    }

    require(IERC20(prizeToken).balanceOf(address(this)) >= prizeAmount, "Btcbingo: Treasury not enough prize token balance");
    IERC20(prizeToken).transfer(msg.sender, prizeAmount);
  }

  function executeRound() external onlyOperator {
    // CurrentEpoch refers to previous round (n-1)
    require(rounds[currentEpoch].lockTimestamp != 0, "Can only end round after round has locked");
    require(block.timestamp >= rounds[currentEpoch].closeTimestamp, "Can only end round after closeTimestamp");
    require(
      block.timestamp <= rounds[currentEpoch].closeTimestamp + bufferSeconds,
      "Can only end round within bufferSeconds"
    );

    Round storage round = rounds[currentEpoch];
    round.closeTimestamp = block.timestamp;
    emit EndRound(currentEpoch);

    // Increment currentEpoch to current round (n)
    currentEpoch = currentEpoch + 1;
    _startRound();
  }

  function forceExecuteRound(uint256 _intervalLockSeconds, uint256 _intervalCloseSeconds) external onlyOperator {
    int256 currentPrice = 0;
    Round storage round = rounds[currentEpoch];
    round.closeTimestamp = block.timestamp;
    round.closePrice = currentPrice;
    round.closeOracleId = 0;
    round.oracleCalled = false;

    round.rewardAmount = 0;
    treasuryAmount = treasuryAmount + round.totalAmount - round.rewardAmount;

    emit EndRound(currentEpoch);

    currentEpoch = currentEpoch + 1;

    Round storage cround = rounds[currentEpoch];
    cround.startTimestamp = block.timestamp;
    cround.lockTimestamp = block.timestamp + _intervalLockSeconds;
    cround.closeTimestamp = block.timestamp + _intervalCloseSeconds;
    cround.epoch = currentEpoch;
    cround.totalAmount = companyPrize;

    emit StartRound(currentEpoch);
  }

  /**
    * @notice Lock running round
    * @dev Callable by operator
    */
  function genesisLockRound() external onlyOperator {
    (uint80 currentRoundId, int256 currentPrice) = _getPriceFromOracle();

    oracleLatestRoundId = uint256(currentRoundId);

    require(rounds[currentEpoch].startTimestamp != 0, "Can only lock round after round has started");
    require(block.timestamp >= rounds[currentEpoch].lockTimestamp, "Can only lock round after lockTimestamp");
    require(
      block.timestamp <= rounds[currentEpoch].lockTimestamp + bufferSeconds,
      "Can only lock round within bufferSeconds"
    );

    currentPrice = currentPrice / (int256(10) ** bingoDecimal) * (int256(10) ** bingoDecimal);
    
    Round storage round = rounds[currentEpoch];
    round.lockTimestamp = block.timestamp;
    round.bingoLocked = true;
    round.closePrice = currentPrice;
    round.closeOracleId = currentRoundId;
    round.oracleCalled = true;

    if (priceRounds[currentEpoch][currentPrice].length > 0) {
      round.rewardAmount = companyPrize + (round.totalAmount - companyPrize) * prizeFee / feeDecimal;
    }
    else {
      round.rewardAmount = 0;
    }
    treasuryAmount = treasuryAmount + round.totalAmount - round.rewardAmount;

    emit LockRound(currentEpoch, currentRoundId, currentPrice);
  }

  function depoistPrize() public {
    require(IERC20(prizeToken).allowance(msg.sender, address(this)) >= companyPrize, 'Btcbingo: Prize token is not approved');
    IERC20(prizeToken).transferFrom(msg.sender, address(this), companyPrize);
  }

  function withdrawTreasuryFee(uint256 amount) public onlyOwner {
    require(treasuryAmount >= amount, "Btcbingo: Wrong amount");
    require(IERC20(prizeToken).balanceOf(address(this)) >= amount, "Btcbingo: Not enough prize token balance");

    IERC20(prizeToken).transfer(msg.sender, amount);
    treasuryAmount = treasuryAmount - amount;
  }

  function recoverPrizeToken() public onlyOwner {
    IERC20(prizeToken).transfer(msg.sender, IERC20(prizeToken).balanceOf(address(this)));
  }

  /**
    * @notice Returns round epochs and bet information for a user that has participated
    * @param user: user address
    * @param cursor: cursor
    * @param size: size
    */
  function getUserRounds(
    address user,
    uint256 cursor,
    uint256 size
  )
    external
    view
    returns (
      uint256[] memory,
      BingoInfo[] memory,
      uint256
    )
  {
    uint256 length = size;

    if (length > userRoundLists[user].length - cursor) {
      length = userRoundLists[user].length - cursor;
    }

    uint256[] memory epoches = new uint256[](length);
    BingoInfo[] memory bingoInfo = new BingoInfo[](length);

    uint256 prevEpoch = 0;
    for (uint256 i = 0; i < length; i++) {
      epoches[i] = userRoundLists[user][cursor + i];
      if (epoches[i] == prevEpoch) {
        bingoInfo[i] = ledger[epoches[i]][user][2];
      }
      else {
        bingoInfo[i] = ledger[epoches[i]][user][1];
      }

      prevEpoch = epoches[i];
    }

    return (epoches, bingoInfo, cursor + length);
  }

  /**
    * @notice Returns round epochs length
    * @param user: user address
    */
  function getUserRoundsLength(address user) external view returns (uint256) {
    return userRoundLists[user].length;
  }

  /**
    * @notice Get the claimable stats of specific epoch and user account
    * @param epoch: epoch
    * @param user: user address
    */
  function claimable(uint256 epoch, address user) public view returns (uint8) {
    Round memory round = rounds[epoch];
    if ( ! round.oracleCalled) return 0;

    uint8 numberBingo = userRounds[user][epoch];
    
    uint8 rclaim = 0;
    for (uint8 i = 0; i < numberBingo; i ++) {
      if (ledger[epoch][user][i+1].price == round.closePrice && ledger[epoch][user][i+1].claimed == false) {
        rclaim = rclaim + 1;
      }
    }

    return rclaim;
  }

  function setPriceFeed(address _priceFeed) public onlyOwner {
    priceFeed = AggregatorV3Interface(_priceFeed);
  }
  function setPrizeToken(address _prizeToken) public onlyOwner {
    prizeToken = IERC20(_prizeToken);
  }
  function setTreasuryFee(uint256 _prizeFee, uint256 _feeDecimal) public onlyOwner {
    prizeFee = _prizeFee;
    feeDecimal = _feeDecimal;
  }
  function setBingoDecimal(uint8 _bingoDecimal) public onlyOwner {
    bingoDecimal = _bingoDecimal;
  }
  function setBufferSeconds(uint256 _bufferSeconds) public onlyOwner {
    bufferSeconds = _bufferSeconds;
  }
  function setIntervalLockSeconds(uint256 _intervalLockSeconds) public onlyOwner {
    intervalLockSeconds = _intervalLockSeconds;
  }
  function setIntervalCloseSeconds(uint256 _intervalCloseSeconds) public onlyOwner {
    require(_intervalCloseSeconds >= intervalLockSeconds, "Btcbingo: Wrong close timestamp");
    intervalCloseSeconds = _intervalCloseSeconds;
  }
  function setCompanyPrize(uint256 _companyPrize) public onlyOwner {
    companyPrize = _companyPrize;
  }
  function setBingoAmount(uint256 _bingoAmount) public onlyOwner {
    bingoAmount = _bingoAmount;
  }
  function setCommunityMember(address _account, bool _value) public onlyOwner {
    communityMembers[_account] = _value;
  }
  function setTvlMember(address _account, bool _value) public onlyOwner {
    tvlMembers[_account] = _value;
  }

  function _startRound() internal {
    Round storage cround = rounds[currentEpoch];
    cround.startTimestamp = block.timestamp;
    cround.lockTimestamp = block.timestamp + intervalLockSeconds;
    cround.closeTimestamp = block.timestamp + intervalCloseSeconds;
    cround.epoch = currentEpoch;
    cround.totalAmount = companyPrize;

    emit StartRound(currentEpoch);
  }

  /**
    * @notice Determine if a round is valid for receiving bets
    * Round must have started and locked
    * Current timestamp must be within startTimestamp and closeTimestamp
    */
  function _bettable(uint256 epoch) internal view returns (bool) {
    return
      rounds[epoch].startTimestamp != 0 &&
      rounds[epoch].lockTimestamp != 0 &&
      block.timestamp > rounds[epoch].startTimestamp &&
      block.timestamp < rounds[epoch].lockTimestamp;
  }

  /**
    * @notice Get latest recorded price from oracle
    * If it falls below allowed buffer or has not updated, it would be invalid.
    */
  function _getPriceFromOracle() internal view returns (uint80, int256) {
    uint256 leastAllowedTimestamp = block.timestamp + oracleUpdateAllowance;
    (uint80 roundId, int256 price, , uint256 timestamp, ) = priceFeed.latestRoundData();
    require(timestamp <= leastAllowedTimestamp, "Oracle update exceeded max timestamp allowance");
    require(
      uint256(roundId) > oracleLatestRoundId,
      "Oracle update roundId must be larger than oracleLatestRoundId"
    );
    return (roundId, price);
  }

  /**
    * @notice Returns true if `account` is a contract.
    * @param account: account address
    */
  function _isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
}