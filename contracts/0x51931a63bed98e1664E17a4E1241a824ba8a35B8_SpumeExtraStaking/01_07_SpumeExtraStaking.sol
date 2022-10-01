// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract SpumeExtraStaking is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  address private _spumeToken;
  uint256 private _withdrawTime;
  uint256 private _totalStake;
  bool private _canStake;
  mapping(address => uint256) private _balances;

  event Stake(address indexed user, uint256 indexed amount);
  event UnStake(address indexed user, uint256 indexed amount, uint256 indexed totalAmount);

  constructor(address spumeToken, uint256 withdrawTime) {
    _spumeToken = spumeToken;
    _withdrawTime = withdrawTime;
    _canStake = true;
  }

  function stake(uint256 amount) external nonReentrant {
    require(_canStake, "Staking has been closed");
    IERC20(_spumeToken).safeTransferFrom(msg.sender, address(this), amount);
    _balances[msg.sender] += amount;
    _totalStake += amount;
    emit Stake(msg.sender, amount);
  }

  function unStake() external nonReentrant {
    require(block.timestamp >= _withdrawTime, "Cannot withdraw yet");
    uint256 amount = _balances[msg.sender];
    require(amount > 0, "Must withdraw more than zero");
    _balances[msg.sender] -= amount;
    _totalStake -= amount;
    uint256 toSend = (amount * 15) / 10;
    IERC20(_spumeToken).safeTransfer(msg.sender, toSend);
    emit UnStake(msg.sender, amount, toSend);
  }

  function withdrawSpume(uint256 amount) external onlyOwner {
    IERC20(_spumeToken).safeTransfer(msg.sender, amount);
  }

  function setWithdrawTime(uint256 withdrawTime) external onlyOwner {
    _withdrawTime = withdrawTime;
  }

  function setCanStake(bool canStake) external onlyOwner {
    _canStake = canStake;
  }

  function getWithdrawTime() external view returns(uint256) {
    return _withdrawTime;
  }

  function getCanStake() external view returns(bool) {
    return _canStake;
  }

  function getTotalStake() external view returns(uint256) {
    return _totalStake;
  }

  function getSpumeToken() external view returns(address) {
    return _spumeToken;
  }

  function getBalance(address staker) external view returns(uint256) {
    return _balances[staker];
  }
}