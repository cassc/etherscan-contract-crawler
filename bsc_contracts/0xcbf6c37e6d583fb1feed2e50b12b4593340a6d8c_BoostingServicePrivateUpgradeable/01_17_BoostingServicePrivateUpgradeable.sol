// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

import "./interfaces/INmxSupplier.sol";
import "./interfaces/IStakingService.sol";

import "./PausableByOwnerUpgradeable.sol";
import "./RecoverableByOwnerUpgradeable.sol";

contract BoostingServicePrivateUpgradeable is UUPSUpgradeable, PausableByOwnerUpgradeable, RecoverableByOwnerUpgradeable {
    using ABDKMath64x64 for int128;

    struct Staker {
        uint128 initialCompoundRate;
        uint128 initialBoostingRate;

        uint128 principalAmount;
        uint128 boostingAmount;

        uint128 unlockedBoostingAmount;
        uint128 amount;

        uint128 shares;
        uint64 stakedAt;
    }

    struct BoostingRateCheckpoint {
        uint64  time;
        uint128 value;
    }

    uint16  public constant  RATE_DENOMINATOR = 10000; // 2000 - is 20%
    uint16  public constant  MAX_PENALTY_RATE = 2500; // 25%
    uint16  public constant  MAX_PERFORMANCE_FEE = 500; // 5%
    address public constant  NULL_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public immutable REFUND_SUPPLIER_ADDRESS;
    address public immutable NMX;
    address public immutable OLD_LAUNCHPOOL;
    address public immutable LAUNCHPOOL;
    uint32  public immutable DURATION;
    /// @dev time adjusting coefficients
    uint72  public immutable K1;
    uint72  public immutable K2;

    bytes32 public domain_separator;

    address public nmxSupplier;
    uint16  public boostingRate;
    uint16  public penaltyRate;
    uint16  public performanceFee;

    uint128 public totalShares;
    uint128 public totalStakedCompounded;

    uint128 public totalStaked;
    uint128 public totalBoostings;

    uint128 public historicalCompoundRate;
    uint128 public historicalBoostingRate;

    mapping(address => Staker) public stakers;

    BoostingRateCheckpoint[] boostingRateHistory;

    mapping(address => uint256) public nonces;

    address public migrator;
    uint128 public unstakedShares; // unstaked shares when pool is private
    bool public upgraded; // true when pool transferred to new launchpool

    string private constant UNSTAKE_TYPE =
    "Unstake(address owner,address spender,uint128 value,uint256 nonce,uint256 deadline)";
    bytes32 public constant UNSTAKE_TYPEHASH = keccak256(abi.encodePacked(UNSTAKE_TYPE));


    string private constant CLAIM_TYPE =
    "Claim(address owner,address spender,uint128 value,uint256 nonce,uint256 deadline)";
    bytes32 public constant CLAIM_TYPEHASH =
    keccak256(abi.encodePacked(CLAIM_TYPE));

    event Staked(address indexed owner, uint128 amount);
    event Unstaked(address indexed from, address indexed to, uint128 amount);
    event BoostingAccrued(address indexed owner, uint128 amount);
    event BoostingBurnt(address indexed owner, uint128 amount);
    event BoostingUnlocked(address indexed owner, uint128 amount);
    event BoostingClaimed(address indexed owner, address indexed spender, uint128 amount);
    event CompoundAccrued(address indexed owner, uint128 amount);
    event CompoundBurnt(address indexed owner, uint128 amount);
    event CompoundUnlocked(address indexed owner, uint128 amount);
    event PenaltyBurnt(address indexed owner, uint128 amount);
    event ParamsChanged(address nmxSupplier, uint16 boostingRate, uint16 penaltyRate, uint16 performanceFee);

    constructor(
        address _nmx,
        address _oldLaunchpool,
        address _launchpool,
        address _refundSupplierAddress,
        uint32 _duration,
        uint72 _k1,
        uint72 _k2
    ) {
        NMX = _nmx;
        OLD_LAUNCHPOOL = _oldLaunchpool;
        LAUNCHPOOL = _launchpool;
        REFUND_SUPPLIER_ADDRESS = _refundSupplierAddress;
        DURATION = _duration;
        K1 = _k1;
        K2 = _k2;
    }

    /**
     @dev Modifier to make a function callable only when the contract is upgraded
     */
    modifier whenUpgraded() {
        require(upgraded, "BoostingService: NOT_UPGRADED");
        _;
    }

    function initialize(
        address _nmxSupplier,
        uint16 _boostingRate,
        uint16 _penaltyRate,
        uint16 _performanceFee
    ) public initializer {
        require(_penaltyRate <= MAX_PENALTY_RATE, 'BoostingService: INVALID_PENALTY_RATE');
        require(_performanceFee <= MAX_PERFORMANCE_FEE, 'BoostingService: INVALID_PERFORMANCE_FEE');

        __PausableByOwner_init();

        _changeParams(_nmxSupplier, _boostingRate, _penaltyRate, _performanceFee);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        domain_separator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("BoostingService")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

        IERC20(NMX).approve(LAUNCHPOOL, 2**256 - 1);
        _recordBoostingRateHistory(0);
    }

    function changeParams(
        address _nmxSupplier,
        uint16 _boostingRate,
        uint16 _penaltyRate,
        uint16 _performanceFee
    )
    external
    onlyOwner
    whenUpgraded
    {
        _changeParams(_nmxSupplier, _boostingRate, _penaltyRate, _performanceFee);
    }

    function _changeParams(
        address _nmxSupplier,
        uint16 _boostingRate,
        uint16 _penaltyRate,
        uint16 _performanceFee
    )
    private
    {
        require(_penaltyRate <= MAX_PENALTY_RATE, 'BoostingService: INVALID_PENALTY_RATE');
        require(_performanceFee <= MAX_PERFORMANCE_FEE, 'BoostingService: INVALID_PERFORMANCE_FEE');

        nmxSupplier = _nmxSupplier;
        boostingRate = _boostingRate;
        penaltyRate = _penaltyRate;
        performanceFee = _performanceFee;
        emit ParamsChanged(_nmxSupplier, _boostingRate, _penaltyRate, _performanceFee);
    }

    function upgradeLaunchPool() external onlyOwner {
        require(OLD_LAUNCHPOOL != LAUNCHPOOL, 'BoostingService: INVALID_LAUNCHPOOL');
        require(!upgraded, 'BoostingService: ALREADY_UPGRADED');

        IStakingService(OLD_LAUNCHPOOL).unstake(totalStakedCompounded);
        uint128 compoundRewards = _receiveCompound();
        _receiveBoosting(compoundRewards);
        IERC20(NMX).approve(OLD_LAUNCHPOOL, 0);

        IERC20(NMX).approve(LAUNCHPOOL, 2**256 - 1);
        IStakingService(LAUNCHPOOL).stakeFrom(address(this), totalStakedCompounded); // already with compound rewards

        upgraded = true;
    }

    function changeMigrator(address _migrator) external onlyOwner {
        migrator = _migrator;
    }

    function getAndUpdateStaker() external whenUpgraded whenNotPaused returns (Staker memory) {
        Staker storage staker = stakers[_msgSender()];
        _compoundAndRecalculateShares(staker, 0, _msgSender());
        return staker;
    }

    function claimBoostingRewards() external {
        address owner = _msgSender();
        _claimReward(owner, owner);
    }

    function claimBoostingRewardsWithAuthorization(
        address owner,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        _verifySignature(
            CLAIM_TYPEHASH,
            owner,
            _msgSender(),
            0,
            deadline,
            v,
            r,
            s
        );

        _claimReward(owner, _msgSender());
    }

    function _claimReward(address owner, address spender) private whenUpgraded whenNotPaused {
        Staker storage staker = stakers[owner];
        _compoundAndRecalculateShares(staker, 0, owner);

        uint128 _stakerBoosting = staker.unlockedBoostingAmount;
        require(_stakerBoosting > 0, "BoostingService: NO BOOSTING REWARDS");

        staker.unlockedBoostingAmount = 0;
        totalBoostings -= _stakerBoosting;

        bool transferred = IERC20(NMX).transfer(spender, _stakerBoosting);
        require(transferred, "BoostingService: FAILED_TRANSFER");
        emit BoostingClaimed(owner, spender, _stakerBoosting);
    }

    function unstakeSharesWithAuthorization(
        address owner,
        uint128 shares,
        uint128 signedShares,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint128) {
        require(shares <= signedShares, "BoostingService: INVALID_AMOUNT");

        address spender = _msgSender();

        _verifySignature(
            UNSTAKE_TYPEHASH,
            owner,
            spender,
            signedShares,
            deadline,
            v,
            r,
            s
        );

        return _unstakeShares(owner, spender, shares);
    }

    function unstakeShares(uint128 shares) external returns (uint128) {
        return _unstakeShares(_msgSender(), _msgSender(), shares);
    }

    function _unstakeShares(address owner, address spender, uint128 shares) private whenUpgraded whenNotPaused returns (uint128) {
        Staker storage staker = stakers[owner];
        _compoundAndRecalculateShares(staker, 0, owner);

        require(shares <= staker.shares, "BoostingService: INVALID_AMOUNT");
        unstakedShares += shares;

        uint64 _stakedAt  = staker.stakedAt;

        // 2 cases - new user or lock is expired
        if (_stakedAt > 0) {
            // unstake with loss
            return _unstakeSharesLocked(staker, owner, spender, shares);
        } else {
            // unstake without loss
            return _unstakeSharesUnlocked(staker, owner, spender, shares);
        }
    }

    function _unstakeSharesLocked(Staker storage staker, address owner, address spender, uint128 shares) private returns (uint128) {
        require(spender != migrator, "BoostingService: LOCKED_MIGRATION");
        uint128 _stakerShares = staker.shares;
        require(shares <= _stakerShares, "BoostingService: NOT_ENOUGH_BALANCE");

        uint128 principalDiff  = uint128(uint256(staker.principalAmount) * shares / _stakerShares);
        uint128 amountDiff     = uint128(uint256(staker.amount) * shares / _stakerShares);
        uint128 boostingDiff   = uint128(uint256(staker.boostingAmount) * shares / _stakerShares);

        staker.principalAmount -= principalDiff;
        staker.amount -= amountDiff;
        staker.boostingAmount -= boostingDiff;
        staker.shares -= shares;

        if (shares == _stakerShares) {
            staker.stakedAt = 0;
        }

        totalBoostings -= boostingDiff;
        totalStakedCompounded -= amountDiff;
        totalStaked -= principalDiff;
        totalShares -= shares;


        uint128 penaltyAmount = (principalDiff * penaltyRate) / RATE_DENOMINATOR;
        uint128 withdrawAmount = principalDiff - penaltyAmount;
        // amountDiff already includes unstakeAmount so no need to count penaltyAmount
        uint128 compoundBurned = (amountDiff - principalDiff);
        uint128 burnedAmount = compoundBurned + penaltyAmount;


        IStakingService(LAUNCHPOOL).unstake(amountDiff);
        _refundSupplier(boostingDiff);
        _burn(burnedAmount);
        emit PenaltyBurnt(owner, penaltyAmount);
        emit BoostingBurnt(owner, boostingDiff);
        emit CompoundBurnt(owner, compoundBurned);
        bool transferred = IERC20(NMX).transfer(spender, withdrawAmount);
        require(transferred, "BoostingService: FAILED_TRANSFER");
        emit Unstaked(owner, spender, principalDiff);

        return withdrawAmount;
    }

    function _unstakeSharesUnlocked(Staker storage staker, address owner, address spender, uint128 shares) private returns (uint128)  {
        uint128 _stakerShares = staker.shares;
        require(shares <= _stakerShares, "BoostingService: NOT_ENOUGH_BALANCE");

        uint128 unstakeAmount = uint128(uint256(staker.amount) * shares / _stakerShares);

        staker.amount -= unstakeAmount;
        staker.principalAmount -= unstakeAmount;
        staker.shares -= shares;

        // TODO: test
        totalStakedCompounded -= unstakeAmount;
        totalStaked -= unstakeAmount;
        totalShares -= shares;

        uint128 fee = 0;
        if (spender != migrator) {
            fee = unstakeAmount * performanceFee / RATE_DENOMINATOR;
        }
        uint128 unstakeAmountWithFee = unstakeAmount - fee;
        IStakingService(LAUNCHPOOL).unstake(unstakeAmount);
        IERC20(NMX).transfer(spender, unstakeAmountWithFee);
        _burn(fee);
        emit Unstaked(owner, spender, unstakeAmount);

        return unstakeAmountWithFee;
    }


    function _compoundAndRecalculateShares(
        Staker storage staker,
        uint128 amount,
        address owner
    )
    private
    returns(uint128 adjustedStakedAmount)
    {
        uint128 compoundRewards = _receiveCompound();
        _receiveBoosting(compoundRewards);

        adjustedStakedAmount = _materializeShares(staker, owner);
        _stakeShares(staker, amount);

        adjustedStakedAmount += amount;
        if (adjustedStakedAmount > 0) {
            emit Staked(owner, adjustedStakedAmount);
        }

        uint128 compoundAmount = compoundRewards + amount;
        IStakingService(LAUNCHPOOL).stakeFrom(address(this), compoundAmount);
    }

    function _receiveCompound() private returns (uint128 claimedReward) {
        uint128 _totalShares = totalShares;
        uint128 _unstakedShares = unstakedShares;
        uint128 _fullShares = _totalShares + _unstakedShares;

        claimedReward = uint128(IStakingService(LAUNCHPOOL).claimReward());
        if (_fullShares > 0) {
            uint128 _rewardRate = (claimedReward << 40) / _fullShares;

            if (_unstakedShares > 0) {
                uint128 _unusedReward = (_rewardRate * _unstakedShares) >> 40;
                _refundSupplier(_unusedReward);
                claimedReward -= _unusedReward;
            }

            totalStakedCompounded += claimedReward;
            historicalCompoundRate += _rewardRate;
        } else {
            _burn(claimedReward);
            claimedReward = 0;
        }
    }

    function _receiveBoosting(uint128 compoundRewards) private {
        uint128 boostingRewards = uint128(INmxSupplier(nmxSupplier).supplyNmx(uint40(block.timestamp)));
        uint128 expectedBoostings = (compoundRewards * boostingRate) / RATE_DENOMINATOR;

        // theoretically we can receive less than expected
        if (boostingRewards > expectedBoostings) {
            // todo: test
            _refundSupplier(boostingRewards - expectedBoostings);
            boostingRewards = expectedBoostings;
        }

        uint128 _totalShares = totalShares;
        if (_totalShares > 0) {
            uint128 _historicalBoostingRate = historicalBoostingRate + ((boostingRewards << 40) / _totalShares);
            historicalBoostingRate = _historicalBoostingRate;
            _recordBoostingRateHistory(_historicalBoostingRate);
            totalBoostings += boostingRewards;
        } else {
            _refundSupplier(boostingRewards);
        }
    }

    function _materializeShares(Staker storage staker, address owner) private returns(uint128 principalAmountDiff) {
        uint128 _stakerShares = staker.shares;
        uint128 _stakerInitialBoostingRate = staker.initialBoostingRate;

        uint128 compoundAmount = uint128(((uint168(historicalCompoundRate) - staker.initialCompoundRate) * _stakerShares) >> 40);
        uint128 boostingAmount = uint128(((uint168(historicalBoostingRate) - _stakerInitialBoostingRate) * _stakerShares) >> 40);

        uint64 _stakedAt  = staker.stakedAt;
        uint64 stakingEnd = _stakedAt + DURATION;
        bool unlocked;

        // 2 cases - new user or lock is expired
        if (stakingEnd < block.timestamp) {
            unlocked = true;
            // lock is expired
            if (_stakedAt > 0) {
                // one time action: materialize boostings up to the staking end and burn leftovers
                uint128 boostingRateAtCheckpoint = _findNearestLowestBoostingRate(stakingEnd);
                uint128 boostingAmountAtCheckpoint = uint128(((uint168(boostingRateAtCheckpoint) - _stakerInitialBoostingRate) * _stakerShares) >> 40);
                uint128 leftOvers = boostingAmount - boostingAmountAtCheckpoint;
                boostingAmount = boostingAmountAtCheckpoint;
                // todo: regression test
                totalBoostings -= leftOvers;
                uint128 unlockedAmount = staker.boostingAmount + boostingAmount;
                staker.unlockedBoostingAmount += unlockedAmount;
                staker.boostingAmount = 0;
                emit BoostingAccrued(owner, boostingAmount);
                emit BoostingUnlocked(owner, unlockedAmount);
                staker.stakedAt = 0; // will be overwritten in _stakeShares() if user is staking again
                _refundSupplier(leftOvers);
            } else if (boostingAmount > 0) {
                // if staker.stakedAt == 0 it's either a new user or an unloked user
                // if boostingAmount > 0 then it's a user that was previously unlocked and their's lefover boostings were burned
                // and all their due boostings were materialized, since unlocked users do not receive the boost, we now burn everything
                // todo: regression test
                totalBoostings -= boostingAmount;
                _refundSupplier(boostingAmount);
            }
        } else {
            staker.boostingAmount += boostingAmount;
            emit BoostingAccrued(owner, boostingAmount);
        }

        staker.amount += compoundAmount;
        emit CompoundAccrued(owner, compoundAmount);

        if (unlocked) {
            uint128 _principal = staker.principalAmount;
            uint128 _amount = staker.amount;
            principalAmountDiff = _amount  - _principal;
            // materialize compounded rewards
            staker.principalAmount = _amount;
            totalStaked += principalAmountDiff;
            emit CompoundUnlocked(owner, principalAmountDiff);
            // emit Staked(owner, diff);
        }

        staker.initialCompoundRate = historicalCompoundRate;
        staker.initialBoostingRate = historicalBoostingRate;
    }


    function _stakeShares(Staker storage staker, uint128 amount) private {
        if (amount == 0) return;

        uint128 currentShares;
        uint128 _totalShares = totalShares;
        if (_totalShares != 0) {
            currentShares = uint128((uint256(amount) * _totalShares) / totalStakedCompounded);
        } else {
            require(amount >= 10**16, 'BoostingService: INVALID_INITIAL_AMOUNT');
            currentShares = amount;
        }

        uint128 prevPrincipalAmount = staker.principalAmount;

        staker.principalAmount += amount;
        staker.amount += amount;
        staker.shares += currentShares;

        uint64 time = _recalculateStakingTime(staker.stakedAt, prevPrincipalAmount, amount);
        staker.stakedAt = uint64(block.timestamp) - time;
        // emit Staked(owner, amount);

        totalShares += currentShares;
        totalStakedCompounded += amount;
        totalStaked += amount;
    }

    function _burn(uint128 amount) private {
        bool transferred = IERC20(NMX).transfer(NULL_ADDRESS, amount);
        require(transferred, "BoostingService: BURN_TRANSFER_FAILED");
    }

    function _refundSupplier(uint128 amount) private {
        bool transferred = IERC20(NMX).transfer(REFUND_SUPPLIER_ADDRESS, amount);
        require(transferred, "BoostingService: REFUND_TRANSFER_FAILED");
    }

    function _recordBoostingRateHistory(uint128 _boostingRate) private {
        BoostingRateCheckpoint storage checkpoint = boostingRateHistory.push();
        checkpoint.time = uint64(block.timestamp);
        checkpoint.value = _boostingRate;
    }

    function _findNearestLowestBoostingRate(uint64 timestamp) private view returns (uint128) {
        uint256 length = boostingRateHistory.length;
        if (length == 0) {
            return 0;
        }

        // If the requested time is equal to or after the time of the latest registered value, return latest value
        uint256 lastIndex = length - 1;
        if (timestamp >= boostingRateHistory[lastIndex].time) {
            return boostingRateHistory[lastIndex].value;
        }

        // If the requested time is previous to the first registered value, return 0 as if there was no autocompounding
        if (timestamp < boostingRateHistory[0].time) {
            return 0;
        }

        // Execute a binary search between the checkpointed times of the history
        uint256 low = 0;
        uint256 high = lastIndex;

        while (high > low) {
            // for this to overflow array size should be ~2^255
            uint256 mid = (high + low + 1) / 2;
            BoostingRateCheckpoint storage checkpoint = boostingRateHistory[mid];
            uint64 midTime = checkpoint.time;

            if (timestamp > midTime) {
                low = mid;
            } else if (timestamp < midTime) {
                // no overflow: high > low >= 0 => high >= 1 => mid >= 1
                high = mid - 1;
            } else {
                return checkpoint.value;
            }
        }

        uint128 value = boostingRateHistory[low].value;
        if (low < length - 1) {
            uint64 time0 = boostingRateHistory[low].time;
            uint64 time1 = boostingRateHistory[low + 1].time;
            uint128 value1 = boostingRateHistory[low + 1].value;
            // value = value0 + (value1 - value0) / (time1 - time0) * (timestamp - time0) = [value0 * (time1 - time0) + (value1 - value0) * (timestamp - time0)] / (time1 - time0)
            value = (value * (time1 - time0) + (value1 - value) * (timestamp - time0)) / (time1 - time0);
        }
        return value;
    }

    function _verifySignature(
        bytes32 typehash,
        address owner,
        address spender,
        uint128 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private {
        require(deadline >= block.timestamp, "BoostingService: EXPIRED");
        bytes32 digest =
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                domain_separator,
                keccak256(
                    abi.encode(
                        typehash,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "BoostingService: INVALID_SIGNATURE"
        );
    }

    /**
    @dev recalculates user's actual staking time after re-stake
        the formula is principalAmount * secondsSinceStake / (principalAmount + stakeAmount) / (k1 + secondsSinceStake/durationInSeconds*k2)
    @return Calculated user staking time in seconds
    */
    function _recalculateStakingTime(
        uint64 stakedAt,
        uint128 principalAmount,
        uint128 stakingAmount
    )
    internal
    view
    returns(uint64)
    {
        // if this service doesn't have time adjusting coefficient or staker is new or staker is unlocked
        if (K1 == 0 || stakedAt == 0) {
            return 0;
        }

        // todo: can be unchecked {}
        uint64 secondsSinceStake = uint64(block.timestamp) - stakedAt;

        uint128 newAmount = principalAmount + stakingAmount;
        uint192 amountsRatio = (uint192(principalAmount) << 64) / newAmount;
        uint256 first = uint256(secondsSinceStake) * amountsRatio;

        uint192 second = ((uint128(secondsSinceStake) * K2) / DURATION) + K1;
        uint256 result = first / second;

        return uint64(result);
    }

    function getRecoverableAmount(address tokenAddress) override internal view returns (uint256) {
        if (tokenAddress == NMX) {
            uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
            uint256 reserved = totalStakedCompounded + totalBoostings;
            assert(balance >= reserved);
            return balance - reserved;
        }
        return RecoverableByOwnerUpgradeable.getRecoverableAmount(tokenAddress);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}