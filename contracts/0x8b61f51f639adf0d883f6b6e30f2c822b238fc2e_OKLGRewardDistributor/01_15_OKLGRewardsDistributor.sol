// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './interfaces/IConditional.sol';
import './interfaces/IMultiplier.sol';
import './interfaces/IOKLGRewardDistributor.sol';
import './OKLGWithdrawable.sol';

contract OKLGRewardDistributor is IOKLGRewardDistributor, OKLGWithdrawable {
  using SafeMath for uint256;

  struct Reward {
    uint256 totalExcluded; // excluded reward
    uint256 totalRealised;
    uint256 lastClaim; // used for boosting logic
  }

  struct Share {
    uint256 amount;
    uint256 amountBase;
    uint256 stakedTime;
    uint256[] nftBoostTokenIds;
  }

  uint256 public minSecondsBeforeUnstake = 43200;
  address public shareholderToken;
  address public nftBoosterToken;
  uint256 public totalStakedUsers;
  uint256 public totalSharesBoosted;
  uint256 public totalSharesDeposited; // will only be actual deposited tokens without handling any reflections or otherwise
  address wrappedNative;
  IUniswapV2Router02 router;

  // amount of shares a user has
  mapping(address => Share) shares;
  // reward information per user
  mapping(address => Reward) public rewards;

  address public boostContract;
  address public boostMultiplierContract;

  uint256 public totalRewards;
  uint256 public totalDistributed; // to be shown in UI
  uint256 public rewardsPerShare;

  uint256 public constant ACC_FACTOR = 10**36;
  address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

  constructor(
    address _dexRouter,
    address _shareholderToken,
    address _nftBoosterToken,
    address _wrappedNative
  ) {
    router = IUniswapV2Router02(_dexRouter);
    shareholderToken = _shareholderToken;
    nftBoosterToken = _nftBoosterToken;
    wrappedNative = _wrappedNative;
  }

  function stake(uint256 amount, uint256[] memory nftTokenIds) external {
    _stake(msg.sender, amount, nftTokenIds, false);
  }

  function _stake(
    address shareholder,
    uint256 amount,
    uint256[] memory nftTokenIds,
    bool overrideTransfers
  ) private {
    if (shares[shareholder].amount > 0 && !overrideTransfers) {
      distributeReward(shareholder, false);
    }

    IERC20 shareContract = IERC20(shareholderToken);
    uint256 stakeAmount = amount == 0
      ? shareContract.balanceOf(shareholder)
      : amount;
    uint256 sharesBefore = shares[shareholder].amount;

    // for compounding we will pass in this contract override flag and assume the tokens
    // received by the contract during the compounding process are already here, therefore
    // whatever the amount is passed in is what we care about and leave it at that. If a normal
    // staking though by a user, transfer tokens from the user to the contract.
    uint256 finalBaseAmount = stakeAmount;
    if (!overrideTransfers) {
      uint256 shareBalanceBefore = shareContract.balanceOf(address(this));
      shareContract.transferFrom(shareholder, address(this), stakeAmount);
      finalBaseAmount = shareContract.balanceOf(address(this)).sub(
        shareBalanceBefore
      );

      IERC721 nftContract = IERC721(nftBoosterToken);
      for (uint256 i = 0; i < nftTokenIds.length; i++) {
        nftContract.transferFrom(shareholder, address(this), nftTokenIds[i]);
        shares[shareholder].nftBoostTokenIds.push(nftTokenIds[i]);
      }
    }

    // NOTE: temporarily setting shares[shareholder].amount to base deposited to get elevated shares.
    // They depend on shares[shareholder].amount being populated, but we're simply reversing this
    // after calculating boosted amount
    uint256 currentAmountWithBoost = shares[shareholder].amount;
    shares[shareholder].amount = shares[shareholder].amountBase.add(
      finalBaseAmount
    );

    // this is the final amount AFTER adding the new base amount, not just the additional
    uint256 finalBoostedAmount = getElevatedSharesWithBooster(
      shareholder,
      shares[shareholder].amount
    );

    shares[shareholder].amount = currentAmountWithBoost;

    totalSharesDeposited = totalSharesDeposited.add(finalBaseAmount);
    totalSharesBoosted = totalSharesBoosted.sub(shares[shareholder].amount).add(
        finalBoostedAmount
      );
    shares[shareholder].amountBase += finalBaseAmount;
    shares[shareholder].amount = finalBoostedAmount;
    shares[shareholder].stakedTime = block.timestamp;
    if (sharesBefore == 0 && shares[shareholder].amount > 0) {
      totalStakedUsers++;
    }
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );
  }

  function unstake(uint256 boostedAmount, bool relinquishRewards) external {
    require(
      shares[msg.sender].amount > 0 &&
        (boostedAmount == 0 || boostedAmount <= shares[msg.sender].amount),
      'you can only unstake if you have some staked'
    );
    require(
      block.timestamp > shares[msg.sender].stakedTime + minSecondsBeforeUnstake,
      'must be staked for minimum time and at least one block if no min'
    );
    if (!relinquishRewards) {
      distributeReward(msg.sender, false);
    }

    IERC20 shareContract = IERC20(shareholderToken);
    uint256 boostedAmountToUnstake = boostedAmount == 0
      ? shares[msg.sender].amount
      : boostedAmount;

    // NOTE: temporarily setting shares[shareholder].amount to base deposited to get elevated shares.
    // They depend on shares[shareholder].amount being populated, but we're simply reversing this
    // after calculating boosted amount
    uint256 currentAmountWithBoost = shares[msg.sender].amount;
    shares[msg.sender].amount = shares[msg.sender].amountBase;
    uint256 baseAmount = getBaseSharesFromBoosted(
      msg.sender,
      boostedAmountToUnstake
    );
    shares[msg.sender].amount = currentAmountWithBoost;

    // handle reflections tokens
    uint256 finalWithdrawAmount = getAppreciatedShares(baseAmount);

    if (boostedAmount == 0) {
      uint256[] memory tokenIds = shares[msg.sender].nftBoostTokenIds;
      IERC721 nftContract = IERC721(nftBoosterToken);
      for (uint256 i = 0; i < tokenIds.length; i++) {
        nftContract.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
      }
      totalStakedUsers--;
      delete shares[msg.sender].nftBoostTokenIds;
    }

    shareContract.transfer(msg.sender, finalWithdrawAmount);

    totalSharesDeposited = totalSharesDeposited.sub(baseAmount);
    totalSharesBoosted = totalSharesBoosted.sub(boostedAmountToUnstake);
    shares[msg.sender].amountBase -= baseAmount;
    shares[msg.sender].amount -= boostedAmountToUnstake;
    rewards[msg.sender].totalExcluded = getCumulativeRewards(
      shares[msg.sender].amount
    );
  }

  function depositRewards() external payable override {
    require(msg.value > 0, 'value must be greater than 0');
    require(
      totalSharesBoosted > 0,
      'must be shares deposited to be rewarded rewards'
    );

    uint256 amount = msg.value;

    totalRewards = totalRewards.add(amount);
    rewardsPerShare = rewardsPerShare.add(
      ACC_FACTOR.mul(amount).div(totalSharesBoosted)
    );
  }

  function distributeReward(address shareholder, bool compound) internal {
    require(
      block.timestamp > rewards[shareholder].lastClaim,
      'can only claim once per block'
    );
    if (shares[shareholder].amount == 0) {
      return;
    }

    uint256 amount = getUnpaid(shareholder);

    rewards[shareholder].totalRealised = rewards[shareholder].totalRealised.add(
      amount
    );
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );
    rewards[shareholder].lastClaim = block.timestamp;

    if (amount > 0) {
      totalDistributed = totalDistributed.add(amount);
      uint256 balanceBefore = address(this).balance;
      if (compound) {
        IERC20 shareToken = IERC20(shareholderToken);
        uint256 balBefore = shareToken.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = wrappedNative;
        path[1] = shareholderToken;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
          value: amount
        }(0, path, address(this), block.timestamp);
        uint256 amountReceived = shareToken.balanceOf(address(this)).sub(
          balBefore
        );
        if (amountReceived > 0) {
          uint256[] memory _empty = new uint256[](0);
          _stake(shareholder, amountReceived, _empty, true);
        }
      } else {
        (bool sent, ) = payable(shareholder).call{ value: amount }('');
        require(sent, 'ETH was not successfully sent');
      }
      require(
        address(this).balance >= balanceBefore - amount,
        'only take proper amount from contract'
      );
    }
  }

  function claimReward(bool compound) external {
    distributeReward(msg.sender, compound);
  }

  function getAppreciatedShares(uint256 amount) public view returns (uint256) {
    IERC20 shareContract = IERC20(shareholderToken);
    uint256 totalSharesBalance = shareContract.balanceOf(address(this));
    uint256 appreciationRatio18 = totalSharesBalance.mul(10**18).div(
      totalSharesDeposited
    );
    return amount.mul(appreciationRatio18).div(10**18);
  }

  // getElevatedSharesWithBooster:
  // A + Ax = B
  // ------------------------
  // getBaseSharesFromBoosted:
  // A + Ax = B
  // A(1 + x) = B
  // A = B/(1 + x)
  function getElevatedSharesWithBooster(address shareholder, uint256 baseAmount)
    internal
    view
    returns (uint256)
  {
    return
      eligibleForRewardBooster(shareholder)
        ? baseAmount.add(
          baseAmount.mul(getBoostMultiplier(shareholder)).div(10**2)
        )
        : baseAmount;
  }

  function getBaseSharesFromBoosted(address shareholder, uint256 boostedAmount)
    public
    view
    returns (uint256)
  {
    uint256 multiplier = 10**18;
    return
      eligibleForRewardBooster(shareholder)
        ? boostedAmount.mul(multiplier).div(
          multiplier.add(
            multiplier.mul(getBoostMultiplier(shareholder)).div(10**2)
          )
        )
        : boostedAmount;
  }

  // NOTE: 2022-01-31 LW: new boost contract assumes OKLG and booster NFTs are staked in this contract
  function getBoostMultiplier(address wallet) public view returns (uint256) {
    return
      boostMultiplierContract == address(0)
        ? 0
        : IMultiplier(boostMultiplierContract).getMultiplier(wallet);
  }

  // NOTE: 2022-01-31 LW: new boost contract assumes OKLG and booster NFTs are staked in this contract
  function eligibleForRewardBooster(address shareholder)
    public
    view
    returns (bool)
  {
    return
      boostContract != address(0) &&
      IConditional(boostContract).passesTest(shareholder);
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

    return earnedRewards.sub(rewardsExcluded);
  }

  function getCumulativeRewards(uint256 share) internal view returns (uint256) {
    return share.mul(rewardsPerShare).div(ACC_FACTOR);
  }

  function getBaseShares(address user) external view returns (uint256) {
    return shares[user].amountBase;
  }

  function getShares(address user) external view override returns (uint256) {
    return shares[user].amount;
  }

  function getBoostNfts(address user)
    external
    view
    override
    returns (uint256[] memory)
  {
    return shares[user].nftBoostTokenIds;
  }

  function setShareholderToken(address _token) external onlyOwner {
    shareholderToken = _token;
  }

  function setBoostContract(address _contract) external onlyOwner {
    if (_contract != address(0)) {
      IConditional _contCheck = IConditional(_contract);
      // allow setting to zero address to effectively turn off check logic
      require(
        _contCheck.passesTest(address(0)) == true ||
          _contCheck.passesTest(address(0)) == false,
        'contract does not implement interface'
      );
    }
    boostContract = _contract;
  }

  function setBoostMultiplierContract(address _contract) external onlyOwner {
    if (_contract != address(0)) {
      IMultiplier _contCheck = IMultiplier(_contract);
      // allow setting to zero address to effectively turn off check logic
      require(
        _contCheck.getMultiplier(address(0)) >= 0,
        'contract does not implement interface'
      );
    }
    boostMultiplierContract = _contract;
  }

  function setMinSecondsBeforeUnstake(uint256 _seconds) external onlyOwner {
    minSecondsBeforeUnstake = _seconds;
  }

  function stakeOverride(address[] memory users, Share[] memory shareholderInfo)
    external
    onlyOwner
  {
    require(users.length == shareholderInfo.length, 'must be same length');
    uint256[] memory _empty = new uint256[](0);
    for (uint256 i = 0; i < users.length; i++) {
      shares[users[i]].nftBoostTokenIds = shareholderInfo[i].nftBoostTokenIds;
      _stake(users[i], shareholderInfo[i].amountBase, _empty, true);
    }
  }

  function withdrawNfts(address nftContractAddy, uint256[] memory _tokenIds)
    external
    onlyOwner
  {
    IERC721 nftContract = IERC721(nftContractAddy);
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      nftContract.transferFrom(address(this), owner(), _tokenIds[i]);
    }
  }

  receive() external payable {}
}