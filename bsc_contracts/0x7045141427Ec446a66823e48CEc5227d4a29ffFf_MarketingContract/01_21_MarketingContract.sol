// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MarketingNFTStaking.sol";

contract MarketingContract is Ownable {
    using SafeMath for uint256;

    IERC20 public busd;
    MarketingNFTStaking public nftStaking;

    Pool[4] public LOTTERY_POOLS;
    uint256[] public INCOME_PERCENTS = [
    10, // 1%,
    11, // 1.1%
    12, // 1.2%;
    13, // 1.3;
    14, // 1.4%;
    15  // 1.5%;
    ];
    uint256[] public REF_LEVEL_PERCENT = [
    60, // 6%
    30, // 3%
    15, // 1.5%
    10, // 1%
    5, // 0.5%
    3, // 0.3%
    3, // 0.3%
    3, // 0.3%
    3, // 0.3%
    3, // 0.3%
    3, // 0.3%
    3, // 0.3%
    3, // 0.3%
    3, // 0.3%
    3 // 0.3%
    ];
    uint256[] public DAILY_BONUS_PERCENT = [
    200, // 20%
    70, // 7%
    70, // 7%
    70, // 7%
    70, // 7%
    50, // 5%
    50, // 5%
    50, // 5%
    50, // 5%
    50, // 5%
    30, // 3%
    30, // 3%
    30, // 3%
    30, // 3%
    30, // 3%
    20, // 2%
    20, // 2%
    20, // 2%
    20, // 2%
    20 // 2%
    ];

    uint256 public ONE_DAY = 86400;
    uint256 public ONE_WEEK = 604800;
    uint256 public MIN_DEPOSIT = 20 ether;
    uint256 public MAX_START_DEPOSIT = 2000 ether;
    uint256 public MAX_DEPOSIT = 1000000 ether;
    uint256 public MIN_WITHDRAW = 1 ether;
    uint256 public MIN_WITHDRAW_LIMIT = 100 ether;
    uint256 public MAX_REF_LEVEL = REF_LEVEL_PERCENT.length;
    uint256 public TOTAL_REF_PERCENT = 150; // 15%
    uint256 public PERCENT_MULTIPLIER = 10;
    uint256 public REWARD_EPOCH_SECONDS = ONE_DAY;
    uint256 public TOP_USERS_DISTRIBUTION_PERCENT = 10; // 1%
    uint256 public MAX_DAILY_BONUS_LEVEL = DAILY_BONUS_PERCENT.length;
    uint256 public TOTAL_DAILY_BONUS_PERCENT = 980; // 98%
    uint256 public POOL_WINNERS_AMOUNT = 10;
    uint256 public POOL_DISTRIBUTION_PERC = 10;
    uint256 public POOL_ENTER_FEE = 1 ether;
    uint256 public DEPOSIT_FEE_PERCENT = 50; // 5%

    struct RoundUserStats {
        uint256 amount;
    }
    struct Pool {
        uint8 usersAmount;
        uint8 maxUsersAmount;
        uint32 gambleRound;
        uint256 liquidity;
        uint256 totalPrize;
        uint256 extraLiquidity;
        uint256 minDeposit;
    }
    struct User {
        address _address;
        address inviter;
        uint256 deposit;
        uint256 lastDeposit;
        uint256 totalDeposit;
        uint256 totalRefs;
        uint256 totalRefIncome;
        uint256 rewards;
        uint256 claimedRewards;
        uint256 claimedNftRewards;
        uint256 lastClaim;
        uint256 missedRewards;
    }

    uint256 private nonce = 1;
    address[] private uniqueUserAddresses;

    uint256 public distributionRound;
    bool public initialized = false;
    uint256 public initializedAt;
    address public top;
    address public devAddress;
    uint256 public usersTotal = 0;

    mapping (address => mapping(uint256 => uint256)) private referralsIncome;
    mapping (address => mapping(uint256 => uint256)) private referralsCount;
    mapping (uint256 => mapping(address => RoundUserStats)) private roundDeposits;
    mapping (uint256 => address[5]) private topRoundAddresses;
    mapping (uint256 => uint256) private totalRoundDeposits;
    //mapping(poolIndex => poolUsers)
    mapping(uint256 => address[]) private poolUsers;

    mapping (address => User) public users;
    //mapping(poolIndex => mapping(gambleRound => mapping(userAddress => bool));
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public poolGambleRoundUsers;

    modifier whenInitialized() {
        require(initialized, "NOT INITIALIZED");
        _;
    }

    event Deposit(address indexed _address, uint256 amount, address indexed inviter);
    event Withdraw(address indexed _address, uint256 amount);
    event RefReward(address indexed _address, uint256 amount, uint256 level, address sender);
    event RefRewardMiss(address indexed _address, uint256 amount, uint256 level, address sender);
    event DailyBonusReward(address indexed _address, uint256 amount, uint256 level, address sender);
    event DailyBonusRewardMiss(address indexed _address, uint256 amount, uint256 level, address sender);
    event DailyDistributionRewards(address indexed _address, uint256 amount);
    event DailyDistributionRewardMiss(address indexed _address, uint256 amount);
    event PoolGamblingWinners(uint256 round, uint256 poolIndex, address[] winners);
    event PoolGamblingReward(address indexed winner, uint256 amount, uint256 round, uint256 poolIndex);
    event PoolGamblingRewardMiss(address indexed winner, uint256 amount, uint256 round, uint256 poolIndex);
    event IncomeMiss(address indexed _address, uint256 amount);

    constructor(address _devAddress, address busdAddress) {
        devAddress = _devAddress;
        busd = IERC20(busdAddress);
        LOTTERY_POOLS[0] = Pool(0, 200, 0, 0, 50 ether, 0, 0);
        LOTTERY_POOLS[1] = Pool(0, 100, 0, 0, 100 ether, 0, 200 ether);
        LOTTERY_POOLS[2] = Pool(0, 50, 0, 0, 500 ether, 0, 1000 ether);
        LOTTERY_POOLS[3] = Pool(0, 50, 0, 0, 1000 ether, 0, 2000 ether);
    }

    fallback() external payable {
        // custom function code
        payable (msg.sender).transfer(msg.value);
    }

    receive() external payable {
        // custom function code
        payable (msg.sender).transfer(msg.value);
    }

    // set nft distribution rewards
    function setNftStaking(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "EMPTY ADDRESS");
        nftStaking = MarketingNFTStaking(contractAddress);
    }

    /**
    * @param inviter - address of a person who sent invitation
    * @param amount - deposit amount. Contract uses erc20 for rewards
    * @dev this function increments user deposit, totalDeposit and distributes
    * all extra rewards: referral, top users, nft staking
    */
    function deposit(address inviter, uint256 amount) external whenInitialized {
        User storage user = users[msg.sender];

        if (users[msg.sender].inviter != address(0) || msg.sender == top) {
            inviter = users[msg.sender].inviter;
        }

        if (msg.sender != top) {
            require(users[inviter]._address != address(0), "INVITER MUST EXIST");
        }


        uint256 withdrawLimit = getWithdrawLimit(msg.sender);
        require(user.claimedRewards == withdrawLimit, "CANT PROCEED TO NEXT ROUND");
        
        require(amount >= getMinDeposit(msg.sender), "DEPOSIT MINIMUM VALUE");
        require(amount <= getMaxDeposit(msg.sender), "DEPOSIT IS HIGHER THAN MAX DEPOSIT");

        busd.transferFrom(msg.sender, address(this), amount);

        bool isFirstDeposit = !(user.totalDeposit > 0);

        if(isFirstDeposit) {
            uniqueUserAddresses.push(msg.sender);
            user._address = msg.sender;
            usersTotal++;
            user.inviter = inviter;
        }

        distributeRefFees(amount, inviter, isFirstDeposit);

        user.lastClaim = 0;
        user.lastDeposit = block.timestamp;
        user.deposit = amount;
        user.totalDeposit = SafeMath.add(user.totalDeposit, amount);
        user.claimedRewards = 0;

        emit Deposit(msg.sender, amount, inviter);

        uint256 depositFee = getPercentFromNumber(amount, DEPOSIT_FEE_PERCENT, PERCENT_MULTIPLIER);
        busd.transfer(devAddress, depositFee);
        distributeRewards(amount, 0);
    }

    /**
    * @dev withdraw users rewards
    * withdraw amount should be more than MIN_WITHDRAW and less than withdrawLimit
    * all extra rewards accounted: referral, top users, nft staking
    *
    * @dev distributes fee to devAddress
    */
    function withdraw() external whenInitialized {
        User storage user = users[msg.sender];

        (
            uint256 incomeValue,
            uint256 nftValue,
            uint256 withdrawLimit,
            uint256 missedIncome
        ) = getIncomeSinceLastClaim(msg.sender);
        require(incomeValue > MIN_WITHDRAW, "REWARDS TOO LOW");
        require(user.claimedRewards < withdrawLimit, "WITHDRAW LIMIT REACHED");

        require(getBalance() >= incomeValue, "NOT ENOUGH BALANCE");
        
        uint256 withdrawFee = getPercentFromNumber(incomeValue, getWithdrawPercent(msg.sender), PERCENT_MULTIPLIER);
        uint256 restAmount = incomeValue.sub(withdrawFee);
        
        user.claimedRewards = SafeMath.add(user.claimedRewards, incomeValue);
        user.claimedNftRewards = SafeMath.add(user.claimedNftRewards, nftValue);
        user.rewards = 0;
        user.lastClaim = block.timestamp;

        busd.transfer(devAddress, withdrawFee);
        busd.transfer(msg.sender, restAmount);
        
        emit Withdraw(msg.sender, restAmount);

        if (missedIncome > 0) {
            emit IncomeMiss(msg.sender, missedIncome);
        }

        distributeDailyMatchingBonus(restAmount, msg.sender);

        distributeRewards(0, restAmount);
    }

    /**
    * @dev logs msg.sender address to pool with index poolIndex
    * @dev gamble will starts when
    * pool.liquidity == pool.totalPrize && pool.usersAmount == pool.maxUsersAmount
    */
    function takePartInPool(uint256 poolIndex) external {
        require(poolIndex < LOTTERY_POOLS.length, "ONLY 4 POOLS EXIST");
        User memory user = users[msg.sender];
        Pool storage pool = LOTTERY_POOLS[poolIndex];
        require(user.deposit >= pool.minDeposit, "DEPOSIT TOO SMALL");
        require(pool.usersAmount < pool.maxUsersAmount, "ALREADY FULL USER PACK");
        require(user.totalDeposit > 0, "TOTAL DEPOSIT 0");
        //mapping(poolIndex => mapping(gambleRound => mapping(userAddress => bool));
        require(!poolGambleRoundUsers[poolIndex][pool.gambleRound][user._address], "ALREADY PARTICIPATING");
        if (getPoolEntersAmount(user._address, poolIndex) > 10) {
            busd.transfer(devAddress, POOL_ENTER_FEE);
        }
        if (pool.gambleRound == 0) {
            poolUsers[poolIndex].push(user._address);
        } else {
            poolUsers[poolIndex][pool.usersAmount] = user._address;
        }
        pool.usersAmount++;
        poolGambleRoundUsers[poolIndex][pool.gambleRound][user._address] = true;
        if(pool.liquidity == pool.totalPrize && pool.usersAmount == pool.maxUsersAmount) {
            handleLottery(poolIndex);
        }
    }

    function distributeRewards(uint256 depositAmount, uint256 withdrawAmount) internal {
        distributeRewardsByTopDeposits(depositAmount);
        fillLotteryPools(depositAmount > withdrawAmount ? depositAmount : withdrawAmount);
    }

    /**
    * @dev distributes reward to addresses which exist in topRoundAddresses mapping.
    * @dev if depositAmount > 0 checks whether depositAmount is larger
    * than deposits of users in topRoundAddresses. If so, place msg.sender to topRoundAddresses
    * @dev increment round if initializedAt + distributionRound.mul(ONE_DAY) < block.timestamp
    */
    function distributeRewardsByTopDeposits(uint256 depositAmount) internal {
        if(initializedAt + distributionRound.mul(ONE_DAY) < block.timestamp) {
            increaseDailyDistributionRound();
        }

        if (depositAmount > 0) {
            roundDeposits[distributionRound][msg.sender].amount += depositAmount;
            totalRoundDeposits[distributionRound] += depositAmount;
            replaceTopUsers();
        }
    }

    /**
    * @dev replace top users if msg.sender's deposit is large enough
    */
    function replaceTopUsers() private {
        uint256 index = 5;
        address[5] memory currentTopRoundAddresses = topRoundAddresses[distributionRound];
        while(index > 0) {
            if (
                roundDeposits[distributionRound][msg.sender].amount >
                roundDeposits[distributionRound][currentTopRoundAddresses[index - 1]].amount
            ) {
                index--;
            } else {
                break;
            }
        }
        if (index < 5) {
            for (uint256 i = 4; i > index; i--) {
                topRoundAddresses[distributionRound][i] = topRoundAddresses[distributionRound][i - 1];
            }
            topRoundAddresses[distributionRound][index] = msg.sender;
        }
    }

    /**
    * @dev distributes reward to addresses which exist in topRoundAddresses mapping.
    * @dev increment round if initializedAt + distributionRound.mul(ONE_DAY) < block.timestamp
    */
    function increaseDailyDistributionRound() private {
        require(initializedAt + SafeMath.mul(distributionRound, ONE_DAY) < block.timestamp, "TOO EARLY FOR STARTING NEW ROUND");
        distributeRoundIncentivesToTopUsers();
        distributionRound++;
    }

    /**
    * @dev distributes reward to addresses which exist in topRoundAddresses mapping.
    */
    function distributeRoundIncentivesToTopUsers() private {
        address[5] memory _topRoundAddresses = topRoundAddresses[distributionRound];
        uint256 rewardsAmount = getPercentFromNumber(
            totalRoundDeposits[distributionRound],
                TOP_USERS_DISTRIBUTION_PERCENT,
                PERCENT_MULTIPLIER
        );
        for (uint256 i = 0; i < _topRoundAddresses.length; i++) {
            if (_topRoundAddresses[i] != address(0)) {
                (uint256 safeRewardAmount, uint256 missedRewards) = safeRewardTransfer(
                    _topRoundAddresses[i],
                    rewardsAmount
                );
                if (safeRewardAmount > 0) {
                    emit DailyDistributionRewards(_topRoundAddresses[i], safeRewardAmount);
                }
                if (missedRewards > 0) {
                    emit DailyDistributionRewardMiss(_topRoundAddresses[i], missedRewards);
                    users[_topRoundAddresses[i]].missedRewards = users[_topRoundAddresses[i]]
                    .missedRewards
                    .add(missedRewards);
                }
            }
        }
    }

    /**
    * @dev fill all pools with equal proportion from amount value
    * @dev start lottery if newLiquidity == pool.totalPrize && pool.usersAmount == pool.maxUsersAmount
    */
    function fillLotteryPools(uint256 amount) private {
        uint256 poolsAmount = LOTTERY_POOLS.length;
        uint256 poolDepAmount = amount.mul(POOL_DISTRIBUTION_PERC).div(poolsAmount).div(100).div(PERCENT_MULTIPLIER);
        for (uint i = 0; i < poolsAmount; i++) {
            Pool storage pool = LOTTERY_POOLS[i];
            uint256 newLiquidity = pool.liquidity.add(poolDepAmount);
            if (newLiquidity >= pool.totalPrize) {
                pool.extraLiquidity = pool.extraLiquidity.add(newLiquidity.sub(pool.totalPrize));
                newLiquidity = pool.totalPrize;
            }
            pool.liquidity = newLiquidity;
            if(newLiquidity == pool.totalPrize && pool.usersAmount == pool.maxUsersAmount) {
                handleLottery(i);
            }
        }
    }

    /**
    * @dev selects randomly (almost) 10 winners and distributes prize to them
    * @dev if pool got extraLiquidity than fill pool.liquidity field with it.
    */
    function handleLottery(uint256 poolIndex) private {
        Pool storage pool = LOTTERY_POOLS[poolIndex];
        runGamble(poolIndex);

        uint256 newLiquidity = 0;
        if (pool.extraLiquidity > 0) {
            if (pool.extraLiquidity > pool.totalPrize) {
                newLiquidity = pool.totalPrize;
                pool.extraLiquidity = pool.extraLiquidity.sub(pool.totalPrize);
            } else {
                newLiquidity = pool.extraLiquidity;
                pool.extraLiquidity = 0;
            }
        }
        pool.liquidity = newLiquidity;
    }

    /**
    * @dev selects randomly (almost) 10 winners and distributes prize to them
    */
    function runGamble(uint256 poolIndex) private {
        Pool storage pool = LOTTERY_POOLS[poolIndex];
        uint256 _nonce = nonce + 1;
        uint256 winnerIndex = 0;
        uint256 userReward = pool.liquidity.div(POOL_WINNERS_AMOUNT);
        address[] memory winners = new address[](POOL_WINNERS_AMOUNT);
        while(winnerIndex < POOL_WINNERS_AMOUNT) {
            uint256 winner = getRandomNumber(0, pool.usersAmount - 1);
            address winnerAddress = poolUsers[poolIndex][winner];
            (uint256 safeRewardAmount, uint256 missedRewards) = safeRewardTransfer(winnerAddress, userReward);
            winners[winnerIndex] = winnerAddress;
            winnerIndex++;
            _nonce++;
            if (safeRewardAmount > 0) {
                emit PoolGamblingReward(winnerAddress, safeRewardAmount, pool.gambleRound, poolIndex);
            }
            if (missedRewards > 0) {
                emit PoolGamblingRewardMiss(winnerAddress, missedRewards, pool.gambleRound, poolIndex);
                users[winnerAddress].missedRewards = users[winnerAddress].missedRewards.add(missedRewards);
            }
        }
        nonce = _nonce;
        emit PoolGamblingWinners(pool.gambleRound, poolIndex, winners);
        pool.gambleRound++;
        pool.usersAmount = 0;
    }


    /**
    * @dev distributes referral rewards. Latter depends from level of the ref and amount of
    * refs in 1 level.
    * Deeper levels open if there are enough users at first level: 1 user = 1 deeper level
    * @dev call this method from deposit one
    */
    function distributeRefFees(uint256 amount, address inviter, bool isFirstDeposit) internal {
        address currentInviter = inviter;
        uint256 currentLevel = 1;
        bool isTopReached = inviter == address(0);
        while(!isTopReached && currentLevel <= MAX_REF_LEVEL) {
            isTopReached = currentInviter == top;
            uint256 refAmount = getPercentFromNumber(amount, getRefLevelPercent(currentLevel), PERCENT_MULTIPLIER);
            User storage _currentInviterUser = users[currentInviter];

            if (isFirstDeposit) {
                // increment referrals count only on first deposit
                // by level
                referralsCount[currentInviter][currentLevel] = referralsCount[currentInviter][currentLevel].add(1);
                // global
                _currentInviterUser.totalRefs = _currentInviterUser.totalRefs.add(1);
            }

            // Level 1 referrals count must be higher or equal to current level
            if (referralsCount[currentInviter][1] >= currentLevel) {
                (uint256 rewardAmount, uint256 missedRewards) = safeRewardTransfer(
                    _currentInviterUser._address,
                    refAmount
                );
                // save referral income statistic by level
                // save global income referral statistic
                _currentInviterUser.totalRefIncome = _currentInviterUser.totalRefIncome.add(rewardAmount);
                if (rewardAmount > 0) {
                    emit RefReward(currentInviter, rewardAmount, currentLevel, msg.sender);
                    referralsIncome[currentInviter][currentLevel] = referralsIncome[currentInviter][currentLevel]
                    .add(rewardAmount);
                }
                if (missedRewards > 0) {
                    emit RefRewardMiss(currentInviter, missedRewards, currentLevel, msg.sender);
                    _currentInviterUser.missedRewards = _currentInviterUser.missedRewards.add(missedRewards);
                }
            } else {
                emit RefRewardMiss(currentInviter, refAmount, currentLevel, msg.sender);
                _currentInviterUser.missedRewards = _currentInviterUser.missedRewards.add(refAmount);
            }

            currentInviter = users[currentInviter].inviter;

            currentLevel++;
        }
    }

    /**
    * @dev distributes referral rewards. Latter depends from level of the ref and amount of
    * refs in 1 level.
    * Deeper levels open if there are enough users at first level: 1 user = 1 deeper level
    * @dev call this method from withdraw one
    */
    function distributeDailyMatchingBonus(uint256 amount, address withdrawer) internal {
        address currentInviter = users[withdrawer].inviter;
        uint256 currentLevel = 1;
        bool isTopReached = currentInviter == address(0);
        while(!isTopReached && currentLevel <= MAX_DAILY_BONUS_LEVEL) {
            isTopReached = currentInviter == top;
            uint256 refAmount = getPercentFromNumber(
                amount,
                getDailyBonusLevelPercent(currentLevel),
                PERCENT_MULTIPLIER
            );
            User storage currentInviterUser = users[currentInviter];
            // Level 1 referrals count must be higher or equal to current level
            if (referralsCount[currentInviter][1] >= currentLevel) {
                (uint256 rewardAmount, uint256 missedRewards) = safeRewardTransfer(
                    currentInviterUser._address,
                    refAmount
                );
                if (rewardAmount > 0) {
                    emit DailyBonusReward(currentInviter, rewardAmount, currentLevel, msg.sender);
                }
                if (missedRewards > 0) {
                    emit DailyBonusRewardMiss(currentInviter, missedRewards, currentLevel, msg.sender);
                    currentInviterUser.missedRewards = currentInviterUser.missedRewards.add(missedRewards);
                }
            } else {
                emit DailyBonusRewardMiss(currentInviter, refAmount, currentLevel, msg.sender);
                currentInviterUser.missedRewards = currentInviterUser.missedRewards.add(refAmount);
            }

            currentInviter = users[currentInviter].inviter;

            currentLevel++;
        }
    }

    function initialize(uint256 amount) external onlyOwner {
        require(!initialized, "initialized");
        require(amount >= getMinDeposit(msg.sender), "DEPOSIT MINIMUM VALUE");
        require(amount <= getMaxDeposit(msg.sender), "DEPOSIT IS HIGHER THAN MAX DEPOSIT");

        busd.transferFrom(msg.sender, address(this), amount);
        
        User storage user = users[msg.sender];
        
        user._address = msg.sender;
        user.deposit = amount;
        user.lastDeposit = block.timestamp;
        user.totalDeposit = amount;

        emit Deposit(msg.sender, amount, address(0));

        uniqueUserAddresses.push(msg.sender);
        top = msg.sender;

        initialized = true;
        initializedAt = block.timestamp;
        distributionRound = 1;
    }

    /* getters */

    /**
    * @dev returns users withdraw limit
    */
    function getWithdrawLimit(address _address) public view returns (uint256) {
        uint256 userDeposit = users[_address].deposit;
        if (userDeposit >= 100000 ether) return userDeposit.mul(2);

        return userDeposit.mul(3);
    }

    /**
    * @dev returns fee percent of users withdraw
    */
    function getWithdrawPercent(address _address) public view returns (uint256) {
        User memory user = users[_address];
        (uint256 income,, uint256 withdrawLimit,) = getIncomeSinceLastClaim(_address);

        if (income.add(user.claimedRewards) == withdrawLimit) return SafeMath.mul(3, PERCENT_MULTIPLIER);
        
        uint256 lastClaim = user.lastClaim > 0 ? user.lastClaim : user.lastDeposit;
        uint256 timestamp = block.timestamp;

        if (timestamp - lastClaim > 3 * ONE_WEEK) return SafeMath.mul(3, PERCENT_MULTIPLIER); // 3%
        if (timestamp - lastClaim > 2 * ONE_WEEK) return SafeMath.mul(4, PERCENT_MULTIPLIER); // 4%
        if (timestamp - lastClaim > ONE_WEEK) return SafeMath.mul(7, PERCENT_MULTIPLIER); // 7%

        return SafeMath.mul(10, PERCENT_MULTIPLIER); // 10%
    }

    /**
    * @dev returns users level which used for accumulate rewards from passive deposit income
    */
    function getUserLevel(address _address) public view returns (uint256) {
        uint256 userDeposit = users[_address].deposit;
        
        if (userDeposit > 50000 ether) return 5;
        if (userDeposit > 10000 ether) return 4;
        if (userDeposit > 5000 ether) return 3;   
        if (userDeposit > 1000 ether) return 2;      
        if (userDeposit > 500 ether) return 1;

        return 0;
    }

    /**
    * @dev min deposit with which user can enter
    */
    function getMinDeposit(address _address) public view returns (uint256) {
        if (users[_address].deposit > 0) return users[_address].deposit.mul(2); 
        return MIN_DEPOSIT;
    }

    /**
    * @dev max deposit with which user can enter
    */
    function getMaxDeposit(address _address) public view returns (uint256) {
        if (users[_address].deposit > 0) return MAX_DEPOSIT;
        return MAX_START_DEPOSIT;
    }

    function getBalance() public view returns(uint256) {
        return busd.balanceOf(address(this));
    }

    /**
    * @return amount of referrals of user _address at selected level
    */
    function getReferralsCount(address _address, uint256 level) public view returns(uint256) {
        return referralsCount[_address][level];
    }

    /**
    * @return income from referrals of user _address at selected level
    */
    function getReferralsIncome(address _address, uint256 level) public view returns(uint256) {
        return referralsIncome[_address][level];
    }

    /**
    * @dev percent that user obtain from ref deposit on exact level (distributeRefFees)
    */
    function getRefLevelPercent(uint level) public view returns(uint256) {
        return REF_LEVEL_PERCENT[level - 1];
    }

    /**
    * @dev percent that user obtain from ref deposit on exact level (distributeDailyMatchingBonus)
    */
    function getDailyBonusLevelPercent(uint level) public view returns(uint256) {
        return DAILY_BONUS_PERCENT[level - 1];
    }

    /**
    * @return user income since last collection of rewards with withdraw()
    * totalIncome - total income since last claim (totalIncome = 0 if limit reached)
    * nftIncome - income from nft staking
    * withdrawLimit - maximum amount user can fetch from contract
    */
    function getIncomeSinceLastClaim(address _address) public view returns(uint256, uint256, uint256, uint256) {
        User memory user = users[_address];

        uint256 withdrawLimit = getWithdrawLimit(_address);

        uint256 secondsPassed = user.lastClaim > 0 ?
            SafeMath.sub(block.timestamp, user.lastClaim) :
            SafeMath.sub(block.timestamp, user.lastDeposit);
        uint256 incomeMultiplier = getUserIncomeMultiplier(_address, secondsPassed);
        uint256 nftIncomeMultiplier;
        uint256 nftIncome;
        if (address(nftStaking) != address(0)) {
            nftIncomeMultiplier = nftStaking.getRewardMultiplier(_address);
            nftIncome = user.deposit
            .mul(nftIncomeMultiplier)
            .div(REWARD_EPOCH_SECONDS)
            .div(PERCENT_MULTIPLIER)
            .div(100)
            .sub(user.claimedNftRewards);
        }
        uint256 passiveIncome = user.deposit.mul(incomeMultiplier).div(PERCENT_MULTIPLIER).div(100);
        uint256 totalIncome = passiveIncome.add(user.rewards).add(nftIncome);
        uint256 rawBalance = user.claimedRewards.add(totalIncome);

        //if raw income more than 100% from deposit than cut passive income by 2
        if (rawBalance.sub(passiveIncome) >= user.deposit) {
            passiveIncome = passiveIncome.div(2);
            totalIncome = passiveIncome.add(user.rewards).add(nftIncome);
            rawBalance = user.claimedRewards.add(totalIncome);
        } else if (rawBalance > user.deposit) {
            uint256 regPassive = user.deposit.sub(rawBalance.sub(passiveIncome));
            passiveIncome = passiveIncome.add(regPassive).div(2);
            totalIncome = passiveIncome.add(user.rewards).add(nftIncome);
            rawBalance = user.claimedRewards.add(totalIncome);
        }


        uint256 missedIncome;
        if (rawBalance > withdrawLimit) {
            totalIncome = withdrawLimit.sub(user.claimedRewards);
            missedIncome = rawBalance.sub(withdrawLimit);
        }

        return (totalIncome, nftIncome, withdrawLimit, missedIncome);
    }


    /**
    * @return total _distributionRound deposit
    */
    function getTotalRoundDeposit(uint256 _distributionRound) external view returns(uint256) {
        return totalRoundDeposits[_distributionRound];
    }

    /**
    * @return users with top deposits in current round
    */
    function getTopRoundUsers(uint256 _distributionRound) external view returns(address[5] memory) {
        return topRoundAddresses[_distributionRound];
    }

    /**
    * @return users deposit in current round
    */
    function getUserRoundDeposit(address userAddress, uint256 _distributionRound) external view returns(uint256) {
        return roundDeposits[_distributionRound][userAddress].amount;
    }

    /**
    * @return users passive income percent
    */
    function getUserIncomeMultiplier(address userAddress, uint256 secondsPassed) public view returns(uint256) {
        uint256 userLevel = getUserLevel(userAddress);
        uint256 epochesPassed = SafeMath.mul(secondsPassed, 100).div(REWARD_EPOCH_SECONDS).div(100);
        return SafeMath.mul(epochesPassed, INCOME_PERCENTS[userLevel]);
    }

    /* helpers */

    function getPercentFromNumber(uint256 number, uint256 modifiedPercent, uint256 percentModifier)
        private
        pure
        returns(uint256)
    {
        return number.mul(modifiedPercent).div(100).div(percentModifier);
    }

    // transfer reward with limit check
    function safeRewardTransfer(address _address, uint256 revAmount) private returns(uint256, uint256) {
        uint256 userRewards = users[_address].rewards;
        (uint256 totalIncome,,uint256 withdrawLimit,) = getIncomeSinceLastClaim(_address);
        uint256 accRews = SafeMath.add(totalIncome, users[_address].claimedRewards);
        uint256 revSafeTransferAmount = revAmount;
        uint256 missedRewards;
        if (SafeMath.add(revAmount, accRews) > withdrawLimit) {
            revSafeTransferAmount = SafeMath.sub(withdrawLimit, accRews);
            missedRewards = SafeMath.sub(revAmount, revSafeTransferAmount);
        }
        users[_address].rewards = SafeMath.add(userRewards, revSafeTransferAmount);
        return (revSafeTransferAmount, missedRewards);
    }

    function setDevAddress(address _newDevAddress) external onlyOwner {
        require(_newDevAddress != address(0), "ZERO ADDRESS");

        devAddress = _newDevAddress;
    }

    function setMinWithdraw(uint256 amount) external onlyOwner {
        require(amount < MIN_WITHDRAW_LIMIT, "MIN WITHDRAW LIMIT");
        require(amount > 0, "WRONG AMOUNT");

        MIN_WITHDRAW = amount;
    }

    /**
    * @return returns users from pool with index poolIndex from current gamble round
    */
    function getPoolUsers(uint256 poolIndex) external view returns(address[] memory) {
        require(poolIndex < LOTTERY_POOLS.length, "ONLY 4 POOLS EXIST");
        address[] memory poolUsersByIndex = new address[](LOTTERY_POOLS[poolIndex].usersAmount);
        for (uint256 i = 0; i < poolUsersByIndex.length; i++) {
            poolUsersByIndex[i] = poolUsers[poolIndex][i];
        }
        return poolUsersByIndex;
    }

    function getUniqueUsers(uint256 startIndex) external view returns (User[] memory) {
        uint256 length = uniqueUserAddresses.length > startIndex
            ? uniqueUserAddresses.length - startIndex
            : 0;
        User[] memory uniqueUsers = new User[](length);
        uint256 i = 0;
        while (i < length) {
            uniqueUsers[i] = users[uniqueUserAddresses[startIndex + i]];
            ++i;
        }
        return uniqueUsers;
    }

    /**
    * @return total users enters amount in pool with index poolIndex
    */
    function getPoolEntersAmount(address _address, uint256 poolIndex) public view returns(uint256) {
        uint256 lastGambleRound = LOTTERY_POOLS[poolIndex].gambleRound;
        uint256 round = 0;
        uint256 entersAmount = 0;
        while (round <= lastGambleRound) {
            bool userInRound = poolGambleRoundUsers[poolIndex][round][_address];
            if (userInRound) ++entersAmount;
            ++round;
        }
        return entersAmount;
    }

    function getRandomNumber(uint minNumber, uint maxNumber) internal returns (uint) {
        nonce++;
        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) %
            (maxNumber - minNumber);
        randomNumber = randomNumber + minNumber;
        return randomNumber;
    }


}