// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IMinterFactory {
    function mintTo(address to, address tokenAddress) external;
}

contract ComboStakingV2 is Ownable {
    using SafeERC20 for IERC20;

    uint256 public minStakingValue = 250000 * 10 ** 18;
    bool public stakingEnabled = true;    
    
    enum StakingLevel {
        SIMPLE,
        UNCOMMON,
        RARE,
        EPIC,
        LEGENDARY
    }

    struct RewardRule {
        uint256 apr;
        uint256 period;
        address nftHero;
    }

    struct Staking {
        uint256 timestamp;
        uint256 amount;
        uint256 rewarded;
        StakingLevel targetLevel;
        StakingLevel rewardedLevel;
        bool isCompleted;
        bool isInitialized;
    }

    struct UserStaking {
        mapping(uint256 => Staking) stakings;
        mapping(uint256 => bool) activeStakings;
        uint256 stakingNumber;
    }

    mapping(address => UserStaking) private stakers;
    mapping(StakingLevel => RewardRule) public rewardRules;

    uint256 public totalStaked;
    IERC20 public taleToken;
    IMinterFactory public minterFactory;

    event Stake(address indexed staker, uint256 amount, StakingLevel targetLevel);
    event TaleReward(address indexed staker, uint256 amount, uint256 reward);
    event NftReward(address indexed staker, address taleHero);
    
    constructor(address _taleToken, address _minterFactory) {
        taleToken = IERC20(_taleToken);
        minterFactory = IMinterFactory(_minterFactory);
        rewardRules[StakingLevel.SIMPLE] = RewardRule(15, 15 days, address(0));
        rewardRules[StakingLevel.UNCOMMON] = RewardRule(30, 30 days, address(0));
        rewardRules[StakingLevel.RARE] = RewardRule(50, 50 days, address(0));
        rewardRules[StakingLevel.EPIC] = RewardRule(75, 75 days, address(0));
        rewardRules[StakingLevel.LEGENDARY] = RewardRule(100, 100 days, address(0));
    }

    /**
    * @notice Starts a new staking.
    *
    * @param amount Amount of tokens to stake.
    * @param targetLevel Type of staking, see StakingLevel enum and rewardRules.
    */
    function stake(uint256 amount, StakingLevel targetLevel) external {
        require(stakingEnabled, "TaleStaking: Staking disabled");
        require(amount >= minStakingValue, "TaleStaking: Amount less then the minimum staking value");
        address staker = _msgSender();

        //check erc20 balance and allowance
        require(taleToken.balanceOf(staker) >= amount, "TaleStaking: Insufficient tokens");
        require(taleToken.allowance(staker, address(this)) >= amount, "TaleStaking: Not enough tokens allowed");

        uint stakingId = stakers[staker].stakingNumber;    
        stakers[staker].stakingNumber = stakingId + 1;
        stakers[staker].stakings[stakingId] = Staking(block.timestamp, amount, 0, targetLevel, StakingLevel.SIMPLE, false, true);
        stakers[staker].activeStakings[stakingId] = true;

        totalStaked += amount;
        taleToken.safeTransferFrom(staker, address(this), amount);  

        emit Stake(staker, amount, targetLevel);
    }

    /**
    * @notice Pays rewards and withdraws the specified amount of tokens from staking. 
    *
    * @param stakingId Id of staking;
    */
    function claim(uint256 stakingId) external {
        address staker = _msgSender();
        Staking storage staking = stakers[staker].stakings[stakingId];        
        require(staking.isInitialized, "TaleStaking: Staking is not exists");
        require(!staking.isCompleted, "TaleStaking: Staking is completed");
        bool nftClaimed = claimNft(staking, staker);
        bool taleClaimed = claimTale(staking, stakingId, staker);
        require(nftClaimed || taleClaimed, "TaleStaking: Nothing to claim");
    }

    function claimTale(Staking storage staking, uint256 stakingId, address staker) private returns(bool cliamed) {
        RewardRule memory rewardRule = rewardRules[staking.targetLevel];
        if (block.timestamp >= staking.timestamp + rewardRule.period) {                    
            staking.isCompleted = true;       
            staking.rewarded = staking.amount * rewardRule.apr * rewardRule.period / 365 days / 100;
            delete stakers[staker].activeStakings[stakingId];
            
            totalStaked -= staking.amount;
            uint256 totalAmount = staking.amount + staking.rewarded;
            uint thisBalance = taleToken.balanceOf(address(this));
            require(thisBalance >= totalAmount, "TaleStaking: Insufficient funds in the pool");
            taleToken.safeTransfer(staker, totalAmount);
            cliamed = true;
            emit TaleReward(staker, staking.amount, staking.rewarded);
        }
    }

    function claimNft(Staking storage staking, address staker) private returns(bool cliamed) {
        uint256 stakingDuration = block.timestamp - staking.timestamp;
        for (uint256 i = uint256(staking.rewardedLevel)  + 1; i <= uint256(staking.targetLevel); ++i) {
            StakingLevel level = StakingLevel(i);
            RewardRule memory rule = rewardRules[level];
            if (stakingDuration >= rule.period) {
                staking.rewardedLevel = level;
                require(rule.nftHero != address(0), "TaleStaking: Hero unset");
                minterFactory.mintTo(staker, rule.nftHero);
                cliamed = true;
                emit NftReward(staker, rule.nftHero);
            } else {
                break;
            }       
        }
    }

    /**
    * @notice Returns the maximum available level for the user and staking
    *
    * @param user User address
    * @param stakingId Id of staking;
    */
    function getAvailableLevel(address user, uint256 stakingId) public view returns (StakingLevel) {
        Staking storage staking = stakers[user].stakings[stakingId];  
        StakingLevel availableLevel;        
        uint256 stakingDuration = block.timestamp - staking.timestamp;
        for (uint256 i = uint256(staking.rewardedLevel)  + 1; i < 5; ++i) {
            StakingLevel level = StakingLevel(i);
            RewardRule memory rule = rewardRules[level];
            if (rule.period <= stakingDuration) {
                availableLevel = level;
            } else {
                break;
            }       
        }

        return availableLevel;
    }

    /**
    * @notice Sets MinterFactory, only available to the owner
    *
    * @param factory Address of minter factory
    */
    function setMinterFactory(address factory) external onlyOwner {
        minterFactory = IMinterFactory(factory);
    }

    /**
    * @notice Sets hero staking rules for different levels
    */
    function setStakingRule(
        StakingLevel level, 
        uint256 apr, 
        uint256 period,
        address nftHero
        ) external onlyOwner {
        require(period >= 3600, "Period must be more then 3600");
        if (level == StakingLevel.SIMPLE) {
            require(nftHero == address(0), "Simple level shouldn't have a hero");
        } else {
            StakingLevel previousLevel = StakingLevel(uint(level) - 1);
            require(rewardRules[previousLevel].period < period, "The rule for a higher level must have a longer period than the previous level");
        }
        rewardRules[level] = RewardRule(apr, period, nftHero);
    }

    function setStakingEnabled(bool isEnabled) external onlyOwner {
        stakingEnabled = isEnabled;
    }

    /**
    * @notice Sets the minimum staking value
    *
    * @param value Minimum value
    */
    function setMinStakingValue(uint256 value) external onlyOwner {
        minStakingValue = value;
    }

    /**
    * @notice Withdraws tokens from the pool. 
    *         Available only to the owner of the contract.
    *
    * @param to Address where tokens will be withdrawn
    * @param amount Amount of tokens to withdraw.
    */
    function withdraw(address to, uint256 amount) external onlyOwner {
        require(getPoolSize() >= amount, "TaleStaking: Owner can't withdraw more than pool size");
        taleToken.safeTransfer(to, amount);
    }

    /**
    * @notice Returns the current number of tokens in the pool
    */
    function getPoolSize() public view returns(uint256) {
        uint256 balance = taleToken.balanceOf(address(this));
        return balance - totalStaked;
    }

    /**
    * @notice Returns active staking indexes for the specified user
    *
    * @param user Address for which indexes will be returned
    */
    function getActiveStakingIndexes(address user) external view returns(uint256[] memory) {
        uint256 activeStakingsCount = getActiveStakingCount(user);
        uint256[] memory result = new uint256[](activeStakingsCount);
        uint256 j = 0;
        for (uint256 i = 0; i < stakers[user].stakingNumber; ++i) {
            if (stakers[user].activeStakings[i]) {
                result[j] = i;
                ++j;
            }
        }
        return result;
    }

    /**
    * @notice Returns staking for the specified user and index
    *
    * @param user Address for which indexes will be returned
    * @param stakingIndex Index of the staking
    */
    function getStaking(address user, uint256 stakingIndex) external view returns(Staking memory) {
        Staking memory staking = stakers[user].stakings[stakingIndex];        
        require(staking.isInitialized, "TaleStaking: Staking is not exists");
        return staking;
    }

   /**
    * @notice Returns the number of all stakings for the user
    *
    * @param user The user whose number of stakings will be returned
    */
    function getAllStakingCount(address user) public view returns(uint256) {
        return stakers[user].stakingNumber;
    }

   /**
    * @notice Returns the number of active stakings for the user
    *
    * @param user The user whose number of stakings will be returned
    */
    function getActiveStakingCount(address user) public view returns(uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < stakers[user].stakingNumber; ++i) {
            if (stakers[user].activeStakings[i]) {
                ++count;
            }
        }
        return count;
    }
}