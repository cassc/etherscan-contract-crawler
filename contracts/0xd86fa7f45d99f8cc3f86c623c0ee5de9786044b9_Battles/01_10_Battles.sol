// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

contract Battles is Context, Ownable, VRFConsumerBaseV2 {
  using SafeERC20 for IERC20;

  uint256 public createFee;
  uint256 public enterFee;

  mapping(address => bool) public whitelist;

  VRFCoordinatorV2Interface _vrfCoordinator;
  uint64 _vrfSubId;
  bytes32 _vrfKeyHash;
  uint16 _vrfBlocks = 3;
  uint32 _vrfCallbackLimit = 300000;

  uint256 public currentGame;
  // game => currentidx
  mapping(uint256 => uint256) _gameIdx;
  // VRF reqID => game
  mapping(uint256 => uint256) _settleReqGame;
  // game => VRF reqId
  mapping(uint256 => uint256) _settleGameReq;

  struct Battle {
    uint256 game;
    address player1;
    address player2;
    address requiredP2;
    address battleToken;
    uint256 battleAmount;
  }
  Battle[] public battles;

  event Create(
    uint256 indexed game,
    address player1,
    address battleToken,
    uint256 amount
  );
  event Cancel(uint256 indexed game, address requestor, address player1);
  event Enter(
    uint256 indexed game,
    uint256 requestId,
    address player1,
    address player2,
    address battleToken,
    uint256 battleAmount
  );
  event Settle(
    uint256 indexed game,
    uint256 requestId,
    address player1,
    address player2,
    address battleToken,
    uint256 battleAmount,
    address winner,
    uint256 amountWon
  );

  constructor(
    address _coord,
    uint64 _subId,
    bytes32 _keyHash
  ) VRFConsumerBaseV2(_coord) {
    _vrfCoordinator = VRFCoordinatorV2Interface(_coord);
    _vrfSubId = _subId;
    _vrfKeyHash = _keyHash;
    whitelist[0x85225Ed797fd4128Ac45A992C46eA4681a7A15dA] = true;
  }

  function createBattle(
    address _battleToken,
    uint256 _battleAmount,
    address _requiredP2
  ) external payable {
    if (_battleToken == address(0)) {
      require(msg.value == _battleAmount + createFee, 'ETH');
    } else {
      require(msg.value == createFee, 'ETH');
      require(whitelist[_battleToken], 'TOKEN');
      IERC20 token = IERC20(_battleToken);
      uint256 _before = token.balanceOf(address(this));
      token.safeTransferFrom(_msgSender(), address(this), _battleAmount);
      require(token.balanceOf(address(this)) == _before + _battleAmount, 'TXR');
    }
    _processFee(createFee);
    currentGame++;
    _gameIdx[currentGame] = battles.length;
    battles.push(
      Battle({
        game: currentGame,
        player1: _msgSender(),
        player2: address(0),
        requiredP2: _requiredP2,
        battleToken: _battleToken,
        battleAmount: _battleAmount
      })
    );
    emit Create(currentGame, _msgSender(), _battleToken, _battleAmount);
  }

  function cancelBattle(uint256 _game) external {
    require(_settleGameReq[_game] == 0, 'SETTLING');

    uint256 _idx = _gameIdx[_game];
    Battle memory _battle = battles[_idx];
    require(_battle.player1 == _msgSender() || owner() == _msgSender(), 'AUTH');
    _removeBattle(_game);

    if (_battle.battleToken == address(0)) {
      uint256 _balBefore = address(this).balance;
      (bool success, ) = payable(_battle.player1).call{
        value: _battle.battleAmount
      }('');
      require(success, 'ETH');
      require(
        address(this).balance >= _balBefore - _battle.battleAmount,
        'MEV'
      );
    } else {
      IERC20(_battle.battleToken).safeTransfer(
        _battle.player1,
        _battle.battleAmount
      );
    }
    emit Cancel(_game, _msgSender(), _battle.player1);
  }

  function enterBattle(uint256 _game) external payable {
    require(_settleGameReq[_game] == 0, 'SETTLING');
    uint256 _idx = _gameIdx[_game];
    Battle storage _battle = battles[_idx];
    require(_battle.game == _game && _battle.player1 != _msgSender(), 'VAL');
    require(
      _battle.requiredP2 == address(0) || _battle.requiredP2 == _msgSender(),
      'REQ2'
    );

    _battle.player2 = _msgSender();

    if (_battle.battleToken == address(0)) {
      require(msg.value == _battle.battleAmount + enterFee, 'ETH1');
    } else {
      require(msg.value == enterFee, 'ETH2');
      IERC20(_battle.battleToken).safeTransferFrom(
        _msgSender(),
        address(this),
        _battle.battleAmount
      );
    }
    _processFee(enterFee);
    uint256 _requestId = _vrfCoordinator.requestRandomWords(
      _vrfKeyHash,
      _vrfSubId,
      _vrfBlocks,
      _vrfCallbackLimit,
      uint16(1)
    );
    _settleReqGame[_requestId] = _game;
    _settleGameReq[_game] = _requestId;
    emit Enter(
      _game,
      _requestId,
      _battle.player1,
      _battle.player2,
      _battle.battleToken,
      _battle.battleAmount
    );
  }

  function fulfillRandomWords(
    uint256 _requestId,
    uint256[] memory _randomNumbers
  ) internal override {
    uint256 _randomNumber = _randomNumbers[0];
    uint256 _game = _settleReqGame[_requestId];
    uint256 _idx = _gameIdx[_game];
    Battle memory _battle = battles[_idx];
    _removeBattle(_game);

    uint256 _totalAmount = _battle.battleAmount * 2;
    uint256 _winAmount = (_totalAmount * 39) / 40;
    uint256 _adminAmount = _totalAmount - _winAmount;

    address _winner = _randomNumber % 2 == 0
      ? _battle.player1
      : _battle.player2;
    if (_battle.battleToken == address(0)) {
      uint256 _balBefore = address(this).balance;
      (bool success, ) = payable(_winner).call{ value: _winAmount }('');
      (bool success2, ) = payable(owner()).call{ value: _adminAmount }('');
      require(success && success2, 'ETH');
      require(address(this).balance >= _balBefore - _totalAmount, 'MEV');
    } else {
      IERC20(_battle.battleToken).safeTransfer(_winner, _winAmount);
      IERC20(_battle.battleToken).safeTransfer(owner(), _adminAmount);
    }

    emit Settle(
      _game,
      _requestId,
      _battle.player1,
      _battle.player2,
      _battle.battleToken,
      _battle.battleAmount,
      _winner,
      _winAmount
    );
  }

  function _processFee(uint256 _wei) internal {
    if (_wei == 0) {
      return;
    }
    (bool _s, ) = payable(owner()).call{ value: _wei }('');
    require(_s, 'FEE');
  }

  function _removeBattle(uint256 _game) internal {
    uint256 _idx = _gameIdx[_game];
    _gameIdx[battles[battles.length - 1].game] = _idx;
    battles[_idx] = battles[battles.length - 1];
    battles.pop();
  }

  function getBattlesNum() external view returns (uint256) {
    return battles.length;
  }

  function getBattles() external view returns (Battle[] memory) {
    return battles;
  }

  function setWhitelistTokens(
    address _token,
    bool _isWhitelisted
  ) external onlyOwner {
    require(whitelist[_token] != _isWhitelisted, 'TOGGLE');
    whitelist[_token] = _isWhitelisted;
  }

  function setCreateFee(uint256 _wei) external onlyOwner {
    createFee = _wei;
  }

  function setEnterFee(uint256 _wei) external onlyOwner {
    enterFee = _wei;
  }

  function setVrfSubId(uint64 _subId) external onlyOwner {
    _vrfSubId = _subId;
  }

  function setVrfNumBlocks(uint16 _blocks) external onlyOwner {
    _vrfBlocks = _blocks;
  }

  function setVrfCallbackGasLimit(uint32 _gas) external onlyOwner {
    _vrfCallbackLimit = _gas;
  }

  receive() external payable {
    (bool _s, ) = payable(owner()).call{ value: msg.value }('');
    require(_s, 'RECEIVE');
  }
}