// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../node_modules/@openzeppelin/contracts/interfaces/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../node_modules/@openzeppelin/contracts/security/Pausable.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract FlexibleStaking is Pausable, Ownable {
  using SafeMath for uint256;
  using SafeCast for uint256;

  IERC20 private _token;

  struct Position {
    // 32 bytes
    address account;
    uint48 openedAt;
    uint48 expiresAt;
    // ----------------
    // 16 bytes
    uint128 deposit;
    // ----------------
    uint80 id;
    uint80 previousId;
    uint80 nextId;
  }
  struct Condition {
    uint256 expiresAfter;
    bool exists;
  }
  event OpenPosition(address indexed account, Position position);
  event ClosePosition(address indexed account, Position position);
  event SetMinDeposit(uint256 minDeposit);
  event SetMaxDeposit(uint256 maxDeposit);
  event Withdraw(address tokenAddress, address withdrawalAddress);
  event SetConditions(uint256[] expiresAfter, bytes32[] hashes);

  mapping(uint80 => Position) private _positions;
  mapping(address => uint80) private _accountsPositionsTail;

  mapping(address => uint80) private _accountsActivePositionsCount;
  mapping(address => uint256) private _accountsActiveDeposit;

  uint80 private _totalPositionsCount = 0;
  uint80 private _activePositionsCount = 0;
  uint256 private _stakedAmount = 0;

  uint256[] private _availableExpiresAfter = [90 days];
  bytes32[] private _availableConditionsHashes = [
    keccak256(abi.encodePacked(_availableExpiresAfter[0]))
  ];
  mapping(bytes32 => Condition) private _conditionsMap;

  uint256 private _minDeposit = 100 ether;
  uint256 private _maxDeposit = 100000 ether;

  constructor(address tokenAddress) {
    _token = IERC20(tokenAddress);
    setConditions(_availableExpiresAfter);
  }

  function _incrementTotalPositionsCount() internal virtual returns (uint80) {
    _totalPositionsCount = _totalPositionsCount + 1;
    return _totalPositionsCount;
  }

  function openPosition(uint128 amount, bytes32 conditionHash)
    public
    whenNotPaused
    returns (bool)
  {
    require(
      _token.balanceOf(msg.sender) >= amount,
      "Not enough tokens to stake"
    );
    require(amount >= _minDeposit, "Amount is less than min deposit");
    require(
      amount + _accountsActiveDeposit[msg.sender] <= _maxDeposit,
      "Amount plus active deposit is greater than max deposit"
    );
    require(amount > 0, "Amount must be greater than 0");
    require(msg.sender != address(0), "Receiver address cannot be 0");
    require(
      _token.allowance(msg.sender, address(this)) >= amount,
      "Not enough allowance to stake"
    );
    require(_conditionsMap[conditionHash].exists, "Condition doesn't exist");

    _activePositionsCount = _activePositionsCount + 1;

    uint80 id = _incrementTotalPositionsCount();

    _token.transferFrom(msg.sender, address(this), amount);
    _accountsActiveDeposit[msg.sender] = _accountsActiveDeposit[msg.sender].add(
      amount
    );
    _stakedAmount = _stakedAmount.add(amount);

    Position memory position = Position(
      msg.sender,
      block.timestamp.toUint48(),
      block
        .timestamp
        .add(_conditionsMap[conditionHash].expiresAfter)
        .toUint48(),
      amount,
      id,
      _accountsPositionsTail[msg.sender],
      0
    );

    if (_accountsPositionsTail[msg.sender] != 0) {
      _positions[_accountsPositionsTail[msg.sender]].nextId = id;
    }

    _positions[id] = position;

    _accountsActivePositionsCount[msg.sender] =
      _accountsActivePositionsCount[msg.sender] +
      1;

    _accountsPositionsTail[msg.sender] = id;

    emit OpenPosition(msg.sender, position);

    return true;
  }

  function closePosition(uint80 id) public {
    require(_positions[id].deposit > 0, "Position does not exist");
    require(_positions[id].account == msg.sender, "Not your position");
    require(
      _positions[id].expiresAt < block.timestamp,
      "Position is not expired"
    );

    uint256 amount = _positions[id].deposit;
    _token.transfer(msg.sender, amount);
    _accountsActiveDeposit[msg.sender] = _accountsActiveDeposit[msg.sender].sub(
      amount
    );
    _stakedAmount = _stakedAmount.sub(amount);

    // # if position is not the first one in the list (has previous position)
    if (_positions[id].previousId != 0) {
      _positions[_positions[id].previousId].nextId = _positions[id].nextId;
    }

    // # if position is not the last one in the list (has next position)
    if (_positions[id].nextId != 0) {
      _positions[_positions[id].nextId].previousId = _positions[id].previousId;
    }

    // # if position is the last one in the list (has no next position)
    if (_accountsPositionsTail[msg.sender] == id) {
      _accountsPositionsTail[msg.sender] = _positions[id].previousId;
    }
    // # save position to emit event
    Position memory position = _positions[id];
    delete _positions[id];
    _accountsActivePositionsCount[msg.sender] =
      _accountsActivePositionsCount[msg.sender] -
      1;

    _activePositionsCount = _activePositionsCount - 1;

    emit ClosePosition(msg.sender, position);
  }

  // # pause unpause
  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  // # get and set max deposit
  function getMaxDeposit() public view virtual returns (uint256) {
    return _maxDeposit;
  }

  function setMaxDeposit(uint256 newMaxDeposit) public onlyOwner {
    require(newMaxDeposit >= 0, "Amount must be greater or equal than 0");

    _maxDeposit = newMaxDeposit;
    emit SetMaxDeposit(newMaxDeposit);
  }

  // # get and set min deposit
  function getMinDeposit() public view virtual returns (uint256) {
    return _minDeposit;
  }

  function setMinDeposit(uint256 newMinDeposit) public onlyOwner {
    require(newMinDeposit >= 0, "Amount must be greater or equal than 0");

    _minDeposit = newMinDeposit;
    emit SetMinDeposit(newMinDeposit);
  }

  function getConditions()
    public
    view
    virtual
    returns (
      uint256[] memory availableExpiresAfter,
      bytes32[] memory availableConditionsHashes
    )
  {
    return (_availableExpiresAfter, _availableConditionsHashes);
  }

  function setConditions(uint256[] memory expiresAfter) public onlyOwner {
    // # reset all values to 0
    for (uint256 i = 0; i < _availableExpiresAfter.length; i++) {
      bytes32 key = keccak256(abi.encodePacked(_availableExpiresAfter[i]));
      delete _conditionsMap[key];
      _availableExpiresAfter[i] = 0;
    }

    bytes32[] memory newAvailableConditionsHashes = new bytes32[](
      expiresAfter.length
    );
    // # set new values
    for (uint256 i = 0; i < expiresAfter.length; i++) {
      bytes32 key = keccak256(abi.encodePacked(expiresAfter[i]));
      _conditionsMap[key] = Condition(expiresAfter[i], true);
      newAvailableConditionsHashes[i] = key;
    }

    _availableExpiresAfter = expiresAfter;
    _availableConditionsHashes = newAvailableConditionsHashes;

    emit SetConditions(expiresAfter, newAvailableConditionsHashes);
  }

  function getAllPositions(address account)
    public
    view
    virtual
    returns (Position[] memory)
  {
    Position[] memory positions = new Position[](
      _accountsActivePositionsCount[account]
    );

    if (_accountsActivePositionsCount[account] == 0) {
      return positions;
    }

    // # we cant assign negative value to uint256 so we need to use this trick
    uint80 activePositionsIndex = _accountsActivePositionsCount[account];
    uint80 prevId = 0;
    for (uint256 i = _accountsActivePositionsCount[account]; i > 0; i--) {
      if (i == _accountsActivePositionsCount[account]) {
        positions[activePositionsIndex - 1] = _positions[
          _accountsPositionsTail[account]
        ];

        prevId = positions[activePositionsIndex - 1].previousId;

        activePositionsIndex--;
      } else {
        positions[activePositionsIndex - 1] = _positions[prevId];
        prevId = positions[activePositionsIndex - 1].previousId;
        activePositionsIndex--;
      }
    }

    return positions;
  }

  function getLastPosition(address account)
    public
    view
    virtual
    returns (Position memory)
  {
    return _positions[_accountsPositionsTail[account]];
  }

  function getLastPositionId(address account)
    public
    view
    virtual
    returns (uint80 id)
  {
    return _accountsPositionsTail[account];
  }

  function getPosition(uint80 id)
    public
    view
    virtual
    returns (Position memory)
  {
    return _positions[id];
  }

  function getTotalPositionsCount() public view virtual returns (uint256) {
    return _totalPositionsCount;
  }

  function getActivePositionsCount() public view virtual returns (uint256) {
    return _activePositionsCount;
  }

  function getAccountsActivePositionsCount(address account)
    public
    view
    virtual
    returns (uint256)
  {
    return _accountsActivePositionsCount[account];
  }

  function withdraw(address tokenAddress, address withdrawalAddress)
    public
    onlyOwner
  {
    IERC20 token = IERC20(tokenAddress);
    // # if token is not the same as staked token
    if (tokenAddress != address(_token)) {
      token.transfer(withdrawalAddress, token.balanceOf(address(this)));
    } else {
      token.transfer(
        withdrawalAddress,
        token.balanceOf(address(this)) - _stakedAmount
      );
    }

    emit Withdraw(tokenAddress, withdrawalAddress);
  }

  function balanceOf(address account) public view virtual returns (uint256) {
    return _accountsActiveDeposit[account];
  }
}