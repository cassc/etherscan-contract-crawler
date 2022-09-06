/******************************************************************************************************
Yieldification Staking Rewards

Website: https://yieldification.com
Twitter: https://twitter.com/yieldification
Telegram: https://t.me/yieldification
******************************************************************************************************/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './interfaces/IStakeRewards.sol';

contract StakeRewards is IStakeRewards, Ownable {
  address public ydf;
  IERC721 private sYDF;
  IERC721 private slYDF;
  IUniswapV2Router02 private uniswapV2Router;

  uint256 public compoundBuySlippage = 2;

  uint256 public totalStakedUsers;
  uint256 public totalSharesDeposited;

  struct Share {
    uint256 amount;
    uint256 stakedTime;
  }
  struct Reward {
    uint256 totalExcluded;
    uint256 totalRealised;
  }
  mapping(address => Share) private shares;
  mapping(address => Reward) public rewards;

  uint256 public totalRewards;
  uint256 public totalDistributed;
  uint256 public rewardsPerShare;

  uint256 private constant ACC_FACTOR = 10**36;

  event AddShares(address indexed user, uint256 amount);
  event RemoveShares(address indexed user, uint256 amount);
  event ClaimReward(address user);
  event DistributeReward(address indexed user, uint256 amount);
  event DepositRewards(address indexed user, uint256 amountTokens);

  modifier onlyToken() {
    require(
      msg.sender == address(sYDF) || msg.sender == address(slYDF),
      'must be stake token'
    );
    _;
  }

  constructor(address _ydf, address _dexRouter) {
    ydf = _ydf;
    uniswapV2Router = IUniswapV2Router02(_dexRouter);
  }

  function setShare(
    address shareholder,
    uint256 balanceUpdate,
    bool isRemoving
  ) external override onlyToken {
    if (isRemoving) {
      _removeShares(shareholder, balanceUpdate);
      emit RemoveShares(shareholder, balanceUpdate);
    } else {
      _addShares(shareholder, balanceUpdate);
      emit AddShares(shareholder, balanceUpdate);
    }
  }

  function _addShares(address shareholder, uint256 amount) private {
    if (shares[shareholder].amount > 0) {
      _distributeReward(shareholder, false);
    }

    uint256 sharesBefore = shares[shareholder].amount;

    totalSharesDeposited += amount;
    shares[shareholder].amount += amount;
    shares[shareholder].stakedTime = block.timestamp;
    if (sharesBefore == 0 && shares[shareholder].amount > 0) {
      totalStakedUsers++;
    }
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );
  }

  function _removeShares(address shareholder, uint256 amount) private {
    require(
      shares[shareholder].amount > 0 &&
        (amount == 0 || amount <= shares[shareholder].amount),
      'you can only unstake if you have some staked'
    );
    _distributeReward(shareholder, false);

    uint256 removeAmount = amount == 0 ? shares[shareholder].amount : amount;

    totalSharesDeposited -= removeAmount;
    shares[shareholder].amount -= removeAmount;
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );
  }

  function depositRewards() external payable override {
    uint256 _amount = msg.value;
    require(_amount > 0, 'must provide ETH to deposit for rewards');
    require(totalSharesDeposited > 0, 'must be shares to distribute rewards');

    totalRewards += _amount;
    rewardsPerShare += (ACC_FACTOR * _amount) / totalSharesDeposited;
    emit DepositRewards(msg.sender, _amount);
  }

  function _distributeReward(address shareholder, bool compound) internal {
    if (shares[shareholder].amount == 0) {
      return;
    }

    uint256 amount = getUnpaid(shareholder);
    rewards[shareholder].totalRealised += amount;
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );

    if (amount > 0) {
      totalDistributed += amount;
      uint256 _balBefore = address(this).balance;
      if (compound) {
        uint256 _tokensToReceiveNoSlip = _getTokensToReceiveOnBuyNoSlippage(
          amount
        );
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = ydf;
        uniswapV2Router.swapExactETHForTokens{ value: amount }(
          (_tokensToReceiveNoSlip * (100 - compoundBuySlippage)) / 100, // handle slippage
          path,
          shareholder,
          block.timestamp
        );
      } else {
        payable(shareholder).call{ value: amount }('');
      }
      require(address(this).balance >= _balBefore - amount, 'took too much');
      emit DistributeReward(shareholder, amount);
    }
  }

  function _getTokensToReceiveOnBuyNoSlippage(uint256 _amountETH)
    internal
    view
    returns (uint256)
  {
    address pairAddy = IUniswapV2Factory(uniswapV2Router.factory()).getPair(
      uniswapV2Router.WETH(),
      ydf
    );
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddy);
    (uint112 _r0, uint112 _r1, ) = pair.getReserves();
    if (pair.token0() == uniswapV2Router.WETH()) {
      return (_amountETH * _r1) / _r0;
    } else {
      return (_amountETH * _r0) / _r1;
    }
  }

  function claimReward(bool _compound) external override {
    _distributeReward(msg.sender, _compound);
    emit ClaimReward(msg.sender);
  }

  // returns the unpaid rewards
  function getUnpaid(address shareholder) public view returns (uint256) {
    if (shares[shareholder].amount == 0) {
      return 0;
    }

    uint256 earnedRewards = getCumulativeRewards(shares[shareholder].amount);
    uint256 rewardsExcluded = rewards[shareholder].totalExcluded;
    if (earnedRewards <= rewardsExcluded) {
      return 0;
    }

    return earnedRewards - rewardsExcluded;
  }

  function getCumulativeRewards(uint256 share) internal view returns (uint256) {
    return (share * rewardsPerShare) / ACC_FACTOR;
  }

  function getShares(address user) external view override returns (uint256) {
    return shares[user].amount;
  }

  function getsYDF() external view returns (address) {
    return address(sYDF);
  }

  function getslYDF() external view returns (address) {
    return address(slYDF);
  }

  function setCompoundBuySlippage(uint8 _slippage) external onlyOwner {
    require(_slippage <= 100, 'cannot be more than 100% slippage');
    compoundBuySlippage = _slippage;
  }

  function setsYDF(address _sYDF) external onlyOwner {
    sYDF = IERC721(_sYDF);
  }

  function setslYDF(address _slYDF) external onlyOwner {
    slYDF = IERC721(_slYDF);
  }
}