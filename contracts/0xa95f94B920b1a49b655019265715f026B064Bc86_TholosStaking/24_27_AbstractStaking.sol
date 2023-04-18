// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// OZ Upgrades imports
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// ABDK
import { ABDKMath64x64 } from "abdk-libraries-solidity/ABDKMath64x64.sol";

// Local
import { Configurable } from "../utils/Configurable.sol";
import { IPool } from "../interfaces/IPool.sol";
import { IStaking } from "../interfaces/IStaking.sol";

/**************************************
    
    Staking abstract contract

    ------------------------------

    Features:
    - supports $THOL deposits
    - supports additional currencies deposits
    - expresses additional currencies in $THOL value
    - combines all deposits into staking power
    - auto-compounds interest
    - decreases APY over time based on rewards supply
    - NFT staking compound with custom logic

**************************************/

abstract contract AbstractStaking is Initializable, IStaking, Configurable, AccessControlUpgradeable {

    // -----------------------------------------------------------------------
    //                              Library usage
    // -----------------------------------------------------------------------

    using ABDKMath64x64 for int128;

    // -----------------------------------------------------------------------
    //                              Roles
    // -----------------------------------------------------------------------

    bytes32 public constant CAN_MANAGE = keccak256("CAN_MANAGE");
    bytes32 public constant CAN_UPGRADE = keccak256("CAN_UPGRADE");

    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    uint128 constant internal DAY = 24 hours;
    uint256 constant internal DAYS_IN_YEAR = 365;
    uint256 constant internal PRECISION_SCALE = 10 ** 20;

    // -----------------------------------------------------------------------
    //                             State variables
    // -----------------------------------------------------------------------

    // storage
    mapping (address => Balance) public balances;

    // contracts
    IPool public depositPool;
    address public rewardPool;

    // tracking
    Compounding public compounding;
    uint96 public depositSum;
    uint96 public pendingSum;
    uint72 public pendingSumPrecision;

    // -----------------------------------------------------------------------
    //                             Setup
    // -----------------------------------------------------------------------

    /**************************************

        Initializer

     **************************************/

    function __AbstractStaking_init() internal
    onlyInitializing {

        // setup roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CAN_MANAGE, msg.sender);
        _grantRole(CAN_UPGRADE, msg.sender);

    }

    /**************************************

        Configure

        ------------------------------

        @param _configuration byte encoded parameters to configure

    **************************************/

    function _configure(
        address _depositPool,
        address _rewardPool
    ) internal {

        // tx.members
        uint128 now_ = SafeCast.toUint128(block.timestamp);

        // set storage
        depositPool = IPool(_depositPool);
        rewardPool = _rewardPool;

        // init compounding
        uint96 freeRewards_ = _rewardPoolInfo();
        if (freeRewards_ == 0) revert UninitializedRewardPool();
        compounding = Compounding(
            ABDKMath64x64.fromUInt(1),                                          // rate: int128(1 << 64)
            ABDKMath64x64.fromUInt(22).div(ABDKMath64x64.fromUInt(100)),        // default yield 22%
            bytes32(0),                                                         // extra rate
            now_,                                                               // ts
            freeRewards_                                                        // assumes pool has tokens already
        );

    }

    // -----------------------------------------------------------------------
    //                             External
    // -----------------------------------------------------------------------

    /**************************************

        Deposit sender funds

        ------------------------------

        @param _amount amount of $THOL to deposit
        @param _extraAmount byte encoded additional currencies to deposit

    **************************************/

    function deposit(
        uint96 _amount,
        bytes memory _extraAmount
    ) external override
    onlyInState(State.CONFIGURED) {

        // tx.members
        address sender_ = msg.sender;

        // deposit
        _deposit(_amount, _extraAmount);

        // local compound
        uint96 rewards_ = accrue(sender_);

        // increase balance
        _increaseBalance(_amount, _extraAmount);

        // events
        emit Deposit(
            sender_,
            _amount,
            _extraAmount,
            rewards_
        );

    }

    /**************************************

        Withdraw sender funds

        ------------------------------

        @param _amount amount of $THOL to withdraw
        @param _extraAmount byte encoded additional currencies to withdraw

    **************************************/

    function withdraw(
        uint96 _amount,
        bytes memory _extraAmount
    ) external override
    onlyInState(State.CONFIGURED) {

        // tx.members
        address sender_ = msg.sender;

        // accrue
        uint96 rewards_ = accrue(sender_);

        // check balance
        _checkBalance(_amount, _extraAmount);

        // update balances
        _decreaseBalance(_amount, _extraAmount);

        // withdraw
        _withdraw(_amount, _extraAmount);

        // events
        emit Withdrawal(
            sender_,
            _amount,
            _extraAmount,
            rewards_
        );

    }

    /**************************************

        Compound

    **************************************/

    function compound() external override
    onlyInState(State.CONFIGURED) {

        // tx.members
        uint128 now_ = SafeCast.toUint128(block.timestamp);

        // revert if called too soon
        if (compounding.ts + DAY > now_) {
            revert CompoundingNotReady(compounding.ts + DAY, now_);
        }

        // based on all available funds
        uint96 compoundedSum_ = depositSum + pendingSum;

        // based on extra funds
        uint96 extraSum_ = _getExtraSum();

        // return if nothing to compound
        if (compoundedSum_ + extraSum_ == 0) return;

        // calculate free tokens
        uint96 freeRewardsLastCompound_ = compounding.freeRewards;
        uint96 freeRewards_ = freeRewards();

        // degradation ratio
        int128 degradationRatio_ = ABDKMath64x64.divu(
            uint256(freeRewards_),
            uint256(freeRewardsLastCompound_)
        );

        // last annual percentage yield
        int128 apy_ = compounding.dapy;

        // degraded apy
        int128 dapy_ = degradationRatio_.mul(apy_);

        // instant percentage yield
        int128 ipy_ = dapy_.div(ABDKMath64x64.fromUInt(DAYS_IN_YEAR));
        if (ipy_ == 0) revert NoMoreRewardsLeft();

        // get compounding multiplier
        int128 compoundingMultiplier_ = ipy_.add(ABDKMath64x64.fromUInt(1));

        // calculate extra rewards and extra rate
        (uint96 extraRewards_, bytes32 extraRate_) = _calculateExtraRewards(extraSum_, ipy_);

        // calculate base rewards
        uint96 baseRewards_ = _calculateBaseRewardsWithPrecision(ipy_, compoundedSum_);

        // calculate total rewards
        uint96 totalRewards_ = baseRewards_ + extraRewards_;

        // verify available rewards
        if (totalRewards_ > freeRewards_) revert InsufficientRewards(totalRewards_, freeRewards_);

        // virtually increase pending sum
        pendingSum += totalRewards_;

        // increase compounding index
        compounding = Compounding(
            compounding.rate.mul(compoundingMultiplier_),                       // updated compounding index
            dapy_,                                                              // degraded apy
            _incrementExtraRate(compounding.extraRate, extraRate_),             // updated extra rate
            now_,                                                               // ts
            freeRewards_                                                        // free rewards
        );

        // event
        emit Compounded(compounding);

    }

    /**************************************

        View: Get total available balance

        ------------------------------

        @notice returns sum of deposited tokens and $THOL rewards
        @param _account address that owns tokens and rewards

    **************************************/

    function balanceOf(address _account) external override view
    onlyInState(State.CONFIGURED)
    returns (uint96) {

        // get reward of
        uint96 reward_ = rewardOf(_account);

        // return deposited tokens + reward
        return balances[_account].amount + reward_;

    }

    // -----------------------------------------------------------------------
    //                             Public
    // -----------------------------------------------------------------------
    
    /**************************************

        View: Get free rewards

        ------------------------------

        @return freeRewards_ current reward pool capacity minus pending rewards

    **************************************/

    function freeRewards() public override view
    onlyInState(State.CONFIGURED)
    returns (uint96) {

        // return
        return _rewardPoolInfo() - pendingSum;

    }

    /**************************************

        View: Get total rewards

        ------------------------------

        @param _account address eligible for rewards

    **************************************/

    function rewardOf(address _account) public override view
    onlyInState(State.CONFIGURED)
    returns (uint96 totalRewards) {

        // total amount of rewards
        totalRewards = userBaseRewards(_account) + _userExtraRewards(_account);

    }

    /**************************************

        View: Get amount of rewards for base token

        ------------------------------

        @param _account address for which rewards should be calculated

    **************************************/

    function userBaseRewards(address _account) public override view
    onlyInState(State.CONFIGURED)
    returns (uint96) {

        // get balance
        Balance memory balance_ = balances[_account];
        if (balance_.compoundingSnapshot == 0 || balance_.amount == 0) return 0;

        // calculate multiplier ratio
        int128 compoundingRatio_ = compounding.rate.div(balance_.compoundingSnapshot);

        // return compounded balance
        return uint96(compoundingRatio_.mulu(uint256(balance_.amount))) - balance_.amount;

    }

    /**************************************

        View: Get total amount of rewards for extra tokens

        ------------------------------

        @param _account address for which rewards should be calculated

    **************************************/

    function userExtraRewards(address _account) public override view
    onlyInState(State.CONFIGURED)
    returns (uint96) {

        // return
        return _userExtraRewards(_account);

    }

    // -----------------------------------------------------------------------
    //                             Internal
    // -----------------------------------------------------------------------

    /**************************************

        Accrue

        ------------------------------

        @notice Internally compounds tokens from reward pool to deposit pool for given address
        @dev Action performed during deposit and right before withdrawal
        @param _account address for which reward is physically compounded into deposit

    **************************************/

    function accrue(address _account) internal
    returns (uint96 earnings_) {

        // compute amount pending
        earnings_ = rewardOf(_account);
        if (earnings_ == 0) return 0;

        // get balance
        Balance memory balance_ = balances[_account];

        // update tracking globally
        pendingSum -= earnings_;
        depositSum += earnings_;

        // sum tokens with pending
        uint96 tokensAndEarnings_ = balance_.amount + earnings_;

        // update balance of account
        balances[_account] = Balance(
            tokensAndEarnings_,             // amount
            compounding.rate,               // snapshot
            compounding.extraRate           // extra snapshot
        );

        // transfer tokens from reward pool to deposit pool
        _rewardPoolWithdraw(address(depositPool), earnings_);

    }

    /**************************************

        Calculate base rewards (with maintaining precision between local and global compound)

        ------------------------------

        @param _ipy Calculated IPY value.
        @param _compoundedSum Total amount of deposited and pending tokens.
        @return baseRewards_ Rewards for THOL.

    **************************************/

    function _calculateBaseRewardsWithPrecision(int128 _ipy, uint96 _compoundedSum) internal
    returns (uint96 baseRewards_) {

        // return if 0
        if (_compoundedSum == 0) return 0;

        // calculate rewards without precision
        baseRewards_ = uint96(_ipy.mulu(_compoundedSum));

        // calculate only precision for calculated rewards
        uint256 baseRewardsLostPrecision_ = _ipy.mulu(_compoundedSum * PRECISION_SCALE) % PRECISION_SCALE;

        // increase rewards by 1 if the sum of previously and currently lost precision is greater than
        // threshold value (PRECISION_SCALE)
        if (pendingSumPrecision + baseRewardsLostPrecision_ >= PRECISION_SCALE) baseRewards_++;

        // this ensures that computations performed all at once and individually will not suffer mismatch due to lost sum of remainders
        pendingSumPrecision = uint72((pendingSumPrecision + baseRewardsLostPrecision_) % PRECISION_SCALE);

    }

    // -----------------------------------------------------------------------
    //                             Gap
    // -----------------------------------------------------------------------

    /**************************************

        Storage gap

        ------------------------------

        @dev This empty reserved space is put in place to allow future versions to add new
        variables without shifting down storage in the inheritance chain.
        See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

    **************************************/

    uint256[50] private __gap;

}