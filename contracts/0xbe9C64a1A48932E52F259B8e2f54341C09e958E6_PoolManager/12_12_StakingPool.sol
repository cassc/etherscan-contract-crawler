// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './interfaces/IPoolExtension.sol';

contract StakingPool is Context, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  IUniswapV2Router02 immutable _router;
  uint256 constant MULTIPLIER = 10 ** 36;
  address public token;
  uint256 public lockupPeriod;
  uint256 public totalStakedUsers;
  uint256 public totalSharesDeposited;

  IPoolExtension public extension;

  struct Share {
    uint256 amount;
    uint256 stakedTime;
  }
  struct Reward {
    uint256 excluded;
    uint256 realised;
  }
  mapping(address => Share) public shares;
  mapping(address => Reward) public rewards;

  uint256 public rewardsPerShare;
  uint256 public totalDistributed;
  uint256 public totalRewards;

  event Stake(address indexed user, uint256 amount);
  event Unstake(address indexed user, uint256 amount);
  event ClaimReward(address user);
  event DepositRewards(address indexed user, uint256 amountTokens);
  event DistributeReward(
    address indexed user,
    uint256 amount,
    bool _wasCompounded
  );

  constructor(address _token, uint256 _lockupPeriod, address __router) {
    token = _token;
    lockupPeriod = _lockupPeriod;
    _router = IUniswapV2Router02(__router);
  }

  function stake(uint256 _amount) external nonReentrant {
    IERC20(token).safeTransferFrom(_msgSender(), address(this), _amount);
    _setShare(_msgSender(), _amount, false);
  }

  function stakeForWallets(
    address[] memory _wallets,
    uint256[] memory _amounts
  ) external nonReentrant {
    require(_wallets.length == _amounts.length, 'INSYNC');
    uint256 _totalAmount;
    for (uint256 _i; _i < _wallets.length; _i++) {
      _totalAmount += _amounts[_i];
      _setShare(_wallets[_i], _amounts[_i], false);
    }
    IERC20(token).safeTransferFrom(_msgSender(), address(this), _totalAmount);
  }

  function unstake(uint256 _amount) external nonReentrant {
    IERC20(token).safeTransfer(_msgSender(), _amount);
    _setShare(_msgSender(), _amount, true);
  }

  function _setShare(
    address wallet,
    uint256 balanceUpdate,
    bool isRemoving
  ) internal {
    if (address(extension) != address(0)) {
      try extension.setShare(wallet, balanceUpdate, isRemoving) {} catch {}
    }
    if (isRemoving) {
      _removeShares(wallet, balanceUpdate);
      emit Unstake(wallet, balanceUpdate);
    } else {
      _addShares(wallet, balanceUpdate);
      emit Stake(wallet, balanceUpdate);
    }
  }

  function _addShares(address wallet, uint256 amount) private {
    if (shares[wallet].amount > 0) {
      _distributeReward(wallet, false, 0);
    }
    uint256 sharesBefore = shares[wallet].amount;
    totalSharesDeposited += amount;
    shares[wallet].amount += amount;
    shares[wallet].stakedTime = block.timestamp;
    if (sharesBefore == 0 && shares[wallet].amount > 0) {
      totalStakedUsers++;
    }
    rewards[wallet].excluded = _cumulativeRewards(shares[wallet].amount);
  }

  function _removeShares(address wallet, uint256 amount) private {
    require(
      shares[wallet].amount > 0 && amount <= shares[wallet].amount,
      'REM: amount'
    );
    require(
      block.timestamp > shares[wallet].stakedTime + lockupPeriod,
      'REM: timelock'
    );
    uint256 _unclaimed = getUnpaid(wallet);
    bool _otherStakersPresent = totalSharesDeposited - amount > 0;
    if (!_otherStakersPresent) {
      _distributeReward(wallet, false, 0);
    }
    totalSharesDeposited -= amount;
    shares[wallet].amount -= amount;
    if (shares[wallet].amount == 0) {
      totalStakedUsers--;
    }
    rewards[wallet].excluded = _cumulativeRewards(shares[wallet].amount);
    // if there are other stakers and unclaimed rewards,
    // deposit them back into the pool for other stakers to claim
    if (_otherStakersPresent && _unclaimed > 0) {
      _depositRewards(wallet, _unclaimed);
    }
  }

  function depositRewards() external payable {
    _depositRewards(_msgSender(), msg.value);
  }

  function _depositRewards(address _wallet, uint256 _amountETH) internal {
    require(_amountETH > 0, 'ETH');
    require(totalSharesDeposited > 0, 'SHARES');
    totalRewards += _amountETH;
    rewardsPerShare += (MULTIPLIER * _amountETH) / totalSharesDeposited;
    emit DepositRewards(_wallet, _amountETH);
  }

  function _distributeReward(
    address _wallet,
    bool _compound,
    uint256 _compoundMinTokensToReceive
  ) internal {
    if (shares[_wallet].amount == 0) {
      return;
    }
    shares[_wallet].stakedTime = block.timestamp; // reset every claim
    uint256 _amountWei = getUnpaid(_wallet);
    rewards[_wallet].realised += _amountWei;
    rewards[_wallet].excluded = _cumulativeRewards(shares[_wallet].amount);
    if (_amountWei > 0) {
      totalDistributed += _amountWei;
      if (_compound) {
        _compoundRewards(_wallet, _amountWei, _compoundMinTokensToReceive);
      } else {
        uint256 _balBefore = address(this).balance;
        (bool success, ) = payable(_wallet).call{ value: _amountWei }('');
        require(success, 'DIST0');
        require(address(this).balance >= _balBefore - _amountWei, 'DIST1');
      }
      emit DistributeReward(_wallet, _amountWei, _compound);
    }
  }

  function _compoundRewards(
    address _wallet,
    uint256 _wei,
    uint256 _minTokensToReceive
  ) internal {
    address[] memory path = new address[](2);
    path[0] = _router.WETH();
    path[1] = token;

    IERC20 _token = IERC20(token);
    uint256 _tokenBalBefore = _token.balanceOf(address(this));
    _router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: _wei }(
      _minTokensToReceive,
      path,
      address(this),
      block.timestamp
    );
    uint256 _compoundAmount = _token.balanceOf(address(this)) - _tokenBalBefore;
    _setShare(_wallet, _compoundAmount, false);
  }

  function claimReward(
    bool _compound,
    uint256 _compMinTokensToReceive
  ) external nonReentrant {
    _distributeReward(_msgSender(), _compound, _compMinTokensToReceive);
    emit ClaimReward(_msgSender());
  }

  function claimRewardAdmin(
    address _wallet,
    bool _compound,
    uint256 _compMinTokensToReceive
  ) external nonReentrant onlyOwner {
    _distributeReward(_wallet, _compound, _compMinTokensToReceive);
    emit ClaimReward(_wallet);
  }

  function getUnpaid(address wallet) public view returns (uint256) {
    if (shares[wallet].amount == 0) {
      return 0;
    }
    uint256 earnedRewards = _cumulativeRewards(shares[wallet].amount);
    uint256 rewardsExcluded = rewards[wallet].excluded;
    if (earnedRewards <= rewardsExcluded) {
      return 0;
    }
    return earnedRewards - rewardsExcluded;
  }

  function _cumulativeRewards(uint256 share) internal view returns (uint256) {
    return (share * rewardsPerShare) / MULTIPLIER;
  }

  function setPoolExtension(IPoolExtension _extension) external onlyOwner {
    extension = _extension;
  }

  function setLockupPeriod(uint256 _seconds) external onlyOwner {
    require(_seconds < 365 days, 'lte 1 year');
    lockupPeriod = _seconds;
  }

  function withdrawTokens(uint256 _amount) external onlyOwner {
    IERC20 _token = IERC20(token);
    _token.safeTransfer(
      _msgSender(),
      _amount == 0 ? _token.balanceOf(address(this)) : _amount
    );
  }
}