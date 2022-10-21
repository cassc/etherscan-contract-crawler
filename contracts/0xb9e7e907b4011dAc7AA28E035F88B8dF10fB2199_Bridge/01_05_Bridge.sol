// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

contract Bridge is Ownable {
  IERC20 _token = IERC20(0x30dcBa0405004cF124045793E1933C798Af9E66a);
  bool public isActive;
  uint256 public bridgeCost = 2 ether / 100;
  uint16 public sourceConfirmations = 30;

  struct Bridge {
    bytes32 id;
    bool isSource;
    uint256 sourceBlock;
    bool isComplete;
    address wallet;
    uint256 amount;
  }

  address[] _relays;
  mapping(address => uint256) _relaysIdx;

  mapping(bytes32 => Bridge) public sources;
  bytes32[] _incompleteSources;
  mapping(bytes32 => uint256) _incSourceIdx;

  mapping(bytes32 => Bridge) public receivers;
  bytes32[] _incompleteReceivers;
  mapping(bytes32 => uint256) _incReceiverIdx;
  mapping(bytes32 => address) public receiverIniter;
  mapping(bytes32 => address) public receiverSender;

  event Create(bytes32 indexed id, address wallet, uint256 amount);
  event InitDeliver(bytes32 indexed id, address wallet, uint256 amount);
  event Deliver(bytes32 indexed id, address wallet, uint256 amount);

  modifier onlyRelay() {
    bool _isValid;
    for (uint256 _i = 0; _i < _relays.length; _i++) {
      if (_relays[_i] == msg.sender) {
        _isValid = true;
        break;
      }
    }
    require(_isValid, 'Must be relay');
    _;
  }

  function getBridgeToken() external view returns (address) {
    return address(_token);
  }

  function getIncompleteSources() external view returns (bytes32[] memory) {
    return _incompleteSources;
  }

  function getIncompleteReceivers() external view returns (bytes32[] memory) {
    return _incompleteReceivers;
  }

  function setBridgeToken(address __token) external onlyOwner {
    _token = IERC20(__token);
  }

  function setIsActive(bool _isActive) external onlyOwner {
    isActive = _isActive;
  }

  function setBridgeCost(uint256 _wei) external onlyOwner {
    bridgeCost = _wei;
  }

  function setRelay(address _relay, bool _isRelay) external onlyOwner {
    uint256 _idx = _relaysIdx[_relay];
    if (_isRelay) {
      require(
        _relays.length == 0 || (_idx == 0 && _relays[_idx] != _relay),
        'Must enable'
      );
      _relaysIdx[_relay] = _relays.length;
      _relays.push(_relay);
    } else {
      require(_relays[_idx] == _relay, 'Must disable');
      delete _relaysIdx[_relay];
      _relaysIdx[_relays[_relays.length - 1]] = _idx;
      _relays[_idx] = _relays[_relays.length - 1];
      _relays.pop();
    }
  }

  function create(uint256 _amount) external payable {
    require(isActive, 'Bridge disabled');
    require(msg.value >= bridgeCost, 'Must pay bridge fee');

    _amount = _amount == 0 ? _token.balanceOf(msg.sender) : _amount;
    require(_amount > 0, 'Must bridge some tokens');

    bytes32 _id = sha256(abi.encodePacked(msg.sender, block.number, _amount));
    require(sources[_id].id == bytes32(0), 'Can only bridge once per block');

    _token.transferFrom(msg.sender, address(this), _amount);

    sources[_id] = Bridge({
      id: _id,
      isSource: true,
      sourceBlock: block.number,
      isComplete: false,
      wallet: msg.sender,
      amount: _amount
    });
    _incSourceIdx[_id] = _incompleteSources.length;
    _incompleteSources.push(_id);
    emit Create(_id, msg.sender, _amount);
  }

  function setSourceComplete(bytes32 _id) external onlyRelay {
    require(sources[_id].id != bytes32(0), 'Source does not exist');
    require(!sources[_id].isComplete, 'Source is already complete');
    sources[_id].isComplete = true;

    uint256 _sourceIdx = _incSourceIdx[_id];
    delete _incSourceIdx[_id];
    _incSourceIdx[
      _incompleteSources[_incompleteSources.length - 1]
    ] = _sourceIdx;
    _incompleteSources[_sourceIdx] = _incompleteSources[
      _incompleteSources.length - 1
    ];
    _incompleteSources.pop();
  }

  function initDeliver(
    bytes32 _id,
    address _user,
    uint256 _sourceBlock,
    uint256 _amount
  ) external onlyRelay {
    require(isActive, 'Bridge disabled');

    bytes32 _idCheck = sha256(abi.encodePacked(_user, _sourceBlock, _amount));
    require(_id == _idCheck, 'Not recognized');
    require(receiverIniter[_id] == address(0), 'Already initialized');

    receiverIniter[_id] = msg.sender;
    receivers[_id] = Bridge({
      id: _id,
      isSource: false,
      sourceBlock: _sourceBlock,
      isComplete: false,
      wallet: _user,
      amount: _amount
    });
    _incReceiverIdx[_id] = _incompleteReceivers.length;
    _incompleteReceivers.push(_id);
    emit InitDeliver(_id, receivers[_id].wallet, receivers[_id].amount);
  }

  function deliver(bytes32 _id) external onlyRelay {
    require(isActive, 'Bridge disabled');
    Bridge storage receiver = receivers[_id];
    require(receiver.id == _id && _id != bytes32(0), 'Invalid bridge txn');
    require(
      msg.sender != receiverIniter[_id],
      'Initer and sender must be different'
    );
    require(!receiver.isComplete, 'Already completed');

    receiverSender[_id] = msg.sender;
    receiver.isComplete = true;

    _token.transfer(receiver.wallet, receiver.amount);

    uint256 _recIdx = _incReceiverIdx[_id];
    delete _incReceiverIdx[_id];
    _incReceiverIdx[
      _incompleteReceivers[_incompleteReceivers.length - 1]
    ] = _recIdx;
    _incompleteReceivers[_recIdx] = _incompleteReceivers[
      _incompleteReceivers.length - 1
    ];
    _incompleteReceivers.pop();
    emit Deliver(_id, receiver.wallet, receiver.amount);
  }

  function setSourceConfirmations(uint16 _conf) external onlyOwner {
    sourceConfirmations = _conf;
  }

  function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
    IERC20 _contract = IERC20(_token);
    _amount = _amount == 0 ? _contract.balanceOf(address(this)) : _amount;
    require(_amount > 0);
    _contract.transfer(owner(), _amount);
  }

  function withdrawETH() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
  }
}