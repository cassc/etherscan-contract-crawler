// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../libraries/Errors.sol";
import "../interfaces/IBentCVXRewarder.sol";

contract BentCVXRewarderV2 is Ownable, ReentrancyGuard, IBentCVXRewarder {
    using SafeERC20 for IERC20;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event ClaimAll(address indexed user);
    event Claim(address indexed user, uint256[] pids);

    struct PoolData {
        address rewardToken;
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e36. See below.
        uint256 rewardRate;
        uint256 reserves;
    }

    address public bentCVXStaking;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    uint256 public rewardPoolsCount;
    mapping(uint256 => PoolData) public rewardPools;
    mapping(address => bool) public isRewardToken;
    mapping(uint256 => mapping(address => uint256)) internal userRewardDebt;
    mapping(uint256 => mapping(address => uint256)) internal userPendingRewards;

    uint256 public windowLength; // amount of blocks where we assume around 12 sec per block
    uint256 public minWindowLength = 7200; // minimum amount of blocks where 7200 = 1 day
    uint256 public endRewardBlock; // end block of rewards stream
    uint256 public lastRewardBlock; // last block of rewards streamed
    uint256 public harvesterFee = 0; // percentage fee to onReward caller where 100 = 1%

    modifier onlyBentCVXStaking() {
        require(bentCVXStaking == _msgSender(), Errors.UNAUTHORIZED);
        _;
    }

    constructor(
        address _bentCVXStaking,
        address[] memory _rewardTokens,
        uint256 _windowLength
    ) {
        bentCVXStaking = _bentCVXStaking;
        addRewardTokens(_rewardTokens);
        windowLength = _windowLength;
    }

    function setHarvesterFee(uint256 _fee) public onlyOwner {
        require(_fee <= 100, Errors.EXCEED_MAX_HARVESTER_FEE);
        harvesterFee = _fee;
    }

    function setWindowLength(uint256 _windowLength) public onlyOwner {
        require(_windowLength >= minWindowLength, Errors.INVALID_WINDOW_LENGTH);
        windowLength = _windowLength;
    }

    function addRewardTokens(address[] memory _rewardTokens) public onlyOwner {
        uint256 length = _rewardTokens.length;
        for (uint256 i = 0; i < length; ++i) {
            require(!isRewardToken[_rewardTokens[i]], Errors.ALREADY_EXISTS);
            rewardPools[rewardPoolsCount + i].rewardToken = _rewardTokens[i];
            isRewardToken[_rewardTokens[i]] = true;
        }
        rewardPoolsCount += length;
    }

    function removeRewardToken(uint256 _index) external onlyOwner {
        require(_index < rewardPoolsCount, Errors.INVALID_INDEX);

        isRewardToken[rewardPools[_index].rewardToken] = false;
        delete rewardPools[_index];
    }

    function pendingReward(address user)
        external
        view
        returns (uint256[] memory pending)
    {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        pending = new uint256[](_rewardPoolsCount);

        if (totalSupply != 0) {
            uint256[] memory addedRewards = _calcAddedRewards();
            for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
                PoolData memory pool = rewardPools[i];
                if (pool.rewardToken == address(0)) {
                    continue;
                }
                uint256 newAccRewardPerShare = pool.accRewardPerShare +
                    ((addedRewards[i] * 1e36) / totalSupply);

                pending[i] =
                    userPendingRewards[i][user] +
                    ((balanceOf[user] * newAccRewardPerShare) / 1e36) -
                    userRewardDebt[i][user];
            }
        }
    }

    function deposit(address _user, uint256 _amount)
        external
        override
        onlyBentCVXStaking
    {
        require(_amount != 0, Errors.ZERO_AMOUNT);

        _updateAccPerShare(true, _user);

        _mint(_user, _amount);

        _updateUserRewardDebt(_user);

        emit Deposit(_user, _amount);
    }

    function withdraw(address _user, uint256 _amount)
        external
        override
        onlyBentCVXStaking
    {
        require(
            balanceOf[_user] >= _amount && _amount != 0,
            Errors.INVALID_AMOUNT
        );

        _updateAccPerShare(true, _user);

        _burn(_user, _amount);

        _updateUserRewardDebt(_user);

        emit Withdraw(_user, _amount);
    }

    function claimAll(address _user)
        external
        override
        nonReentrant
        returns (bool claimed)
    {
        _updateAccPerShare(true, _user);

        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            uint256 claimAmount = _claim(i, _user);
            if (claimAmount > 0) {
                claimed = true;
            }
        }

        _updateUserRewardDebt(_user);

        emit ClaimAll(_user);
    }

    function claim(address _user, uint256[] memory pids)
        external
        override
        nonReentrant
        returns (bool claimed)
    {
        _updateAccPerShare(true, _user);

        for (uint256 i = 0; i < pids.length; ++i) {
            uint256 claimAmount = _claim(pids[i], _user);
            if (claimAmount > 0) {
                claimed = true;
            }
        }

        _updateUserRewardDebt(_user);

        emit Claim(_user, pids);
    }

    function onReward() external nonReentrant {
        _updateAccPerShare(false, address(0));

        bool newRewardsAvailable = false;
        for (uint256 i = 0; i < rewardPoolsCount; ++i) {
            PoolData storage pool = rewardPools[i];
            if (pool.rewardToken == address(0)) {
                continue;
            }

            uint256 newRewards = IERC20(pool.rewardToken).balanceOf(
                address(this)
            ) - pool.reserves;
            uint256 newRewardsFees = (newRewards * harvesterFee) / 10000;
            uint256 newRewardsFinal = newRewards - newRewardsFees;

            if (newRewardsFinal > 0) {
                newRewardsAvailable = true;
            }

            if (endRewardBlock > lastRewardBlock) {
                pool.rewardRate =
                    (pool.rewardRate *
                        (endRewardBlock - lastRewardBlock) +
                        newRewardsFinal *
                        1e36) /
                    windowLength;
            } else {
                pool.rewardRate = (newRewardsFinal * 1e36) / windowLength;
            }

            pool.reserves += newRewardsFinal;

            if (newRewardsFees > 0) {
                IERC20(pool.rewardToken).transfer(msg.sender, newRewardsFees);
            }
        }

        require(newRewardsAvailable, Errors.ZERO_AMOUNT);

        endRewardBlock = lastRewardBlock + windowLength;
    }

    function updateReserve() external nonReentrant onlyOwner {
        for (uint256 i = 0; i < rewardPoolsCount; ++i) {
            PoolData storage pool = rewardPools[i];
            if (pool.rewardToken == address(0)) {
                continue;
            }

            pool.reserves = IERC20(pool.rewardToken).balanceOf(address(this));
        }
    }

    // Internal Functions

    function _updateAccPerShare(bool withdrawReward, address user) internal {
        uint256[] memory addedRewards = _calcAddedRewards();
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            PoolData storage pool = rewardPools[i];
            if (pool.rewardToken == address(0)) {
                continue;
            }

            if (totalSupply == 0) {
                pool.accRewardPerShare = block.number;
            } else {
                pool.accRewardPerShare +=
                    (addedRewards[i] * (1e36)) /
                    totalSupply;
            }

            if (withdrawReward) {
                uint256 pending = ((balanceOf[user] * pool.accRewardPerShare) /
                    1e36) - userRewardDebt[i][user];

                if (pending > 0) {
                    userPendingRewards[i][user] += pending;
                }
            }
        }

        lastRewardBlock = block.number;
    }

    function _calcAddedRewards()
        internal
        view
        returns (uint256[] memory addedRewards)
    {
        uint256 startBlock = endRewardBlock > lastRewardBlock + windowLength
            ? endRewardBlock - windowLength
            : lastRewardBlock;
        uint256 endBlock = block.number > endRewardBlock
            ? endRewardBlock
            : block.number;
        uint256 duration = endBlock > startBlock ? endBlock - startBlock : 0;

        uint256 _rewardPoolsCount = rewardPoolsCount;
        addedRewards = new uint256[](_rewardPoolsCount);
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            addedRewards[i] = (rewardPools[i].rewardRate * duration) / 1e36;
        }
    }

    function _updateUserRewardDebt(address user) internal {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            if (rewardPools[i].rewardToken != address(0)) {
                userRewardDebt[i][user] =
                    (balanceOf[user] * rewardPools[i].accRewardPerShare) /
                    1e36;
            }
        }
    }

    function _claim(uint256 pid, address user)
        internal
        returns (uint256 claimAmount)
    {
        if (rewardPools[pid].rewardToken == address(0)) {
            return 0;
        }

        claimAmount = userPendingRewards[pid][user];
        if (claimAmount > 0) {
            IERC20(rewardPools[pid].rewardToken).safeTransfer(
                user,
                claimAmount
            );
            rewardPools[pid].reserves -= claimAmount;
            userPendingRewards[pid][user] = 0;
        }
    }

    function _mint(address _user, uint256 _amount) internal {
        balanceOf[_user] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _user, uint256 _amount) internal {
        balanceOf[_user] -= _amount;
        totalSupply -= _amount;
    }
}