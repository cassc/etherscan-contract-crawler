// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import './interfaces/ISmoltingInu.sol';
import './SmolGame.sol';

contract Battles is SmolGame, VRFConsumerBaseV2 {
  uint256 private constant PERCENT_DENOMENATOR = 1000;
  address public mainBattleToken = 0x553539d40AE81FD0d9C4b991B0b77bE6f6Bc030e;

  VRFCoordinatorV2Interface vrfCoord;
  LinkTokenInterface link;
  uint64 private _vrfSubscriptionId;
  bytes32 private _vrfKeyHash;
  uint16 private _vrfNumBlocks = 3;
  uint32 private _vrfCallbackGasLimit = 600000;
  mapping(uint256 => bytes32) private _battleSettleInit;
  mapping(bytes32 => uint256) private _battleSettleInitReqId;

  struct Battle {
    bytes32 id;
    uint256 allIndex;
    uint256 activeIndex;
    uint256 timestamp;
    address player1;
    address player2;
    address requiredPlayer2; // if player1 wants to battle specific address, provide here
    bool isNativeToken; // ETH, BNB, etc.
    address erc20Token;
    uint256 desiredAmount;
    uint256 actualAmount;
    bool isSettled;
    bool isCancelled;
  }
  bytes32[] public allBattles;
  bytes32[] public activeBattles;
  mapping(bytes32 => Battle) public battlesIndexed;

  uint256 public battleWinMainPercentage = (PERCENT_DENOMENATOR * 95) / 100; // 95% wager amount
  uint256 public battleWinAltPercentage = (PERCENT_DENOMENATOR * 90) / 100; // 90% wager amount
  uint256 public battleAmountBattled;
  uint256 public battlesInitiatorWon;
  uint256 public battlesChallengerWon;
  mapping(address => uint256) public battlesUserWon;
  mapping(address => uint256) public battlesUserLost;
  mapping(address => uint256) public battleUserAmountWon;
  mapping(address => uint256) public battleUserAmountLost;
  mapping(address => bool) public lastBattleWon;

  event CreateBattle(
    bytes32 indexed battleId,
    address player1,
    bool isNative,
    address erc20Token,
    uint256 amountWagered
  );
  event CancelBattle(bytes32 indexed battleId);
  event EnterBattle(
    bytes32 indexed battleId,
    uint256 requestId,
    address player1,
    address player2,
    bool isNative,
    address erc20Token,
    uint256 amountWagered
  );
  event SettledBattle(
    bytes32 indexed battleId,
    uint256 requestId,
    address player1,
    address player2,
    bool isNative,
    address erc20Token,
    uint256 amountWagered,
    address winner,
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

  function createBattle(
    bool _isNative,
    address _erc20,
    uint256 _amount,
    address _requiredPlayer2
  ) external payable {
    uint256 _actualAmount = _amount;
    if (_isNative) {
      require(
        msg.value >= _amount + getFinalServiceFeeWei(),
        'not enough ETH in wallet to battle this much'
      );
    } else {
      IERC20 token = IERC20(_erc20);
      require(
        token.balanceOf(msg.sender) > _amount,
        'not enough of token in wallet to battle this much'
      );
      uint256 _balBefore = token.balanceOf(address(this));
      token.transferFrom(msg.sender, address(this), _amount);
      _actualAmount = token.balanceOf(address(this)) - _balBefore;
    }

    bytes32 _battleId = getBattleId(
      msg.sender,
      _isNative,
      _erc20,
      block.timestamp
    );
    require(battlesIndexed[_battleId].timestamp == 0, 'battle already created');

    battlesIndexed[_battleId] = Battle({
      id: _battleId,
      allIndex: allBattles.length,
      activeIndex: activeBattles.length,
      timestamp: block.timestamp,
      player1: msg.sender,
      player2: address(0),
      requiredPlayer2: _requiredPlayer2,
      isNativeToken: _isNative,
      erc20Token: _erc20,
      desiredAmount: _amount,
      actualAmount: _actualAmount,
      isSettled: false,
      isCancelled: false
    });
    allBattles.push(_battleId);
    activeBattles.push(_battleId);

    _payServiceFee();
    emit CreateBattle(_battleId, msg.sender, _isNative, _erc20, _amount);
  }

  function cancelBattle(bytes32 _battleId) external {
    Battle storage _battle = battlesIndexed[_battleId];
    require(_battle.timestamp > 0, 'battle not created yet');
    require(
      _battle.player1 == msg.sender || owner() == msg.sender,
      'user not authorized to cancel'
    );
    require(
      _battle.player2 == address(0),
      'battle settlement is already underway'
    );
    require(
      !_battle.isSettled && !_battle.isCancelled,
      'battle already settled or cancelled'
    );

    _battle.isCancelled = true;
    _removeActiveBattle(_battle.activeIndex);

    if (_battle.isNativeToken) {
      uint256 _balBefore = address(this).balance;
      (bool success, ) = payable(_battle.player1).call{
        value: _battle.actualAmount
      }('');
      require(success, 'could not refund player1 original battle fee');
      require(
        address(this).balance >= _balBefore - _battle.actualAmount,
        'too much withdrawn'
      );
    } else {
      IERC20 token = IERC20(_battle.erc20Token);
      token.transfer(_battle.player1, _battle.actualAmount);
    }
    emit CancelBattle(_battleId);
  }

  function enterBattle(bytes32 _battleId) external payable {
    require(_battleSettleInitReqId[_battleId] == 0, 'already initiated');
    _payServiceFee();
    Battle storage _battle = battlesIndexed[_battleId];
    require(
      _battle.requiredPlayer2 == address(0) ||
        _battle.requiredPlayer2 == msg.sender,
      'battler is invalid user'
    );
    _battle.player2 = msg.sender;
    if (_battle.isNativeToken) {
      require(
        msg.value >= _battle.actualAmount + getFinalServiceFeeWei(),
        'not enough ETH in wallet to battle this much'
      );
    } else {
      IERC20 token = IERC20(_battle.erc20Token);
      uint256 _balBefore = token.balanceOf(address(this));
      token.transferFrom(msg.sender, address(this), _battle.desiredAmount);
      require(
        token.balanceOf(address(this)) >= _balBefore + _battle.actualAmount,
        'not enough transferred probably because of token taxes'
      );
    }

    uint256 requestId = vrfCoord.requestRandomWords(
      _vrfKeyHash,
      _vrfSubscriptionId,
      _vrfNumBlocks,
      _vrfCallbackGasLimit,
      uint16(1)
    );
    _battleSettleInit[requestId] = _battleId;
    _battleSettleInitReqId[_battleId] = requestId;

    _removeActiveBattle(_battle.activeIndex);

    emit EnterBattle(
      _battleId,
      requestId,
      _battle.player1,
      _battle.player2,
      _battle.isNativeToken,
      _battle.erc20Token,
      _battle.actualAmount
    );
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    _settleBattle(requestId, randomWords[0]);
  }

  function manualFulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) external onlyOwner {
    _settleBattle(requestId, randomWords[0]);
  }

  function _settleBattle(uint256 requestId, uint256 randomNumber) private {
    bytes32 _battleId = _battleSettleInit[requestId];
    Battle storage _battle = battlesIndexed[_battleId];
    require(!_battle.isSettled, 'battle already settled');
    _battle.isSettled = true;

    uint256 _feePercentage = _battle.isNativeToken
      ? battleWinAltPercentage
      : _battle.erc20Token == mainBattleToken
      ? battleWinMainPercentage
      : battleWinAltPercentage;
    uint256 _amountToWin = _battle.actualAmount +
      (_battle.actualAmount * _feePercentage) /
      PERCENT_DENOMENATOR;

    address _winner = randomNumber % 2 == 0 ? _battle.player1 : _battle.player2;
    address _loser = _battle.player1 == _winner
      ? _battle.player2
      : _battle.player1;
    if (_battle.isNativeToken) {
      uint256 _balBefore = address(this).balance;
      (bool success, ) = payable(_winner).call{ value: _amountToWin }('');
      require(success, 'could not pay winner battle winnings');
      require(
        address(this).balance >= _balBefore - _amountToWin,
        'too much withdrawn'
      );
    } else {
      IERC20 token = IERC20(_battle.erc20Token);
      token.transfer(_winner, _amountToWin);

      if (_battle.erc20Token == mainBattleToken) {
        _addPlayThrough(_battle.player1, _battle.desiredAmount);
        _addPlayThrough(_battle.player2, _battle.desiredAmount);
      }
    }

    battleAmountBattled += _battle.desiredAmount * 2;
    battlesInitiatorWon += randomNumber % 2 == 0 ? 1 : 0;
    battlesChallengerWon += randomNumber % 2 == 0 ? 0 : 1;
    battlesUserWon[_winner]++;
    battlesUserLost[_loser]++;
    battleUserAmountWon[_winner] += _amountToWin - _battle.actualAmount;
    battleUserAmountLost[_loser] += _battle.desiredAmount;
    lastBattleWon[_winner] = true;
    lastBattleWon[_loser] = false;

    // emit SettledBattle(_battleId, _winner, _amountToWin);
    emit SettledBattle(
      _battleId,
      requestId,
      _battle.player1,
      _battle.player2,
      _battle.isNativeToken,
      _battle.erc20Token,
      _battle.actualAmount,
      _winner,
      _amountToWin
    );
  }

  function _removeActiveBattle(uint256 _activeIndex) internal {
    if (activeBattles.length > 1) {
      activeBattles[_activeIndex] = activeBattles[activeBattles.length - 1];
      battlesIndexed[activeBattles[_activeIndex]].activeIndex = _activeIndex;
    }
    activeBattles.pop();
  }

  function _addPlayThrough(address _user, uint256 _amount) internal {
    ISmoltingInu(mainBattleToken).addPlayThrough(
      _user,
      _amount,
      percentageWagerTowardsRewards
    );
  }

  function getBattleId(
    address _player1,
    bool _isNative,
    address _erc20Token,
    uint256 _timestamp
  ) public pure returns (bytes32) {
    return
      keccak256(abi.encodePacked(_player1, _isNative, _erc20Token, _timestamp));
  }

  function getNumBattles() external view returns (uint256) {
    return allBattles.length;
  }

  function getNumActiveBattles() external view returns (uint256) {
    return activeBattles.length;
  }

  function getAllActiveBattles() external view returns (Battle[] memory) {
    Battle[] memory _battles = new Battle[](activeBattles.length);
    for (uint256 i = 0; i < activeBattles.length; i++) {
      _battles[i] = battlesIndexed[activeBattles[i]];
    }
    return _battles;
  }

  function setMainBattleToken(address _token) external onlyOwner {
    mainBattleToken = _token;
  }

  function setBattleWinMainPercentage(uint256 _percentage) external onlyOwner {
    require(_percentage <= PERCENT_DENOMENATOR, 'cannot exceed 100%');
    battleWinMainPercentage = _percentage;
  }

  function setBattleWinAltPercentage(uint256 _percentage) external onlyOwner {
    require(_percentage <= PERCENT_DENOMENATOR, 'cannot exceed 100%');
    battleWinAltPercentage = _percentage;
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