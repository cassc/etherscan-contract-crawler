// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { Pausable } from '../Pausable.sol';

abstract contract RevenueShareBase is Ownable, Pausable {
    using SafeERC20 for IERC20;

    struct Reward {
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 balance;
    }
    struct Balances {
        uint256 locked;
    }
    struct LockedBalance {
        uint256 amount;
        uint256 unlockTime;
    }
    struct RewardData {
        address token;
        uint256 amount;
    }

    bool public publicExitAreSet;
    uint256 internal constant SHARE_PRECISION = 1e18;
    uint256 public constant rewardsDuration = 7 days;
    uint256 public constant rewardLookback = 1 days;
    uint256 public immutable lockDuration;
    uint256 public lockedSupply;
    address[] public rewardTokens;
    IERC20 public lockToken;

    mapping(address => Reward) public rewardData;
    mapping(address => mapping(address => uint)) public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint)) public rewards;
    mapping(address => Balances) internal balances;
    mapping(address => LockedBalance[]) internal userLocks;

    event Locked(address indexed user, uint256 amount);
    event WithdrawnExpiredLocks(address indexed user, uint256 amount);
    event PublicExit();
    event RewardPaid(address indexed user, address indexed rewardsToken, uint256 reward);

    constructor(uint256 _lockDuration) {
        lockDuration = _lockDuration;
    }

    /**
     * @dev Add rewards token to the list
     */
    function addReward(address _rewardsToken) external virtual;

    /**
     * @dev User can withdraw his locked funds without a lock period if publicExitAreSet set
     */
    function publicExit() external onlyOwner {
        require(!publicExitAreSet, 'public exit are set');
        publicExitAreSet = true;
        emit PublicExit();
    }

    /**
     * @dev Information on a user's total/locked/available balances
     * @param _user is the address of the user for which the locked balances are checked
     * @return total is the amount of locked and unlocked tokens
     * @return available is the number of unlocked tokens (that are available to withdraw)
     * @return lockedTotal is the number of locked tokens (that are not available to withdraw yet)
     * @return lockData is the list with the number of tokens and their unlock time
     */
    function lockedBalances(
        address _user
    )
        external
        view
        returns (
            uint256 total,
            uint256 available,
            uint256 lockedTotal,
            LockedBalance[] memory lockData
        )
    {
        LockedBalance[] storage locks = userLocks[_user];
        uint256 idx;
        for (uint256 i = 0; i < locks.length; i++) {
            if (locks[i].unlockTime > block.timestamp) {
                if (idx == 0) {
                    lockData = new LockedBalance[](locks.length - i);
                }
                lockData[idx] = locks[i];
                idx++;
                lockedTotal += locks[i].amount;
            } else {
                available += locks[i].amount;
            }
        }
        return (balances[_user].locked, available, lockedTotal, lockData);
    }

    /**
     * @dev Withdraw `lockToken` after the locked time (withdraw Expired Locks)
     */
    function withdraw() external {
        _updateReward(msg.sender);
        LockedBalance[] storage locks = userLocks[msg.sender];
        Balances storage bal = balances[msg.sender];
        uint256 amount;
        uint256 length = locks.length;
        require(length > 0, 'Amount of locks can not be zero value');
        if (locks[length - 1].unlockTime <= block.timestamp || publicExitAreSet) {
            amount = bal.locked;
            delete userLocks[msg.sender];
        } else {
            for (uint256 i = 0; i < length; i++) {
                if (locks[i].unlockTime > block.timestamp) break;
                amount += locks[i].amount;
                delete locks[i];
            }
        }
        require(amount > 0, 'Amount of locked tokens can not be zero value');
        bal.locked -= amount;
        lockedSupply -= amount;
        lockToken.safeTransfer(msg.sender, amount);
        emit WithdrawnExpiredLocks(msg.sender, amount);
    }

    /**
     * @dev Address and claimable amount of all reward tokens for the provided user
     * @param _user is the address of the user for which the rewards are checked
     * @return _rewards is the list with the amount and token addresses that can be claimed
     */
    function claimableRewards(address _user) external view returns (RewardData[] memory _rewards) {
        _rewards = new RewardData[](rewardTokens.length);
        for (uint256 i = 0; i < _rewards.length; i++) {
            _rewards[i].token = rewardTokens[i];
            _rewards[i].amount =
                _earned(
                    _user,
                    _rewards[i].token,
                    balances[_user].locked,
                    _rewardPerToken(rewardTokens[i], lockedSupply)
                ) /
                SHARE_PRECISION;
        }
        return _rewards;
    }

    /**
     * @dev Transfer Reward tokens to the user
     * This function will be executed by anyone every 24 hours (a user or the backend side).
     * @param _rewardTokens are the reward token addresses
     */
    function getReward(address[] calldata _rewardTokens) external whenNotPaused {
        _updateReward(msg.sender);
        _getReward(_rewardTokens);
    }

    /**
     * @dev Returns amount of rewards per token
     * @param _rewardToken is the reward token address
     */
    function rewardPerToken(address _rewardToken) external view returns (uint256) {
        return _rewardPerToken(_rewardToken, lockedSupply);
    }

    /**
     * @dev Returns a last datetime for applicable reward
     * @param _rewardToken the address of the reward token
     * @return applicableLastTime is the last time applicable reward
     */
    function lastTimeRewardApplicable(address _rewardToken) public view returns (uint256) {
        uint256 periodFinish = rewardData[_rewardToken].periodFinish;
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    /**
     * @dev main functionality of lock tokens to receive rewards
     * @param _amount is the number of `lockToken` tokens
     * @param _onBehalfOf is the address who sent the _amount of tokens for locking
     */
    function _lock(uint256 _amount, address _onBehalfOf) internal {
        require(_amount > 0, 'Cannot lock 0');
        require(_onBehalfOf != address(0), 'address != 0');
        require(
            userLocks[_onBehalfOf].length <= 100,
            'User can not execute lock function more than 100 times'
        );
        _updateReward(_onBehalfOf);
        lockedSupply += _amount;
        Balances storage bal = balances[_onBehalfOf];
        bal.locked += _amount;
        userLocks[_onBehalfOf].push(
            LockedBalance({ amount: _amount, unlockTime: block.timestamp + lockDuration })
        );
        lockToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Locked(_onBehalfOf, _amount);
    }

    /**
     * @dev Transfer rewards for the user and notify unseen reward that updates rewardRate
     * @param _rewardTokens is the provided tokens for getting rewards
     */
    function _getReward(address[] memory _rewardTokens) internal {
        uint256 length = _rewardTokens.length;
        for (uint256 i; i < length; i++) {
            address token = _rewardTokens[i];
            uint256 reward = rewards[msg.sender][token] / SHARE_PRECISION;
            Reward storage r = rewardData[token];
            uint256 periodFinish = r.periodFinish;
            require(periodFinish > 0, 'Unknown reward token');
            uint256 balance = r.balance;
            if (periodFinish < block.timestamp + (rewardsDuration - rewardLookback)) {
                uint256 unseen = _unseen(token, balance);
                if (unseen > 0) {
                    _notifyReward(token, unseen);
                    balance += unseen;
                }
            }
            r.balance = balance - reward;
            if (reward == 0) continue;
            rewards[msg.sender][token] = 0;
            IERC20(token).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, token, reward);
        }
    }

    /**
     * @dev Updates rewardRate, periodFinish and lastUpdateTime for provided reward token.
     * @dev The code is designed in a way that _notifyReward does not force invoke _updateReward method
     * @param _rewardsToken is the reward token address
     * @param _reward is the unseen amount of reward token
     */
    function _notifyReward(address _rewardsToken, uint256 _reward) internal {
        Reward storage r = rewardData[_rewardsToken];
        if (block.timestamp >= r.periodFinish) {
            r.rewardRate = (_reward * SHARE_PRECISION) / rewardsDuration;
        } else {
            uint256 remaining = r.periodFinish - block.timestamp;
            uint256 leftover = (remaining * r.rewardRate) / SHARE_PRECISION;
            r.rewardRate = ((_reward + leftover) * SHARE_PRECISION) / rewardsDuration;
        }
        r.lastUpdateTime = block.timestamp;
        r.periodFinish = block.timestamp + rewardsDuration;
    }

    /**
     * @dev Updates reward information for the user
     * @param _user is the user address
     */
    function _updateReward(address _user) internal {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            Reward storage r = rewardData[token];
            uint256 rpt = _rewardPerToken(token, lockedSupply);
            r.rewardPerTokenStored = rpt;
            r.lastUpdateTime = lastTimeRewardApplicable(token);
            if (_user != address(this)) {
                rewards[_user][token] = _earned(_user, token, balances[_user].locked, rpt);
                userRewardPerTokenPaid[_user][token] = rpt;
            }
        }
    }

    /**
     * @dev Returns current unseen balance for provided token
     * @param _token is the token that will be checked for the unseen balance
     * @param _balance is the provided current balance for the token
     * @return unseen is an amount of calculated unseen balance
     */
    function _unseen(
        address _token,
        uint256 _balance
    ) internal view virtual returns (uint256 unseen);

    /**
     * @dev Returns amount of rewards per token
     * @param _rewardsToken is the reward token address
     * @param _supply is total locked tokens
     * @return amount of calculated rewards
     */
    function _rewardPerToken(
        address _rewardsToken,
        uint256 _supply
    ) internal view returns (uint256) {
        if (_supply == 0) {
            return rewardData[_rewardsToken].rewardPerTokenStored;
        }
        return
            rewardData[_rewardsToken].rewardPerTokenStored +
            (((lastTimeRewardApplicable(_rewardsToken) - rewardData[_rewardsToken].lastUpdateTime) *
                rewardData[_rewardsToken].rewardRate *
                SHARE_PRECISION) / _supply);
    }

    /**
     * @dev Returns current reward info
     * @param _user is the user address
     * @param _rewardsToken is the address of the reward token
     * @param _balance is the currently locked balance for the user
     * @param _currentRewardPerToken is the provided current reward per token
     * @return calculated reward balance
     */
    function _earned(
        address _user,
        address _rewardsToken,
        uint256 _balance,
        uint256 _currentRewardPerToken
    ) internal view returns (uint256) {
        return
            (_balance * (_currentRewardPerToken - userRewardPerTokenPaid[_user][_rewardsToken])) /
            SHARE_PRECISION +
            rewards[_user][_rewardsToken];
    }
}