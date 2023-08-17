// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

contract DebaucheryPVP is Context, Ownable, VRFConsumerBaseV2 {
  using SafeERC20 for IERC20;

  address public constant EXCESS = 0x0a7D7B118c57e956E5C2Ca9e0f1b4AA1D2aAA9c3;

  uint256 public createFee;
  uint256 public enterFee;

  VRFCoordinatorV2Interface _clCoordinator;
  uint64 _clSubId;
  bytes32 _clKeyHash;
  uint16 _clBlocks = 3;
  uint32 _clCallbackLimit = 300000;

  uint256 public latestGameNumber;
  // game number => current pvps idx
  mapping(uint256 => uint256) _gameNumberIdx;
  // VRF request ID => game number
  mapping(uint256 => uint256) _settleInfo;
  // game number => VRF request ID
  mapping(uint256 => uint256) _settleInfReqIdIdx;

  struct PVP {
    uint256 gameNumber;
    address p1;
    address p2;
    address forceP2;
    address pvpToken;
    uint256 pvpAmount;
  }
  PVP[] public pvps;

  event Create(
    uint256 indexed gameNumber,
    address p1,
    address pvpToken,
    uint256 amount
  );
  event Cancel(uint256 indexed gameNumber, address requestor, address p1);
  event Enter(
    uint256 indexed gameNumber,
    uint256 requestId,
    address p1,
    address p2,
    address pvpToken,
    uint256 pvpAmount
  );
  event Settle(
    uint256 indexed gameNumber,
    uint256 requestId,
    address p1,
    address p2,
    address pvpToken,
    uint256 pvpAmount,
    address winner,
    uint256 amountWon
  );

  constructor(
    address _coordinator,
    uint64 _subId,
    bytes32 _keyHash
  ) VRFConsumerBaseV2(_coordinator) {
    _clCoordinator = VRFCoordinatorV2Interface(_coordinator);
    _clSubId = _subId;
    _clKeyHash = _keyHash;
  }

  function createPVP(
    address _pvpToken,
    uint256 _pvpAmount,
    address _forceP2
  ) external payable {
    if (_pvpToken == address(0)) {
      require(msg.value == _pvpAmount + createFee, 'ETH');
    } else {
      require(msg.value == createFee, 'ETH');
      require(_pvpToken == EXCESS, 'TOKEN');
      IERC20 token = IERC20(_pvpToken);
      token.safeTransferFrom(_msgSender(), address(this), _pvpAmount);
    }
    _processFee(createFee);
    latestGameNumber++;
    _gameNumberIdx[latestGameNumber] = pvps.length;
    pvps.push(
      PVP({
        gameNumber: latestGameNumber,
        p1: _msgSender(),
        p2: address(0),
        forceP2: _forceP2,
        pvpToken: _pvpToken,
        pvpAmount: _pvpAmount
      })
    );
    emit Create(latestGameNumber, _msgSender(), _pvpToken, _pvpAmount);
  }

  function cancelPVP(uint256 _gameNumber) external {
    require(_settleInfReqIdIdx[_gameNumber] == 0, 'SETTLING');

    uint256 _idx = _gameNumberIdx[_gameNumber];
    PVP memory _pvp = pvps[_idx];
    require(_pvp.p1 == _msgSender() || owner() == _msgSender(), 'AUTH');
    _removePVP(_gameNumber);

    if (_pvp.pvpToken == address(0)) {
      uint256 _balBefore = address(this).balance;
      (bool success, ) = payable(_pvp.p1).call{ value: _pvp.pvpAmount }('');
      require(success, 'ETH');
      require(address(this).balance >= _balBefore - _pvp.pvpAmount, 'MEV');
    } else {
      IERC20(_pvp.pvpToken).safeTransfer(_pvp.p1, _pvp.pvpAmount);
    }
    emit Cancel(_gameNumber, _msgSender(), _pvp.p1);
  }

  function enterPVP(uint256 _gameNumber) external payable {
    require(_settleInfReqIdIdx[_gameNumber] == 0, 'SETTLING');
    uint256 _idx = _gameNumberIdx[_gameNumber];
    PVP storage _pvp = pvps[_idx];
    require(
      _pvp.gameNumber == _gameNumber && _pvp.p1 != _msgSender(),
      'VALIDATION'
    );
    require(
      _pvp.forceP2 == address(0) || _pvp.forceP2 == _msgSender(),
      'REQPLAYER2'
    );

    _pvp.p2 = _msgSender();

    if (_pvp.pvpToken == address(0)) {
      require(msg.value == _pvp.pvpAmount + enterFee, 'ETH');
    } else {
      require(msg.value == enterFee, 'ETH');
      IERC20(_pvp.pvpToken).safeTransferFrom(
        _msgSender(),
        address(this),
        _pvp.pvpAmount
      );
    }
    _processFee(enterFee);
    uint256 _requestId = _clCoordinator.requestRandomWords(
      _clKeyHash,
      _clSubId,
      _clBlocks,
      _clCallbackLimit,
      uint16(1)
    );
    _settleInfo[_requestId] = _gameNumber;
    _settleInfReqIdIdx[_gameNumber] = _requestId;
    emit Enter(
      _gameNumber,
      _requestId,
      _pvp.p1,
      _pvp.p2,
      _pvp.pvpToken,
      _pvp.pvpAmount
    );
  }

  function fulfillRandomWords(
    uint256 _requestId,
    uint256[] memory _randomWords
  ) internal override {
    uint256 _randomNumber = _randomWords[0];
    uint256 _gameNumber = _settleInfo[_requestId];
    uint256 _idx = _gameNumberIdx[_gameNumber];
    PVP memory _pvp = pvps[_idx];
    _removePVP(_gameNumber);

    uint256 _totalAmount = _pvp.pvpAmount * 2;
    uint256 _winAmount = (_totalAmount * 95) / 100;
    uint256 _adminAmount = _totalAmount - _winAmount;

    address _winner = _randomNumber % 2 == 0 ? _pvp.p1 : _pvp.p2;
    if (_pvp.pvpToken == address(0)) {
      uint256 _balBefore = address(this).balance;
      (bool success, ) = payable(_winner).call{ value: _winAmount }('');
      (bool success2, ) = payable(owner()).call{ value: _adminAmount }('');
      require(success && success2, 'ETH');
      require(address(this).balance >= _balBefore - _totalAmount, 'MEV');
    } else {
      IERC20(_pvp.pvpToken).safeTransfer(_winner, _winAmount);
      IERC20(_pvp.pvpToken).safeTransfer(owner(), _adminAmount);
    }

    emit Settle(
      _gameNumber,
      _requestId,
      _pvp.p1,
      _pvp.p2,
      _pvp.pvpToken,
      _pvp.pvpAmount,
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

  function _removePVP(uint256 _gameNumber) internal {
    uint256 _idx = _gameNumberIdx[_gameNumber];
    _gameNumberIdx[pvps[pvps.length - 1].gameNumber] = _idx;
    pvps[_idx] = pvps[pvps.length - 1];
    pvps.pop();
  }

  function getPVPsNum() external view returns (uint256) {
    return pvps.length;
  }

  function getPVPs() external view returns (PVP[] memory) {
    return pvps;
  }

  function setCreateFee(uint256 _wei) external onlyOwner {
    createFee = _wei;
  }

  function setEnterFee(uint256 _wei) external onlyOwner {
    enterFee = _wei;
  }

  function setClSubId(uint64 _subId) external onlyOwner {
    _clSubId = _subId;
  }

  function setClNumBlocks(uint16 _blocks) external onlyOwner {
    _clBlocks = _blocks;
  }

  function setClCallbackGasLimit(uint32 _gas) external onlyOwner {
    _clCallbackLimit = _gas;
  }
}