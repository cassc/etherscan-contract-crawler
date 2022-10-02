// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@quant-finance/solidity-datetime/contracts/DateTime.sol";
import "./interfaces/IERC20Burnable.sol";
import "./interfaces/IGymLevelPool.sol";
import "./interfaces/IGymMLM.sol";
import "./interfaces/IGymMLMQualifications.sol";
import "./interfaces/IGymNetwork.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IPancakePair.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/IWETH.sol";
import "./RewardRateConfigurable.sol";
import "./interfaces/INFTReflection.sol";
import "./interfaces/ICommissionActivation.sol";

/* preserved Line */
/* preserved Line */
/* preserved Line */
/* preserved Line */

/**
 * @notice GymSinglePool contract:
 * - Users can:
 *   # Deposit GYMNET
 *   # Withdraw assets
 */

contract GymSinglePool is ReentrancyGuardUpgradeable, OwnableUpgradeable, RewardRateConfigurable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Info of each user
     * One Address can have many Deposits with different periods. Unlimited Amount.
     * Total Depsit Tokens = Total amount of user active stake in all.
     * Total Depsit Dollar Value = Total Dollar Value over all staking single pools. Calculated when user deposits tokens, and dollar value is for that exact moment rate.
     * level = level qualification for this pool. Used internally, for global qualification please check MLM Contract.
     * depositId = incremental ID of deposits, eg. if user has 3 stakings then this value will be 2;
     * totalClaimt = Total amount of tokens user claimt.
     */
    struct UserInfo {
        uint256 totalDepositTokens;
        uint256 totalDepositDollarValue;
        uint256 totalGGYMNET;
        uint256 level;
        uint256 depositId;
        uint256 totalClaimt;
    }

    /**
     * @notice Info for each staking by ID
     * One Address can have many Deposits with different periods. Unlimited Amount.
     * depositTokens = amount of tokens for exact deposit.
     * depositDollarValue = Dollar value of deposit.
     * stakePeriod = Locking Period - from 3 months to 30 months. value is integer
     * depositTimestamp = timestamp of deposit
     * withdrawalTimestamp = Timestamp when user can withdraw his locked tokens
     * rewardsGained = amount of rewards user has gained during the process
     * is_finished = checks if user has already withdrawn tokens
     */
    struct UserDeposits {
        uint256 depositTokens;
        uint256 depositDollarValue;
        uint256 stakePeriod;
        uint256 depositTimestamp;
        uint256 withdrawalTimestamp;
        uint256 rewardsGained;
        uint256 rewardsClaimt;
        uint256 rewardDebt;
        uint256 ggymnetAmt;
        bool is_finished;
        bool is_unlocked;
    }
    /**
     * @notice Info of Pool
     * @param lastRewardBlock: Last block number that reward distribution occurs
     * @param accUTacoPerShare: Accumulated rewardPool per share, times 1e18
     */
    struct PoolInfo {
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }

    /// Startblock number
    uint256 public startBlock;
    uint256 public withdrawFee;

    // MLM Contract - RelationShip address
    address public relationship;
    /// Treasury address where will be sent all unused assets
    address public treasuryAddress;
    /// Info of pool.
    PoolInfo public poolInfo;
    /// Info of each user that staked tokens.
    mapping(address => UserInfo) public userInfo;

    /// accepts user address and id of element to select - returns information about selected staking by id
    mapping(address => UserDeposits[]) public user_deposits;

    uint256 private lastChangeBlock;

    /// GYMNET token contract address
    address public tokenAddress;

    /// Level Qualifications for the pool
    uint256[25] public levels;
    /// Locking Periods
    uint256[6] public months;
    /// GGYMNET AMT Allocation
    uint256[6] public ggymnetAlloc;

    /// Amount of Total GYMNET Locked in the pool
    uint256 public totalGymnetLocked;
    uint256 public totalGGymnetInPoolLocked;

    /// Amount of GYMNET all users has claimt over time.
    uint256 public totalClaimtInPool;

    /// Percent that will be sent to MLM Contract for comission distribution
    uint256 public RELATIONSHIP_REWARD;

    /// 6% comissions
    uint256 public poolRewardsAmount;

    address public holderRewardContractAddress;

    address public runnerScriptAddress;
    uint256 public totalBurntInSinglePool;
    bool public isPoolActive;
    bool public isInMigrationToVTwo;
    uint256 public totalGymnetUnlocked;
    address public vaultContractAddress;
    address public farmingContractAddress;

    address public levelPoolContractAddress;
    address public mlmQualificationsAddress;
    mapping(address => bool) private whitelist_contract;
    address public nftReflectionAddress;
    /* ========== EVENTS ========== */

    event Initialized(address indexed executor, uint256 at);
    event Deposit(address indexed user, uint256 amount, uint256 indexed period);
    event Withdraw(address indexed user, uint256 amount, uint256 indexed period);
    event RewardPaid(address indexed token, address indexed user, uint256 amount);
    event ClaimUserReward(address indexed user, uint256 amount);

    event WhitelistContract(address indexed _contract, bool _whitelist);

    event SetStartBlock(uint256 startBlock);
    event SetGymMLMAddress(address indexed _address);
    event SetTokenAddress(address indexed _address);
    event SetGymVaultsBankAddress(address indexed _address);
    event SetGymFarmingAddress(address indexed _address);
    event SetGymMLMQualificationsAddress(address indexed _address);
    event SetGymLevelPoolAddress(address indexed _address);
    event SetRunnerScriptAddress(address indexed _address);
    event SetGymHolderRewardAddress(address indexed _address);
    event SetTreasuryAddress(address indexed _address);

    event SetRelationshipReward(uint256 amount);
    event SetPoolActive(bool isActive);
    event SetMigrationToV2(bool isMigration);

    modifier onlyRunnerScript() {
        require(msg.sender == runnerScriptAddress || msg.sender == owner(), "Only Runner Script");
        _;
    }
    modifier onlyWhitelistedContract() {
        require(
            whitelist_contract[msg.sender] || msg.sender == owner(),
            "GymSinglePool: not whitelisted or owner"
        );
        _;
    }

    modifier hasInvestment(address _user) {
        require(
            IGymMLM(relationship).hasInvestment(_user),
            "GymFarming: only user with investment"
        );
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    // all initialize parameters are mandatory
    function initialize(
        uint256 _startBlock,
        address _gym,
        address _mlm,
        uint256 _gymRewardRate
    ) external initializer {
        require(block.number < _startBlock, "SinglePool: Start block must have a bigger value");
        startBlock = _startBlock; // Number of Upcoming Block
        relationship = _mlm; // address of MLM contract
        tokenAddress = _gym; // address of GYMNET Contract
        runnerScriptAddress = msg.sender;
        isPoolActive = false;
        isInMigrationToVTwo = false;
        RELATIONSHIP_REWARD = 39; // Relationship commission amount
        levels = [
            0,
            0,
            50,
            100,
            250,
            500,
            1000,
            2500,
            5000,
            7500,
            10000,
            10000,
            15000,
            20000,
            20000,
            25000,
            30000,
            30000,
            30000,
            30000,
            35000,
            35000,
            40000,
            45000,
            50000
        ]; // Internal Pool Levels
        months = [3, 6, 12, 18, 24, 30]; // Locking Periods
        ggymnetAlloc = [
            76923076920000000,
            90909090910000000,
            105263157900000000,
            125000000000000000,
            153846153800000000,
            200000000000000000
        ]; // GGYMNET ALLOCATION AMOUNT

        poolInfo = PoolInfo({lastRewardBlock: _startBlock, accRewardPerShare: 0});

        lastChangeBlock = _startBlock;

        __Ownable_init();
        __ReentrancyGuard_init();
        __RewardRateConfigurable_init(_gymRewardRate, 864000);
    }

    function setPoolInfo(
        uint256 lastRewardBlock,
        uint256 accRewardPerShare,
        uint256 rewardPerBlock,
        uint256 rewardUpdateBlocksInterval
    ) external onlyOwner {
        updatePool();

        poolInfo = PoolInfo({
            lastRewardBlock: lastRewardBlock,
            accRewardPerShare: accRewardPerShare
        });

        _setRewardConfiguration(rewardPerBlock, rewardUpdateBlocksInterval);
    }

    function setLastRewardBlock(uint256 lastRewardBlock, uint256 accRewardPerShare)
        external
        onlyOwner
    {
        poolInfo = PoolInfo({
            lastRewardBlock: lastRewardBlock,
            accRewardPerShare: accRewardPerShare
        });
    }

    function updateStartBlock(uint256 _startBlock) external onlyOwner {
        startBlock = _startBlock;

        emit SetStartBlock(_startBlock);
    }

    function setMLMAddress(address _relationship) external onlyOwner {
        relationship = _relationship;

        emit SetGymMLMAddress(_relationship);
    }

    function setNftReflectionAddress(address _nftReflection) external onlyOwner {
        nftReflectionAddress = _nftReflection;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;

        emit SetTokenAddress(_tokenAddress);
    }

    function setVaultContractAddress(address _vaultContractAddress) external onlyOwner {
        vaultContractAddress = _vaultContractAddress;

        emit SetGymVaultsBankAddress(_vaultContractAddress);
    }

    function setFarmingContractAddress(address _farmingContractAddress) external onlyOwner {
        farmingContractAddress = _farmingContractAddress;

        emit SetGymFarmingAddress(_farmingContractAddress);
    }

    function setMLMQualificationsAddress(address _address) external onlyOwner {
        mlmQualificationsAddress = _address;

        emit SetGymMLMQualificationsAddress(_address);
    }

    function setLevelPoolContractAddress(address _levelPoolContractAddress) external onlyOwner {
        levelPoolContractAddress = _levelPoolContractAddress;

        emit SetGymLevelPoolAddress(_levelPoolContractAddress);
    }

    function setRelationshipReward(uint256 _amount) external onlyOwner {
        RELATIONSHIP_REWARD = _amount;

        emit SetRelationshipReward(_amount);
    }

    function setOnlyRunnerScript(address _onlyRunnerScript) external onlyOwner {
        runnerScriptAddress = _onlyRunnerScript;

        emit SetRunnerScriptAddress(_onlyRunnerScript);
    }

    function setIsPoolActive(bool _isPoolActive) external onlyOwner {
        isPoolActive = _isPoolActive;

        emit SetPoolActive(_isPoolActive);
    }

    function setIsInMigrationToVTwo(bool _isInMigrationToVTwo) external onlyOwner {
        isInMigrationToVTwo = _isInMigrationToVTwo;

        emit SetMigrationToV2(_isInMigrationToVTwo);
    }

    function setHolderRewardContractAddress(address _holderRewardContractAddress)
        external
        onlyOwner
    {
        holderRewardContractAddress = _holderRewardContractAddress;

        emit SetGymHolderRewardAddress(_holderRewardContractAddress);
    }

    function setLevels(uint256[25] calldata _levels) external onlyOwner {
        levels = _levels;
    }

    /**
     * @notice Add or remove wallet to/from whitelist, callable only by contract owner
     *         whitelisted wallet will be able to call functions
     *         marked with onlyWhitelistedContract modifier
     * @param _wallet wallet to whitelist
     * @param _whitelist boolean flag, add or remove to/from whitelist
     */
    function whitelistContract(address _wallet, bool _whitelist) external onlyOwner {
        whitelist_contract[_wallet] = _whitelist;

        emit WhitelistContract(_wallet, _whitelist);
    }

    function isWhitelistedContract(address wallet) external view returns (bool) {
        return whitelist_contract[wallet];
    }

    /**
     * @notice  Function to set Treasury address
     * @param _treasuryAddress Address of treasury address
     */
    function setTreasuryAddress(address _treasuryAddress) external nonReentrant onlyOwner {
        treasuryAddress = _treasuryAddress;

        emit SetTreasuryAddress(_treasuryAddress);
    }

    /**
     * @notice Deposit in given pool
     * @param _depositAmount: Amount of want token that user wants to deposit
     */
    function deposit(
        uint256 _depositAmount,
        uint8 _periodId,
        bool isUnlocked
    ) external nonReentrant hasInvestment(msg.sender) {
        require(isPoolActive, "Contract is not running yet");
        //TO-DO Add Vault check here
        if (isUnlocked) {
            _periodId = 0;
        }
        if (
            !ICommissionActivation(0x3E1240E879b4613C7Ae6eE1772292FC80B9c259e)
                .getCommissionActivation(msg.sender, 3)
        ) {
            _activatePendingCommissions(msg.sender);
        }

        _deposit(_depositAmount, _periodId, isUnlocked);
        _updateLevelPoolQualification(msg.sender);
    }

    /**
     * @notice Deposit in given pool
     * @param _depositAmount: Amount of want token that user wants to deposit
     */
    function depositFromOtherContract(
        uint256 _depositAmount,
        uint8 _periodId,
        bool isUnlocked,
        address _from
    ) external nonReentrant onlyWhitelistedContract {
        require(isPoolActive, "Contract is not running yet");
        if (isUnlocked) {
            _periodId = 0;
        }
        if (
            !ICommissionActivation(0x3E1240E879b4613C7Ae6eE1772292FC80B9c259e)
                .getCommissionActivation(_from, 3)
        ) {
            _activatePendingCommissions(_from);
        }
        _autoDeposit(_depositAmount, _periodId, isUnlocked, _from);

        _updateLevelPoolQualification(_from);
    }

    /**
     * @notice To get User level in other contract for single pool.
     * @param _user: User address
     */
    function getUserLevelInSinglePool(address _user) external view returns (uint32) {
        uint256 _totalDepositDollarValue = userInfo[_user].totalDepositDollarValue;
        uint32 level = 0;
        for (uint32 i = 0; i < levels.length; i++) {
            if (_totalDepositDollarValue >= levels[i]) {
                level = i;
            }
        }
        return level;
    }

    function activatePendingCommissions() external {
        if (
            !ICommissionActivation(0x3E1240E879b4613C7Ae6eE1772292FC80B9c259e)
                .getCommissionActivation(msg.sender, 3)
        ) {
            _activatePendingCommissions(msg.sender);
        }
    }

    function _activatePendingCommissions(address _from) private {
        //TODO: change before deployment
        ICommissionActivation(0x3E1240E879b4613C7Ae6eE1772292FC80B9c259e).activateCommissions(
            3,
            _from
        );
        uint256 ggymnetAmtTotal = 0;
        for (uint256 _depositId = 0; _depositId < userInfo[_from].depositId; ++_depositId) {
            UserDeposits memory depositDetails = user_deposits[_from][_depositId];
            if (!depositDetails.is_finished) {
                ggymnetAmtTotal += depositDetails.ggymnetAmt;
            }
        }
        if(ggymnetAmtTotal > 0) {
            IGymMLM(relationship).distributeCommissions(
                ggymnetAmtTotal,
                0,
                3,
                true,
                _from
            );
        }
    }

    /**
    Should approve allowance before initiating
    accepts depositAmount in WEI
    periodID - id of months array accordingly
    */
    function _deposit(
        uint256 _depositAmount,
        uint8 _periodId,
        bool _isUnlocked
    ) private {
        UserInfo storage user = userInfo[msg.sender];
        IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
        PoolInfo storage pool = poolInfo;
        updatePool();

        uint256 lockTimesamp = DateTime.addMonths(block.timestamp, months[_periodId]);
        uint256 burnTokensAmount = 0;

        if (!_isUnlocked) {
            burnTokensAmount = (_depositAmount * 4) / 100;
            totalBurntInSinglePool += burnTokensAmount;
            IERC20Burnable(tokenAddress).burnFrom(msg.sender, burnTokensAmount);
        }

        uint256 amountToDeposit = _depositAmount - burnTokensAmount;

        token.safeTransferFrom(msg.sender, address(this), amountToDeposit);

        uint256 UsdValueOfGym = ((amountToDeposit * IGYMNETWORK(tokenAddress).getGYMNETPrice()) /
            1e18) / 1e18;
        uint256 _ggymnetAmt = (amountToDeposit * ggymnetAlloc[_periodId]) / 1e18;

        if (_isUnlocked) {
            _ggymnetAmt = 0;
            totalGymnetUnlocked += amountToDeposit;
            lockTimesamp = DateTime.addSeconds(block.timestamp, months[_periodId]);
        }
        user.totalDepositTokens += amountToDeposit;
        user.totalDepositDollarValue += UsdValueOfGym;
        totalGymnetLocked += amountToDeposit;
        totalGGymnetInPoolLocked += _ggymnetAmt;

        uint256 rewardDebt = (_ggymnetAmt * (pool.accRewardPerShare)) / (1e18);
        UserDeposits memory depositDetails = UserDeposits({
            depositTokens: amountToDeposit,
            depositDollarValue: UsdValueOfGym,
            stakePeriod: _isUnlocked ? 0 : months[_periodId],
            depositTimestamp: block.timestamp,
            withdrawalTimestamp: lockTimesamp,
            rewardsGained: 0,
            is_finished: false,
            rewardsClaimt: 0,
            rewardDebt: rewardDebt,
            ggymnetAmt: _ggymnetAmt,
            is_unlocked: _isUnlocked
        });
        user.totalGGYMNET += _ggymnetAmt;
        user_deposits[msg.sender].push(depositDetails);
        user.depositId = user_deposits[msg.sender].length;

        IGymMLM(relationship).distributeCommissions(_ggymnetAmt, 0, 3, true, msg.sender);

        refreshMyLevel(msg.sender);
        emit Deposit(msg.sender, _depositAmount, _periodId);
    }

    /**
    Should approve allowance before initiating
    accepts depositAmount in WEI
    periodID - id of months array accordingly
    */
    function _autoDeposit(
        uint256 _depositAmount,
        uint8 _periodId,
        bool _isUnlocked,
        address _from
    ) private {
        UserInfo storage user = userInfo[_from];
        IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
        PoolInfo storage pool = poolInfo;
        token.approve(address(this), _depositAmount);
        updatePool();
        uint256 lockTimesamp = DateTime.addMonths(block.timestamp, months[_periodId]);
        uint256 burnTokensAmount = 0;
        uint256 amountToDeposit = _depositAmount - burnTokensAmount;
        uint256 UsdValueOfGym = ((amountToDeposit * IGYMNETWORK(tokenAddress).getGYMNETPrice()) /
            1e18) / 1e18;
        uint256 _ggymnetAmt = (amountToDeposit * ggymnetAlloc[_periodId]) / 1e18;

        if (_isUnlocked) {
            _ggymnetAmt = 0;
            totalGymnetUnlocked += amountToDeposit;
            lockTimesamp = DateTime.addSeconds(block.timestamp, months[_periodId]);
        }
        user.totalDepositTokens += amountToDeposit;
        user.totalDepositDollarValue += UsdValueOfGym;
        totalGymnetLocked += amountToDeposit;
        totalGGymnetInPoolLocked += _ggymnetAmt;

        uint256 rewardDebt = (_ggymnetAmt * (pool.accRewardPerShare)) / (1e18);
        UserDeposits memory depositDetails = UserDeposits({
            depositTokens: amountToDeposit,
            depositDollarValue: UsdValueOfGym,
            stakePeriod: _isUnlocked ? 0 : months[_periodId],
            depositTimestamp: block.timestamp,
            withdrawalTimestamp: lockTimesamp,
            rewardsGained: 0,
            is_finished: false,
            rewardsClaimt: 0,
            rewardDebt: rewardDebt,
            ggymnetAmt: _ggymnetAmt,
            is_unlocked: _isUnlocked
        });
        user_deposits[_from].push(depositDetails);
        user.totalGGYMNET += _ggymnetAmt;
        user.depositId = user_deposits[_from].length;

        IGymMLM(relationship).distributeCommissions(_ggymnetAmt, 0, 3, true, _from);
        refreshMyLevel(_from);
        emit Deposit(_from, amountToDeposit, _periodId);
    }

    /**
     * @notice withdraw one claim
     * @param _depositId: is the id of user element.
     */
    function withdraw(uint256 _depositId) external nonReentrant {
        require(_depositId >= 0, "Value is not specified");
        updatePool();
        _withdraw(_depositId);

        _updateLevelPoolQualification(msg.sender);
    }

    /**
    Should approve allowance before initiating
    accepts _depositId - is the id of user element. 
    */
    function _withdraw(uint256 _depositId) private {
        UserInfo storage user = userInfo[msg.sender];
        IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
        PoolInfo storage pool = poolInfo;
        UserDeposits storage depositDetails = user_deposits[msg.sender][_depositId];
        if (!isInMigrationToVTwo) {
            require(
                block.timestamp > depositDetails.withdrawalTimestamp,
                "Locking Period isn't over yet."
            );
        }
        require(!depositDetails.is_finished, "You already withdrawn your deposit.");

        _claim(_depositId, 1);
        depositDetails.rewardDebt = (depositDetails.ggymnetAmt * (pool.accRewardPerShare)) / (1e18);

        user.totalDepositTokens -= depositDetails.depositTokens;
        user.totalDepositDollarValue -= depositDetails.depositDollarValue;
        user.totalGGYMNET -= depositDetails.ggymnetAmt;
        totalGymnetLocked -= depositDetails.depositTokens;
        totalGGymnetInPoolLocked -= depositDetails.ggymnetAmt;

        if (depositDetails.stakePeriod == 0) {
            totalGymnetUnlocked -= depositDetails.depositTokens;
        }

        token.safeTransfer(msg.sender, depositDetails.depositTokens);

        refreshMyLevel(msg.sender);
        //TODO: change before deployment
        if (
            ICommissionActivation(0x3E1240E879b4613C7Ae6eE1772292FC80B9c259e)
                .getCommissionActivation(msg.sender, 3)
        ) {
            IGymMLM(relationship).distributeCommissions(
                depositDetails.ggymnetAmt,
                0,
                3,
                false,
                msg.sender
            );
        }
        depositDetails.is_finished = true;
        emit Withdraw(msg.sender, depositDetails.depositTokens, depositDetails.stakePeriod);
    }

    /**
     * @notice Claim rewards you gained over period
     * @param _depositId: is the id of user element.
     */
    function claim(uint256 _depositId) external nonReentrant {
        require(_depositId >= 0, "Value is not specified");
        updatePool();
        if (
            !ICommissionActivation(0x3E1240E879b4613C7Ae6eE1772292FC80B9c259e)
                .getCommissionActivation(msg.sender, 3)
        ) {
            _activatePendingCommissions(msg.sender);
        }
        _claim(_depositId, 0);
    }

    /*
    Should approve allowance before initiating
    accepts _depositId - is the id of user element. 
    */
    function _claim(uint256 _depositId, uint256 fromWithdraw) private {
        UserInfo storage user = userInfo[msg.sender];
        IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
        UserDeposits storage depositDetails = user_deposits[msg.sender][_depositId];
        PoolInfo storage pool = poolInfo;

        uint256 pending = pendingReward(_depositId, msg.sender);

        if (fromWithdraw == 0) {
            require(pending > 0, "No rewards to claim.");
        }

        if (pending > 0) {
            uint256 distributeRewardTokenAmt = (pending * RELATIONSHIP_REWARD) / 100;
            token.safeTransfer(relationship, distributeRewardTokenAmt);
            IGymMLM(relationship).distributeRewards(pending, address(tokenAddress), msg.sender, 3);

            // 6% distribution
            uint256 calculateDistrubutionReward = (pending * 6) / 100;
            poolRewardsAmount += calculateDistrubutionReward;

            uint256 calcUserRewards = (pending -
                distributeRewardTokenAmt -
                calculateDistrubutionReward);
            safeRewardTransfer(tokenAddress, msg.sender, calcUserRewards);

            user.totalClaimt += calcUserRewards;
            totalClaimtInPool += pending;
            depositDetails.rewardsClaimt += pending;
            depositDetails.rewardDebt =
                (depositDetails.ggymnetAmt * (pool.accRewardPerShare)) /
                (1e18);
            emit ClaimUserReward(msg.sender, calcUserRewards);
            depositDetails.rewardsGained = 0;
        }

        // token.safeTransferFrom(address(this),msg.sender, depositDetails.rewardsGained);
    }

    /*
    transfers pool commisions to management
    */
    function transferPoolRewards() public onlyRunnerScript {
        require(
            address(holderRewardContractAddress) != address(0x0),
            "Holder Reward Address::SET_ZERO_ADDRESS"
        );
        IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
        token.safeTransfer(holderRewardContractAddress, poolRewardsAmount);
        // token.safeTransfer(relationship, poolRewardsAmount/2);
        poolRewardsAmount = 0;
    }

    /**
     * @notice  Safe transfer function for reward tokens
     * @param _rewardToken Address of reward token contract
     * @param _to Address of reciever
     * @param _amount Amount of reward tokens to transfer
     */
    function safeRewardTransfer(
        address _rewardToken,
        address _to,
        uint256 _amount
    ) internal {
        uint256 _bal = IERC20Upgradeable(_rewardToken).balanceOf(address(this));
        uint256 amountToTransfer = _amount > _bal ? _bal : _amount;

        IERC20Upgradeable(_rewardToken).safeTransfer(_to, amountToTransfer);
    }

    /**
     * @notice To get User Info in other contract.
     */
    function getUserInfo(address _user) external view returns (UserInfo memory) {
        return userInfo[_user];
    }

    /**
     * @notice View function to see pending reward on frontend.
     * @param _depositId: Staking pool id
     * @param _user: User address
     */
    function pendingReward(uint256 _depositId, address _user) public view returns (uint256) {
        return _getPendingRewards(_depositId, _user);
    }

    /**
     * @notice View function to see all pending rewards
     * @param _user: User address
     */
    function pendingRewardTotal(address _user) external view returns (uint256) {
        uint256 rewards;
        for (uint256 _depositId = 0; _depositId < userInfo[_user].depositId; ++_depositId) {
            rewards += _getPendingRewards(_depositId, _user);
        }
        return rewards;
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function updatePool() public {
        PoolInfo storage pool = poolInfo;
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 sharesTotal = totalGGymnetInPoolLocked;
        if (sharesTotal == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number - pool.lastRewardBlock;
        if (multiplier <= 0) {
            return;
        }
        uint256 _reward = (multiplier * getRewardPerBlock());
        pool.accRewardPerShare = pool.accRewardPerShare + ((_reward * 1e18) / sharesTotal);
        pool.lastRewardBlock = block.number;

        // Update rewardPerBlock right AFTER pool update
        _updateRewardPerBlock();
    }

    /**
     * @notice Claim All Rewards in one Transaction Internat Function.
     * If reinvest = true, Rewards will be reinvested as a new Staking
     * Reinvest Period Id is the id of months element
     */
    function _claimAll(bool reinvest, uint8 reinvestPeriodId) private {
        UserInfo storage user = userInfo[msg.sender];
        IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
        PoolInfo storage pool = poolInfo;
        updatePool();
        uint256 distributeRewardTokenAmtTotal = 0;
        uint256 calcUserRewardsTotal = 0;
        uint256 totalDistribute = 0;
        for (uint256 i = 0; i < user.depositId; i++) {
            UserDeposits storage depositDetails = user_deposits[msg.sender][i];
            uint256 pending = pendingReward(i, msg.sender);
            totalDistribute += pending;
            if (pending > 0) {
                uint256 distributeRewardTokenAmt = (pending * RELATIONSHIP_REWARD) / 100;
                distributeRewardTokenAmtTotal += distributeRewardTokenAmt;
                // 6% distribution
                uint256 calculateDistrubutionReward = (pending * 6) / 100;
                poolRewardsAmount += calculateDistrubutionReward;

                uint256 calcUserRewards = (pending -
                    distributeRewardTokenAmt -
                    calculateDistrubutionReward);
                calcUserRewardsTotal += calcUserRewards;

                user.totalClaimt += calcUserRewards;
                totalClaimtInPool += pending;
                depositDetails.rewardsClaimt += pending;
                depositDetails.rewardDebt =
                    (depositDetails.ggymnetAmt * (pool.accRewardPerShare)) /
                    (1e18);
                emit ClaimUserReward(msg.sender, calcUserRewards);
                depositDetails.rewardsGained = 0;
            }
        }
        token.safeTransfer(relationship, distributeRewardTokenAmtTotal);
        IGymMLM(relationship).distributeRewards(
            totalDistribute,
            address(tokenAddress),
            msg.sender,
            3
        );
        safeRewardTransfer(tokenAddress, msg.sender, calcUserRewardsTotal);
        if (reinvest == true) {
            _deposit(calcUserRewardsTotal, reinvestPeriodId, false);
        }
    }

    /**
     * @notice Claim All Rewards in one Transaction.
     */
    function claimAll() external nonReentrant {
        if (
            !ICommissionActivation(0x3E1240E879b4613C7Ae6eE1772292FC80B9c259e)
                .getCommissionActivation(msg.sender, 3)
        ) {
            _activatePendingCommissions(msg.sender);
        }
        _claimAll(false, 0);
    }

    /**
     * @notice Claim and Reinvest all rewards public function to trigger internal _claimAll function.
     */
    function claimAndReinvest(bool reinvest, uint8 periodId) public nonReentrant {
        require(isPoolActive, "Contract is not running yet");
        if (
            !ICommissionActivation(0x3E1240E879b4613C7Ae6eE1772292FC80B9c259e)
                .getCommissionActivation(msg.sender, 3)
        ) {
            _activatePendingCommissions(msg.sender);
        }
        _claimAll(reinvest, periodId);
    }

    function refreshMyLevel(address _user) public {
        UserInfo storage user = userInfo[_user];
        for (uint256 i = 0; i < levels.length; i++) {
            if (user.totalDepositDollarValue >= levels[i]) {
                user.level = i;
            }
        }
        if (nftReflectionAddress != address(0)) {
            INFTReflection(nftReflectionAddress).updateUser(user.totalGGYMNET, _user);
        }
    }

    function totalLockedTokens(address _user) public view returns (uint256) {
        UserInfo memory user = userInfo[_user];
        uint256 totalDepositLocked = 0;
        for (uint256 i = 0; i < user.depositId; i++) {
            UserDeposits memory depositDetails = user_deposits[_user][i];
            if (depositDetails.stakePeriod != 0 && !depositDetails.is_finished) {
                totalDepositLocked += depositDetails.depositTokens;
            }
        }
        return totalDepositLocked;
    }

    function userTotalGGymnetLocked(address _user) public view returns (uint256) {
        UserInfo memory user = userInfo[_user];
        uint256 totalGgymnetLocked = 0;
        for (uint256 i = 0; i < user.depositId; i++) {
            UserDeposits memory depositDetails = user_deposits[_user][i];
            if (!depositDetails.is_unlocked && !depositDetails.is_finished) {
                totalGgymnetLocked += depositDetails.ggymnetAmt;
            }
        }
        return totalGgymnetLocked;
    }

    function _updateLevelPoolQualification(address wallet) internal {
        if (mlmQualificationsAddress != address(0) && levelPoolContractAddress != address(0)) {
            uint256 userLevel = IGymMLMQualifications(mlmQualificationsAddress).getUserCurrentLevel(
                wallet
            );
            IGymLevelPool(levelPoolContractAddress).updateUserQualification(wallet, userLevel);
        }
    }

    /**
    Should approve allowance before initiating
    accepts depositAmount in WEI
    periodID - id of months array accordingly
    */
    function transferFromOldVersion(
        uint256 _depositAmount,
        uint8 _periodId,
        bool _isUnlocked,
        address _from,
        uint256 totalDepositValue
    ) public nonReentrant onlyWhitelistedContract {
        if (
            !ICommissionActivation(0x3E1240E879b4613C7Ae6eE1772292FC80B9c259e)
                .getCommissionActivation(_from, 3)
        ) {
            _activatePendingCommissions(_from);
        }

        UserInfo storage user = userInfo[_from];
        IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
        PoolInfo storage pool = poolInfo;

        token.safeApprove(address(this), 0);
        token.safeApprove(address(this), _depositAmount);

        updatePool();

        uint256 lockTimesamp = DateTime.addMonths(block.timestamp, months[_periodId]);
        uint256 burnTokensAmount = 0;
        uint256 amountToDeposit = _depositAmount - burnTokensAmount;
        uint256 _ggymnetAmt = (amountToDeposit * ggymnetAlloc[_periodId]) / 1e18;

        if (_isUnlocked) {
            _ggymnetAmt = 0;
            totalGymnetUnlocked += amountToDeposit;
            lockTimesamp = DateTime.addSeconds(block.timestamp, months[_periodId]);
        }

        user.totalDepositTokens += amountToDeposit;
        user.totalDepositDollarValue += (totalDepositValue / 1e18);
        totalGymnetLocked += amountToDeposit;
        totalGGymnetInPoolLocked += _ggymnetAmt;

        uint256 rewardDebt = (_ggymnetAmt * (pool.accRewardPerShare)) / (1e18);
        UserDeposits memory depositDetails = UserDeposits({
            depositTokens: amountToDeposit,
            depositDollarValue: (totalDepositValue / 1e18),
            stakePeriod: _isUnlocked ? 0 : months[_periodId],
            depositTimestamp: block.timestamp,
            withdrawalTimestamp: lockTimesamp,
            rewardsGained: 0,
            is_finished: false,
            rewardsClaimt: 0,
            rewardDebt: rewardDebt,
            ggymnetAmt: _ggymnetAmt,
            is_unlocked: _isUnlocked
        });
        user_deposits[_from].push(depositDetails);
        user.totalGGYMNET += _ggymnetAmt;
        user.depositId = user_deposits[_from].length;


         IGymMLM(relationship).distributeCommissions(_ggymnetAmt, 0, 3, true, _from);
        refreshMyLevel(_from);
        emit Deposit(_from, amountToDeposit, _periodId);
    }

    function _getPendingRewards(uint256 _depositId, address _user) private view returns (uint256) {
        UserDeposits storage depositDetails = user_deposits[_user][_depositId];
        PoolInfo storage pool = poolInfo;
        if (depositDetails.is_finished || depositDetails.is_unlocked) {
            return 0;
        }

        uint256 _accRewardPerShare = pool.accRewardPerShare;
        uint256 sharesTotal = totalGGymnetInPoolLocked;

        if (block.number > pool.lastRewardBlock && sharesTotal != 0) {
            uint256 _multiplier = block.number - pool.lastRewardBlock;
            uint256 _reward = (_multiplier * getRewardPerBlock());
            _accRewardPerShare = _accRewardPerShare + ((_reward * 1e18) / sharesTotal);
        }

        return
            (depositDetails.ggymnetAmt * _accRewardPerShare) / (1e18) - (depositDetails.rewardDebt);
    }
}