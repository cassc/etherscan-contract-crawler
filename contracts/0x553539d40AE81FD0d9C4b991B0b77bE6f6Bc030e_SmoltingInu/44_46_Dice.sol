// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import './interfaces/ISmoltingInu.sol';
import './SmolGame.sol';

/**
 * @title Dice
 * @dev Chainlink VRF powered dice roller
 */
contract Dice is SmolGame, VRFConsumerBaseV2 {
  uint256 private constant PERCENT_DENOMENATOR = 1000;

  ISmoltingInu smol = ISmoltingInu(0x553539d40AE81FD0d9C4b991B0b77bE6f6Bc030e);
  uint256 public diceMinBalancePerc = (PERCENT_DENOMENATOR * 5) / 100; // 5% user's balance
  uint256 public diceMinWagerAbsolute;
  uint256 public diceMaxWagerAbsolute;
  uint256 public payoutMultiple = PERCENT_DENOMENATOR * 5;
  uint256 public diceWon;
  uint256 public diceLost;
  uint256 public diceAmountWon;
  uint256 public diceAmountLost;
  mapping(address => uint256) public diceUserWon;
  mapping(address => uint256) public diceUserLost;
  mapping(address => uint256) public diceUserAmountWon;
  mapping(address => uint256) public diceUserAmountLost;
  mapping(address => bool) public lastRollDiceWon;
  mapping(uint8 => uint256) public sidesRolled;

  mapping(uint256 => address) private _rollDiceInitUser;
  mapping(uint256 => uint256) private _rollDiceInitAmount;
  mapping(uint256 => uint8) private _rollDiceInitSideSelected;
  mapping(uint256 => uint256) private _rollDiceInitNonce;
  mapping(uint256 => bool) private _rollDiceInitSettled;
  mapping(address => uint256) public userWagerNonce;

  VRFCoordinatorV2Interface vrfCoord;
  LinkTokenInterface link;
  uint64 private _vrfSubscriptionId;
  bytes32 private _vrfKeyHash;
  uint16 private _vrfNumBlocks = 3;
  uint32 private _vrfCallbackGasLimit = 600000;

  event RollDice(
    address indexed wagerer,
    uint256 indexed nonce,
    uint8 indexed sideSelected,
    uint256 requestId,
    uint256 amountWagered
  );
  event GetDiceResult(
    address indexed wagerer,
    uint256 indexed nonce,
    uint8 indexed sideSelected,
    uint256 requestId,
    uint256 amountWagered,
    uint8 sideRolled,
    bool isWinner,
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

  function rollDice(uint8 _sideSelected, uint256 _percent) external payable {
    require(_sideSelected > 0 && _sideSelected <= 6, 'invalid side selected');
    require(
      _percent >= diceMinBalancePerc && _percent <= PERCENT_DENOMENATOR,
      'must wager between half and your entire bag'
    );
    uint256 _finalWagerAmount = (smol.balanceOf(msg.sender) * _percent) /
      PERCENT_DENOMENATOR;
    require(
      _finalWagerAmount >= diceMinWagerAbsolute,
      'does not meet minimum amount requirements'
    );
    require(
      diceMaxWagerAbsolute == 0 || _finalWagerAmount <= diceMaxWagerAbsolute,
      'exceeded maximum amount requirements'
    );

    _enforceMinMaxWagerLogic(msg.sender, _finalWagerAmount);
    smol.transferFrom(msg.sender, address(this), _finalWagerAmount);
    smol.addPlayThrough(
      msg.sender,
      _finalWagerAmount,
      percentageWagerTowardsRewards
    );
    uint256 requestId = vrfCoord.requestRandomWords(
      _vrfKeyHash,
      _vrfSubscriptionId,
      _vrfNumBlocks,
      _vrfCallbackGasLimit,
      uint16(1)
    );

    _rollDiceInitUser[requestId] = msg.sender;
    _rollDiceInitAmount[requestId] = _finalWagerAmount;
    _rollDiceInitSideSelected[requestId] = _sideSelected;
    _rollDiceInitNonce[requestId] = userWagerNonce[msg.sender];
    userWagerNonce[msg.sender]++;

    _payServiceFee();
    emit RollDice(
      msg.sender,
      _rollDiceInitNonce[requestId],
      _sideSelected,
      requestId,
      _finalWagerAmount
    );
  }

  function manualSettleRollDice(uint256 requestId, uint256[] memory randomWords)
    external
    onlyOwner
  {
    _settleRollDice(requestId, randomWords[0]);
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    _settleRollDice(requestId, randomWords[0]);
  }

  function _settleRollDice(uint256 requestId, uint256 randomNumber) internal {
    address _user = _rollDiceInitUser[requestId];
    require(_user != address(0), 'dice record does not exist');
    require(!_rollDiceInitSettled[requestId], 'already settled');
    _rollDiceInitSettled[requestId] = true;

    uint256 _amountWagered = _rollDiceInitAmount[requestId];
    uint256 _nonce = _rollDiceInitNonce[requestId];
    uint256 _amountToWin = (_amountWagered * payoutMultiple) /
      PERCENT_DENOMENATOR;
    uint8 _sideSelected = _rollDiceInitSideSelected[requestId];
    // `X mod 6` returns 0-5, so need to subtract side selected by 1 to get real result
    bool _didUserWin = randomNumber % 6 == _sideSelected - 1;
    uint8 _sideRolled = uint8(randomNumber % 6) + 1;
    sidesRolled[_sideRolled]++;

    if (_didUserWin) {
      smol.transfer(_user, _amountWagered);
      smol.gameMint(_user, _amountToWin);
      diceWon++;
      diceAmountWon += _amountToWin;
      diceUserWon[_user]++;
      diceUserAmountWon[_user] += _amountToWin;
      lastRollDiceWon[_user] = true;
    } else {
      smol.gameBurn(address(this), _amountWagered);
      diceLost++;
      diceAmountLost += _amountWagered;
      diceUserLost[_user]++;
      diceUserAmountLost[_user] += _amountWagered;
      lastRollDiceWon[_user] = false;
    }

    emit GetDiceResult(
      _user,
      _nonce,
      _sideSelected,
      requestId,
      _amountWagered,
      _sideRolled,
      _didUserWin,
      _amountToWin
    );
  }

  function getSmolToken() external view returns (address) {
    return address(smol);
  }

  function setPayoutMultiple(uint256 _multiple) external onlyOwner {
    require(_multiple > 0, 'must be more than 0');
    payoutMultiple = _multiple;
  }

  function setSmolToken(address _token) external onlyOwner {
    smol = ISmoltingInu(_token);
  }

  function setDiceMinBalancePerc(uint256 _percent) external onlyOwner {
    require(_percent <= PERCENT_DENOMENATOR, 'must be less than 100%');
    diceMinBalancePerc = _percent;
  }

  function setDiceMinWagerAbsolute(uint256 _amount) external onlyOwner {
    diceMinWagerAbsolute = _amount;
  }

  function setDiceMaxWagerAbsolute(uint256 _amount) external onlyOwner {
    diceMaxWagerAbsolute = _amount;
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