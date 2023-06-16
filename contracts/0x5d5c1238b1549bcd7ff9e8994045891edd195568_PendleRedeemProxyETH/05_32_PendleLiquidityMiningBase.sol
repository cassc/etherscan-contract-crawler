// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "../../libraries/MathLib.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../interfaces/IPendleForge.sol";
import "../../interfaces/IPendleData.sol";
import "../../interfaces/IPendleLpHolder.sol";
import "../../core/PendleLpHolder.sol";
import "../../interfaces/IPendleLiquidityMining.sol";
import "../../interfaces/IPendleWhitelist.sol";
import "../../interfaces/IPendlePausingManager.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
@dev things that must hold in this contract:
 - If an user's stake information is updated (hence lastTimeUserStakeUpdated is changed),
    then his pending rewards are calculated as well
    (and saved in availableRewardsForEpoch[user][epochId])
@dev We define 1 Unit = 1 LP stake in contract 1 second. For example, 20 LP stakes 30 secs will create 600 units for the user
@dev Basically the logic of distributing rewards is very simple: For each epoch, we calculate how many units that each user
has contributed in this epoch. The rewards will be distributed proportionately based on that number
@dev IMPORTANT: All markets with the same triplets of (marketFactoryId,XYT,baseToken) will share the same LiqMining contract
I.e: All the markets using the same LiqMining contract are only different from each other by their expiries
@dev CORE LOGIC: So in a single LiqMining contract:
* the rewards will be distributed among different expiries by ratios set by Governance
* In a single expiry, the reward will be distributed by the ratio of units (explained above)
*/
abstract contract PendleLiquidityMiningBase is
    IPendleLiquidityMining,
    WithdrawableV2,
    ReentrancyGuard
{
    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserExpiries {
        uint256[] expiries;
        mapping(uint256 => bool) hasExpiry;
    }

    struct EpochData {
        // total units for different expiries in this epoch
        mapping(uint256 => uint256) stakeUnitsForExpiry;
        // the last time in this epoch that we updated the stakeUnits for this expiry
        mapping(uint256 => uint256) lastUpdatedForExpiry;
        /* availableRewardsForEpoch[user][epochId] is the amount of PENDLEs the user can withdraw
        at the beginning of epochId*/
        mapping(address => uint256) availableRewardsForUser;
        // number of units an user has contributed in this epoch & expiry
        mapping(address => mapping(uint256 => uint256)) stakeUnitsForUser;
        // the reward setting to use
        uint256 settingId;
        // totalRewards for this epoch
        uint256 totalRewards;
    }

    // For each expiry, we will have one struct
    struct ExpiryData {
        // the last time the units of an user was updated in this expiry
        mapping(address => uint256) lastTimeUserStakeUpdated; // map user => time
        // the last epoch the user claimed rewards. After the rewards an epoch has been claimed, there won't be any
        // additional rewards in that epoch for the user to claim
        mapping(address => uint256) lastEpochClaimed;
        // total amount of LP in this expiry (to use for units calculation)
        uint256 totalStakeLP;
        // lpHolder contract for this expiry
        address lpHolder;
        // the LP balances for each user in this expiry
        mapping(address => uint256) balances;
        // variables for lp interest calculations
        uint256 lastNYield;
        uint256 paramL;
        mapping(address => uint256) lastParamL;
        mapping(address => uint256) dueInterests;
    }

    struct LatestSetting {
        uint256 id;
        uint256 firstEpochToApply;
    }

    IPendleWhitelist public immutable whitelist;
    IPendleRouter public immutable router;
    IPendleData public immutable data;
    address public immutable override pendleTokenAddress;
    bytes32 public immutable override forgeId;
    address public immutable override forge;
    bytes32 public immutable override marketFactoryId;
    IPendlePausingManager private immutable pausingManager;

    address public immutable override underlyingAsset;
    address public immutable override underlyingYieldToken;
    address public immutable override baseToken;
    uint256 public immutable override startTime;
    uint256 public immutable override epochDuration;
    uint256 public override numberOfEpochs;
    uint256 public immutable override vestingEpochs;
    bool public funded;

    uint256[] public allExpiries;
    uint256 private constant ALLOCATION_DENOMINATOR = 1_000_000_000;
    uint256 internal constant MULTIPLIER = 10**20;

    // allocationSettings[settingId][expiry] = rewards portion of a pool for settingId
    mapping(uint256 => mapping(uint256 => uint256)) public allocationSettings;
    LatestSetting public latestSetting;

    mapping(uint256 => ExpiryData) internal expiryData;
    mapping(uint256 => EpochData) private epochData;
    mapping(address => UserExpiries) private userExpiries;

    modifier isFunded() {
        require(funded, "NOT_FUNDED");
        _;
    }

    modifier nonContractOrWhitelisted() {
        bool isEOA = !Address.isContract(msg.sender) && tx.origin == msg.sender;
        require(isEOA || whitelist.whitelisted(msg.sender), "CONTRACT_NOT_WHITELISTED");
        _;
    }

    constructor(
        address _governanceManager,
        address _pausingManager,
        address _whitelist,
        address _pendleTokenAddress,
        address _router,
        bytes32 _marketFactoryId,
        bytes32 _forgeId,
        address _underlyingAsset,
        address _baseToken,
        uint256 _startTime,
        uint256 _epochDuration,
        uint256 _vestingEpochs
    ) PermissionsV2(_governanceManager) {
        require(_startTime > block.timestamp, "START_TIME_OVER");
        require(IERC20(_pendleTokenAddress).totalSupply() > 0, "INVALID_ERC20");
        require(IERC20(_underlyingAsset).totalSupply() > 0, "INVALID_ERC20");
        require(IERC20(_baseToken).totalSupply() > 0, "INVALID_ERC20");
        require(_vestingEpochs > 0, "INVALID_VESTING_EPOCHS");

        pendleTokenAddress = _pendleTokenAddress;
        router = IPendleRouter(_router);
        whitelist = IPendleWhitelist(_whitelist);
        IPendleData _dataTemp = IPendleRouter(_router).data();
        data = _dataTemp;
        require(
            _dataTemp.getMarketFactoryAddress(_marketFactoryId) != address(0),
            "INVALID_MARKET_FACTORY_ID"
        );
        require(_dataTemp.getForgeAddress(_forgeId) != address(0), "INVALID_FORGE_ID");

        address _forgeTemp = _dataTemp.getForgeAddress(_forgeId);
        forge = _forgeTemp;
        underlyingYieldToken = IPendleForge(_forgeTemp).getYieldBearingToken(_underlyingAsset);
        pausingManager = IPendlePausingManager(_pausingManager);
        marketFactoryId = _marketFactoryId;
        forgeId = _forgeId;
        underlyingAsset = _underlyingAsset;
        baseToken = _baseToken;
        startTime = _startTime;
        epochDuration = _epochDuration;
        vestingEpochs = _vestingEpochs;
    }

    // Only the liqMiningEmergencyHandler can call this function, when its in emergencyMode
    // this will allow a spender to spend the whole balance of the specified tokens from this contract
    // as well as to spend tokensForLpHolder from the respective lp holders for expiries specified
    // the spender should ideally be a contract with logic for users to withdraw out their funds.
    function setUpEmergencyMode(uint256[] calldata expiries, address spender) external override {
        (, bool emergencyMode) = pausingManager.checkLiqMiningStatus(address(this));
        require(emergencyMode, "NOT_EMERGENCY");

        (address liqMiningEmergencyHandler, , ) = pausingManager.liqMiningEmergencyHandler();
        require(msg.sender == liqMiningEmergencyHandler, "NOT_EMERGENCY_HANDLER");

        for (uint256 i = 0; i < expiries.length; i++) {
            IPendleLpHolder(expiryData[expiries[i]].lpHolder).setUpEmergencyMode(spender);
        }
        IERC20(pendleTokenAddress).approve(spender, type(uint256).max);
    }

    /**
     * @notice fund new epochs
     * @dev Once the last epoch is over, the program is permanently override
     * @dev the settings must be set before epochs can be funded
        => if funded=true, means that epochs have been funded & have already has valid allocation settings
     * conditions:
        * Must only be called by governance
     */
    function fund(uint256[] calldata _rewards) external override onlyGovernance {
        checkNotPaused();
        // Can only be fund if there is already a setting
        require(latestSetting.id > 0, "NO_ALLOC_SETTING");
        // Once the program is over, cannot fund
        require(getCurrentEpochId() <= numberOfEpochs, "LAST_EPOCH_OVER");

        uint256 nNewEpochs = _rewards.length;
        uint256 totalFunded;
        // all the funding will be used for new epochs
        for (uint256 i = 0; i < nNewEpochs; i++) {
            totalFunded = totalFunded.add(_rewards[i]);
            epochData[numberOfEpochs + i + 1].totalRewards = _rewards[i];
        }

        require(totalFunded > 0, "ZERO_FUND");
        funded = true;
        numberOfEpochs = numberOfEpochs.add(nNewEpochs);
        IERC20(pendleTokenAddress).safeTransferFrom(msg.sender, address(this), totalFunded);
        emit Funded(_rewards, numberOfEpochs);
    }

    /**
    @notice top up rewards for any funded future epochs (but not to create new epochs)
    * conditions:
        * Must only be called by governance
        * The contract must have been funded already
    */
    function topUpRewards(uint256[] calldata _epochIds, uint256[] calldata _rewards)
        external
        override
        onlyGovernance
        isFunded
    {
        checkNotPaused();
        require(latestSetting.id > 0, "NO_ALLOC_SETTING");
        require(_epochIds.length == _rewards.length, "INVALID_ARRAYS");

        uint256 curEpoch = getCurrentEpochId();
        uint256 endEpoch = numberOfEpochs;
        uint256 totalTopUp;

        for (uint256 i = 0; i < _epochIds.length; i++) {
            require(curEpoch < _epochIds[i] && _epochIds[i] <= endEpoch, "INVALID_EPOCH_ID");
            totalTopUp = totalTopUp.add(_rewards[i]);
            epochData[_epochIds[i]].totalRewards = epochData[_epochIds[i]].totalRewards.add(
                _rewards[i]
            );
        }

        require(totalTopUp > 0, "ZERO_FUND");
        IERC20(pendleTokenAddress).safeTransferFrom(msg.sender, address(this), totalTopUp);
        emit RewardsToppedUp(_epochIds, _rewards);
    }

    /**
    @notice set a new allocation setting, which will be applied from the next epoch onwards
    @dev  all the epochData from latestSetting.firstEpochToApply+1 to current epoch will follow the previous
    allocation setting
    @dev We must set the very first allocation setting before the start of epoch 1,
            otherwise epoch 1 will not have any allocation setting!
        In that case, we will not be able to set any allocation and hence its not possible to
            fund the contract as well
        => We should just throw this contract away, and funds are SAFU!
    @dev the length of _expiries array is expected to be small, 2 or 3
    @dev it's intentional that we don't check the existence of expiries
     */
    function setAllocationSetting(
        uint256[] calldata _expiries,
        uint256[] calldata _allocationNumerators
    ) external onlyGovernance {
        checkNotPaused();
        require(_expiries.length == _allocationNumerators.length, "INVALID_ALLOCATION");
        if (latestSetting.id == 0) {
            require(block.timestamp < startTime, "LATE_FIRST_ALLOCATION");
        }

        uint256 curEpoch = getCurrentEpochId();
        // set the settingId for past epochs
        for (uint256 i = latestSetting.firstEpochToApply; i <= curEpoch; i++) {
            epochData[i].settingId = latestSetting.id;
        }

        // create a new setting that will be applied from the next epoch onwards
        latestSetting.firstEpochToApply = curEpoch + 1;
        latestSetting.id++;

        uint256 sumAllocationNumerators;
        for (uint256 _i = 0; _i < _expiries.length; _i++) {
            allocationSettings[latestSetting.id][_expiries[_i]] = _allocationNumerators[_i];
            sumAllocationNumerators = sumAllocationNumerators.add(_allocationNumerators[_i]);
        }
        require(sumAllocationNumerators == ALLOCATION_DENOMINATOR, "INVALID_ALLOCATION");
        emit AllocationSettingSet(_expiries, _allocationNumerators);
    }

    /**
     * @notice Use to stake their LPs to a specific expiry
     * @param newLpHoldingContractAddress will be /= 0 in case a new lpHolder contract is deployed
    Conditions:
        * only be called if the contract has been funded
        * must have Reentrancy protection
        * only be called if 0 < current epoch <= numberOfEpochs
    Note:
        * Even if an expiry currently has zero rewards allocated to it, we still allow users to stake their
        LP in
     */
    function stake(
        address to,
        uint256 expiry,
        uint256 amount
    )
        external
        override
        isFunded
        nonReentrant
        nonContractOrWhitelisted
        returns (address newLpHoldingContractAddress)
    {
        checkNotPaused();
        newLpHoldingContractAddress = _stake(to, expiry, amount);
    }

    /**
     * @notice Similar to stake() function, but using a permit to approve for LP tokens first
     */
    function stakeWithPermit(
        uint256 expiry,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        override
        isFunded
        nonReentrant
        nonContractOrWhitelisted
        returns (address newLpHoldingContractAddress)
    {
        checkNotPaused();
        address xyt = address(data.xytTokens(forgeId, underlyingAsset, expiry));
        address marketAddress = data.getMarket(marketFactoryId, xyt, baseToken);
        // Pendle Market LP tokens are EIP-2612 compliant, hence we can approve liq-mining contract using a signature
        IPendleYieldToken(marketAddress).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );

        newLpHoldingContractAddress = _stake(msg.sender, expiry, amount);
    }

    /**
     * @notice Use to withdraw their LP from a specific expiry
    Conditions:
        * only be called if the contract has been funded.
        * must have Reentrancy protection
        * only be called if 0 < current epoch (always can withdraw)
     */
    function withdraw(
        address to,
        uint256 expiry,
        uint256 amount
    ) external override nonReentrant isFunded {
        checkNotPaused();
        uint256 curEpoch = getCurrentEpochId();
        require(curEpoch > 0, "NOT_STARTED");
        require(amount != 0, "ZERO_AMOUNT");

        ExpiryData storage exd = expiryData[expiry];
        require(exd.balances[msg.sender] >= amount, "INSUFFICIENT_BALANCE");

        _pushLpToken(to, expiry, amount);
        emit Withdrawn(expiry, msg.sender, amount);
    }

    /**
     * @notice use to claim PENDLE rewards
    Conditions:
        * only be called if the contract has been funded.
        * must have Reentrancy protection
        * only be called if 0 < current epoch (always can withdraw)
        * Anyone can call it (and claim it for any other user)
     */
    function redeemRewards(uint256 expiry, address user)
        external
        override
        isFunded
        nonReentrant
        returns (uint256 rewards)
    {
        checkNotPaused();
        uint256 curEpoch = getCurrentEpochId();
        require(curEpoch > 0, "NOT_STARTED");
        require(user != address(0), "ZERO_ADDRESS");
        require(userExpiries[user].hasExpiry[expiry], "INVALID_EXPIRY");

        rewards = _beforeTransferPendingRewards(expiry, user);
        if (rewards != 0) {
            IERC20(pendleTokenAddress).safeTransfer(user, rewards);
        }
    }

    /**
     * @notice use to claim lpInterest
    Conditions:
        * must have Reentrancy protection
        * Anyone can call it (and claim it for any other user)
     */
    function redeemLpInterests(uint256 expiry, address user)
        external
        override
        nonReentrant
        returns (uint256 interests)
    {
        checkNotPaused();
        require(user != address(0), "ZERO_ADDRESS");
        require(userExpiries[user].hasExpiry[expiry], "INVALID_EXPIRY");
        interests = _beforeTransferDueInterests(expiry, user);
        _safeTransferYieldToken(expiry, user, interests);
        emit RedeemLpInterests(expiry, user, interests);
    }

    function totalRewardsForEpoch(uint256 epochId)
        external
        view
        override
        returns (uint256 rewards)
    {
        rewards = epochData[epochId].totalRewards;
    }

    function readUserExpiries(address _user)
        external
        view
        override
        returns (uint256[] memory _expiries)
    {
        _expiries = userExpiries[_user].expiries;
    }

    function getBalances(uint256 expiry, address user) external view override returns (uint256) {
        return expiryData[expiry].balances[user];
    }

    function lpHolderForExpiry(uint256 expiry) external view override returns (address) {
        return expiryData[expiry].lpHolder;
    }

    function readExpiryData(uint256 expiry)
        external
        view
        returns (
            uint256 totalStakeLP,
            uint256 lastNYield,
            uint256 paramL,
            address lpHolder
        )
    {
        totalStakeLP = expiryData[expiry].totalStakeLP;
        lastNYield = expiryData[expiry].lastNYield;
        paramL = expiryData[expiry].paramL;
        lpHolder = expiryData[expiry].lpHolder;
    }

    function readUserSpecificExpiryData(uint256 expiry, address user)
        external
        view
        returns (
            uint256 lastTimeUserStakeUpdated,
            uint256 lastEpochClaimed,
            uint256 balances,
            uint256 lastParamL,
            uint256 dueInterests
        )
    {
        lastTimeUserStakeUpdated = expiryData[expiry].lastTimeUserStakeUpdated[user];
        lastEpochClaimed = expiryData[expiry].lastEpochClaimed[user];
        balances = expiryData[expiry].balances[user];
        lastParamL = expiryData[expiry].lastParamL[user];
        dueInterests = expiryData[expiry].dueInterests[user];
    }

    function readEpochData(uint256 epochId)
        external
        view
        returns (uint256 settingId, uint256 totalRewards)
    {
        settingId = epochData[epochId].settingId;
        totalRewards = epochData[epochId].totalRewards;
    }

    function readExpirySpecificEpochData(uint256 epochId, uint256 expiry)
        external
        view
        returns (uint256 stakeUnits, uint256 lastUpdatedForExpiry)
    {
        stakeUnits = epochData[epochId].stakeUnitsForExpiry[expiry];
        lastUpdatedForExpiry = epochData[epochId].lastUpdatedForExpiry[expiry];
    }

    function readAvailableRewardsForUser(uint256 epochId, address user)
        external
        view
        returns (uint256 availableRewardsForUser)
    {
        availableRewardsForUser = epochData[epochId].availableRewardsForUser[user];
    }

    function readStakeUnitsForUser(
        uint256 epochId,
        address user,
        uint256 expiry
    ) external view returns (uint256 stakeUnitsForUser) {
        stakeUnitsForUser = epochData[epochId].stakeUnitsForUser[user][expiry];
    }

    function readAllExpiriesLength() external view override returns (uint256 length) {
        length = allExpiries.length;
    }

    // 1-indexed
    function getCurrentEpochId() public view returns (uint256) {
        return _epochOfTimestamp(block.timestamp);
    }

    function checkNotPaused() internal {
        (bool paused, ) = pausingManager.checkLiqMiningStatus(address(this));
        require(!paused, "LIQ_MINING_PAUSED");
    }

    function _stake(
        address to,
        uint256 expiry,
        uint256 amount
    ) internal returns (address newLpHoldingContractAddress) {
        ExpiryData storage exd = expiryData[expiry];
        uint256 curEpoch = getCurrentEpochId();
        require(curEpoch > 0, "NOT_STARTED");
        require(curEpoch <= numberOfEpochs, "INCENTIVES_PERIOD_OVER");
        require(amount != 0, "ZERO_AMOUNT");

        address xyt = address(data.xytTokens(forgeId, underlyingAsset, expiry));
        address marketAddress = data.getMarket(marketFactoryId, xyt, baseToken);
        require(xyt != address(0), "YT_NOT_FOUND");
        require(marketAddress != address(0), "MARKET_NOT_FOUND");

        // there is no lpHolder for this expiry yet, we will create one
        if (exd.lpHolder == address(0)) {
            newLpHoldingContractAddress = _addNewExpiry(expiry, marketAddress);
        }

        if (!userExpiries[msg.sender].hasExpiry[expiry]) {
            userExpiries[msg.sender].expiries.push(expiry);
            userExpiries[msg.sender].hasExpiry[expiry] = true;
        }

        _pullLpToken(to, marketAddress, expiry, amount);
        emit Staked(expiry, msg.sender, amount);
    }

    /**
    @notice update the following stake data for the current epoch:
        - epochData[_curEpoch].stakeUnitsForExpiry
        - epochData[_curEpoch].lastUpdatedForExpiry
    @dev If this is the very first transaction involving this expiry, then need to update for the
    previous epoch as well. If the previous didn't have any transactions at all, (and hence was not
    updated at all), we need to update it and check the previous previous ones, and so on..
    @dev must be called right before every _updatePendingRewards()
    @dev this is the only function that updates lastTimeUserStakeUpdated & stakeUnitsForExpiry
    @dev other functions must make sure that totalStakeLPForExpiry could be assumed
        to stay exactly the same since lastTimeUserStakeUpdated until now;
    @dev to be called only by _updatePendingRewards
     */
    function _updateStakeDataForExpiry(uint256 expiry) internal {
        uint256 _curEpoch = getCurrentEpochId();

        // loop through all epochData in descending order
        for (uint256 i = Math.min(_curEpoch, numberOfEpochs); i > 0; i--) {
            uint256 epochEndTime = _endTimeOfEpoch(i);
            uint256 lastUpdatedForEpoch = epochData[i].lastUpdatedForExpiry[expiry];

            if (lastUpdatedForEpoch == epochEndTime) {
                break; // its already updated until this epoch, our job here is done
            }

            // if the epoch hasn't been fully updated yet, we will update it
            // just add the amount of units contributed by users since lastUpdatedForEpoch -> now
            // by calling _calcUnitsStakeInEpoch
            epochData[i].stakeUnitsForExpiry[expiry] = epochData[i]
                .stakeUnitsForExpiry[expiry]
                .add(
                    _calcUnitsStakeInEpoch(expiryData[expiry].totalStakeLP, lastUpdatedForEpoch, i)
                );
            // If the epoch has ended, lastUpdated = epochEndTime
            // If not yet, lastUpdated = block.timestamp (aka now)
            epochData[i].lastUpdatedForExpiry[expiry] = Math.min(block.timestamp, epochEndTime);
        }
    }

    /**
    @notice Update pending rewards to users
        The rewards are calculated since the last time rewards was calculated for him,
        I.e. Since the last time his stake was "updated"
        I.e. Since lastTimeUserStakeUpdated[user]
    @dev The user's stake since lastTimeUserStakeUpdated[user] until now = balances[user][expiry]
    @dev After this function, the following should be updated correctly up to this point:
            - availableRewardsForEpoch[user][all epochData]
            - epochData[all epochData].stakeUnitsForUser
    @dev This must be called before any transfer action of LP (push LP, pull LP)
        (and this has been implemented in two functions _pushLpToken & _pullLpToken of this contract)
    */
    function _updatePendingRewards(uint256 expiry, address user) internal {
        _updateStakeDataForExpiry(expiry);
        ExpiryData storage exd = expiryData[expiry];

        // user has not staked this LP_expiry before, no need to do anything
        if (exd.lastTimeUserStakeUpdated[user] == 0) {
            exd.lastTimeUserStakeUpdated[user] = block.timestamp;
            return;
        }

        uint256 _curEpoch = getCurrentEpochId();
        uint256 _endEpoch = Math.min(numberOfEpochs, _curEpoch);

        // if _curEpoch<=numberOfEpochs
        // => the endEpoch hasn't ended yet (since endEpoch=curEpoch)
        bool _isEndEpochOver = (_curEpoch > numberOfEpochs);

        uint256 _startEpoch = _epochOfTimestamp(exd.lastTimeUserStakeUpdated[user]);

        /* Go through all epochs until now
        to update stakeUnitsForUser and availableRewardsForEpoch
        */
        for (uint256 epochId = _startEpoch; epochId <= _endEpoch; epochId++) {
            if (epochData[epochId].stakeUnitsForExpiry[expiry] == 0) {
                /* in the extreme extreme case of zero staked LPs for this expiry even now,
                    => nothing to do from this epoch onwards */
                if (exd.totalStakeLP == 0) break;
                continue;
            }

            // updating stakeUnits for users. The logic of this is similar to that of _updateStakeDataForExpiry
            // Please refer to _updateStakeDataForExpiry for more details
            epochData[epochId].stakeUnitsForUser[user][expiry] = epochData[epochId]
            .stakeUnitsForUser[user][expiry].add(
                    _calcUnitsStakeInEpoch(
                        exd.balances[user],
                        exd.lastTimeUserStakeUpdated[user],
                        epochId
                    )
                );

            // all epochs prior to the endEpoch must have ended
            // if epochId == _endEpoch, we must check if the epoch has ended or not
            if (epochId == _endEpoch && !_isEndEpochOver) {
                // not ended yet, break
                break;
            }

            // Now this epoch has ended,let's distribute its reward to this user

            // calc the amount of rewards the user is eligible to receive from this epoch
            uint256 rewardsPerVestingEpoch = _calcAmountRewardsForUserInEpoch(
                expiry,
                user,
                epochId
            );

            // Now we distribute this rewards over the vestingEpochs starting from epochId + 1
            // to epochId + vestingEpochs
            for (uint256 i = epochId + 1; i <= epochId + vestingEpochs; i++) {
                epochData[i].availableRewardsForUser[user] = epochData[i]
                    .availableRewardsForUser[user]
                    .add(rewardsPerVestingEpoch);
            }
        }

        exd.lastTimeUserStakeUpdated[user] = block.timestamp;
    }

    // calc the amount of rewards the user is eligible to receive from this epoch
    // but we will return the amount per vestingEpoch instead
    function _calcAmountRewardsForUserInEpoch(
        uint256 expiry,
        address user,
        uint256 epochId
    ) internal view returns (uint256 rewardsPerVestingEpoch) {
        uint256 settingId = epochId >= latestSetting.firstEpochToApply
            ? latestSetting.id
            : epochData[epochId].settingId;

        uint256 rewardsForThisExpiry = epochData[epochId]
            .totalRewards
            .mul(allocationSettings[settingId][expiry])
            .div(ALLOCATION_DENOMINATOR);

        rewardsPerVestingEpoch = rewardsForThisExpiry
            .mul(epochData[epochId].stakeUnitsForUser[user][expiry])
            .div(epochData[epochId].stakeUnitsForExpiry[expiry])
            .div(vestingEpochs);
    }

    /**
     * @notice returns the stakeUnits in the _epochId(th) epoch of an user if he stake from _startTime to now
     * @dev to calculate durationStakeThisEpoch:
     *   user will stake from _startTime -> _endTime, while the epoch last from _startTimeOfEpoch -> _endTimeOfEpoch
     *   => the stakeDuration of user will be min(_endTime,_endTimeOfEpoch) - max(_startTime,_startTimeOfEpoch)
     */
    function _calcUnitsStakeInEpoch(
        uint256 lpAmount,
        uint256 _startTime,
        uint256 _epochId
    ) internal view returns (uint256 stakeUnitsForUser) {
        uint256 _endTime = block.timestamp;

        uint256 _l = Math.max(_startTime, _startTimeOfEpoch(_epochId));
        uint256 _r = Math.min(_endTime, _endTimeOfEpoch(_epochId));
        uint256 durationStakeThisEpoch = _r.subMax0(_l);

        return lpAmount.mul(durationStakeThisEpoch);
    }

    /// @notice pull the lp token from users. This must be the only way to pull LP
    function _pullLpToken(
        address to,
        address marketAddress,
        uint256 expiry,
        uint256 amount
    ) internal {
        _updatePendingRewards(expiry, to);
        _updateDueInterests(expiry, to);

        ExpiryData storage exd = expiryData[expiry];
        exd.balances[to] = exd.balances[to].add(amount);
        exd.totalStakeLP = exd.totalStakeLP.add(amount);

        IERC20(marketAddress).safeTransferFrom(msg.sender, expiryData[expiry].lpHolder, amount);
    }

    /// @notice push the lp token to users. This must be the only way to send LP out
    function _pushLpToken(
        address to,
        uint256 expiry,
        uint256 amount
    ) internal {
        _updatePendingRewards(expiry, msg.sender);
        _updateDueInterests(expiry, msg.sender);

        ExpiryData storage exd = expiryData[expiry];
        exd.balances[msg.sender] = exd.balances[msg.sender].sub(amount);
        exd.totalStakeLP = exd.totalStakeLP.sub(amount);

        IPendleLpHolder(expiryData[expiry].lpHolder).sendLp(to, amount);
    }

    /**
     * Same logic as the function in PendleMarketBase
     */
    function _beforeTransferDueInterests(uint256 expiry, address user)
        internal
        returns (uint256 amountOut)
    {
        ExpiryData storage exd = expiryData[expiry];

        _updateDueInterests(expiry, user);

        amountOut = exd.dueInterests[user];
        exd.dueInterests[user] = 0;

        exd.lastNYield = exd.lastNYield.subMax0(amountOut);
    }

    /**
    @dev Must be the only way to transfer aToken/cToken out
    @dev Please refer to _safeTransfer of PendleForgeBase for the rationale of this function
    */
    function _safeTransferYieldToken(
        uint256 _expiry,
        address _user,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;
        _amount = Math.min(
            _amount,
            IERC20(underlyingYieldToken).balanceOf(expiryData[_expiry].lpHolder)
        );
        IPendleLpHolder(expiryData[_expiry].lpHolder).sendInterests(_user, _amount);
    }

    /**
    @notice Calc the amount of rewards that the user can receive now.
    @dev To be called before any rewards is transferred out
    */
    function _beforeTransferPendingRewards(uint256 expiry, address user)
        internal
        returns (uint256 amountOut)
    {
        _updatePendingRewards(expiry, user);

        uint256 _lastEpoch = Math.min(getCurrentEpochId(), numberOfEpochs + vestingEpochs);
        for (uint256 i = expiryData[expiry].lastEpochClaimed[user]; i <= _lastEpoch; i++) {
            if (epochData[i].availableRewardsForUser[user] > 0) {
                amountOut = amountOut.add(epochData[i].availableRewardsForUser[user]);
                epochData[i].availableRewardsForUser[user] = 0;
            }
        }

        expiryData[expiry].lastEpochClaimed[user] = _lastEpoch;
        emit PendleRewardsSettled(expiry, user, amountOut);
        return amountOut;
    }

    /**
     * @dev Same logic as the function in PendleMarketBase
     */
    function checkNeedUpdateParamL(uint256 expiry) internal returns (bool) {
        return _getIncomeIndexIncreaseRate(expiry) > data.interestUpdateRateDeltaForMarket();
    }

    /**
     * @dev all LP interests related functions are almost identical to markets' functions
     * @dev Same logic as the function in PendleMarketBase
     */
    function _updateParamL(uint256 expiry) internal {
        ExpiryData storage exd = expiryData[expiry];

        if (!checkNeedUpdateParamL(expiry)) return;

        IPendleLpHolder(exd.lpHolder).redeemLpInterests();

        uint256 currentNYield = IERC20(underlyingYieldToken).balanceOf(exd.lpHolder);
        (uint256 firstTerm, uint256 paramR) = _getFirstTermAndParamR(expiry, currentNYield);

        uint256 secondTerm;

        if (exd.totalStakeLP != 0) secondTerm = paramR.mul(MULTIPLIER).div(exd.totalStakeLP);

        // Update new states
        exd.paramL = firstTerm.add(secondTerm);
        exd.lastNYield = currentNYield;
    }

    /**
     * @notice Use to create a new lpHolder contract
     * Must only be called by Stake
     */
    function _addNewExpiry(uint256 expiry, address marketAddress)
        internal
        returns (address newLpHoldingContractAddress)
    {
        allExpiries.push(expiry);
        newLpHoldingContractAddress = address(
            new PendleLpHolder(
                address(governanceManager),
                marketAddress,
                address(router),
                underlyingYieldToken
            )
        );
        expiryData[expiry].lpHolder = newLpHoldingContractAddress;
        _afterAddingNewExpiry(expiry);
    }


    function _epochOfTimestamp(uint256 t) internal view returns (uint256) {
        if (t < startTime) return 0;
        return (t.sub(startTime)).div(epochDuration).add(1);
    }

    function _startTimeOfEpoch(uint256 t) internal view returns (uint256) {
        // epoch id starting from 1
        return startTime.add((t.sub(1)).mul(epochDuration));
    }

    function _endTimeOfEpoch(uint256 t) internal view returns (uint256) {
        // epoch id starting from 1
        return startTime.add(t.mul(epochDuration));
    }

    // There should be only PENDLE in here(LPs and yield tokens are kept in LP holders)
    // hence governance is allowed to withdraw anything other than PENDLE
    function _allowedToWithdraw(address _token) internal view override returns (bool allowed) {
        allowed = _token != pendleTokenAddress;
    }

    function _updateDueInterests(uint256 expiry, address user) internal virtual;

    function _getFirstTermAndParamR(uint256 expiry, uint256 currentNYield)
        internal
        virtual
        returns (uint256 firstTerm, uint256 paramR);

    function _afterAddingNewExpiry(uint256 expiry) internal virtual;

    function _getIncomeIndexIncreaseRate(uint256 expiry)
        internal
        virtual
        returns (uint256 increaseRate);
}