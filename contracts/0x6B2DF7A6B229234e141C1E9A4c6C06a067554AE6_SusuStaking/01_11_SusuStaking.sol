// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IERC721SU.sol";
import "./utils/SafeArray.sol";

contract SusuStaking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeArray for uint256[];

    // Interfaces for ERC20 and ERC721SU
    IERC20 public rewardsToken;
    IERC721SU public nftCollection;

    // Staker info
    struct Staker {
        uint256 amountStaked;
        uint256[] stakedTokens;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
    }

    // Stake reward time, default end time 2025.01.01
    uint256 public stakeEndTime = 1735689600;
    uint256 public stakeStartTime = 0;

    bool public stakeActive = true;
    bool public claimRewardsActive = true;

    // Staking Time
    uint256 public constant LOCK_TIME_ZERO = 0;
    uint256 public constant LOCK_TIME_ONE = 30 days;
    uint256 public constant LOCK_TIME_TWO = 180 days;
    uint256 public constant LOCK_TIME_THREE = 360 days;

    // Lock type
    enum LockType {
        LOCK_ZERO,
        LOCK_ONE,
        LOCK_TWO,
        LOCK_THREE
    }

    // Rewards Base Bips
    uint256 public constant PERCENT_BASE_BIPS = 100;
    uint256 public GOLD_EXTRA_BIPS = 6;
    uint256 public BIPS_ZERO = 30;
    uint256 public BIPS_ONE = 100;
    uint256 public BIPS_TWO = 200;
    uint256 public BIPS_THREE = 300;

    // Lock info
    struct LockInfo {
        uint256 unlockTime;
        uint256 lockTime;
        LockType lockType;
    }

    // Rewards per hour per token deposited in wei.
    // Rewards are cumulated once every hour.
    uint256 private rewardsPerHour = 416 * 1e14;

    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;
    // Mapping of Token Id to staker. Made for the SC to remeber
    // who to send back the ERC721 Token to.
    mapping(uint256 => address) public stakerAddress;
    // Mapping of Token Id to lock info.
    mapping(uint256 => LockInfo) public stakerLockInfo;

    address[] public stakersArray;

    /// @notice event emitted when a user claim rewards
    event ClaimReward(address owner, uint256 amount);
    /// @notice event emitted when a user stake ERC721 tokens
    event StakeTokens(address owner, uint256[] tokenId, LockType _lockType);
    /// @notice event emitted when a user withdraw ERC721 tokens
    event WithdrawTokens(address owner, uint256[] tokenId);

    constructor() {
        rewardsToken = IERC20(0xc9A06e920e160f63A7576aB3c5B693b0ef10A82f);
        nftCollection = IERC721SU(0x29e0A58F62A34a29965ac5c64f5F3c792bEe7A9a);
        stakeStartTime = block.timestamp;
    }

    function stake(uint256[] calldata _tokenIds, LockType _lockType)
        external
        nonReentrant
    {
        require(stakeActive, "Stake is not active");
        if (stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        } else {
            stakersArray.push(msg.sender);
        }
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            require(
                nftCollection.ownerOf(_tokenIds[i]) == msg.sender,
                "Can't stake tokens you don't own!"
            );
            nftCollection.transferFrom(msg.sender, address(this), _tokenIds[i]);
            stakers[msg.sender].stakedTokens.push(_tokenIds[i]);
            stakerLockInfo[_tokenIds[i]].lockType = _lockType;
            stakerLockInfo[_tokenIds[i]].lockTime = getStakeLockTime(_lockType);
            stakerLockInfo[_tokenIds[i]].unlockTime =
                block.timestamp +
                getStakeLockTime(_lockType);
            stakerAddress[_tokenIds[i]] = msg.sender;
        }
        stakers[msg.sender].amountStaked += len;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        emit StakeTokens(msg.sender, _tokenIds, _lockType);
    }

    function withdraw(uint256[] calldata _tokenIds)
        external
        nonReentrant
        beforeWithdrawCheck(_tokenIds)
    {
        require(
            stakers[msg.sender].amountStaked > 0,
            "You have no tokens staked"
        );
        uint256 rewards = calculateRewards(msg.sender);
        stakers[msg.sender].unclaimedRewards += rewards;
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            require(stakerAddress[_tokenIds[i]] == msg.sender);
            stakerAddress[_tokenIds[i]] = address(0);
            nftCollection.transferFrom(address(this), msg.sender, _tokenIds[i]);
            stakers[msg.sender].stakedTokens.removeElement(_tokenIds[i]);
            stakerLockInfo[_tokenIds[i]].lockType = LockType.LOCK_ZERO;
            stakerLockInfo[_tokenIds[i]].lockTime = 0;
            stakerLockInfo[_tokenIds[i]].unlockTime = 0;
        }
        stakers[msg.sender].amountStaked -= len;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        if (stakers[msg.sender].amountStaked == 0) {
            for (uint256 i; i < stakersArray.length; ++i) {
                if (stakersArray[i] == msg.sender) {
                    stakersArray[i] = stakersArray[stakersArray.length - 1];
                    stakersArray.pop();
                }
            }
        }
        emit WithdrawTokens(msg.sender, _tokenIds);
    }

    function claimRewards() external nonReentrant {
        require(claimRewardsActive, "Claim rewards is not active");
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;
        rewardsToken.safeTransfer(msg.sender, rewards);
        emit ClaimReward(msg.sender, rewards);
    }

    //////////
    // Admin//
    //////////

    function setRewardsPerHour(uint256 _newValue) external onlyOwner {
        rewardsPerHour = _newValue;
    }

    function setGoldExtraBips(uint256 _bips) external onlyOwner {
        GOLD_EXTRA_BIPS = _bips;
    }

    function setStakeTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(
            _endTime >= _startTime,
            "Start time cannot be greater than end time"
        );
        stakeStartTime = _startTime;
        stakeEndTime = _endTime;
    }

    function setAllStakeBips(
        uint256 _zero,
        uint256 _one,
        uint256 _two,
        uint256 _three
    ) external onlyOwner {
        BIPS_ZERO = _zero;
        BIPS_ONE = _one;
        BIPS_TWO = _two;
        BIPS_THREE = _three;
    }

    function setRewardsToken(IERC20 _rewardsToken) external onlyOwner {
        rewardsToken = _rewardsToken;
    }

    function setNftCollection(IERC721SU _nftCollection) external onlyOwner {
        nftCollection = _nftCollection;
    }

    function toggleStakeActive() external onlyOwner {
        stakeActive = !stakeActive;
    }

    function withdrawToken(uint256 _amount) external onlyOwner {
        rewardsToken.safeTransfer(msg.sender, _amount);
    }

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Urgent withdraw will not calculate users rewards
    function urgentWithdrawByUsers(address[] calldata _users)
        external
        onlyOwner
    {
        uint256 userLen = _users.length;
        for (uint256 i; i < userLen; ++i) {
            address userAddress = _users[i];
            require(
                stakers[userAddress].amountStaked > 0,
                "Has user have no tokens staked"
            );
            uint256 tokensLen = stakers[userAddress].amountStaked;
            for (uint256 j; j < tokensLen; ++j) {
                uint256 tokenId = stakers[userAddress].stakedTokens[j];
                stakerAddress[tokenId] = address(0);
                nftCollection.transferFrom(address(this), userAddress, tokenId);
                stakerLockInfo[tokenId].lockType = LockType.LOCK_ZERO;
                stakerLockInfo[tokenId].lockTime = 0;
                stakerLockInfo[tokenId].unlockTime = 0;
            }
            stakers[userAddress].amountStaked -= tokensLen;
            if (stakers[userAddress].amountStaked == 0) {
                for (uint256 j; j < stakersArray.length; ++j) {
                    if (stakersArray[j] == userAddress) {
                        stakersArray[j] = stakersArray[stakersArray.length - 1];
                        stakersArray.pop();
                    }
                }
            }
            emit WithdrawTokens(userAddress, stakers[userAddress].stakedTokens);
            delete stakers[userAddress].stakedTokens;
        }
    }

    //////////
    // View //
    //////////

    function userStakeInfo(address _user)
        public
        view
        returns (
            uint256 _amountStaked,
            uint256 _availableRewards,
            uint256[] memory _stakedTokens
        )
    {
        return (
            stakers[_user].amountStaked,
            availableRewards(_user),
            stakers[_user].stakedTokens
        );
    }

    function availableRewards(address _user) internal view returns (uint256) {
        if (stakers[_user].amountStaked == 0) {
            return stakers[_user].unclaimedRewards;
        }
        uint256 _rewards = stakers[_user].unclaimedRewards +
            calculateRewards(_user);
        return _rewards;
    }

    /////////////
    // Internal//
    /////////////

    function isGoldPass(uint256 _tokenId) internal view returns (bool) {
        string memory level = nftCollection.getPassLevel(_tokenId);
        if (
            keccak256(abi.encodePacked(level)) ==
            keccak256(abi.encodePacked("Gold"))
        ) {
            return true;
        }
        return false;
    }

    function getStakeLockTime(LockType _lock) internal pure returns (uint256) {
        if (_lock == LockType.LOCK_ONE) {
            return LOCK_TIME_ONE;
        } else if (_lock == LockType.LOCK_TWO) {
            return LOCK_TIME_TWO;
        } else if (_lock == LockType.LOCK_THREE) {
            return LOCK_TIME_THREE;
        }
        return LOCK_TIME_ZERO;
    }

    // Reward bips per second
    function getRewardBips(uint256 _tokenId) internal view returns (uint256) {
        LockType lockType = stakerLockInfo[_tokenId].lockType;
        uint256 rewardBips = 0;
        if (lockType == LockType.LOCK_ZERO) {
            rewardBips =
                (rewardsPerHour * BIPS_ZERO) /
                PERCENT_BASE_BIPS /
                3600;
        } else if (lockType == LockType.LOCK_ONE) {
            rewardBips = (rewardsPerHour * BIPS_ONE) / PERCENT_BASE_BIPS / 3600;
        } else if (lockType == LockType.LOCK_TWO) {
            rewardBips = (rewardsPerHour * BIPS_TWO) / PERCENT_BASE_BIPS / 3600;
        } else if (lockType == LockType.LOCK_THREE) {
            rewardBips =
                (rewardsPerHour * BIPS_THREE) /
                PERCENT_BASE_BIPS /
                3600;
        }
        if (isGoldPass(_tokenId)) {
            rewardBips = rewardBips * GOLD_EXTRA_BIPS;
        }
        return rewardBips;
    }

    // Because the rewards are calculated passively, the owner has to first update the rewards
    // to all the stakers, witch could result in very heavy load and expensive transactions or
    // even reverting due to reaching the gas limit per block. Redesign incoming to bound loop.
    function calculateAllStakerReward() public onlyOwner {
        address[] memory _stakers = stakersArray;
        uint256 len = _stakers.length;
        for (uint256 i; i < len; ++i) {
            address user = _stakers[i];
            stakers[user].unclaimedRewards += calculateRewards(user);
            stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        }
    }

    function getCalculateTime(uint256 _timeOfLastUpdate)
        internal
        view
        returns (uint256)
    {
        uint256 startTime;
        uint256 endTime;
        if (block.timestamp > stakeEndTime) {
            endTime = stakeEndTime;
        } else {
            endTime = block.timestamp;
        }
        if (_timeOfLastUpdate < stakeStartTime) {
            startTime = stakeStartTime;
        } else {
            startTime = _timeOfLastUpdate;
        }
        if (endTime > startTime) {
            return endTime - startTime;
        }
        return 0;
    }

    function calculateRewards(address _staker)
        internal
        view
        returns (uint256 _rewards)
    {
        Staker memory staker = stakers[_staker];
        uint256 totalBips = 0;
        for (uint256 i; i < staker.stakedTokens.length; ++i) {
            totalBips += getRewardBips(staker.stakedTokens[i]);
        }
        return getCalculateTime(staker.timeOfLastUpdate) * totalBips;
    }

    /////////////
    // Modifier//
    /////////////

    modifier beforeWithdrawCheck(uint256[] calldata _tokenIds) {
        Staker memory staker = stakers[msg.sender];
        for (uint256 i; i < _tokenIds.length; ++i) {
            require(
                block.timestamp > stakerLockInfo[_tokenIds[i]].unlockTime,
                "Has token in unlock time"
            );
        }
        _;
    }
}