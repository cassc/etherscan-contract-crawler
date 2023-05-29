// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.6.0

import "openzeppelin-v3/token/ERC20/IERC20.sol";
import "openzeppelin-v3/token/ERC20/SafeERC20.sol";
import "openzeppelin-v3/math/Math.sol";
import "openzeppelin-v3/access/Ownable.sol";
import "openzeppelin-v3/utils/ReentrancyGuard.sol";

import "../libraries/BoringMath.sol";
import "../interfaces/IRewardsEscrow.sol";

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// POP locked in this contract will be entitled to voting rights for popcorn.network
// Based on CVX Locking contract for https://www.convexfinance.com/
// Based on EPS Staking contract for http://ellipsis.finance/
// Based on SNX MultiRewards by iamdefinitelyahuman - https://github.com/iamdefinitelyahuman/multi-rewards

contract PopLocker is ReentrancyGuard, Ownable {
  using BoringMath for uint256;
  using BoringMath224 for uint224;
  using BoringMath112 for uint112;
  using BoringMath32 for uint32;
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  struct Reward {
    bool useBoost;
    uint40 periodFinish;
    uint208 rewardRate;
    uint40 lastUpdateTime;
    uint208 rewardPerTokenStored;
  }
  struct Balances {
    uint112 locked;
    uint112 boosted;
    uint32 nextUnlockIndex;
  }
  struct LockedBalance {
    uint112 amount;
    uint112 boosted;
    uint32 unlockTime;
  }
  struct EarnedData {
    address token;
    uint256 amount;
  }
  struct Epoch {
    uint224 supply; //epoch boosted supply
    uint32 date; //epoch start date
  }

  //token constants
  IERC20 public stakingToken;
  IRewardsEscrow public rewardsEscrow;

  //rewards
  address[] public rewardTokens;
  mapping(address => Reward) public rewardData;

  // duration in seconds for rewards to be held in escrow
  uint256 public escrowDuration;

  // Duration that rewards are streamed over
  uint256 public constant rewardsDuration = 7 days;

  // Duration of lock/earned penalty period
  uint256 public constant lockDuration = rewardsDuration * 12;

  // reward token -> distributor -> is approved to add rewards
  mapping(address => mapping(address => bool)) public rewardDistributors;

  // user -> reward token -> amount
  mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
  mapping(address => mapping(address => uint256)) public rewards;

  //supplies and epochs
  uint256 public lockedSupply;
  uint256 public boostedSupply;
  Epoch[] public epochs;

  //mappings for balance data
  mapping(address => Balances) public balances;
  mapping(address => LockedBalance[]) public userLocks;

  //boost
  address public boostPayment;
  uint256 public maximumBoostPayment = 0;
  uint256 public boostRate = 10000;
  uint256 public nextMaximumBoostPayment = 0;
  uint256 public nextBoostRate = 10000;
  uint256 public constant denominator = 10000;

  //management
  uint256 public kickRewardPerEpoch = 100;
  uint256 public kickRewardEpochDelay = 4;

  //shutdown
  bool public isShutdown = false;

  //erc20-like interface
  string private _name;
  string private _symbol;
  uint8 private immutable _decimals;

  /* ========== CONSTRUCTOR ========== */

  constructor(IERC20 _stakingToken, IRewardsEscrow _rewardsEscrow) public Ownable() {
    _name = "Vote Locked POP Token";
    _symbol = "vlPOP";
    _decimals = 18;

    stakingToken = _stakingToken;
    rewardsEscrow = _rewardsEscrow;
    escrowDuration = 365 days;

    uint256 currentEpoch = block.timestamp.div(rewardsDuration).mul(rewardsDuration);
    epochs.push(Epoch({ supply: 0, date: uint32(currentEpoch) }));
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /* ========== ADMIN CONFIGURATION ========== */

  // Add a new reward token to be distributed to stakers
  function addReward(
    address _rewardsToken,
    address _distributor,
    bool _useBoost
  ) public onlyOwner {
    require(rewardData[_rewardsToken].lastUpdateTime == 0);
    rewardTokens.push(_rewardsToken);
    rewardData[_rewardsToken].lastUpdateTime = uint40(block.timestamp);
    rewardData[_rewardsToken].periodFinish = uint40(block.timestamp);
    rewardData[_rewardsToken].useBoost = _useBoost;
    rewardDistributors[_rewardsToken][_distributor] = true;
  }

  // Modify approval for an address to call notifyRewardAmount
  function approveRewardDistributor(
    address _rewardsToken,
    address _distributor,
    bool _approved
  ) external onlyOwner {
    require(rewardData[_rewardsToken].lastUpdateTime > 0, "rewards token does not exist");
    rewardDistributors[_rewardsToken][_distributor] = _approved;
  }

  //set boost parameters
  function setBoost(
    uint256 _max,
    uint256 _rate,
    address _receivingAddress
  ) external onlyOwner {
    require(_max < 1500, "over max payment"); //max 15%
    require(_rate < 30000, "over max rate"); //max 3x
    require(_receivingAddress != address(0), "invalid address"); //must point somewhere valid
    nextMaximumBoostPayment = _max;
    nextBoostRate = _rate;
    boostPayment = _receivingAddress;
  }

  function setEscrowDuration(uint256 duration) external onlyOwner {
    emit EscrowDurationUpdated(escrowDuration, duration);
    escrowDuration = duration;
  }

  //set kick incentive
  function setKickIncentive(uint256 _rate, uint256 _delay) external onlyOwner {
    require(_rate <= 500, "over max rate"); //max 5% per epoch
    require(_delay >= 2, "min delay"); //minimum 2 epochs of grace
    kickRewardPerEpoch = _rate;
    kickRewardEpochDelay = _delay;
  }

  //shutdown the contract.
  function shutdown() external onlyOwner {
    isShutdown = true;
  }

  //set approvals for rewards escrow
  function setApprovals() external {
    IERC20(stakingToken).safeApprove(address(rewardsEscrow), 0);
    IERC20(stakingToken).safeApprove(address(rewardsEscrow), uint256(-1));
  }

  /* ========== VIEWS ========== */

  function _rewardPerToken(address _rewardsToken) internal view returns (uint256) {
    if (boostedSupply == 0) {
      return rewardData[_rewardsToken].rewardPerTokenStored;
    }
    return
      uint256(rewardData[_rewardsToken].rewardPerTokenStored).add(
        _lastTimeRewardApplicable(rewardData[_rewardsToken].periodFinish)
          .sub(rewardData[_rewardsToken].lastUpdateTime)
          .mul(rewardData[_rewardsToken].rewardRate)
          .mul(1e18)
          .div(rewardData[_rewardsToken].useBoost ? boostedSupply : lockedSupply)
      );
  }

  function _earned(
    address _user,
    address _rewardsToken,
    uint256 _balance
  ) internal view returns (uint256) {
    return
      _balance.mul(_rewardPerToken(_rewardsToken).sub(userRewardPerTokenPaid[_user][_rewardsToken])).div(1e18).add(
        rewards[_user][_rewardsToken]
      );
  }

  function _lastTimeRewardApplicable(uint256 _finishTime) internal view returns (uint256) {
    return Math.min(block.timestamp, _finishTime);
  }

  function lastTimeRewardApplicable(address _rewardsToken) public view returns (uint256) {
    return _lastTimeRewardApplicable(rewardData[_rewardsToken].periodFinish);
  }

  function rewardPerToken(address _rewardsToken) external view returns (uint256) {
    return _rewardPerToken(_rewardsToken);
  }

  function getRewardForDuration(address _rewardsToken) external view returns (uint256) {
    return uint256(rewardData[_rewardsToken].rewardRate).mul(rewardsDuration);
  }

  // Address and claimable amount of all reward tokens for the given account
  function claimableRewards(address _account) external view returns (EarnedData[] memory userRewards) {
    userRewards = new EarnedData[](rewardTokens.length);
    Balances storage userBalance = balances[_account];
    uint256 boostedBal = userBalance.boosted;
    for (uint256 i = 0; i < userRewards.length; i++) {
      address token = rewardTokens[i];
      userRewards[i].token = token;
      userRewards[i].amount = _earned(_account, token, rewardData[token].useBoost ? boostedBal : userBalance.locked);
    }
    return userRewards;
  }

  // Total BOOSTED balance of an account, including unlocked but not withdrawn tokens
  function rewardWeightOf(address _user) external view returns (uint256 amount) {
    return balances[_user].boosted;
  }

  // total token balance of an account, including unlocked but not withdrawn tokens
  function lockedBalanceOf(address _user) external view returns (uint256 amount) {
    return balances[_user].locked;
  }

  //BOOSTED balance of an account which only includes properly locked tokens as of the most recent eligible epoch
  function balanceOf(address _user) external view returns (uint256 amount) {
    LockedBalance[] storage locks = userLocks[_user];
    Balances storage userBalance = balances[_user];
    uint256 nextUnlockIndex = userBalance.nextUnlockIndex;

    //start with current boosted amount
    amount = balances[_user].boosted;

    uint256 locksLength = locks.length;
    //remove old records only (will be better gas-wise than adding up)
    for (uint256 i = nextUnlockIndex; i < locksLength; i++) {
      if (locks[i].unlockTime <= block.timestamp) {
        amount = amount.sub(locks[i].boosted);
      } else {
        //stop now as no futher checks are needed
        break;
      }
    }

    //also remove amount in the current epoch
    uint256 currentEpoch = block.timestamp.div(rewardsDuration).mul(rewardsDuration);
    if (locksLength > 0 && uint256(locks[locksLength - 1].unlockTime).sub(lockDuration) == currentEpoch) {
      amount = amount.sub(locks[locksLength - 1].boosted);
    }

    return amount;
  }

  //BOOSTED balance of an account which only includes properly locked tokens at the given epoch
  function balanceAtEpochOf(uint256 _epoch, address _user) external view returns (uint256 amount) {
    LockedBalance[] storage locks = userLocks[_user];

    //get timestamp of given epoch index
    uint256 epochTime = epochs[_epoch].date;
    //get timestamp of first non-inclusive epoch
    uint256 cutoffEpoch = epochTime.sub(lockDuration);

    //current epoch is not counted
    uint256 currentEpoch = block.timestamp.div(rewardsDuration).mul(rewardsDuration);

    //need to add up since the range could be in the middle somewhere
    //traverse inversely to make more current queries more gas efficient
    for (uint256 i = locks.length - 1; i + 1 != 0; i--) {
      uint256 lockEpoch = uint256(locks[i].unlockTime).sub(lockDuration);
      //lock epoch must be less or equal to the epoch we're basing from.
      //also not include the current epoch
      if (lockEpoch <= epochTime && lockEpoch < currentEpoch) {
        if (lockEpoch > cutoffEpoch) {
          amount = amount.add(locks[i].boosted);
        } else {
          //stop now as no futher checks matter
          break;
        }
      }
    }

    return amount;
  }

  //supply of all properly locked BOOSTED balances at most recent eligible epoch
  function totalSupply() external view returns (uint256 supply) {
    uint256 currentEpoch = block.timestamp.div(rewardsDuration).mul(rewardsDuration);
    uint256 cutoffEpoch = currentEpoch.sub(lockDuration);
    uint256 epochindex = epochs.length;

    //do not include current epoch's supply
    if (uint256(epochs[epochindex - 1].date) == currentEpoch) {
      epochindex--;
    }

    //traverse inversely to make more current queries more gas efficient
    for (uint256 i = epochindex - 1; i + 1 != 0; i--) {
      Epoch storage e = epochs[i];
      if (uint256(e.date) <= cutoffEpoch) {
        break;
      }
      supply = supply.add(e.supply);
    }

    return supply;
  }

  //supply of all properly locked BOOSTED balances at the given epoch
  function totalSupplyAtEpoch(uint256 _epoch) external view returns (uint256 supply) {
    uint256 epochStart = uint256(epochs[_epoch].date).div(rewardsDuration).mul(rewardsDuration);
    uint256 cutoffEpoch = epochStart.sub(lockDuration);
    uint256 currentEpoch = block.timestamp.div(rewardsDuration).mul(rewardsDuration);

    //do not include current epoch's supply
    if (uint256(epochs[_epoch].date) == currentEpoch) {
      _epoch--;
    }

    //traverse inversely to make more current queries more gas efficient
    for (uint256 i = _epoch; i + 1 != 0; i--) {
      Epoch storage e = epochs[i];
      if (uint256(e.date) <= cutoffEpoch) {
        break;
      }
      supply = supply.add(epochs[i].supply);
    }

    return supply;
  }

  //find an epoch index based on timestamp
  function findEpochId(uint256 _time) external view returns (uint256 epoch) {
    uint256 max = epochs.length - 1;
    uint256 min = 0;

    //convert to start point
    _time = _time.div(rewardsDuration).mul(rewardsDuration);

    for (uint256 i = 0; i < 128; i++) {
      if (min >= max) break;

      uint256 mid = (min + max + 1) / 2;
      uint256 midEpochBlock = epochs[mid].date;
      if (midEpochBlock == _time) {
        //found
        return mid;
      } else if (midEpochBlock < _time) {
        min = mid;
      } else {
        max = mid - 1;
      }
    }
    return min;
  }

  // Information on a user's locked balances
  function lockedBalances(address _user)
    external
    view
    returns (
      uint256 total,
      uint256 unlockable,
      uint256 locked,
      LockedBalance[] memory lockData
    )
  {
    LockedBalance[] storage locks = userLocks[_user];
    Balances storage userBalance = balances[_user];
    uint256 nextUnlockIndex = userBalance.nextUnlockIndex;
    uint256 idx;
    for (uint256 i = nextUnlockIndex; i < locks.length; i++) {
      if (locks[i].unlockTime > block.timestamp) {
        if (idx == 0) {
          lockData = new LockedBalance[](locks.length - i);
        }
        lockData[idx] = locks[i];
        idx++;
        locked = locked.add(locks[i].amount);
      } else {
        unlockable = unlockable.add(locks[i].amount);
      }
    }
    return (userBalance.locked, unlockable, locked, lockData);
  }

  //number of epochs
  function epochCount() external view returns (uint256) {
    return epochs.length;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function checkpointEpoch() external {
    _checkpointEpoch();
  }

  //insert a new epoch if needed. fill in any gaps
  function _checkpointEpoch() internal {
    uint256 currentEpoch = block.timestamp.div(rewardsDuration).mul(rewardsDuration);
    uint256 epochindex = epochs.length;

    //first epoch add in constructor, no need to check 0 length

    //check to add
    if (epochs[epochindex - 1].date < currentEpoch) {
      //fill any epoch gaps
      while (epochs[epochs.length - 1].date != currentEpoch) {
        uint256 nextEpochDate = uint256(epochs[epochs.length - 1].date).add(rewardsDuration);
        epochs.push(Epoch({ supply: 0, date: uint32(nextEpochDate) }));
      }

      //update boost parameters on a new epoch
      if (boostRate != nextBoostRate) {
        boostRate = nextBoostRate;
      }
      if (maximumBoostPayment != nextMaximumBoostPayment) {
        maximumBoostPayment = nextMaximumBoostPayment;
      }
    }
  }

  // Locked tokens cannot be withdrawn for lockDuration and are eligible to receive stakingReward rewards
  function lock(
    address _account,
    uint256 _amount,
    uint256 _spendRatio
  ) external nonReentrant {
    //pull tokens
    stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

    //lock
    _lock(_account, _amount, _spendRatio);
  }

  //lock tokens
  function _lock(
    address _account,
    uint256 _amount,
    uint256 _spendRatio
  ) internal updateReward(_account) {
    require(_amount > 0, "Cannot stake 0");
    require(_spendRatio <= maximumBoostPayment, "over max spend");
    require(!isShutdown, "shutdown");

    Balances storage bal = balances[_account];

    //must try check pointing epoch first
    _checkpointEpoch();

    //calc lock and boosted amount
    uint256 spendAmount = _amount.mul(_spendRatio).div(denominator);
    uint256 boostRatio = boostRate.mul(_spendRatio).div(maximumBoostPayment == 0 ? 1 : maximumBoostPayment);
    uint112 lockAmount = _amount.sub(spendAmount).to112();
    uint112 boostedAmount = _amount.add(_amount.mul(boostRatio).div(denominator)).to112();

    //add user balances
    bal.locked = bal.locked.add(lockAmount);
    bal.boosted = bal.boosted.add(boostedAmount);

    //add to total supplies
    lockedSupply = lockedSupply.add(lockAmount);
    boostedSupply = boostedSupply.add(boostedAmount);

    //add user lock records or add to current
    uint256 currentEpoch = block.timestamp.div(rewardsDuration).mul(rewardsDuration);
    uint256 unlockTime = currentEpoch.add(lockDuration);
    uint256 idx = userLocks[_account].length;
    if (idx == 0 || userLocks[_account][idx - 1].unlockTime < unlockTime) {
      userLocks[_account].push(
        LockedBalance({ amount: lockAmount, boosted: boostedAmount, unlockTime: uint32(unlockTime) })
      );
    } else {
      LockedBalance storage userL = userLocks[_account][idx - 1];
      userL.amount = userL.amount.add(lockAmount);
      userL.boosted = userL.boosted.add(boostedAmount);
    }

    //update epoch supply, epoch checkpointed above so safe to add to latest
    Epoch storage e = epochs[epochs.length - 1];
    e.supply = e.supply.add(uint224(boostedAmount));

    //send boost payment
    if (spendAmount > 0) {
      stakingToken.safeTransfer(boostPayment, spendAmount);
    }

    emit Staked(_account, _amount, lockAmount, boostedAmount);
  }

  // Withdraw all currently locked tokens where the unlock time has passed
  function _processExpiredLocks(
    address _account,
    bool _relock,
    uint256 _spendRatio,
    address _withdrawTo,
    address _rewardAddress,
    uint256 _checkDelay
  ) internal updateReward(_account) {
    LockedBalance[] storage locks = userLocks[_account];
    Balances storage userBalance = balances[_account];
    uint112 locked;
    uint112 boostedAmount;
    uint256 length = locks.length;
    uint256 reward = 0;

    if (isShutdown || locks[length - 1].unlockTime <= block.timestamp.sub(_checkDelay)) {
      //if time is beyond last lock, can just bundle everything together
      locked = userBalance.locked;
      boostedAmount = userBalance.boosted;

      //dont delete, just set next index
      userBalance.nextUnlockIndex = length.to32();

      //check for kick reward
      //this wont have the exact reward rate that you would get if looped through
      //but this section is supposed to be for quick and easy low gas processing of all locks
      //we'll assume that if the reward was good enough someone would have processed at an earlier epoch
      if (_checkDelay > 0) {
        reward = _getDelayAdjustedReward(_checkDelay, locks[length - 1]);
      }
    } else {
      //use a processed index(nextUnlockIndex) to not loop as much
      //deleting does not change array length
      uint32 nextUnlockIndex = userBalance.nextUnlockIndex;
      for (uint256 i = nextUnlockIndex; i < length; i++) {
        //unlock time must be less or equal to time
        if (locks[i].unlockTime > block.timestamp.sub(_checkDelay)) break;

        //add to cumulative amounts
        locked = locked.add(locks[i].amount);
        boostedAmount = boostedAmount.add(locks[i].boosted);

        //check for kick reward
        //each epoch over due increases reward
        if (_checkDelay > 0) {
          reward = reward.add(_getDelayAdjustedReward(_checkDelay, locks[i]));
        }
        //set next unlock index
        nextUnlockIndex++;
      }
      //update next unlock index
      userBalance.nextUnlockIndex = nextUnlockIndex;
    }
    require(locked > 0, "no exp locks");

    //update user balances and total supplies
    userBalance.locked = userBalance.locked.sub(locked);
    userBalance.boosted = userBalance.boosted.sub(boostedAmount);
    lockedSupply = lockedSupply.sub(locked);
    boostedSupply = boostedSupply.sub(boostedAmount);

    //send process incentive
    if (reward > 0) {
      //if theres a reward(kicked), it will always be a withdraw only

      //reduce return amount by the kick reward
      locked = locked.sub(reward.to112());

      //transfer reward
      stakingToken.safeTransfer(_rewardAddress, reward);

      emit KickReward(_rewardAddress, _account, reward);
    }

    //relock or return to user
    if (_relock) {
      _lock(_withdrawTo, locked, _spendRatio);
      emit Relocked(_account, locked);
    } else {
      stakingToken.safeTransfer(_withdrawTo, locked);
      emit Withdrawn(_account, locked);
    }
  }

  function _getDelayAdjustedReward(uint256 _checkDelay, LockedBalance storage lockedBalance)
    internal
    view
    returns (uint256)
  {
    uint256 currentEpoch = block.timestamp.sub(_checkDelay).div(rewardsDuration).mul(rewardsDuration);
    uint256 epochsover = currentEpoch.sub(uint256(lockedBalance.unlockTime)).div(rewardsDuration);
    uint256 rRate = Math.min(kickRewardPerEpoch.mul(epochsover + 1), denominator);
    return uint256(lockedBalance.amount).mul(rRate).div(denominator);
  }

  // Withdraw/relock all currently locked tokens where the unlock time has passed
  function processExpiredLocks(
    bool _relock,
    uint256 _spendRatio,
    address _withdrawTo
  ) external nonReentrant {
    _processExpiredLocks(msg.sender, _relock, _spendRatio, _withdrawTo, msg.sender, 0);
  }

  // Withdraw/relock all currently locked tokens where the unlock time has passed
  function processExpiredLocks(bool _relock) external nonReentrant {
    _processExpiredLocks(msg.sender, _relock, 0, msg.sender, msg.sender, 0);
  }

  function kickExpiredLocks(address _account) external nonReentrant {
    //allow kick after grace period of 'kickRewardEpochDelay'
    _processExpiredLocks(_account, false, 0, _account, msg.sender, rewardsDuration.mul(kickRewardEpochDelay));
  }

  // Claim all pending rewards
  function getReward(address _account) public nonReentrant updateReward(_account) {
    for (uint256 i; i < rewardTokens.length; i++) {
      address _rewardsToken = rewardTokens[i];
      uint256 reward = rewards[_account][_rewardsToken];
      if (reward > 0) {
        rewards[_account][_rewardsToken] = 0;
        uint256 payout = reward.div(uint256(10));
        uint256 escrowed = payout.mul(uint256(9));
        IERC20(_rewardsToken).safeTransfer(_account, payout);
        IRewardsEscrow(rewardsEscrow).lock(_account, escrowed, escrowDuration);
        emit RewardPaid(_account, _rewardsToken, reward);
      }
    }
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function _notifyReward(address _rewardsToken, uint256 _reward) internal {
    Reward storage rdata = rewardData[_rewardsToken];

    if (block.timestamp >= rdata.periodFinish) {
      rdata.rewardRate = _reward.div(rewardsDuration).to208();
    } else {
      uint256 remaining = uint256(rdata.periodFinish).sub(block.timestamp);
      uint256 leftover = remaining.mul(rdata.rewardRate);
      rdata.rewardRate = _reward.add(leftover).div(rewardsDuration).to208();
    }

    rdata.lastUpdateTime = block.timestamp.to40();
    rdata.periodFinish = block.timestamp.add(rewardsDuration).to40();
  }

  function notifyRewardAmount(address _rewardsToken, uint256 _reward) external updateReward(address(0)) {
    require(rewardDistributors[_rewardsToken][msg.sender], "not authorized");
    require(_reward > 0, "No reward");

    _notifyReward(_rewardsToken, _reward);

    // handle the transfer of reward tokens via `transferFrom` to reduce the number
    // of transactions required and ensure correctness of the _reward amount
    IERC20(_rewardsToken).safeTransferFrom(msg.sender, address(this), _reward);

    emit RewardAdded(_rewardsToken, _reward);
  }

  function setRewardsEscrow(address _rewardsEscrow) external onlyOwner {
    emit RewardsEscrowUpdated(address(rewardsEscrow), _rewardsEscrow);
    rewardsEscrow = IRewardsEscrow(_rewardsEscrow);
  }

  // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
  function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
    require(_tokenAddress != address(stakingToken), "Cannot withdraw staking token");
    require(rewardData[_tokenAddress].lastUpdateTime == 0, "Cannot withdraw reward token");
    IERC20(_tokenAddress).safeTransfer(owner(), _tokenAmount);
    emit Recovered(_tokenAddress, _tokenAmount);
  }

  /* ========== MODIFIERS ========== */

  modifier updateReward(address _account) {
    {
      //stack too deep
      Balances storage userBalance = balances[_account];
      uint256 boostedBal = userBalance.boosted;
      for (uint256 i = 0; i < rewardTokens.length; i++) {
        address token = rewardTokens[i];
        rewardData[token].rewardPerTokenStored = _rewardPerToken(token).to208();
        rewardData[token].lastUpdateTime = _lastTimeRewardApplicable(rewardData[token].periodFinish).to40();
        if (_account != address(0)) {
          //check if reward is boostable or not. use boosted or locked balance accordingly
          rewards[_account][token] = _earned(
            _account,
            token,
            rewardData[token].useBoost ? boostedBal : userBalance.locked
          );
          userRewardPerTokenPaid[_account][token] = rewardData[token].rewardPerTokenStored;
        }
      }
    }
    _;
  }

  /* ========== EVENTS ========== */
  event RewardAdded(address indexed _token, uint256 _reward);
  event RewardsEscrowUpdated(address _previous, address _new);
  event Staked(address indexed _user, uint256 _paidAmount, uint256 _lockedAmount, uint256 _boostedAmount);
  event Withdrawn(address indexed _user, uint256 _amount);
  event Relocked(address indexed _user, uint256 _amount);
  event EscrowDurationUpdated(uint256 _previousDuration, uint256 _newDuration);
  event KickReward(address indexed _user, address indexed _kicked, uint256 _reward);
  event RewardPaid(address indexed _user, address indexed _rewardsToken, uint256 _reward);
  event Recovered(address _token, uint256 _amount);
}