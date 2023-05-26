// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IRewardManager.sol";

abstract contract BaseFeeder is Ownable {
  /// @dev Time-related constants
  uint256 public constant WEEK = 7 days;

  address public token;
  address public rewardSource;

  IRewardManager public rewardManager;
  uint40 public lastRewardBlock;
  uint40 public rewardEndBlock;

  uint256 public rewardRatePerBlock;

  mapping(address => bool) public whitelistedFeedCallers;

  event Feed(uint256 feedAmount);
  event SetCanDistributeRewards(bool canDistributeRewards);
  event SetNewRewardEndBlock(address indexed caller, uint256 preRewardEndBlock, uint256 newRewardEndBlock);
  event SetNewRewardRatePerBlock(address indexed caller, uint256 prevRate, uint256 newRate);
  event SetNewRewardSource(address indexed caller, address prevSource, address newSource);
  event SetNewRewardManager(address indexed caller, address prevManager, address newManager);
  event SetWhitelistedFeedCaller(address indexed caller, address indexed addr, bool ok);

  constructor(
    address _rewardManager,
    address _rewardSource,
    uint256 _rewardRatePerBlock,
    uint40 _lastRewardBlock,
    uint40 _rewardEndBlock
  ) {
    rewardManager = IRewardManager(_rewardManager);
    token = rewardManager.rewardToken();
    rewardSource = _rewardSource;
    lastRewardBlock = _lastRewardBlock;
    rewardEndBlock = _rewardEndBlock;
    rewardRatePerBlock = _rewardRatePerBlock;
    
    require(_lastRewardBlock < _rewardEndBlock, "bad _lastRewardBlock");
  }

  function feed() external {
    require(whitelistedFeedCallers[msg.sender],"!whitelisted");
    _feed();
  }

  function _feed() virtual internal;

  function setRewardRatePerBlock(uint256 _newRate) virtual external onlyOwner   {
    _feed();
    uint256 _prevRate = rewardRatePerBlock;
    rewardRatePerBlock = _newRate;
    emit SetNewRewardRatePerBlock(msg.sender, _prevRate, _newRate);
  }

  function setRewardEndBlock(uint40 _newRewardEndBlock) external onlyOwner {
    uint40 _prevRewardEndBlock = rewardEndBlock;
    require(_newRewardEndBlock > rewardEndBlock, "!future");
    rewardEndBlock = _newRewardEndBlock;
    emit SetNewRewardEndBlock(msg.sender, _prevRewardEndBlock, _newRewardEndBlock);
  }


  function setRewardSource(address _rewardSource) external onlyOwner {
    address _prevSource = rewardSource;
    rewardSource = _rewardSource;
    emit SetNewRewardSource(msg.sender, _prevSource , _rewardSource);
  }

  function setRewardManager(address _newManager) external onlyOwner {
    address _prevManager = address(rewardManager);
    rewardManager = IRewardManager(_newManager);
    emit SetNewRewardManager(msg.sender, _prevManager, _newManager);
  }

  function setWhitelistedFeedCallers(address[] calldata callers, bool ok) external onlyOwner {
    for (uint256 idx = 0; idx < callers.length; idx++) {
      whitelistedFeedCallers[callers[idx]] = ok;
      emit SetWhitelistedFeedCaller(msg.sender, callers[idx], ok);
    }
  }
}