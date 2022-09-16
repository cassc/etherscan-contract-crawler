// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import './interfaces/ISmoltingInu.sol';
import './SmolGame.sol';

contract CoinFlip is SmolGame, VRFConsumerBaseV2 {
  uint256 private constant PERCENT_DENOMENATOR = 1000;

  ISmoltingInu smol = ISmoltingInu(0x553539d40AE81FD0d9C4b991B0b77bE6f6Bc030e);
  VRFCoordinatorV2Interface vrfCoord;
  LinkTokenInterface link;
  uint64 private _vrfSubscriptionId;
  bytes32 private _vrfKeyHash;
  uint16 private _vrfNumBlocks = 3;
  uint32 private _vrfCallbackGasLimit = 600000;
  mapping(uint256 => address) private _flipWagerInitUser;
  mapping(uint256 => bool) private _flipWagerInitIsHeads;
  mapping(uint256 => uint256) private _flipWagerInitAmount;
  mapping(uint256 => uint256) private _flipWagerInitNonce;
  mapping(uint256 => bool) private _flipWagerInitSettled;
  mapping(address => uint256) public userWagerNonce;

  uint256 public coinFlipMinBalancePerc = (PERCENT_DENOMENATOR * 50) / 100; // 50% user's balance
  uint256 public coinFlipWinPercentage = (PERCENT_DENOMENATOR * 95) / 100; // 95% wager amount
  uint256 public coinFlipsWon;
  uint256 public coinFlipsLost;
  uint256 public coinFlipAmountWon;
  uint256 public coinFlipAmountLost;
  mapping(address => uint256) public coinFlipsUserWon;
  mapping(address => uint256) public coinFlipsUserLost;
  mapping(address => uint256) public coinFlipUserAmountWon;
  mapping(address => uint256) public coinFlipUserAmountLost;
  mapping(address => bool) public lastCoinFlipWon;

  event InitiatedCoinFlip(
    address indexed wagerer,
    uint256 indexed nonce,
    uint256 requestId,
    bool isHeads,
    uint256 amountWagered
  );
  event SettledCoinFlip(
    address indexed wagerer,
    uint256 indexed nonce,
    uint256 requestId,
    bool isHeads,
    uint256 amountWagered,
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

  // coinFlipMinBalancePerc <= _percent <= 1000
  function flipCoin(uint16 _percent, bool _isHeads) external payable {
    require(smol.balanceOf(msg.sender) > 0, 'must have a bag to wager');
    require(
      _percent >= coinFlipMinBalancePerc && _percent <= PERCENT_DENOMENATOR,
      'must wager between the minimum and your entire bag'
    );
    uint256 _finalWagerAmount = (smol.balanceOf(msg.sender) * _percent) /
      PERCENT_DENOMENATOR;

    _enforceMinMaxWagerLogic(msg.sender, _finalWagerAmount);
    smol.transferFrom(msg.sender, address(this), _finalWagerAmount);

    uint256 requestId = vrfCoord.requestRandomWords(
      _vrfKeyHash,
      _vrfSubscriptionId,
      _vrfNumBlocks,
      _vrfCallbackGasLimit,
      uint16(1)
    );

    _flipWagerInitUser[requestId] = msg.sender;
    _flipWagerInitAmount[requestId] = _finalWagerAmount;
    _flipWagerInitNonce[requestId] = userWagerNonce[msg.sender];
    _flipWagerInitIsHeads[requestId] = _isHeads;
    userWagerNonce[msg.sender]++;

    smol.addPlayThrough(
      msg.sender,
      _finalWagerAmount,
      percentageWagerTowardsRewards
    );
    smol.setCanSellWithoutElevation(msg.sender, true);
    _payServiceFee();
    emit InitiatedCoinFlip(
      msg.sender,
      _flipWagerInitNonce[requestId],
      requestId,
      _isHeads,
      _finalWagerAmount
    );
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    _settleCoinFlip(requestId, randomWords[0]);
  }

  function manualFulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) external onlyOwner {
    _settleCoinFlip(requestId, randomWords[0]);
  }

  function _settleCoinFlip(uint256 requestId, uint256 randomNumber) internal {
    address _user = _flipWagerInitUser[requestId];
    require(_user != address(0), 'coin flip record does not exist');
    require(!_flipWagerInitSettled[requestId], 'already settled');
    _flipWagerInitSettled[requestId] = true;

    uint256 _amountWagered = _flipWagerInitAmount[requestId];
    uint256 _nonce = _flipWagerInitNonce[requestId];
    bool _isHeads = _flipWagerInitIsHeads[requestId];
    uint256 _amountToWin = (_amountWagered * coinFlipWinPercentage) /
      PERCENT_DENOMENATOR;
    uint8 _selectionMod = _isHeads ? 0 : 1;
    bool _didUserWin = randomNumber % 2 == _selectionMod;

    if (_didUserWin) {
      smol.transfer(_user, _amountWagered);
      smol.gameMint(_user, _amountToWin);
      coinFlipsWon++;
      coinFlipAmountWon += _amountToWin;
      coinFlipsUserWon[_user]++;
      coinFlipUserAmountWon[_user] += _amountToWin;
      lastCoinFlipWon[_user] = true;
    } else {
      smol.gameBurn(address(this), _amountWagered);
      coinFlipsLost++;
      coinFlipAmountLost += _amountWagered;
      coinFlipsUserLost[_user]++;
      coinFlipUserAmountLost[_user] += _amountWagered;
      lastCoinFlipWon[_user] = false;
    }
    emit SettledCoinFlip(
      _user,
      _nonce,
      requestId,
      _isHeads,
      _amountWagered,
      _didUserWin,
      _amountToWin
    );
  }

  function setCoinFlipMinBalancePerc(uint256 _percentage) external onlyOwner {
    require(_percentage <= PERCENT_DENOMENATOR, 'cannot exceed 100%');
    coinFlipMinBalancePerc = _percentage;
  }

  function setCoinFlipWinPercentage(uint256 _percentage) external onlyOwner {
    require(_percentage <= PERCENT_DENOMENATOR, 'cannot exceed 100%');
    coinFlipWinPercentage = _percentage;
  }

  function getSmolToken() external view returns (address) {
    return address(smol);
  }

  function setSmolToken(address _token) external onlyOwner {
    smol = ISmoltingInu(_token);
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