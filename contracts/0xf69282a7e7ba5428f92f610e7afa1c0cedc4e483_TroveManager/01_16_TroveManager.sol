// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "SafeERC20.sol";
import "IERC20.sol";
import "Math.sol";
import "IBorrowerOperations.sol";
import "IDebtToken.sol";
import "ISortedTroves.sol";
import "IVault.sol";
import "IPriceFeed.sol";
import "SystemStart.sol";
import "PrismaBase.sol";
import "PrismaMath.sol";
import "PrismaOwnable.sol";

/**
    @title Prisma Trove Manager
    @notice Based on Liquity's `TroveManager`
            https://github.com/liquity/dev/blob/main/packages/contracts/contracts/TroveManager.sol

            Prisma's implementation is modified so that multiple `TroveManager` and `SortedTroves`
            contracts are deployed in tandem, with each pair managing troves of a single collateral
            type.

            Functionality related to liquidations has been moved to `LiquidationManager`. This was
            necessary to avoid the restriction on deployed bytecode size.
 */
contract TroveManager is PrismaBase, PrismaOwnable, SystemStart {
    using SafeERC20 for IERC20;

    // --- Connected contract declarations ---

    address public immutable borrowerOperationsAddress;
    address public immutable liquidationManager;
    address immutable gasPoolAddress;
    IDebtToken public immutable debtToken;
    IPrismaVault public immutable vault;

    IPriceFeed public priceFeed;
    IERC20 public collateralToken;

    // A doubly linked list of Troves, sorted by their collateral ratios
    ISortedTroves public sortedTroves;

    EmissionId public emissionId;
    // Minimum collateral ratio for individual troves
    uint256 public MCR;

    uint256 constant SECONDS_IN_ONE_MINUTE = 60;
    uint256 constant INTEREST_PRECISION = 1e27;
    uint256 constant SECONDS_IN_YEAR = 365 days;
    uint256 constant REWARD_DURATION = 1 weeks;

    // volume-based amounts are divided by this value to allow storing as uint32
    uint256 constant VOLUME_MULTIPLIER = 1e20;

    // Maximum interest rate must be lower than the minimum LST staking yield
    // so that over time the actual TCR becomes greater than the calculated TCR.
    uint256 public constant MAX_INTEREST_RATE_IN_BPS = 400; // 4%
    uint256 public constant SUNSETTING_INTEREST_RATE = (INTEREST_PRECISION * 5000) / (10000 * SECONDS_IN_YEAR); //50%

    // During bootsrap period redemptions are not allowed
    uint256 public constant BOOTSTRAP_PERIOD = 14 days;

    /*
     * BETA: 18 digit decimal. Parameter by which to divide the redeemed fraction, in order to calc the new base rate from a redemption.
     * Corresponds to (1 / ALPHA) in the white paper.
     */
    uint256 constant BETA = 2;

    // commented values are Liquity's fixed settings for each parameter
    uint256 public minuteDecayFactor; // 999037758833783000  (half-life of 12 hours)
    uint256 public redemptionFeeFloor; // DECIMAL_PRECISION / 1000 * 5  (0.5%)
    uint256 public maxRedemptionFee; // DECIMAL_PRECISION  (100%)
    uint256 public borrowingFeeFloor; // DECIMAL_PRECISION / 1000 * 5  (0.5%)
    uint256 public maxBorrowingFee; // DECIMAL_PRECISION / 100 * 5  (5%)
    uint256 public maxSystemDebt;

    uint256 public interestRate;
    uint256 public activeInterestIndex;
    uint256 public lastActiveIndexUpdate;

    uint256 public systemDeploymentTime;
    bool public sunsetting;
    bool public paused;

    uint256 public baseRate;

    // The timestamp of the latest fee operation (redemption or new debt issuance)
    uint256 public lastFeeOperationTime;

    uint256 public totalStakes;

    // Snapshot of the value of totalStakes, taken immediately after the latest liquidation
    uint256 public totalStakesSnapshot;

    // Snapshot of the total collateral taken immediately after the latest liquidation.
    uint256 public totalCollateralSnapshot;

    /*
     * L_collateral and L_debt track the sums of accumulated liquidation rewards per unit staked. During its lifetime, each stake earns:
     *
     * An collateral gain of ( stake * [L_collateral - L_collateral(0)] )
     * A debt increase  of ( stake * [L_debt - L_debt(0)] )
     *
     * Where L_collateral(0) and L_debt(0) are snapshots of L_collateral and L_debt for the active Trove taken at the instant the stake was made
     */
    uint256 public L_collateral;
    uint256 public L_debt;

    // Error trackers for the trove redistribution calculation
    uint256 public lastCollateralError_Redistribution;
    uint256 public lastDebtError_Redistribution;

    uint256 internal totalActiveCollateral;
    uint256 internal totalActiveDebt;
    uint256 public interestPayable;

    uint256 public defaultedCollateral;
    uint256 public defaultedDebt;

    uint256 public rewardIntegral;
    uint128 public rewardRate;
    uint32 public lastUpdate;
    uint32 public periodFinish;

    mapping(address => uint256) public rewardIntegralFor;
    mapping(address => uint256) private storedPendingReward;

    // week -> total available rewards for 1 day within this week
    uint256[65535] public dailyMintReward;

    // week -> day -> total amount redeemed this day
    uint32[7][65535] private totalMints;

    // account -> data for latest activity
    mapping(address => VolumeData) public accountLatestMint;

    mapping(address => Trove) public Troves;
    mapping(address => uint256) public surplusBalances;

    // Map addresses with active troves to their RewardSnapshot
    mapping(address => RewardSnapshot) public rewardSnapshots;

    // Array of all active trove addresses - used to to compute an approximate hint off-chain, for the sorted list insertion
    address[] TroveOwners;

    struct VolumeData {
        uint32 amount;
        uint32 week;
        uint32 day;
    }

    struct EmissionId {
        uint16 debt;
        uint16 minting;
    }

    // Store the necessary data for a trove
    struct Trove {
        uint256 debt;
        uint256 coll;
        uint256 stake;
        Status status;
        uint128 arrayIndex;
        uint256 activeInterestIndex;
    }

    struct RedemptionTotals {
        uint256 remainingDebt;
        uint256 totalDebtToRedeem;
        uint256 totalCollateralDrawn;
        uint256 collateralFee;
        uint256 collateralToSendToRedeemer;
        uint256 decayedBaseRate;
        uint256 price;
        uint256 totalDebtSupplyAtStart;
    }

    struct SingleRedemptionValues {
        uint256 debtLot;
        uint256 collateralLot;
        bool cancelledPartial;
    }

    // Object containing the collateral and debt snapshots for a given active trove
    struct RewardSnapshot {
        uint256 collateral;
        uint256 debt;
    }

    enum TroveManagerOperation {
        applyPendingRewards,
        liquidateInNormalMode,
        liquidateInRecoveryMode,
        redeemCollateral
    }

    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }

    event TroveUpdated(
        address indexed _borrower,
        uint256 _debt,
        uint256 _coll,
        uint256 _stake,
        TroveManagerOperation _operation
    );
    event Redemption(
        uint256 _attemptedDebtAmount,
        uint256 _actualDebtAmount,
        uint256 _collateralSent,
        uint256 _collateralFee
    );
    event TroveUpdated(address indexed _borrower, uint256 _debt, uint256 _coll, uint256 stake, uint8 operation);
    event BaseRateUpdated(uint256 _baseRate);
    event LastFeeOpTimeUpdated(uint256 _lastFeeOpTime);
    event TotalStakesUpdated(uint256 _newTotalStakes);
    event SystemSnapshotsUpdated(uint256 _totalStakesSnapshot, uint256 _totalCollateralSnapshot);
    event LTermsUpdated(uint256 _L_collateral, uint256 _L_debt);
    event TroveSnapshotsUpdated(uint256 _L_collateral, uint256 _L_debt);
    event TroveIndexUpdated(address _borrower, uint256 _newIndex);
    event CollateralSent(address _to, uint256 _amount);
    event RewardClaimed(address indexed account, address indexed recipient, uint256 claimed);

    modifier whenNotPaused() {
        require(!paused, "Collateral Paused");
        _;
    }

    constructor(
        address _prismaCore,
        address _gasPoolAddress,
        address _debtTokenAddress,
        address _borrowerOperationsAddress,
        address _vault,
        address _liquidationManager,
        uint256 _gasCompensation
    ) PrismaOwnable(_prismaCore) PrismaBase(_gasCompensation) SystemStart(_prismaCore) {
        gasPoolAddress = _gasPoolAddress;
        debtToken = IDebtToken(_debtTokenAddress);
        borrowerOperationsAddress = _borrowerOperationsAddress;
        vault = IPrismaVault(_vault);
        liquidationManager = _liquidationManager;
    }

    function setAddresses(address _priceFeedAddress, address _sortedTrovesAddress, address _collateralToken) external {
        require(address(sortedTroves) == address(0));
        priceFeed = IPriceFeed(_priceFeedAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        collateralToken = IERC20(_collateralToken);

        systemDeploymentTime = block.timestamp;
        sunsetting = false;
        activeInterestIndex = INTEREST_PRECISION;
        lastActiveIndexUpdate = block.timestamp;
    }

    function notifyRegisteredId(uint256[] calldata _assignedIds) external returns (bool) {
        require(msg.sender == address(vault));
        require(emissionId.debt == 0, "Already assigned");
        uint256 length = _assignedIds.length;
        require(length == 2, "Incorrect ID count");
        emissionId = EmissionId({ debt: uint16(_assignedIds[0]), minting: uint16(_assignedIds[1]) });
        periodFinish = uint32(((block.timestamp / 1 weeks) + 1) * 1 weeks);

        return true;
    }

    /**
     * @notice Sets the pause state for this trove manager
     *         Pausing is used to mitigate risks in exceptional circumstances
     *         Functionalities affected by pausing are:
     *         - New borrowing is not possible
     *         - New collateral deposits are not possible
     * @param _paused If true the protocol is paused
     */
    function setPaused(bool _paused) external {
        require((_paused && msg.sender == guardian()) || msg.sender == owner(), "Unauthorized");
        paused = _paused;
    }

    /**
     * @notice Sets a custom price feed for this trove manager
     * @param _priceFeedAddress Price feed address
     */
    function setPriceFeed(address _priceFeedAddress) external onlyOwner {
        priceFeed = IPriceFeed(_priceFeedAddress);
    }

    /**
     * @notice Starts sunsetting a collateral
     *         During sunsetting only the following are possible:
               1) Disable collateral handoff to SP
               2) Greatly Increase interest rate to incentivize redemptions
               3) Remove redemptions fees
               4) Disable new loans
        @dev IMPORTANT: When sunsetting a collateral altogether this function should be called on
                        all TM linked to that collateral as well as `StabilityPool.startCollateralSunset`
     */
    function startSunset() external onlyOwner {
        sunsetting = true;
        _accrueActiveInterests();
        interestRate = SUNSETTING_INTEREST_RATE;
        // accrual function doesn't update timestamp if interest was 0
        lastActiveIndexUpdate = block.timestamp;
        redemptionFeeFloor = 0;
        maxSystemDebt = 0;
    }

    /*
        _minuteDecayFactor is calculated as

            10**18 * (1/2)**(1/n)

        where n = the half-life in minutes
     */
    function setParameters(
        uint256 _minuteDecayFactor,
        uint256 _redemptionFeeFloor,
        uint256 _maxRedemptionFee,
        uint256 _borrowingFeeFloor,
        uint256 _maxBorrowingFee,
        uint256 _interestRateInBPS,
        uint256 _maxSystemDebt,
        uint256 _MCR
    ) public {
        require(!sunsetting, "Cannot change after sunset");
        require(_MCR <= CCR && _MCR >= 1100000000000000000, "MCR cannot be > CCR or < 110%");
        if (minuteDecayFactor != 0) {
            require(msg.sender == owner(), "Only owner");
        }
        require(
            _minuteDecayFactor >= 977159968434245000 && // half-life of 30 minutes
                _minuteDecayFactor <= 999931237762985000 // half-life of 1 week
        );
        require(_redemptionFeeFloor <= _maxRedemptionFee && _maxRedemptionFee <= DECIMAL_PRECISION);
        require(_borrowingFeeFloor <= _maxBorrowingFee && _maxBorrowingFee <= DECIMAL_PRECISION);

        _decayBaseRate();

        minuteDecayFactor = _minuteDecayFactor;
        redemptionFeeFloor = _redemptionFeeFloor;
        maxRedemptionFee = _maxRedemptionFee;
        borrowingFeeFloor = _borrowingFeeFloor;
        maxBorrowingFee = _maxBorrowingFee;
        maxSystemDebt = _maxSystemDebt;

        require(_interestRateInBPS <= MAX_INTEREST_RATE_IN_BPS, "Interest > Maximum");

        uint256 newInterestRate = (INTEREST_PRECISION * _interestRateInBPS) / (10000 * SECONDS_IN_YEAR);
        if (newInterestRate != interestRate) {
            _accrueActiveInterests();
            // accrual function doesn't update timestamp if interest was 0
            lastActiveIndexUpdate = block.timestamp;
            interestRate = newInterestRate;
        }
        MCR = _MCR;
    }

    function collectInterests() external {
        uint256 interestPayableCached = interestPayable;
        require(interestPayableCached > 0, "Nothing to collect");
        debtToken.mint(PRISMA_CORE.feeReceiver(), interestPayableCached);
        interestPayable = 0;
    }

    // --- Getters ---

    function fetchPrice() public returns (uint256) {
        IPriceFeed _priceFeed = priceFeed;
        if (address(_priceFeed) == address(0)) {
            _priceFeed = IPriceFeed(PRISMA_CORE.priceFeed());
        }
        return _priceFeed.fetchPrice(address(collateralToken));
    }

    function getWeekAndDay() public view returns (uint256, uint256) {
        uint256 duration = (block.timestamp - startTime);
        uint256 week = duration / 1 weeks;
        uint256 day = (duration % 1 weeks) / 1 days;
        return (week, day);
    }

    function getTotalMints(uint256 week) external view returns (uint32[7] memory) {
        return totalMints[week];
    }

    function getTroveOwnersCount() external view returns (uint256) {
        return TroveOwners.length;
    }

    function getTroveFromTroveOwnersArray(uint256 _index) external view returns (address) {
        return TroveOwners[_index];
    }

    function getTroveStatus(address _borrower) external view returns (uint256) {
        return uint256(Troves[_borrower].status);
    }

    function getTroveStake(address _borrower) external view returns (uint256) {
        return Troves[_borrower].stake;
    }

    /**
        @notice Get the current total collateral and debt amounts for a trove
        @dev Also includes pending rewards from redistribution
     */
    function getTroveCollAndDebt(address _borrower) public view returns (uint256 coll, uint256 debt) {
        (debt, coll, , ) = getEntireDebtAndColl(_borrower);
        return (coll, debt);
    }

    /**
        @notice Get the total and pending collateral and debt amounts for a trove
        @dev Used by the liquidation manager
     */
    function getEntireDebtAndColl(
        address _borrower
    ) public view returns (uint256 debt, uint256 coll, uint256 pendingDebtReward, uint256 pendingCollateralReward) {
        Trove storage t = Troves[_borrower];
        debt = t.debt;
        coll = t.coll;

        (pendingCollateralReward, pendingDebtReward) = getPendingCollAndDebtRewards(_borrower);
        // Accrued trove interest for correct liquidation values. This assumes the index to be updated.
        uint256 troveInterestIndex = t.activeInterestIndex;
        if (troveInterestIndex > 0) {
            (uint256 currentIndex, ) = _calculateInterestIndex();
            debt = (debt * currentIndex) / troveInterestIndex;
        }

        debt = debt + pendingDebtReward;
        coll = coll + pendingCollateralReward;
    }

    function getEntireSystemColl() public view returns (uint256) {
        return totalActiveCollateral + defaultedCollateral;
    }

    function getEntireSystemDebt() public view returns (uint256) {
        uint256 currentActiveDebt = totalActiveDebt;
        (, uint256 interestFactor) = _calculateInterestIndex();
        if (interestFactor > 0) {
            uint256 activeInterests = Math.mulDiv(currentActiveDebt, interestFactor, INTEREST_PRECISION);
            currentActiveDebt = currentActiveDebt + activeInterests;
        }
        return currentActiveDebt + defaultedDebt;
    }

    function getEntireSystemBalances() external returns (uint256, uint256, uint256) {
        return (getEntireSystemColl(), getEntireSystemDebt(), fetchPrice());
    }

    // --- Helper functions ---

    // Return the nominal collateral ratio (ICR) of a given Trove, without the price. Takes a trove's pending coll and debt rewards from redistributions into account.
    function getNominalICR(address _borrower) public view returns (uint256) {
        (uint256 currentCollateral, uint256 currentDebt) = getTroveCollAndDebt(_borrower);

        uint256 NICR = PrismaMath._computeNominalCR(currentCollateral, currentDebt);
        return NICR;
    }

    // Return the current collateral ratio (ICR) of a given Trove. Takes a trove's pending coll and debt rewards from redistributions into account.
    function getCurrentICR(address _borrower, uint256 _price) public view returns (uint256) {
        (uint256 currentCollateral, uint256 currentDebt) = getTroveCollAndDebt(_borrower);

        uint256 ICR = PrismaMath._computeCR(currentCollateral, currentDebt, _price);
        return ICR;
    }

    function getTotalActiveCollateral() public view returns (uint256) {
        return totalActiveCollateral;
    }

    function getTotalActiveDebt() public view returns (uint256) {
        uint256 currentActiveDebt = totalActiveDebt;
        (, uint256 interestFactor) = _calculateInterestIndex();
        if (interestFactor > 0) {
            uint256 activeInterests = Math.mulDiv(currentActiveDebt, interestFactor, INTEREST_PRECISION);
            currentActiveDebt = currentActiveDebt + activeInterests;
        }
        return currentActiveDebt;
    }

    // Get the borrower's pending accumulated collateral and debt rewards, earned by their stake
    function getPendingCollAndDebtRewards(address _borrower) public view returns (uint256, uint256) {
        RewardSnapshot memory snapshot = rewardSnapshots[_borrower];

        uint256 coll = L_collateral - snapshot.collateral;
        uint256 debt = L_debt - snapshot.debt;

        if (coll + debt == 0 || Troves[_borrower].status != Status.active) return (0, 0);

        uint256 stake = Troves[_borrower].stake;
        return ((stake * coll) / DECIMAL_PRECISION, (stake * debt) / DECIMAL_PRECISION);
    }

    function hasPendingRewards(address _borrower) public view returns (bool) {
        /*
         * A Trove has pending rewards if its snapshot is less than the current rewards per-unit-staked sum:
         * this indicates that rewards have occured since the snapshot was made, and the user therefore has
         * pending rewards
         */
        if (Troves[_borrower].status != Status.active) {
            return false;
        }

        return (rewardSnapshots[_borrower].collateral < L_collateral);
    }

    // --- Redemption fee functions ---

    /*
     * This function has two impacts on the baseRate state variable:
     * 1) decays the baseRate based on time passed since last redemption or debt borrowing operation.
     * then,
     * 2) increases the baseRate based on the amount redeemed, as a proportion of total supply
     */
    function _updateBaseRateFromRedemption(
        uint256 _collateralDrawn,
        uint256 _price,
        uint256 _totalDebtSupply
    ) internal returns (uint256) {
        uint256 decayedBaseRate = _calcDecayedBaseRate();

        /* Convert the drawn collateral back to debt at face value rate (1 debt:1 USD), in order to get
         * the fraction of total supply that was redeemed at face value. */
        uint256 redeemedDebtFraction = (_collateralDrawn * _price) / _totalDebtSupply;

        uint256 newBaseRate = decayedBaseRate + (redeemedDebtFraction / BETA);
        newBaseRate = PrismaMath._min(newBaseRate, DECIMAL_PRECISION); // cap baseRate at a maximum of 100%

        // Update the baseRate state variable
        baseRate = newBaseRate;
        emit BaseRateUpdated(newBaseRate);

        _updateLastFeeOpTime();

        return newBaseRate;
    }

    function getRedemptionRate() public view returns (uint256) {
        return _calcRedemptionRate(baseRate);
    }

    function getRedemptionRateWithDecay() public view returns (uint256) {
        return _calcRedemptionRate(_calcDecayedBaseRate());
    }

    function _calcRedemptionRate(uint256 _baseRate) internal view returns (uint256) {
        return
            PrismaMath._min(
                redemptionFeeFloor + _baseRate,
                maxRedemptionFee // cap at a maximum of 100%
            );
    }

    function getRedemptionFeeWithDecay(uint256 _collateralDrawn) external view returns (uint256) {
        return _calcRedemptionFee(getRedemptionRateWithDecay(), _collateralDrawn);
    }

    function _calcRedemptionFee(uint256 _redemptionRate, uint256 _collateralDrawn) internal pure returns (uint256) {
        uint256 redemptionFee = (_redemptionRate * _collateralDrawn) / DECIMAL_PRECISION;
        require(redemptionFee < _collateralDrawn, "Fee exceeds returned collateral");
        return redemptionFee;
    }

    // --- Borrowing fee functions ---

    function getBorrowingRate() public view returns (uint256) {
        return _calcBorrowingRate(baseRate);
    }

    function getBorrowingRateWithDecay() public view returns (uint256) {
        return _calcBorrowingRate(_calcDecayedBaseRate());
    }

    function _calcBorrowingRate(uint256 _baseRate) internal view returns (uint256) {
        return PrismaMath._min(borrowingFeeFloor + _baseRate, maxBorrowingFee);
    }

    function getBorrowingFee(uint256 _debt) external view returns (uint256) {
        return _calcBorrowingFee(getBorrowingRate(), _debt);
    }

    function getBorrowingFeeWithDecay(uint256 _debt) external view returns (uint256) {
        return _calcBorrowingFee(getBorrowingRateWithDecay(), _debt);
    }

    function _calcBorrowingFee(uint256 _borrowingRate, uint256 _debt) internal pure returns (uint256) {
        return (_borrowingRate * _debt) / DECIMAL_PRECISION;
    }

    // --- Internal fee functions ---

    // Update the last fee operation time only if time passed >= decay interval. This prevents base rate griefing.
    function _updateLastFeeOpTime() internal {
        uint256 timePassed = block.timestamp - lastFeeOperationTime;

        if (timePassed >= SECONDS_IN_ONE_MINUTE) {
            lastFeeOperationTime = block.timestamp;
            emit LastFeeOpTimeUpdated(block.timestamp);
        }
    }

    function _calcDecayedBaseRate() internal view returns (uint256) {
        uint256 minutesPassed = (block.timestamp - lastFeeOperationTime) / SECONDS_IN_ONE_MINUTE;
        uint256 decayFactor = PrismaMath._decPow(minuteDecayFactor, minutesPassed);

        return (baseRate * decayFactor) / DECIMAL_PRECISION;
    }

    // --- Redemption functions ---

    /* Send _debtAmount debt to the system and redeem the corresponding amount of collateral from as many Troves as are needed to fill the redemption
     * request.  Applies pending rewards to a Trove before reducing its debt and coll.
     *
     * Note that if _amount is very large, this function can run out of gas, specially if traversed troves are small. This can be easily avoided by
     * splitting the total _amount in appropriate chunks and calling the function multiple times.
     *
     * Param `_maxIterations` can also be provided, so the loop through Troves is capped (if it’s zero, it will be ignored).This makes it easier to
     * avoid OOG for the frontend, as only knowing approximately the average cost of an iteration is enough, without needing to know the “topology”
     * of the trove list. It also avoids the need to set the cap in stone in the contract, nor doing gas calculations, as both gas price and opcode
     * costs can vary.
     *
     * All Troves that are redeemed from -- with the likely exception of the last one -- will end up with no debt left, therefore they will be closed.
     * If the last Trove does have some remaining debt, it has a finite ICR, and the reinsertion could be anywhere in the list, therefore it requires a hint.
     * A frontend should use getRedemptionHints() to calculate what the ICR of this Trove will be after redemption, and pass a hint for its position
     * in the sortedTroves list along with the ICR value that the hint was found for.
     *
     * If another transaction modifies the list between calling getRedemptionHints() and passing the hints to redeemCollateral(), it
     * is very likely that the last (partially) redeemed Trove would end up with a different ICR than what the hint is for. In this case the
     * redemption will stop after the last completely redeemed Trove and the sender will keep the remaining debt amount, which they can attempt
     * to redeem later.
     */
    function redeemCollateral(
        uint256 _debtAmount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint256 _partialRedemptionHintNICR,
        uint256 _maxIterations,
        uint256 _maxFeePercentage
    ) external {
        ISortedTroves _sortedTrovesCached = sortedTroves;
        RedemptionTotals memory totals;

        require(
            _maxFeePercentage >= redemptionFeeFloor && _maxFeePercentage <= maxRedemptionFee,
            "Max fee 0.5% to 100%"
        );
        require(block.timestamp >= systemDeploymentTime + BOOTSTRAP_PERIOD, "BOOTSTRAP_PERIOD");
        totals.price = fetchPrice();
        uint256 _MCR = MCR;
        require(IBorrowerOperations(borrowerOperationsAddress).getTCR() >= _MCR, "Cannot redeem when TCR < MCR");
        require(_debtAmount > 0, "Amount must be greater than zero");
        require(debtToken.balanceOf(msg.sender) >= _debtAmount, "Insufficient balance");
        _updateBalances();
        totals.totalDebtSupplyAtStart = getEntireSystemDebt();

        totals.remainingDebt = _debtAmount;
        address currentBorrower;

        if (_isValidFirstRedemptionHint(_sortedTrovesCached, _firstRedemptionHint, totals.price, _MCR)) {
            currentBorrower = _firstRedemptionHint;
        } else {
            currentBorrower = _sortedTrovesCached.getLast();
            // Find the first trove with ICR >= MCR
            while (currentBorrower != address(0) && getCurrentICR(currentBorrower, totals.price) < _MCR) {
                currentBorrower = _sortedTrovesCached.getPrev(currentBorrower);
            }
        }

        // Loop through the Troves starting from the one with lowest collateral ratio until _amount of debt is exchanged for collateral
        if (_maxIterations == 0) {
            _maxIterations = type(uint256).max;
        }
        while (currentBorrower != address(0) && totals.remainingDebt > 0 && _maxIterations > 0) {
            _maxIterations--;
            // Save the address of the Trove preceding the current one, before potentially modifying the list
            address nextUserToCheck = _sortedTrovesCached.getPrev(currentBorrower);

            _applyPendingRewards(currentBorrower);
            SingleRedemptionValues memory singleRedemption = _redeemCollateralFromTrove(
                _sortedTrovesCached,
                currentBorrower,
                totals.remainingDebt,
                totals.price,
                _upperPartialRedemptionHint,
                _lowerPartialRedemptionHint,
                _partialRedemptionHintNICR
            );

            if (singleRedemption.cancelledPartial) break; // Partial redemption was cancelled (out-of-date hint, or new net debt < minimum), therefore we could not redeem from the last Trove

            totals.totalDebtToRedeem = totals.totalDebtToRedeem + singleRedemption.debtLot;
            totals.totalCollateralDrawn = totals.totalCollateralDrawn + singleRedemption.collateralLot;

            totals.remainingDebt = totals.remainingDebt - singleRedemption.debtLot;
            currentBorrower = nextUserToCheck;
        }
        require(totals.totalCollateralDrawn > 0, "Unable to redeem any amount");

        // Decay the baseRate due to time passed, and then increase it according to the size of this redemption.
        // Use the saved total debt supply value, from before it was reduced by the redemption.
        _updateBaseRateFromRedemption(totals.totalCollateralDrawn, totals.price, totals.totalDebtSupplyAtStart);

        // Calculate the collateral fee
        totals.collateralFee = sunsetting ? 0 : _calcRedemptionFee(getRedemptionRate(), totals.totalCollateralDrawn);

        _requireUserAcceptsFee(totals.collateralFee, totals.totalCollateralDrawn, _maxFeePercentage);

        _sendCollateral(PRISMA_CORE.feeReceiver(), totals.collateralFee);

        totals.collateralToSendToRedeemer = totals.totalCollateralDrawn - totals.collateralFee;

        emit Redemption(_debtAmount, totals.totalDebtToRedeem, totals.totalCollateralDrawn, totals.collateralFee);

        // Burn the total debt that is cancelled with debt, and send the redeemed collateral to msg.sender
        debtToken.burn(msg.sender, totals.totalDebtToRedeem);
        // Update Trove Manager debt, and send collateral to account
        totalActiveDebt = totalActiveDebt - totals.totalDebtToRedeem;
        _sendCollateral(msg.sender, totals.collateralToSendToRedeemer);
        _resetState();
    }

    // Redeem as much collateral as possible from _borrower's Trove in exchange for debt up to _maxDebtAmount
    function _redeemCollateralFromTrove(
        ISortedTroves _sortedTrovesCached,
        address _borrower,
        uint256 _maxDebtAmount,
        uint256 _price,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint256 _partialRedemptionHintNICR
    ) internal returns (SingleRedemptionValues memory singleRedemption) {
        Trove storage t = Troves[_borrower];
        // Determine the remaining amount (lot) to be redeemed, capped by the entire debt of the Trove minus the liquidation reserve
        singleRedemption.debtLot = PrismaMath._min(_maxDebtAmount, t.debt - DEBT_GAS_COMPENSATION);

        // Get the CollateralLot of equivalent value in USD
        singleRedemption.collateralLot = (singleRedemption.debtLot * DECIMAL_PRECISION) / _price;

        // Decrease the debt and collateral of the current Trove according to the debt lot and corresponding collateral to send
        uint256 newDebt = (t.debt) - singleRedemption.debtLot;
        uint256 newColl = (t.coll) - singleRedemption.collateralLot;

        if (newDebt == DEBT_GAS_COMPENSATION) {
            // No debt left in the Trove (except for the liquidation reserve), therefore the trove gets closed
            _removeStake(_borrower);
            _closeTrove(_borrower, Status.closedByRedemption);
            _redeemCloseTrove(_borrower, DEBT_GAS_COMPENSATION, newColl);
            emit TroveUpdated(_borrower, 0, 0, 0, TroveManagerOperation.redeemCollateral);
        } else {
            uint256 newNICR = PrismaMath._computeNominalCR(newColl, newDebt);
            /*
             * If the provided hint is out of date, we bail since trying to reinsert without a good hint will almost
             * certainly result in running out of gas.
             *
             * If the resultant net debt of the partial is less than the minimum, net debt we bail.
             */

            {
                // We check if the ICR hint is reasonable up to date, with continuous interest there might be slight differences (<1bps)
                uint256 icrError = _partialRedemptionHintNICR > newNICR
                    ? _partialRedemptionHintNICR - newNICR
                    : newNICR - _partialRedemptionHintNICR;
                if (
                    icrError > 5e14 ||
                    _getNetDebt(newDebt) < IBorrowerOperations(borrowerOperationsAddress).minNetDebt()
                ) {
                    singleRedemption.cancelledPartial = true;
                    return singleRedemption;
                }
            }

            _sortedTrovesCached.reInsert(_borrower, newNICR, _upperPartialRedemptionHint, _lowerPartialRedemptionHint);

            t.debt = newDebt;
            t.coll = newColl;
            _updateStakeAndTotalStakes(t);

            emit TroveUpdated(_borrower, newDebt, newColl, t.stake, TroveManagerOperation.redeemCollateral);
        }

        return singleRedemption;
    }

    /*
     * Called when a full redemption occurs, and closes the trove.
     * The redeemer swaps (debt - liquidation reserve) debt for (debt - liquidation reserve) worth of collateral, so the debt liquidation reserve left corresponds to the remaining debt.
     * In order to close the trove, the debt liquidation reserve is burned, and the corresponding debt is removed.
     * The debt recorded on the trove's struct is zero'd elswhere, in _closeTrove.
     * Any surplus collateral left in the trove can be later claimed by the borrower.
     */
    function _redeemCloseTrove(address _borrower, uint256 _debt, uint256 _collateral) internal {
        debtToken.burn(gasPoolAddress, _debt);
        totalActiveDebt = totalActiveDebt - _debt;

        surplusBalances[_borrower] += _collateral;
        totalActiveCollateral -= _collateral;
    }

    function _isValidFirstRedemptionHint(
        ISortedTroves _sortedTroves,
        address _firstRedemptionHint,
        uint256 _price,
        uint256 _MCR
    ) internal view returns (bool) {
        if (
            _firstRedemptionHint == address(0) ||
            !_sortedTroves.contains(_firstRedemptionHint) ||
            getCurrentICR(_firstRedemptionHint, _price) < _MCR
        ) {
            return false;
        }

        address nextTrove = _sortedTroves.getNext(_firstRedemptionHint);
        return nextTrove == address(0) || getCurrentICR(nextTrove, _price) < _MCR;
    }

    /**
     * Claim remaining collateral from a redemption or from a liquidation with ICR > MCR in Recovery Mode
     */
    function claimCollateral(address _receiver) external {
        uint256 claimableColl = surplusBalances[msg.sender];
        require(claimableColl > 0, "No collateral available to claim");

        surplusBalances[msg.sender] = 0;

        collateralToken.safeTransfer(_receiver, claimableColl);
    }

    // --- Reward Claim functions ---

    function claimReward(address receiver) external returns (uint256) {
        uint256 amount = _claimReward(msg.sender);

        if (amount > 0) {
            vault.transferAllocatedTokens(msg.sender, receiver, amount);
        }
        emit RewardClaimed(msg.sender, receiver, amount);
        return amount;
    }

    function vaultClaimReward(address claimant, address) external returns (uint256) {
        require(msg.sender == address(vault));

        return _claimReward(claimant);
    }

    function _claimReward(address account) internal returns (uint256) {
        require(emissionId.debt > 0, "Rewards not active");
        // update active debt rewards
        _applyPendingRewards(account);
        uint256 amount = storedPendingReward[account];
        if (amount > 0) storedPendingReward[account] = 0;

        // add pending mint awards
        uint256 mintAmount = _getPendingMintReward(account);
        if (mintAmount > 0) {
            amount += mintAmount;
            delete accountLatestMint[account];
        }

        return amount;
    }

    function claimableReward(address account) external view returns (uint256) {
        // previously calculated rewards
        uint256 amount = storedPendingReward[account];

        // pending active debt rewards
        uint256 updated = periodFinish;
        if (updated > block.timestamp) updated = block.timestamp;
        uint256 duration = updated - lastUpdate;
        uint256 integral = rewardIntegral;
        if (duration > 0) {
            uint256 supply = totalActiveDebt;
            if (supply > 0) {
                integral += (duration * rewardRate * 1e18) / supply;
            }
        }
        uint256 integralFor = rewardIntegralFor[account];

        if (integral > integralFor) {
            amount += (Troves[account].debt * (integral - integralFor)) / 1e18;
        }

        // pending mint rewards
        amount += _getPendingMintReward(account);

        return amount;
    }

    function _getPendingMintReward(address account) internal view returns (uint256 amount) {
        VolumeData memory data = accountLatestMint[account];
        if (data.amount > 0) {
            (uint256 week, uint256 day) = getWeekAndDay();
            if (data.day != day || data.week != week) {
                return (dailyMintReward[data.week] * data.amount) / totalMints[data.week][data.day];
            }
        }
    }

    function _updateIntegrals(address account, uint256 balance, uint256 supply) internal {
        uint256 integral = _updateRewardIntegral(supply);
        _updateIntegralForAccount(account, balance, integral);
    }

    function _updateIntegralForAccount(address account, uint256 balance, uint256 currentIntegral) internal {
        uint256 integralFor = rewardIntegralFor[account];

        if (currentIntegral > integralFor) {
            storedPendingReward[account] += (balance * (currentIntegral - integralFor)) / 1e18;
            rewardIntegralFor[account] = currentIntegral;
        }
    }

    function _updateRewardIntegral(uint256 supply) internal returns (uint256 integral) {
        uint256 _periodFinish = periodFinish;
        uint256 updated = _periodFinish;
        if (updated > block.timestamp) updated = block.timestamp;
        uint256 duration = updated - lastUpdate;
        integral = rewardIntegral;
        if (duration > 0) {
            lastUpdate = uint32(updated);
            if (supply > 0) {
                integral += (duration * rewardRate * 1e18) / supply;
                rewardIntegral = integral;
            }
        }
        _fetchRewards(_periodFinish);

        return integral;
    }

    function _fetchRewards(uint256 _periodFinish) internal {
        EmissionId memory id = emissionId;
        if (id.debt == 0) return;
        uint256 currentWeek = getWeek();
        if (currentWeek < (_periodFinish - startTime) / 1 weeks) return;
        uint256 previousWeek = (_periodFinish - startTime) / 1 weeks - 1;

        // active debt rewards
        uint256 amount = vault.allocateNewEmissions(id.debt);
        if (block.timestamp < _periodFinish) {
            uint256 remaining = _periodFinish - block.timestamp;
            amount += remaining * rewardRate;
        }
        rewardRate = uint128(amount / REWARD_DURATION);
        lastUpdate = uint32(block.timestamp);
        periodFinish = uint32(block.timestamp + REWARD_DURATION);

        // minting rewards
        amount = vault.allocateNewEmissions(id.minting);
        uint256 reward = dailyMintReward[previousWeek];
        if (reward > 0) {
            uint32[7] memory totals = totalMints[previousWeek];
            for (uint256 i = 0; i < 7; i++) {
                if (totals[i] == 0) {
                    amount += reward;
                }
            }
        }
        dailyMintReward[currentWeek] = amount / 7;
    }

    // --- Trove Adjustment functions ---

    function openTrove(
        address _borrower,
        uint256 _collateralAmount,
        uint256 _compositeDebt,
        uint256 NICR,
        address _upperHint,
        address _lowerHint,
        bool _isRecoveryMode
    ) external whenNotPaused returns (uint256 stake, uint256 arrayIndex) {
        _requireCallerIsBO();
        require(!sunsetting, "Cannot open while sunsetting");
        uint256 supply = totalActiveDebt;

        Trove storage t = Troves[_borrower];
        require(t.status != Status.active, "BorrowerOps: Trove is active");
        t.status = Status.active;
        t.coll = _collateralAmount;
        t.debt = _compositeDebt;
        uint256 currentInterestIndex = _accrueActiveInterests();
        t.activeInterestIndex = currentInterestIndex;
        _updateTroveRewardSnapshots(_borrower);
        stake = _updateStakeAndTotalStakes(t);
        sortedTroves.insert(_borrower, NICR, _upperHint, _lowerHint);

        TroveOwners.push(_borrower);
        arrayIndex = TroveOwners.length - 1;
        t.arrayIndex = uint128(arrayIndex);

        _updateIntegrals(_borrower, 0, supply);
        if (!_isRecoveryMode) _updateMintVolume(_borrower, _compositeDebt);

        totalActiveCollateral = totalActiveCollateral + _collateralAmount;
        uint256 _newTotalDebt = supply + _compositeDebt;
        require(_newTotalDebt + defaultedDebt <= maxSystemDebt, "Collateral debt limit reached");
        totalActiveDebt = _newTotalDebt;
    }

    function updateTroveFromAdjustment(
        bool _isRecoveryMode,
        bool _isDebtIncrease,
        uint256 _debtChange,
        uint256 _netDebtChange,
        bool _isCollIncrease,
        uint256 _collChange,
        address _upperHint,
        address _lowerHint,
        address _borrower,
        address _receiver
    ) external returns (uint256, uint256, uint256) {
        _requireCallerIsBO();
        if (_isCollIncrease || _isDebtIncrease) {
            require(!paused, "Collateral Paused");
            require(!sunsetting, "Cannot increase while sunsetting");
        }

        Trove storage t = Troves[_borrower];
        require(t.status == Status.active, "Trove closed or does not exist");

        uint256 newDebt = t.debt;
        if (_debtChange > 0) {
            if (_isDebtIncrease) {
                newDebt = newDebt + _netDebtChange;
                if (!_isRecoveryMode) _updateMintVolume(_borrower, _netDebtChange);
                _increaseDebt(_receiver, _netDebtChange, _debtChange);
            } else {
                newDebt = newDebt - _netDebtChange;
                _decreaseDebt(_receiver, _debtChange);
            }
            t.debt = newDebt;
        }

        uint256 newColl = t.coll;
        if (_collChange > 0) {
            if (_isCollIncrease) {
                newColl = newColl + _collChange;
                totalActiveCollateral = totalActiveCollateral + _collChange;
                // trust that BorrowerOperations sent the collateral
            } else {
                newColl = newColl - _collChange;
                _sendCollateral(_receiver, _collChange);
            }
            t.coll = newColl;
        }

        uint256 newNICR = PrismaMath._computeNominalCR(newColl, newDebt);
        sortedTroves.reInsert(_borrower, newNICR, _upperHint, _lowerHint);

        return (newColl, newDebt, _updateStakeAndTotalStakes(t));
    }

    function closeTrove(address _borrower, address _receiver, uint256 collAmount, uint256 debtAmount) external {
        _requireCallerIsBO();
        require(Troves[_borrower].status == Status.active, "Trove closed or does not exist");
        _removeStake(_borrower);
        _closeTrove(_borrower, Status.closedByOwner);
        totalActiveDebt = totalActiveDebt - debtAmount;
        _sendCollateral(_receiver, collAmount);
        _resetState();
    }

    /**
        @dev Only called from `closeTrove` because liquidating the final trove is blocked in
             `LiquidationManager`. Many liquidation paths involve redistributing debt and
             collateral to existing troves. If the collateral is being sunset, the final trove
             must be closed by repaying the debt or via a redemption.
     */
    function _resetState() private {
        if (TroveOwners.length == 0) {
            activeInterestIndex = INTEREST_PRECISION;
            lastActiveIndexUpdate = block.timestamp;
            totalStakes = 0;
            totalStakesSnapshot = 0;
            totalCollateralSnapshot = 0;
            L_collateral = 0;
            L_debt = 0;
            lastCollateralError_Redistribution = 0;
            lastDebtError_Redistribution = 0;
            totalActiveCollateral = 0;
            totalActiveDebt = 0;
            defaultedCollateral = 0;
            defaultedDebt = 0;
        }
    }

    function _closeTrove(address _borrower, Status closedStatus) internal {
        uint256 TroveOwnersArrayLength = TroveOwners.length;

        Trove storage t = Troves[_borrower];
        t.status = closedStatus;
        t.coll = 0;
        t.debt = 0;
        t.activeInterestIndex = 0;
        ISortedTroves sortedTrovesCached = sortedTroves;
        rewardSnapshots[_borrower].collateral = 0;
        rewardSnapshots[_borrower].debt = 0;
        if (TroveOwnersArrayLength > 1 && sortedTrovesCached.getSize() > 1) {
            // remove trove owner from the TroveOwners array, not preserving array order
            uint128 index = t.arrayIndex;
            address addressToMove = TroveOwners[TroveOwnersArrayLength - 1];
            TroveOwners[index] = addressToMove;
            Troves[addressToMove].arrayIndex = index;
            emit TroveIndexUpdated(addressToMove, index);
        }

        TroveOwners.pop();

        sortedTrovesCached.remove(_borrower);
        t.arrayIndex = 0;
    }

    function _updateMintVolume(address account, uint256 initialAmount) internal {
        uint32 amount = uint32(initialAmount / VOLUME_MULTIPLIER);
        (uint256 week, uint256 day) = getWeekAndDay();
        totalMints[week][day] += amount;

        VolumeData memory data = accountLatestMint[account];
        if (data.day == day && data.week == week) {
            // if the caller made a previous redemption today, we only increase their redeemed amount
            accountLatestMint[account].amount = data.amount + amount;
        } else {
            if (data.amount > 0) {
                // if the caller made a previous redemption on a different day,
                // calculate the emissions earned for that redemption
                uint256 pending = (dailyMintReward[data.week] * data.amount) / totalMints[data.week][data.day];
                storedPendingReward[account] += pending;
            }
            accountLatestMint[account] = VolumeData({ week: uint32(week), day: uint32(day), amount: amount });
        }
    }

    // Updates the baseRate state variable based on time elapsed since the last redemption or debt borrowing operation.
    function decayBaseRateAndGetBorrowingFee(uint256 _debt) external returns (uint256) {
        _requireCallerIsBO();
        uint256 rate = _decayBaseRate();

        return _calcBorrowingFee(_calcBorrowingRate(rate), _debt);
    }

    function _decayBaseRate() internal returns (uint256) {
        uint256 decayedBaseRate = _calcDecayedBaseRate();

        baseRate = decayedBaseRate;
        emit BaseRateUpdated(decayedBaseRate);

        _updateLastFeeOpTime();

        return decayedBaseRate;
    }

    function applyPendingRewards(address _borrower) external returns (uint256 coll, uint256 debt) {
        _requireCallerIsBO();
        return _applyPendingRewards(_borrower);
    }

    // Add the borrowers's coll and debt rewards earned from redistributions, to their Trove
    function _applyPendingRewards(address _borrower) internal returns (uint256 coll, uint256 debt) {
        Trove storage t = Troves[_borrower];
        if (t.status == Status.active) {
            uint256 troveInterestIndex = t.activeInterestIndex;
            uint256 supply = totalActiveDebt;
            uint256 currentInterestIndex = _accrueActiveInterests();
            debt = t.debt;
            uint256 prevDebt = debt;
            coll = t.coll;
            // We accrued interests for this trove if not already updated
            if (troveInterestIndex < currentInterestIndex) {
                debt = (debt * currentInterestIndex) / troveInterestIndex;
                t.activeInterestIndex = currentInterestIndex;
            }

            if (rewardSnapshots[_borrower].collateral < L_collateral) {
                // Compute pending rewards
                (uint256 pendingCollateralReward, uint256 pendingDebtReward) = getPendingCollAndDebtRewards(_borrower);

                // Apply pending rewards to trove's state
                coll = coll + pendingCollateralReward;
                t.coll = coll;
                debt = debt + pendingDebtReward;

                _updateTroveRewardSnapshots(_borrower);

                _movePendingTroveRewardsToActiveBalance(pendingDebtReward, pendingCollateralReward);

                emit TroveUpdated(_borrower, debt, coll, t.stake, TroveManagerOperation.applyPendingRewards);
            }
            if (prevDebt != debt) {
                t.debt = debt;
            }
            _updateIntegrals(_borrower, prevDebt, supply);
        }
        return (coll, debt);
    }

    function _updateTroveRewardSnapshots(address _borrower) internal {
        uint256 L_collateralCached = L_collateral;
        uint256 L_debtCached = L_debt;
        rewardSnapshots[_borrower] = RewardSnapshot(L_collateralCached, L_debtCached);
        emit TroveSnapshotsUpdated(L_collateralCached, L_debtCached);
    }

    // Remove borrower's stake from the totalStakes sum, and set their stake to 0
    function _removeStake(address _borrower) internal {
        uint256 stake = Troves[_borrower].stake;
        totalStakes = totalStakes - stake;
        Troves[_borrower].stake = 0;
    }

    // Update borrower's stake based on their latest collateral value
    function _updateStakeAndTotalStakes(Trove storage t) internal returns (uint256) {
        uint256 newStake = _computeNewStake(t.coll);
        uint256 oldStake = t.stake;
        t.stake = newStake;
        uint256 newTotalStakes = totalStakes - oldStake + newStake;
        totalStakes = newTotalStakes;
        emit TotalStakesUpdated(newTotalStakes);

        return newStake;
    }

    // Calculate a new stake based on the snapshots of the totalStakes and totalCollateral taken at the last liquidation
    function _computeNewStake(uint256 _coll) internal view returns (uint256) {
        uint256 stake;
        uint256 totalCollateralSnapshotCached = totalCollateralSnapshot;
        if (totalCollateralSnapshotCached == 0) {
            stake = _coll;
        } else {
            /*
             * The following assert() holds true because:
             * - The system always contains >= 1 trove
             * - When we close or liquidate a trove, we redistribute the pending rewards, so if all troves were closed/liquidated,
             * rewards would’ve been emptied and totalCollateralSnapshot would be zero too.
             */
            uint256 totalStakesSnapshotCached = totalStakesSnapshot;
            assert(totalStakesSnapshotCached > 0);
            stake = (_coll * totalStakesSnapshotCached) / totalCollateralSnapshotCached;
        }
        return stake;
    }

    // --- Liquidation Functions ---

    function closeTroveByLiquidation(address _borrower) external {
        _requireCallerIsLM();
        uint256 debtBefore = Troves[_borrower].debt;
        _removeStake(_borrower);
        _closeTrove(_borrower, Status.closedByLiquidation);
        _updateIntegralForAccount(_borrower, debtBefore, rewardIntegral);
    }

    function movePendingTroveRewardsToActiveBalances(uint256 _debt, uint256 _collateral) external {
        _requireCallerIsLM();
        _movePendingTroveRewardsToActiveBalance(_debt, _collateral);
    }

    function _movePendingTroveRewardsToActiveBalance(uint256 _debt, uint256 _collateral) internal {
        defaultedDebt -= _debt;
        totalActiveDebt += _debt;
        defaultedCollateral -= _collateral;
        totalActiveCollateral += _collateral;
    }

    function addCollateralSurplus(address borrower, uint256 collSurplus) external {
        _requireCallerIsLM();
        surplusBalances[borrower] += collSurplus;
    }

    function finalizeLiquidation(
        address _liquidator,
        uint256 _debt,
        uint256 _coll,
        uint256 _collSurplus,
        uint256 _debtGasComp,
        uint256 _collGasComp
    ) external {
        _requireCallerIsLM();
        // redistribute debt and collateral
        _redistributeDebtAndColl(_debt, _coll);

        uint256 _activeColl = totalActiveCollateral;
        if (_collSurplus > 0) {
            _activeColl -= _collSurplus;
            totalActiveCollateral = _activeColl;
        }

        // update system snapshos
        totalStakesSnapshot = totalStakes;
        totalCollateralSnapshot = _activeColl - _collGasComp + defaultedCollateral;
        emit SystemSnapshotsUpdated(totalStakesSnapshot, totalCollateralSnapshot);

        // send gas compensation
        debtToken.returnFromPool(gasPoolAddress, _liquidator, _debtGasComp);
        _sendCollateral(_liquidator, _collGasComp);
    }

    function _redistributeDebtAndColl(uint256 _debt, uint256 _coll) internal {
        if (_debt == 0) {
            return;
        }
        /*
         * Add distributed coll and debt rewards-per-unit-staked to the running totals. Division uses a "feedback"
         * error correction, to keep the cumulative error low in the running totals L_collateral and L_debt:
         *
         * 1) Form numerators which compensate for the floor division errors that occurred the last time this
         * function was called.
         * 2) Calculate "per-unit-staked" ratios.
         * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
         * 4) Store these errors for use in the next correction when this function is called.
         * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
         */
        uint256 collateralNumerator = (_coll * DECIMAL_PRECISION) + lastCollateralError_Redistribution;
        uint256 debtNumerator = (_debt * DECIMAL_PRECISION) + lastDebtError_Redistribution;
        uint256 totalStakesCached = totalStakes;
        // Get the per-unit-staked terms
        uint256 collateralRewardPerUnitStaked = collateralNumerator / totalStakesCached;
        uint256 debtRewardPerUnitStaked = debtNumerator / totalStakesCached;

        lastCollateralError_Redistribution = collateralNumerator - (collateralRewardPerUnitStaked * totalStakesCached);
        lastDebtError_Redistribution = debtNumerator - (debtRewardPerUnitStaked * totalStakesCached);

        // Add per-unit-staked terms to the running totals
        uint256 new_L_collateral = L_collateral + collateralRewardPerUnitStaked;
        uint256 new_L_debt = L_debt + debtRewardPerUnitStaked;
        L_collateral = new_L_collateral;
        L_debt = new_L_debt;

        emit LTermsUpdated(new_L_collateral, new_L_debt);

        totalActiveDebt -= _debt;
        defaultedDebt += _debt;
        defaultedCollateral += _coll;
        totalActiveCollateral -= _coll;
    }

    // --- Trove property setters ---

    function _sendCollateral(address _account, uint256 _amount) private {
        if (_amount > 0) {
            totalActiveCollateral = totalActiveCollateral - _amount;
            emit CollateralSent(_account, _amount);

            collateralToken.safeTransfer(_account, _amount);
        }
    }

    function _increaseDebt(address account, uint256 netDebtAmount, uint256 debtAmount) internal {
        uint256 _newTotalDebt = totalActiveDebt + netDebtAmount;
        require(_newTotalDebt + defaultedDebt <= maxSystemDebt, "Collateral debt limit reached");
        totalActiveDebt = _newTotalDebt;
        debtToken.mint(account, debtAmount);
    }

    function decreaseDebtAndSendCollateral(address account, uint256 debt, uint256 coll) external {
        _requireCallerIsLM();
        _decreaseDebt(account, debt);
        _sendCollateral(account, coll);
    }

    function _decreaseDebt(address account, uint256 amount) internal {
        debtToken.burn(account, amount);
        totalActiveDebt = totalActiveDebt - amount;
    }

    // --- Balances and interest ---

    function updateBalances() external {
        _requireCallerIsLM();
        _updateBalances();
    }

    function _updateBalances() private {
        _updateRewardIntegral(totalActiveDebt);
        _accrueActiveInterests();
    }

    // This function must be called any time the debt or the interest changes
    function _accrueActiveInterests() internal returns (uint256) {
        (uint256 currentInterestIndex, uint256 interestFactor) = _calculateInterestIndex();
        if (interestFactor > 0) {
            uint256 currentDebt = totalActiveDebt;
            uint256 activeInterests = Math.mulDiv(currentDebt, interestFactor, INTEREST_PRECISION);
            totalActiveDebt = currentDebt + activeInterests;
            interestPayable = interestPayable + activeInterests;
            activeInterestIndex = currentInterestIndex;
            lastActiveIndexUpdate = block.timestamp;
        }
        return currentInterestIndex;
    }

    function _calculateInterestIndex() internal view returns (uint256 currentInterestIndex, uint256 interestFactor) {
        uint256 lastIndexUpdateCached = lastActiveIndexUpdate;
        // Short circuit if we updated in the current block
        if (lastIndexUpdateCached == block.timestamp) return (activeInterestIndex, 0);
        uint256 currentInterest = interestRate;
        currentInterestIndex = activeInterestIndex; // we need to return this if it's already up to date
        if (currentInterest > 0) {
            /*
             * Calculate the interest accumulated and the new index:
             * We compound the index and increase the debt accordingly
             */
            uint256 deltaT = block.timestamp - lastIndexUpdateCached;
            interestFactor = deltaT * currentInterest;
            currentInterestIndex =
                currentInterestIndex +
                Math.mulDiv(currentInterestIndex, interestFactor, INTEREST_PRECISION);
        }
    }

    // --- Requires ---

    function _requireCallerIsBO() internal view {
        require(msg.sender == borrowerOperationsAddress, "Caller not BO");
    }

    function _requireCallerIsLM() internal view {
        require(msg.sender == liquidationManager, "Not Liquidation Manager");
    }
}