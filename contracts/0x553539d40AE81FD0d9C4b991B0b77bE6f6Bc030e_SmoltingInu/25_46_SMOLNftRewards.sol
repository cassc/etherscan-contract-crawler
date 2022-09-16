// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './interfaces/ISMOLNftRewards.sol';
import './interfaces/ISmoltingInu.sol';

contract SMOLNftRewards is ISMOLNftRewards, Ownable {
  struct Reward {
    uint256 totalExcluded; // excluded reward
    uint256 totalRealised;
    uint256 lastClaim; // used for boosting logic
  }

  struct Share {
    uint256 amount;
    uint256 stakedTime;
  }

  IERC721 shareholderNFT;
  ISmoltingInu smol = ISmoltingInu(0x553539d40AE81FD0d9C4b991B0b77bE6f6Bc030e);
  uint256 public totalStakedUsers;
  uint256 public totalSharesDeposited; // will only be actual deposited tokens without handling any reflections or otherwise

  // amount of shares a user has
  mapping(address => Share) shares;
  // reward information per user
  mapping(address => Reward) public rewards;

  uint256 public totalRewards;
  uint256 public totalDistributed;
  uint256 public rewardsPerShare;

  uint256 private constant ACC_FACTOR = 10**36;

  event ClaimReward(address user);
  event DistributeReward(address indexed user);
  event DepositRewards(address indexed user, uint256 amountTokens);

  modifier onlyToken() {
    require(msg.sender == address(shareholderNFT), 'must be token contract');
    _;
  }

  constructor(address _shareholderNFT) {
    shareholderNFT = IERC721(_shareholderNFT);
  }

  function setShare(address shareholder, uint256 newBalance)
    external
    onlyToken
  {
    // _addShares and _removeShares takes the amount to add or remove respectively,
    // so we should handle the diff from the new balance when passing in the amounts
    // to these functions
    if (shares[shareholder].amount > newBalance) {
      _removeShares(shareholder, shares[shareholder].amount - newBalance);
    } else if (shares[shareholder].amount < newBalance) {
      _addShares(shareholder, newBalance - shares[shareholder].amount);
    }
  }

  function _addShares(address shareholder, uint256 amount) private {
    if (shares[shareholder].amount > 0) {
      _distributeReward(shareholder);
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
    _distributeReward(shareholder);

    uint256 removeAmount = amount == 0 ? shares[shareholder].amount : amount;

    totalSharesDeposited -= removeAmount;
    shares[shareholder].amount -= removeAmount;
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );
  }

  function depositRewards(uint256 _amount) external override onlyOwner {
    require(
      totalSharesDeposited > 0,
      'must be shares deposited to be rewarded rewards'
    );

    totalRewards += _amount;
    rewardsPerShare += (ACC_FACTOR * _amount) / totalSharesDeposited;
    smol.gameMint(address(this), _amount);
    emit DepositRewards(msg.sender, _amount);
  }

  function _distributeReward(address shareholder) internal {
    if (shares[shareholder].amount == 0) {
      return;
    }

    uint256 amount = getUnpaid(shareholder);

    rewards[shareholder].totalRealised += amount;
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );
    rewards[shareholder].lastClaim = block.timestamp;

    if (amount > 0) {
      totalDistributed += amount;
      smol.transfer(shareholder, amount);
      emit DistributeReward(shareholder);
    }
  }

  function claimReward() external override {
    _distributeReward(msg.sender);
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

  function getShareholderNFT() external view returns (address) {
    return address(shareholderNFT);
  }

  function getSmolToken() external view returns (address) {
    return address(smol);
  }

  function setShareholderNFT(address _nft) external onlyOwner {
    shareholderNFT = IERC721(_nft);
  }

  function setSmolToken(address _token) external onlyOwner {
    smol = ISmoltingInu(_token);
  }
}