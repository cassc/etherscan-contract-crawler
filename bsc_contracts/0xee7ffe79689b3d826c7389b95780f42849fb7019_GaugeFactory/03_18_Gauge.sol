// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./04_18_IGauge.sol";
import "./05_18_IPair.sol";
import "./06_18_IVoter.sol";
import "./07_18_IBribe.sol";
import "./08_18_IERC721.sol";
import "./09_18_IVe.sol";
import "./10_18_MultiRewardsPoolBase.sol";

/// @title Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
contract Gauge is IGauge, MultiRewardsPoolBase {
  using SafeERC20 for IERC20;

  /// @dev The ve token used for gauges
  address public immutable ve;
  address public immutable bribe;
  address public immutable voter;

  mapping(address => uint) public tokenIds;

  uint public fees0;
  uint public fees1;

  event ClaimFees(address indexed from, uint claimed0, uint claimed1);
  event VeTokenLocked(address indexed account, uint tokenId);
  event VeTokenUnlocked(address indexed account, uint tokenId);

  constructor(
    address _stake,
    address _bribe,
    address _ve,
    address _voter,
    address[] memory _allowedRewardTokens
  ) MultiRewardsPoolBase(
    _stake,
    _voter,
    _allowedRewardTokens
  ) {
    bribe = _bribe;
    ve = _ve;
    voter = _voter;
  }

  function claimFees() external lock override returns (uint claimed0, uint claimed1) {
    return _claimFees();
  }

  function _claimFees() internal returns (uint claimed0, uint claimed1) {
    address _underlying = underlying;
    (claimed0, claimed1) = IPair(_underlying).claimFees();
    if (claimed0 > 0 || claimed1 > 0) {
      uint _fees0 = fees0 + claimed0;
      uint _fees1 = fees1 + claimed1;
      (address _token0, address _token1) = IPair(_underlying).tokens();
      if (_fees0 > IMultiRewardsPool(bribe).left(_token0)) {
        fees0 = 0;
        IERC20(_token0).safeIncreaseAllowance(bribe, _fees0);
        IBribe(bribe).notifyRewardAmount(_token0, _fees0);
      } else {
        fees0 = _fees0;
      }
      if (_fees1 > IMultiRewardsPool(bribe).left(_token1)) {
        fees1 = 0;
        IERC20(_token1).safeIncreaseAllowance(bribe, _fees1);
        IBribe(bribe).notifyRewardAmount(_token1, _fees1);
      } else {
        fees1 = _fees1;
      }

      emit ClaimFees(msg.sender, claimed0, claimed1);
    }
  }

  function getReward(address account, address[] memory tokens) external override {
    require(msg.sender == account || msg.sender == voter, "Forbidden");
    IVoter(voter).distribute(address(this));
    _getReward(account, tokens, account);
  }

  function depositAll(uint tokenId) external {
    deposit(IERC20(underlying).balanceOf(msg.sender), tokenId);
  }

  function deposit(uint amount, uint tokenId) public {
    if (tokenId > 0) {
      _lockVeToken(msg.sender, tokenId);
    }
    _deposit(amount);
    IVoter(voter).emitDeposit(tokenId, msg.sender, amount);
  }

  function withdrawAll() external {
    withdraw(balanceOf[msg.sender]);
  }

  function withdraw(uint amount) public {
    uint tokenId = 0;
    if (amount == balanceOf[msg.sender]) {
      tokenId = tokenIds[msg.sender];
    }
    withdrawToken(amount, tokenId);
    IVoter(voter).emitWithdraw(tokenId, msg.sender, amount);
  }

  function withdrawToken(uint amount, uint tokenId) public {
    if (tokenId > 0) {
      _unlockVeToken(msg.sender, tokenId);
    }
    _withdraw(amount);
  }

  /// @dev Balance should be recalculated after the lock
  ///      For locking a new ve token withdraw all funds and deposit again
  function _lockVeToken(address account, uint tokenId) internal {
    require(IERC721(ve).ownerOf(tokenId) == account, "Not ve token owner");
    if (tokenIds[account] == 0) {
      tokenIds[account] = tokenId;
      IVoter(voter).attachTokenToGauge(tokenId, account);
    }
    require(tokenIds[account] == tokenId, "Wrong token");
    emit VeTokenLocked(account, tokenId);
  }

  /// @dev Balance should be recalculated after the unlock
  function _unlockVeToken(address account, uint tokenId) internal {
    require(tokenId == tokenIds[account], "Wrong token");
    tokenIds[account] = 0;
    IVoter(voter).detachTokenFromGauge(tokenId, account);
    emit VeTokenUnlocked(account, tokenId);
  }

  /// @dev Similar to Curve https://resources.curve.fi/reward-gauges/boosting-your-crv-rewards#formula
  function _derivedBalance(address account) internal override view returns (uint) {
    uint _tokenId = tokenIds[account];
    uint _balance = balanceOf[account];
    uint _derived = _balance * 40 / 100;
    uint _adjusted = 0;
    uint _supply = IERC20(ve).totalSupply();
    if (account == IERC721(ve).ownerOf(_tokenId) && _supply > 0) {
      _adjusted = (totalSupply * IVe(ve).balanceOfNFT(_tokenId) / _supply) * 60 / 100;
    }
    return Math.min((_derived + _adjusted), _balance);
  }

  function notifyRewardAmount(address token, uint amount) external {
    // claim rewards should not ruin distribution process
    try Gauge(address(this)).claimFees() {} catch {}
    _notifyRewardAmount(token, amount);
  }

}