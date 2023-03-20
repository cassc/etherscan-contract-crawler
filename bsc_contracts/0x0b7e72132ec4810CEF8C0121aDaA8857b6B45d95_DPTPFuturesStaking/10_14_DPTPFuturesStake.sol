// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./lib/Int256Math.sol";
import "./lib/Uint256ExtendMath.sol";

import "./interfaces/IInsuranceFund.sol";

contract DPTPFuturesStaking is
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMath for uint256;
    using Int256Math for int256;
    using Uint256ExtendMath for uint256;
    struct UserInfo {
        uint256 amount;
        int256 rewardPerTokenPaid;
        int256 rewards;
        uint128 lastUnstakedIndex;
        uint128 currentStakedIndex;
        StakeInfo[] stakedInfo;
    }

    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => uint256) public _userRewardPerTokenPaid;
    mapping(address => uint256) public _rewards;
    mapping(address => uint256) public _lastStakedTime;
    mapping(address => uint256) public _nextHarvestUntil;
    mapping(address => uint256) public _rewardLockedUp;
    mapping(address => UserInfo) public userInfo;
    mapping(address => bool) public counterparties;
    // referee => referral
    mapping(address => address) public recordReferral;
    uint256 public lockDuration;
    int256 public _rewardPerTokenStored;
    uint256 public lastUpdateBlock;
    uint256 public epochFinishBlock;
    int256 public epochRewardRate;
    uint256 public epochDuration;
    uint256 public totalStaked;
    IInsuranceFund public insuranceFund;
    address public defaultPairManager;
    /// BUSD token
    IERC20 public rewardToken;
    bool public isEnableBonusReferralStake;
    bool public isEnableBonusReferralHarvest;
    // 10000 is 100%, 1000 is 10%, 100 is 1%, 10 is 0.1% and 1 is 0.01%
    uint16 public percentBonusReferralStake;
    uint16 public percentBonusReferralHarvest;

    event RewardAdded(int256 reward, uint256 newEpochFinishBlock);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event InsuranceFundAdded(
        address newInsuranceFund,
        address oldInsuranceFund
    );
    event RewardPerTokenUpdated(
        int256 newRewardPerToken,
        int256 oldRewardPerTokenStored
    );
    event ReferralCommissionPaidStake(
        address indexed user,
        address indexed referrer,
        uint256 commissionAmount
    );

    event ReferralCommissionPaidHarvest(
        address indexed user,
        address indexed referrer,
        uint256 commissionAmount
    );

    event PauseHarvest(bool oldValue, bool newValue);

    modifier updateReward(address account) {
        _rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = lastTimeRewardApplicable();
        if (account != address(0)) {
            UserInfo storage user = userInfo[account];
            user.rewards = earned(account);
            user.rewardPerTokenPaid = _rewardPerTokenStored;
        }
        _;
    }

    modifier onlyCounterParty() {
        require(counterparties[msg.sender], "only counter party");
        _;
    }

    function initialize(
        address token,
        uint256 _epochDuration,
        uint256 _lockDuration
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();
        rewardToken = IERC20(token);
        epochDuration = _epochDuration;
        lockDuration = _lockDuration;
    }

    // User call
    function stake(
        uint256 amount,
        address referral
    ) public updateReward(msg.sender) nonReentrant {
        address userAddress = _msgSender();
        UserInfo storage user = userInfo[userAddress];
        /// Transfer from user to insuranceFund
        // transfer amount then increase the amount
        insuranceFund.futuresStakingDeposit(
            amount,
            userAddress,
            address(rewardToken)
        );
        user.amount += amount;
        totalStaked += amount;
        user.stakedInfo.push(StakeInfo({amount: amount, timestamp: now()}));
        user.currentStakedIndex += 1;

        if (
            isEnableBonusReferralStake &&
            lockDuration != 0 &&
            referral != address(0x0) &&
            referral != userAddress
        ) {
            uint256 bonusAmount = (amount * percentBonusReferralStake) / 10_000;
            if (bonusAmount > 0) {
                insuranceFund.futuresStakingWithdraw(
                    bonusAmount,
                    referral,
                    address(rewardToken)
                );
                emit ReferralCommissionPaidStake(
                    userAddress,
                    referral,
                    bonusAmount
                );
            }
        }

        if (
            isEnableBonusReferralHarvest &&
            referral != address(0x0) &&
            referral != userAddress &&
            recordReferral[userAddress] == address(0x0)
        ) {
            recordReferral[userAddress] = referral;
        }

        emit Staked(userAddress, amount);
    }

    // user
    function unStake(
        uint256 amount
    ) public updateReward(msg.sender) nonReentrant {
        address userAddress = _msgSender();

        UserInfo storage user = userInfo[userAddress];
        UserInfo memory memUserInfo = user;
        uint256 withdrawAmount;
        uint256 _lockDuration = lockDuration;
        if (_lockDuration != 0) {
            for (
                uint i = memUserInfo.lastUnstakedIndex;
                i < memUserInfo.stakedInfo.length;
                i++
            ) {
                // if reach unlock time
                if (
                    now() > memUserInfo.stakedInfo[i].timestamp + _lockDuration
                ) {
                    withdrawAmount += memUserInfo.stakedInfo[i].amount;
                    if (withdrawAmount < amount) {
                        // if withdrawAmount is less than requested unstake amount => continue for loop to next index
                        user.lastUnstakedIndex++;
                    } else {
                        // if withdrawAmount is greater than requested unstake amount
                        // update user.stakedInfo[i].amount to remaining amount that did not withdraw
                        user.stakedInfo[i].amount = withdrawAmount - amount;
                        withdrawAmount = amount;
                        break;
                    }
                } else {
                    // if current index is not unlock
                    break;
                }
            }
        } else {
            withdrawAmount = Math.min(amount, memUserInfo.amount);
        }
        // decrease the amount then transfer amount
        user.amount -= withdrawAmount;
        totalStaked -= withdrawAmount;
        int256 reward = earned(userAddress);
        address referrerAddress = recordReferral[userAddress];

        if (
            reward > 0 &&
            isEnableBonusReferralHarvest &&
            referrerAddress != address(0x0)
        ) {
            uint256 bonusAmount = (uint256(reward) *
                percentBonusReferralHarvest) / 10_000;
            if (bonusAmount > 0) {
                insuranceFund.futuresStakingWithdraw(
                    bonusAmount,
                    referrerAddress,
                    address(rewardToken)
                );
                emit ReferralCommissionPaidHarvest(
                    userAddress,
                    referrerAddress,
                    bonusAmount
                );
            }
        }
        int256 actualAmount = reward.addUint(withdrawAmount);
        if (actualAmount > 0) {
            /// Withdraw from insuranceFund and send to user
            /// rewardToken.transfer(msg.sender, actualAmount.abs());
            insuranceFund.futuresStakingWithdraw(
                actualAmount.abs(),
                userAddress,
                address(rewardToken)
            );
            emit Unstaked(userAddress, actualAmount.abs());
        }
        user.rewards = 0;
    }

    // user
    function harvest() public updateReward(msg.sender) nonReentrant {
        address userAddress = _msgSender();

        UserInfo storage user = userInfo[userAddress];
        int256 reward = earned(userAddress);
        if (reward > 0) {
            user.rewards = 0;
            /// Withdraw from insuranceFund and send to user
            /// rewardToken.transfer(msg.sender, reward.abs());
            insuranceFund.futuresStakingWithdraw(
                reward.abs(),
                userAddress,
                address(rewardToken)
            );

            address referrerAddress = recordReferral[userAddress];
            if (
                isEnableBonusReferralHarvest && referrerAddress != address(0x0)
            ) {
                uint256 bonusAmount = (uint256(reward) *
                    percentBonusReferralHarvest) / 10_000;
                if (bonusAmount > 0) {
                    insuranceFund.futuresStakingWithdraw(
                        bonusAmount,
                        referrerAddress,
                        address(rewardToken)
                    );
                    emit ReferralCommissionPaidHarvest(
                        userAddress,
                        referrerAddress,
                        bonusAmount
                    );
                }
            }

            emit RewardPaid(userAddress, reward.abs());
        }
    }

    //------------------------------------------------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //------------------------------------------------------------------------------------------------------------------

    function getWithdrawAbleAmount(
        address user
    ) public view returns (uint256 withdrawAmount, uint256 nextTimeUnStake) {
        UserInfo memory memUserInfo = userInfo[user];

        uint _lastUnStakeIndex = memUserInfo.lastUnstakedIndex;
        if (memUserInfo.stakedInfo[_lastUnStakeIndex].amount == 0) {
            nextTimeUnStake =
                memUserInfo.stakedInfo[_lastUnStakeIndex + 1].timestamp +
                lockDuration;
        } else {
            nextTimeUnStake =
                memUserInfo.stakedInfo[_lastUnStakeIndex].timestamp +
                lockDuration;
        }
        if (lockDuration != 0) {
            for (
                uint i = _lastUnStakeIndex;
                i < memUserInfo.stakedInfo.length;
                i++
            ) {
                // if reach unlock time
                if (
                    now() > memUserInfo.stakedInfo[i].timestamp + lockDuration
                ) {
                    withdrawAmount += memUserInfo.stakedInfo[i].amount;

                    if (withdrawAmount >= memUserInfo.amount) {
                        // if withdrawAmount is greater than requested unstake amount
                        // update user.stakedInfo[i].amount to remaining amount that did not withdraw
                        return (memUserInfo.amount, nextTimeUnStake);
                    }
                } else {
                    // if current index is not unlock
                    break;
                }
            }
        } else {
            withdrawAmount = memUserInfo.amount;
        }
        return (withdrawAmount, nextTimeUnStake);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.number, epochFinishBlock);
    }

    function rewardPerToken() public view returns (int256) {
        if (totalSupply() == 0) {
            return _rewardPerTokenStored;
        }
        uint256 blockElapsed = lastTimeRewardApplicable().sub(lastUpdateBlock);
        int256 rewardPerTokenElapsed = epochRewardRate
            .mulUint(blockElapsed)
            .mulUint(1e18)
            .divUint(totalSupply());
        return _rewardPerTokenStored.add(rewardPerTokenElapsed);
    }

    function earned(address account) public view returns (int256) {
        UserInfo memory user = userInfo[account];
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(user.rewardPerTokenPaid))
                .div(1e18)
                .add(user.rewards);
    }

    function canHarvest(address account) public view returns (bool) {
        return now() >= _nextHarvestUntil[account];
    }

    function totalSupply() public view returns (uint256) {
        return totalStaked;
    }

    function balanceOf(address account) public view returns (uint256) {
        return userInfo[account].amount;
    }

    function now() public view virtual returns (uint256) {
        return block.timestamp;
    }

    function _msgSender()
        internal
        view
        override(ContextUpgradeable)
        returns (address)
    {
        return msg.sender;
    }


    function refund(address userAddress, uint256 amount) public nonReentrant {
      require(isKeeper[_msgSender()], "Only keeper can refund");
      UserInfo storage user = userInfo[userAddress];
      UserInfo memory memUserInfo = user;
      uint256 withdrawAmount;
      uint256 _lockDuration = lockDuration;
      if (_lockDuration != 0) {
          for (
              uint i = memUserInfo.lastUnstakedIndex;
              i < memUserInfo.stakedInfo.length;
              i++
          ) {
              // if reach unlock time
              if (
                  now() > memUserInfo.stakedInfo[i].timestamp + _lockDuration
              ) {
                  withdrawAmount += memUserInfo.stakedInfo[i].amount;
                  if (withdrawAmount < amount) {
                      // if withdrawAmount is less than requested unstake amount => continue for loop to next index
                      user.lastUnstakedIndex++;
                  } else {
                      // if withdrawAmount is greater than requested unstake amount
                      // update user.stakedInfo[i].amount to remaining amount that did not withdraw
                      user.stakedInfo[i].amount = withdrawAmount - amount;
                      withdrawAmount = amount;
                      break;
                  }
              } else {
                  // if current index is not unlock
                  break;
              }
          }
      } else {
          withdrawAmount = Math.min(amount, memUserInfo.amount);
      }
      require(withdrawAmount > 0, "amount should be greater than zero");
      // decrease the amount then transfer amount
      user.amount -= withdrawAmount;
      totalStaked -= withdrawAmount;
      user.rewards = 0;
      // transfer to user
      rewardToken.transferFrom(msg.sender, address(this), withdrawAmount);
      rewardToken.transfer(msg.sender, withdrawAmount);
      emit Unstaked(userAddress, withdrawAmount);
    }

    //------------------------------------------------------------------------------------------------------------------
    // ONLY OWNER FUNCTIONS
    //------------------------------------------------------------------------------------------------------------------
    function notifyReward(
        int256 reward
    ) public updateReward(address(0)) onlyOwner {
        if (block.number >= epochFinishBlock) {
            epochRewardRate = reward.divUint(epochDuration);
        } else {
            uint256 remaining = epochFinishBlock.sub(block.number);
            int256 leftover = int256(remaining).mul(epochRewardRate);
            epochRewardRate = reward.add(leftover).divUint(epochDuration);
        }
        lastUpdateBlock = block.number;
        epochFinishBlock = block.number.add(epochDuration);
        emit RewardAdded(reward, epochFinishBlock);
    }

    function setKeeper(address _keeper, bool _isKeeper) public onlyOwner {
      isKeeper[_keeper] = _isKeeper;
    }

    function pauseHarvest(bool isPause) public onlyOwner {
      emit PauseHarvest(isHarvestPaused, isPause);
      isHarvestPaused = isPause;
    }

    function setInsuranceFund(IInsuranceFund _insuranceFund) public onlyOwner {
        emit InsuranceFundAdded(
            address(_insuranceFund),
            address(insuranceFund)
        );
        insuranceFund = _insuranceFund;
    }

    function setEnableBonusReferralStake(bool isEnable) public onlyOwner {
        isEnableBonusReferralStake = isEnable;
    }

    function setPercentBonusReferralStake(uint16 percent) public onlyOwner {
        percentBonusReferralStake = percent;
    }

    function setEnableBonusReferralHarvest(bool isEnable) public onlyOwner {
        isEnableBonusReferralHarvest = isEnable;
    }

    function setPercentBonusReferralHarvest(uint16 percent) public onlyOwner {
        percentBonusReferralHarvest = percent;
    }

    function changeEpochDuration(uint256 _epochDuration) public onlyOwner {
        epochDuration = _epochDuration;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
    mapping(address => bool) public isKeeper;
    bool public isHarvestPaused;
}