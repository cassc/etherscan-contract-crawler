// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import './interfaces/ISmoltingInu.sol';
import './SmolGame.sol';

/**
 * @title Lottery
 * @dev Chainlink VRF powered lottery for ERC-20 tokens
 */
contract Lottery is SmolGame, VRFConsumerBaseV2 {
  uint256 private constant PERCENT_DENOMENATOR = 1000;

  ISmoltingInu smol = ISmoltingInu(0x553539d40AE81FD0d9C4b991B0b77bE6f6Bc030e);
  uint256 public currentMinWinAmount = 1000 * 10**18;
  uint256 public percentageFeeWin = (PERCENT_DENOMENATOR * 95) / 100;
  uint256 public lottoEntryFee = 10**18; // 1 token (assuming 18 decimals)
  uint256 public lottoTimespan = 60 * 60 * 24; // 24 hours
  uint16 public numberWinners = 1;

  uint256[] public lotteries;
  // lottoTimestamp => isSettled
  mapping(uint256 => bool) public isLotterySettled;
  // lottoTimestamp => participants
  mapping(uint256 => address[]) public lottoParticipants;
  // user => currentLottery => numEntries
  mapping(address => mapping(uint256 => uint256)) public lotteryEntriesPerUser;
  // lottoTimestamp => winner
  mapping(uint256 => address[]) public lottoWinners;
  // lottoTimestamp => amountWon
  mapping(uint256 => uint256) public lottoWinnerAmounts;

  mapping(uint256 => uint256) private _lotterySelectInit;
  mapping(uint256 => uint256) private _lotterySelectReqIdInit;

  VRFCoordinatorV2Interface vrfCoord;
  LinkTokenInterface link;
  uint64 private _vrfSubscriptionId;
  bytes32 private _vrfKeyHash;
  uint16 private _vrfNumBlocks = 3;
  uint32 private _vrfCallbackGasLimit = 600000;

  event DrawWinner(uint256 indexed lottoTimestamp);
  event SelectedWinners(
    uint256 indexed lottoTimestamp,
    address[] winner,
    uint256 amountWon
  );

  constructor(
    address _nativeUSDFeed,
    address _vrfCoordinator,
    uint64 _subscriptionId,
    address _linkToken,
    bytes32 _keyHash
  ) SmolGame(_nativeUSDFeed) VRFConsumerBaseV2(_vrfCoordinator) {
    vrfCoord = VRFCoordinatorV2Interface(_vrfCoordinator);
    link = LinkTokenInterface(_linkToken);
    _vrfSubscriptionId = _subscriptionId;
    _vrfKeyHash = _keyHash;
  }

  function launch() external onlyOwner {
    lotteries.push(block.timestamp);
  }

  function enterLotto(uint256 _entries) external payable {
    _enterLotto(msg.sender, msg.sender, _entries);
  }

  function enterLottoForUser(address _user, uint256 _entries) external payable {
    _enterLotto(msg.sender, _user, _entries);
  }

  function _enterLotto(
    address _payingUser,
    address _entryUser,
    uint256 _entries
  ) internal {
    _payServiceFee();
    uint256 _currentLottery = getCurrentLottery();
    if (block.timestamp > _currentLottery + lottoTimespan) {
      selectLottoWinner();
      _currentLottery = getCurrentLottery();
    }

    smol.transferFrom(_payingUser, address(this), _entries * lottoEntryFee);
    smol.addPlayThrough(
      _entryUser,
      _entries * lottoEntryFee,
      percentageWagerTowardsRewards
    );
    lotteryEntriesPerUser[_entryUser][_currentLottery] += _entries;
    for (uint256 i = 0; i < _entries; i++) {
      lottoParticipants[_currentLottery].push(_entryUser);
    }
  }

  function selectLottoWinner() public {
    uint256 _currentLottery = getCurrentLottery();
    require(
      block.timestamp > _currentLottery + lottoTimespan,
      'lottery time period must be past'
    );
    require(currentMinWinAmount > 0, 'no jackpot to win');
    require(_lotterySelectInit[_currentLottery] == 0, 'already initiated');
    lotteries.push(block.timestamp);

    if (lottoParticipants[_currentLottery].length == 0) {
      _lotterySelectInit[_currentLottery] = 1;
      isLotterySettled[_currentLottery] = true;
      return;
    }

    uint256 requestId = vrfCoord.requestRandomWords(
      _vrfKeyHash,
      _vrfSubscriptionId,
      _vrfNumBlocks,
      _vrfCallbackGasLimit,
      numberWinners
    );
    _lotterySelectInit[_currentLottery] = requestId;
    _lotterySelectReqIdInit[requestId] = _currentLottery;
    emit DrawWinner(_currentLottery);
  }

  function manualSettleLottery(uint256 requestId, uint256[] memory randomWords)
    external
    onlyOwner
  {
    _settleLottery(requestId, randomWords);
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    _settleLottery(requestId, randomWords);
  }

  function _settleLottery(uint256 requestId, uint256[] memory randomWords)
    internal
  {
    uint256 _lotteryToSettle = _lotterySelectReqIdInit[requestId];
    require(_lotteryToSettle != 0, 'lottery selection does not exist');

    uint256 _amountWon = getLotteryRewardAmount(_lotteryToSettle);
    address[] memory _winners = new address[](randomWords.length);
    for (uint256 i = 0; i < randomWords.length; i++) {
      uint256 _winnerIdx = randomWords[i] %
        lottoParticipants[_lotteryToSettle].length;
      _winners[i] = lottoParticipants[_lotteryToSettle][_winnerIdx];
      smol.gameMint(_winners[i], _amountWon / randomWords.length);
    }

    smol.gameBurn(address(this), smol.balanceOf(address(this)));
    lottoWinners[_lotteryToSettle] = _winners;
    lottoWinnerAmounts[_lotteryToSettle] = _amountWon;
    isLotterySettled[_lotteryToSettle] = true;
    emit SelectedWinners(_lotteryToSettle, _winners, _amountWon);
  }

  function getLottoToken() external view returns (address) {
    return address(smol);
  }

  function getCurrentLottery() public view returns (uint256) {
    return lotteries[lotteries.length - 1];
  }

  function getNumberLotteries() external view returns (uint256) {
    return lotteries.length;
  }

  function getCurrentNumberEntriesForUser(address _user)
    external
    view
    returns (uint256)
  {
    return lotteryEntriesPerUser[_user][getCurrentLottery()];
  }

  function getCurrentLotteryRewardAmount() external view returns (uint256) {
    return getLotteryRewardAmount(getCurrentLottery());
  }

  function getLotteryRewardAmount(uint256 _lottery)
    public
    view
    returns (uint256)
  {
    uint256 _participants = getLotteryEntries(_lottery);
    uint256 _entryFeesTotal = _participants * lottoEntryFee;
    uint256 _entryFeeWinAmount = (_entryFeesTotal * percentageFeeWin) /
      PERCENT_DENOMENATOR;

    if (_entryFeeWinAmount < currentMinWinAmount) {
      return currentMinWinAmount;
    }
    return _entryFeeWinAmount;
  }

  function getCurrentLotteryEntries() external view returns (uint256) {
    return getLotteryEntries(getCurrentLottery());
  }

  function getLotteryEntries(uint256 _lottery) public view returns (uint256) {
    return lottoParticipants[_lottery].length;
  }

  function setCurrentMinWinAmount(uint256 _amount) external onlyOwner {
    currentMinWinAmount = _amount;
  }

  function setPercentageFeeWin(uint256 _percent) external onlyOwner {
    require(_percent <= PERCENT_DENOMENATOR, 'cannot be more than 100%');
    require(_percent > 0, 'has to be more than 0%');
    percentageFeeWin = _percent;
  }

  function setLottoToken(address _token) external onlyOwner {
    smol = ISmoltingInu(_token);
  }

  function setLottoTimespan(uint256 _seconds) external onlyOwner {
    lottoTimespan = _seconds;
  }

  function setLottoEntryFee(uint256 _fee) external onlyOwner {
    lottoEntryFee = _fee;
  }

  function setNumberWinners(uint16 _number) external onlyOwner {
    require(_number > 0 && _number <= 20, 'no more than 20 winners');
    numberWinners = _number;
  }

  function setVrfSubscriptionId(uint64 _subId) external onlyOwner {
    _vrfSubscriptionId = _subId;
  }

  function setVrfNumBlocks(uint16 _numBlocks) external onlyOwner {
    _vrfNumBlocks = _numBlocks;
  }

  function setVrfCallbackGasLimit(uint32 _gas) external onlyOwner {
    _vrfCallbackGasLimit = _gas;
  }
}