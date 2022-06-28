// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import './interfaces/ISmoltingInu.sol';
import './SmolGame.sol';

/**
 * @title OverUnder
 * @dev Chainlink VRF powered number picker chance game
 */
contract OverUnder is SmolGame, VRFConsumerBaseV2 {
  uint256 private constant PERCENT_DENOMENATOR = 1000;

  ISmoltingInu smol = ISmoltingInu(0x2bf6267c4997548d8de56087E5d48bDCCb877E77);
  uint256 public minBalancePerc = (PERCENT_DENOMENATOR * 5) / 100; // 5% user's balance
  uint256 public minWagerAbsolute;
  uint256 public maxWagerAbsolute;

  uint256 public payoutMultipleFactor = 985;

  uint8 public numberFloor = 1;
  uint8 public numberCeil = 100;

  uint256 public selectionsMade;
  uint256 public selectionsWon;
  uint256 public selectionsLost;
  uint256 public selectionsAmountWon;
  uint256 public selectionsAmountLost;
  mapping(address => uint256) public selectionsUserWon;
  mapping(address => uint256) public selectionsUserLost;
  mapping(address => uint256) public selectionsUserAmountWon;
  mapping(address => uint256) public selectionsUserAmountLost;
  mapping(uint8 => uint256) public numbersDrawn;

  mapping(uint256 => address) private _selectInit;
  mapping(address => uint256) private _selectInitAmount;
  mapping(address => uint8) private _selectInitSideSelected;
  mapping(address => bool) private _selectInitIsOver;
  mapping(address => uint256) private _selectInitPayout;

  VRFCoordinatorV2Interface vrfCoord;
  LinkTokenInterface link;
  uint64 private _vrfSubscriptionId;
  bytes32 private _vrfKeyHash;
  uint16 private _vrfNumBlocks = 3;
  uint32 private _vrfCallbackGasLimit = 600000;

  event SelectNumber(
    address indexed user,
    uint8 indexed numSelected,
    bool isOver,
    uint256 payoutMultiple,
    uint256 amountWagered,
    uint256 requestId
  );
  event GetResult(
    address indexed user,
    uint8 indexed numSelected,
    bool indexed isWinner,
    bool isOver,
    uint256 payoutMultiple,
    uint8 numDrawn,
    uint256 amountToWin,
    uint256 requestId
  );

  constructor(
    address _vrfCoordinator,
    uint64 _subscriptionId,
    address _linkToken,
    bytes32 _keyHash
  ) VRFConsumerBaseV2(_vrfCoordinator) {
    vrfCoord = VRFCoordinatorV2Interface(_vrfCoordinator);
    link = LinkTokenInterface(_linkToken);
    _vrfSubscriptionId = _subscriptionId;
    _vrfKeyHash = _keyHash;
  }

  function selectNumber(
    uint8 _numSelected,
    bool _isOver,
    uint256 _percent
  ) external payable {
    require(
      _numSelected > numberFloor && _numSelected < numberCeil,
      'number selected must be between floor and ceil'
    );
    require(
      _percent >= minBalancePerc && _percent <= PERCENT_DENOMENATOR,
      'must wager more than minimum balance'
    );
    uint256 _finalWagerAmount = (smol.balanceOf(msg.sender) * _percent) /
      PERCENT_DENOMENATOR;
    require(
      _finalWagerAmount >= minWagerAbsolute,
      'does not meet minimum amount requirements'
    );
    require(
      maxWagerAbsolute == 0 || _finalWagerAmount <= maxWagerAbsolute,
      'exceeded maximum amount requirements'
    );
    require(_selectInitAmount[msg.sender] == 0, 'already initiated');

    smol.transferFrom(msg.sender, address(this), _finalWagerAmount);
    uint256 requestId = vrfCoord.requestRandomWords(
      _vrfKeyHash,
      _vrfSubscriptionId,
      _vrfNumBlocks,
      _vrfCallbackGasLimit,
      uint16(1)
    );

    _selectInit[requestId] = msg.sender;
    _selectInitAmount[msg.sender] = _finalWagerAmount;
    _selectInitSideSelected[msg.sender] = _numSelected;
    _selectInitIsOver[msg.sender] = _isOver;
    _selectInitPayout[msg.sender] = getPayoutMultiple(_numSelected, _isOver);
    selectionsMade++;
    _payServiceFee();
    emit SelectNumber(
      msg.sender,
      _numSelected,
      _isOver,
      _selectInitPayout[msg.sender],
      _finalWagerAmount,
      requestId
    );
  }

  function getPayoutMultiple(uint8 _numSelected, bool _isOver)
    public
    view
    returns (uint256)
  {
    require(
      _numSelected > numberFloor && _numSelected < numberCeil,
      'number selected must be between floor and ceil'
    );
    uint256 odds;
    if (_isOver) {
      odds = (numberCeil * payoutMultipleFactor) / (numberCeil - _numSelected);
    } else {
      odds = (numberCeil * payoutMultipleFactor) / (_numSelected - numberFloor);
    }
    return odds - 1000;
  }

  function manualSettleSelection(
    uint256 requestId,
    uint256[] memory randomWords
  ) external onlyOwner {
    _settle(requestId, randomWords[0]);
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    _settle(requestId, randomWords[0]);
  }

  function _settle(uint256 requestId, uint256 randomNumber) internal {
    address _user = _selectInit[requestId];
    require(_user != address(0), 'number selection record does not exist');

    uint256 _amountWagered = _selectInitAmount[_user];
    uint8 _numSelected = _selectInitSideSelected[_user];
    uint256 _amountToWin = (_amountWagered * _selectInitPayout[_user]) /
      PERCENT_DENOMENATOR;
    uint8 _numberDrawn = uint8(randomNumber % (numberCeil - numberFloor + 1)) +
      numberFloor;
    bool _didUserWin = _selectInitIsOver[_user]
      ? _numberDrawn > _numSelected
      : _numberDrawn < _numSelected;

    if (_didUserWin) {
      smol.transfer(_user, _amountWagered);
      smol.gameMint(_user, _amountToWin);
      selectionsWon++;
      selectionsAmountWon += _amountToWin;
      selectionsUserWon[_user]++;
      selectionsUserAmountWon[_user] += _amountToWin;
    } else if (_numberDrawn == _numSelected) {
      // draw
      smol.transfer(_user, _amountWagered);
    } else {
      smol.gameBurn(address(this), _amountWagered);
      selectionsLost++;
      selectionsAmountLost += _amountWagered;
      selectionsUserLost[_user]++;
      selectionsUserAmountLost[_user] += _amountWagered;
    }
    numbersDrawn[_numberDrawn]++;

    // reset to allow wagering again
    _selectInitAmount[_user] = 0;
    emit GetResult(
      _user,
      _numSelected,
      _didUserWin,
      _selectInitIsOver[_user],
      _selectInitPayout[_user],
      _numberDrawn,
      _amountToWin,
      requestId
    );
  }

  function getSmolToken() external view returns (address) {
    return address(smol);
  }

  function setSmolToken(address _token) external onlyOwner {
    smol = ISmoltingInu(_token);
  }

  function setPayoutMultipleFactor(uint256 _factor) external onlyOwner {
    payoutMultipleFactor = _factor;
  }

  function setFloorAndCeil(uint8 _floor, uint8 _ceil) external onlyOwner {
    require(
      _ceil > _floor && _ceil - _floor >= 2,
      'floor and ceil must be at least 2 units apart'
    );
    numberFloor = _floor;
    numberCeil = _ceil;
  }

  function setMinBalancePerc(uint256 _percent) external onlyOwner {
    require(_percent <= PERCENT_DENOMENATOR, 'must be less than 100%');
    minBalancePerc = _percent;
  }

  function setMinWagerAbsolute(uint256 _amount) external onlyOwner {
    minWagerAbsolute = _amount;
  }

  function setMaxWagerAbsolute(uint256 _amount) external onlyOwner {
    maxWagerAbsolute = _amount;
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