// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libs/Multicall.sol";
import "../libs/ValidatorUtil.sol";
import "../libs/SnapshotUtil.sol";
import "../libs/DelegationUtil.sol";

import "../interfaces/IStakingConfig.sol";
import "../interfaces/IStaking.sol";

import "./ValidatorRegistry.sol";
import "../libs/MathUtils.sol";

abstract contract Staking is ValidatorRegistry, Multicall {

    using SnapshotUtil for ValidatorSnapshot;

    struct ValidatorPool {
        address validatorAddress; // address of validator
        uint96 totalRewards; // total rewards available for delegators
        uint256 sharesSupply; // total shares supply
        uint256 unlocked; // amount unlocked to claim
    }

    /*
     * @dev delegator data
     */
    struct DelegationHistory {
        Delegation[] delegations; // existing delegations
        /**
         * last epoch when made unlock
         * needed to give ability to undelegate only after UndelegatePeriod
         */
        uint64 lastUnlockEpoch;
        uint256 unlockedAmount; // amount not participating in staking
        uint256 delegationGap;
    }

    /*
     * @dev record with delegation data for particular epoch
     */
    struct Delegation {
        uint64 epoch; // particular epoch of record
        uint112 amount; // delegated amount in particular epoch
        /*
         * @dev amount - fromShares(validatorPool, shares) = rewards
         */
        uint256 shares; // amount represented in shares (give ability to accumulate rewards)
        uint96 claimed; // claimed amount of rewards
    }

    /*
     * validator => delegator => delegations
     * @dev history of staker for particular validator
     */
    mapping(address => mapping(address => DelegationHistory)) internal _delegationHistory;

    /*
     * validator pools (validator => pool)
     * @dev all existing pools of validators
     */
    mapping(address => ValidatorPool) internal _validatorPools;

    /*
     * allocated shares (validator => staker => shares)
     * @dev total delegator shares and delegated amount of validator pool
     */
    mapping(address => mapping(address => uint256)) internal _stakerShares;
    mapping(address => mapping(address => uint112)) internal _stakerAmounts;

    uint64 public _MIGRATION_EPOCH;
    bool internal _VALIDATORS_MIGRATED;
    mapping(address => bool) public isMigratedDelegator;

    // reserve some gap for the future upgrades
    uint256[25 - 6] private __reserved;

    /*
     * used by frontend
     * @return amount - undelegated amount + available rewards
     */
    function getDelegatorFee(address validator, address delegator) external override view returns (uint256 amount) {
        uint64 epoch = nextEpoch();
        if (_delegationHistory[validator][delegator].lastUnlockEpoch + _stakingConfig.getUndelegatePeriod() < epoch) {
            amount += _delegationHistory[validator][delegator].unlockedAmount;
        }
        amount += _calcRewards(validator, delegator);
    }

    function getPendingDelegatorFee(address validator, address delegator) external override view returns (uint256) {
        uint64 epoch = nextEpoch();
        if (_delegationHistory[validator][delegator].lastUnlockEpoch + _stakingConfig.getUndelegatePeriod() >= epoch) {
            return _delegationHistory[validator][delegator].unlockedAmount;
        }
        return 0;
    }

    /*
     * used by front-end
     * @return staking rewards available for claim
     */
    function getStakingRewards(address validator, address delegator) external view returns (uint256) {
        return _calcRewards(validator, delegator);
    }

    /*
     * used by front-end
     * @notice calculate available for redelegate amount of rewards
     * @return amountToStake - amount of rewards ready to restake
     * @return rewardsDust - not stakeable part of rewards
     */
    function calcAvailableForRedelegateAmount(address validator, address delegator) external view override returns (uint256 amountToStake, uint256 rewardsDust) {
        uint256 claimableRewards = _calcRewards(validator, delegator);
        return calcAvailableForDelegateAmount(claimableRewards);
    }

    /**
     * @notice should use it for split re/delegate amount into stake-able and dust
     * @return amountToStake - amount possible to stake without dust part
     * @return dust - not stakeable part
     */
    function calcAvailableForDelegateAmount(uint256 amount) public pure override returns (uint256 amountToStake, uint256 dust) {
        amountToStake = (amount / BALANCE_COMPACT_PRECISION) * BALANCE_COMPACT_PRECISION;
        dust = amount - amountToStake;
        return (amountToStake, dust);
    }

    /*
     * @dev collect diff between delegated amount and current shares amount
     */
    function _calcRewards(address validator, address delegator) internal view returns (uint256 rewards) {
        DelegationHistory memory history = _delegationHistory[validator][delegator];
        Delegation[] memory delegations = history.delegations;

        ValidatorPool memory validatorPool = _getValidatorPool(validator);

        for (uint256 i = history.delegationGap; i < delegations.length; i++) {
            // diff between current shares value and delegated amount is profit
            uint256 balance = _fromShares(validatorPool, delegations[i].shares) - delegations[i].claimed;
            uint256 amount = uint256(delegations[i].amount) * BALANCE_COMPACT_PRECISION;
            if (balance > amount) {
                rewards += balance - amount;
            }
        }
    }

    /*
     * used by frontend
     * @return atEpoch - epoch of last delegation
     * @return delegatedAmount - current delegated amount
     */
    function getValidatorDelegation(address validator, address delegator) external view override returns (
        uint256 delegatedAmount,
        uint64 atEpoch
    ) {
        DelegationHistory memory history = _delegationHistory[validator][delegator];
        if (history.delegations.length - history.delegationGap == 0) {
            return (0, 0);
        }
        (, delegatedAmount) = _calcTotal(history);
        delegatedAmount = delegatedAmount * BALANCE_COMPACT_PRECISION;

        atEpoch = history.delegations[history.delegations.length - 1].epoch;
    }

    function _calcTotal(DelegationHistory memory history) internal pure returns (uint256 shares, uint256 amount) {
        Delegation[] memory delegations = history.delegations;
        uint256 length = delegations.length;

        for (uint i = history.delegationGap; i < length; i++) {
            shares += delegations[i].shares;
            amount += delegations[i].amount;
        }
    }

    /*
     * used by frontend
     * @return amount ready to be unlocked
     */
    function calcUnlockedDelegatedAmount(address validator, address delegator) public view returns (uint256) {
        return _calcUnlocked(validator, delegator) * BALANCE_COMPACT_PRECISION;
    }

    function _calcUnlocked(address validator, address delegator) internal view returns (uint256 unlockedAmount) {
        DelegationHistory memory history = _delegationHistory[validator][delegator];
        Delegation[] memory delegations = history.delegations;
        uint256 length = delegations.length;

        uint64 lockPeriod = _stakingConfig.getLockPeriod();
        uint64 epoch = nextEpoch();

        for (; history.delegationGap < length && delegations[history.delegationGap].epoch + lockPeriod < epoch; history.delegationGap++) {
            unlockedAmount += uint256(delegations[history.delegationGap].amount);
        }
    }

    /*
     * used by frontend
     * @notice claim available rewards and unlocked amount
     */
    function claimDelegatorFee(address validator) external override {
        migrateDelegator(msg.sender);
        uint64 epoch = nextEpoch();
        // collect rewards from records
        uint256 claimAmount = _claimRewards(validator, msg.sender);
        // collect unlocked
        claimAmount += _claimUnlocked(validator, msg.sender, epoch);

        _safeTransferWithGasLimit(payable(msg.sender), claimAmount);
        emit Claimed(validator, msg.sender, claimAmount, epoch);
    }

    /*
     * used by frontend
     * @notice claim only available rewards
     */
    function claimStakingRewards(address validator) external override {
        migrateDelegator(msg.sender);
        uint64 epoch = nextEpoch();
        uint256 amount = _claimRewards(validator, msg.sender);
        _safeTransferWithGasLimit(payable(msg.sender), amount);
        emit Claimed(validator, msg.sender, amount, epoch);
    }

    /*
     * @dev extract extra balance from shares and deduct it
     * @return rewards amount to withdraw
     */
    function _claimRewards(address validator, address delegator) internal returns (uint96 availableRewards) {
        DelegationHistory memory history = _delegationHistory[validator][delegator];
        Delegation[] memory delegations = history.delegations;

        // get storage instance
        Delegation[] storage storageDelegations = _delegationHistory[validator][delegator].delegations;

        ValidatorPool memory validatorPool = _getValidatorPool(validator);

        uint96 recordReward;
        // look at all records
        for (uint i = history.delegationGap; i < delegations.length; i++) {
            // calculate diff between shares and delegated amount
            uint256 balance = _fromShares(validatorPool, delegations[i].shares) - delegations[i].claimed;
            uint256 amount = uint256(delegations[i].amount) * BALANCE_COMPACT_PRECISION;
            if (balance > amount) {
                recordReward = uint96(balance - amount);
                availableRewards += recordReward;
                delegations[i].claimed += recordReward;
                // write to storage
                storageDelegations[i] = delegations[i];
            }
        }
    }

    /*
     * used by frontend
     * @notice claim only unlocked delegates
     */
    function claimPendingUndelegates(address validator) external override {
        migrateDelegator(msg.sender);
        uint64 epoch = nextEpoch();
        uint256 amount = _claimUnlocked(validator, msg.sender, epoch);
        // transfer unlocked
        _safeTransferWithGasLimit(payable(msg.sender), amount);
        // emit event
        emit Claimed(validator, msg.sender, amount, epoch);
    }

    /*
     * @dev will not revert tx because used in pair with rewards methods
     * @return unlocked amount to send
     */
    function _claimUnlocked(address validator, address delegator, uint64 epoch) internal returns (uint256 unlockedAmount) {
        DelegationHistory memory history = _delegationHistory[validator][delegator];
        unlockedAmount = history.unlockedAmount;

        // if nothing to unlock return zero
        if (unlockedAmount == 0) {
            return unlockedAmount;
        }
        // if unlock not happened return zero
        if (history.lastUnlockEpoch + _stakingConfig.getUndelegatePeriod() >= epoch) {
            return 0;
        }

        ValidatorPool memory validatorPool = _getValidatorPool(validator);
        require(validatorPool.unlocked >= unlockedAmount, "nothing to undelegate");

        // update validator pool
        validatorPool.unlocked -= unlockedAmount;
        _validatorPools[validator] = validatorPool;

        // reset state
        _delegationHistory[validator][delegator].unlockedAmount = 0;
    }

    /*
     * used by frontend
     * @notice get delegations queue as-is
     * @return list of delegations
     */
    function getDelegateQueue(address validator, address delegator) public view returns (Delegation[] memory queue) {
        DelegationHistory memory history = _delegationHistory[validator][delegator];
        Delegation[] memory delegations = history.delegations;
        queue = new Delegation[](delegations.length - history.delegationGap);
        for (uint gap; history.delegationGap < delegations.length; gap++) {
            Delegation memory delegation = delegations[history.delegationGap++];
            queue[gap] = delegation;
        }
    }

    function _toShares(ValidatorPool memory validatorPool, uint256 amount) internal view returns (uint256) {
        uint256 totalDelegated = getTotalDelegated(validatorPool.validatorAddress);
        if (totalDelegated == 0) {
            return amount;
        } else {
            return MathUtils.multiplyAndDivideCeil(
                amount,
                validatorPool.sharesSupply,
                totalDelegated + validatorPool.totalRewards
            );
        }
    }

    function fromShares(address validator, uint256 shares) external view returns (uint256) {
        return _fromShares(_getValidatorPool(validator), shares);
    }

    function _fromShares(ValidatorPool memory validatorPool, uint256 shares) internal view returns (uint256) {
        uint256 totalDelegated = getTotalDelegated(validatorPool.validatorAddress);
        if (totalDelegated == 0) {
            return shares;
        } else {
            return MathUtils.multiplyAndDivideFloor(
                shares,
                totalDelegated + validatorPool.totalRewards,
                validatorPool.sharesSupply
            );
        }
    }

    /*
     * used by frontend
     * @notice undelegate an amount of unlocked delegations
     */
    function undelegate(address validator, uint256 amount) external override {
        migrateDelegator(msg.sender);
        _undelegate(validator, msg.sender, amount);
    }

    /*
     * @dev before new undelegate already unlocked should be claimed
     * @dev if not, existing unlocked amount will be available only in nextEpoch + getUndelegatePeriod
     * @dev rewards should be claimed during undelegate, because stashed records will not produce new reward
     */
    function _undelegate(address validator, address delegator, uint256 amount) internal {
        require(amount >= BALANCE_COMPACT_PRECISION, "too low");
        require(amount % BALANCE_COMPACT_PRECISION == 0, "no remainder");
        ValidatorPool memory validatorPool = _getValidatorPool(validator);

        uint256 totalDelegated = getTotalDelegated(validatorPool.validatorAddress);
        require(totalDelegated > 0, "insufficient balance");

        uint112 compactAmount = uint112(amount / BALANCE_COMPACT_PRECISION);
        require(uint256(compactAmount) * BALANCE_COMPACT_PRECISION == amount, "overflow");
        require(compactAmount <= _stakerAmounts[validator][delegator], "insufficient balance");

        uint64 beforeEpoch = nextEpoch();

        (uint96 claimed, uint256 shares) = _stashUnlocked(validatorPool, delegator, compactAmount, beforeEpoch);

        // deduct unlocked amount in shares from spentShare to get reward
        uint256 stashed = _fromShares(validatorPool, shares);
        uint96 totalRewards;
        if (stashed > amount) {
            totalRewards = uint96(stashed - amount);
        }
        uint256 availableReward = totalRewards > claimed ? totalRewards - claimed : 0;

        // remove amount from validator
        _removeDelegate(validator, compactAmount, beforeEpoch);

        // update delegator state
        _stakerAmounts[validator][delegator] -= compactAmount;
        _stakerShares[validator][delegator] -= shares;
        // add pending
        validatorPool.unlocked += amount;
        // remove claimed rewards from pool
        validatorPool.totalRewards -= totalRewards;
        // deduct undelegated shares
        validatorPool.sharesSupply -= shares;

        // save the state
        _validatorPools[validator] = validatorPool;
        // send rewards from stashed
        _safeTransferWithGasLimit(payable(delegator), availableReward);
        // emit event
        emit Claimed(validator, delegator, availableReward, beforeEpoch);
        emit Undelegated(validator, delegator, amount, beforeEpoch);
    }

    /*
     * @dev removes amount from unlocked records
     * @dev fulfilled records deleted
     * @return usedShares - spent shares for reward
     * @return rewards - amount of claimed rewards
     */
    function _stashUnlocked(
        ValidatorPool memory validatorPool,
        address delegator,
        uint112 expectedAmount,
        uint64 beforeEpoch
    ) internal returns (uint96 claimed, uint256 spentShares) {
        DelegationHistory memory history = _delegationHistory[validatorPool.validatorAddress][delegator];
        Delegation[] memory delegations = history.delegations;

        // work with memory because we can't copy array
        Delegation[] storage storageDelegations = _delegationHistory[validatorPool.validatorAddress][delegator].delegations;

        uint64 lockPeriod = _stakingConfig.getLockPeriod();
        uint256 unlockedAmount = uint256(expectedAmount) * BALANCE_COMPACT_PRECISION;

        while(history.delegationGap < delegations.length && delegations[history.delegationGap].epoch + lockPeriod < beforeEpoch && expectedAmount > 0) {
            if (delegations[history.delegationGap].amount > expectedAmount) {
                // calculate particular part of shares to remove
                // shares = expected / amount * shares;
                uint256 shares = MathUtils.multiplyAndDivideCeil(expectedAmount * BALANCE_COMPACT_PRECISION, delegations[history.delegationGap].shares, delegations[history.delegationGap].amount * BALANCE_COMPACT_PRECISION);
                uint96 spentClaimed = uint96(MathUtils.multiplyAndDivideCeil(expectedAmount * BALANCE_COMPACT_PRECISION, delegations[history.delegationGap].claimed, delegations[history.delegationGap].amount * BALANCE_COMPACT_PRECISION));

                delegations[history.delegationGap].amount -= expectedAmount;
                delegations[history.delegationGap].shares -= shares;
                delegations[history.delegationGap].claimed -= spentClaimed;

                spentShares += shares;
                claimed += spentClaimed;
                // expected amount is filled
                expectedAmount = 0;
                // save changes to storage
                storageDelegations[history.delegationGap] = delegations[history.delegationGap];
                break;
            }
            expectedAmount -= delegations[history.delegationGap].amount;
            claimed += delegations[history.delegationGap].claimed;
            spentShares += delegations[history.delegationGap].shares;
            delete storageDelegations[history.delegationGap];
            history.delegationGap++;
        }

        require(expectedAmount == 0, "still locked");

        // save new state
        _delegationHistory[validatorPool.validatorAddress][delegator].delegationGap = history.delegationGap;
        _delegationHistory[validatorPool.validatorAddress][delegator].unlockedAmount += unlockedAmount;
        _delegationHistory[validatorPool.validatorAddress][delegator].lastUnlockEpoch = beforeEpoch;
    }

    function _getValidatorPool(address validator) internal view returns (ValidatorPool memory) {
        ValidatorPool memory validatorPool = _validatorPools[validator];
        validatorPool.validatorAddress = validator;
        return validatorPool;
    }

    /*
     * used by frontend
     * @notice make new delegation using available rewards
     */
    function redelegateDelegatorFee(address validator) external override {
        migrateDelegator(msg.sender);
        uint256 rewards = _claimRewards(validator, msg.sender);
        uint256 dust;
        (rewards, dust) = calcAvailableForDelegateAmount(rewards);
        require(rewards > 0, "too low");
        uint64 sinceEpoch = nextEpoch();
        _delegateUnsafe(validator, msg.sender, rewards, sinceEpoch);
        _safeTransferWithGasLimit(payable(msg.sender), dust);
        emit Redelegated(validator, msg.sender, rewards, dust, sinceEpoch);
    }

    function _delegate(address validator, address delegator, uint256 amount) internal {
        migrateDelegator(msg.sender);
        require(amount >= _stakingConfig.getMinStakingAmount(), "less than min");
        // get next epoch
        uint64 sinceEpoch = nextEpoch();
        _delegateUnsafe(validator, delegator, amount, sinceEpoch);
        // emit event
        emit Delegated(validator, delegator, amount, sinceEpoch);
    }

    /*
     * @dev check values before this method
     */
    function _delegateUnsafe(address validator, address delegator, uint256 amount, uint64 sinceEpoch) internal override {
        require(amount % BALANCE_COMPACT_PRECISION == 0, "no remainder");
        uint112 compactAmount = uint112(amount / BALANCE_COMPACT_PRECISION);
        require(uint256(compactAmount) * BALANCE_COMPACT_PRECISION == amount, "overflow");
        // add delegated amount to validator snapshot, revert if validator not exist

        ValidatorPool memory validatorPool = _getValidatorPool(validator);

        uint256 shares = _toShares(validatorPool, amount);
        // increase total accumulated shares for the staker
        _stakerShares[validator][delegator] += shares;
        // increase total accumulated amount for the staker
        _stakerAmounts[validator][delegator] += compactAmount;
        validatorPool.sharesSupply += shares;
        // save validator pool
        _addDelegate(validator, compactAmount, sinceEpoch);

        _adjustDelegation(validator, delegator, sinceEpoch, shares, compactAmount);

        _validatorPools[validator] = validatorPool;
    }

    function _adjustDelegation(address validator, address delegator, uint64 epoch, uint256 shares, uint112 amount) internal {
        DelegationHistory memory history = _delegationHistory[validator][delegator];
        Delegation[] storage delegations = _delegationHistory[validator][delegator].delegations;
        uint256 length = delegations.length;

        if (length - history.delegationGap > 0 && delegations[length - 1].epoch >= epoch) {
            delegations[length - 1].amount = delegations[length - 1].amount + amount;
            delegations[length - 1].shares += shares;
        } else {
            delegations.push(Delegation(epoch, amount, shares, 0));
        }
    }

    function _addReward(address validator, uint96 amount) internal override {
        _validatorPools[validator].totalRewards += amount;
    }

    //  __  __ _                 _   _
    // |  \/  (_) __ _ _ __ __ _| |_(_) ___  _ __
    // | |\/| | |/ _` | '__/ _` | __| |/ _ \| '_ \
    // | |  | | | (_| | | | (_| | |_| | (_) | | | |
    // |_|  |_|_|\__, |_|  \__,_|\__|_|\___/|_| |_|
    //           |___/

    function migrateValidators() external onlyFromGovernance {
        address[] memory validators = _activeValidatorsList;
        require(!_VALIDATORS_MIGRATED, "already migrated");

        for (uint256 i; i < validators.length; i++) {
            address validatorAddress = validators[i];
            // migrate validator to new storage contract
            Validator memory validator = _validatorsMap[validatorAddress];
            _validatorStorage.migrate(validator);
            delete _validatorsMap[validatorAddress];

            // create validatorPool using validator snapshot
            (,,uint256 totalDelegated,,,,,,) = getValidatorStatus(validatorAddress);
            ValidatorPool memory validatorPool = ValidatorPool(validatorAddress, 0, totalDelegated, 0);
            _validatorPools[validatorAddress] = validatorPool;
        }

        _MIGRATION_EPOCH = nextEpoch();
        _VALIDATORS_MIGRATED = true;
    }

    function migrateDelegator(address delegator) public {
        address[] memory validators = _validatorStorage.getValidators();

        if (isMigratedDelegator[delegator]) {
            return;
        }
        isMigratedDelegator[delegator] = true;

        require(validators.length > 0, "no validators");

        ValidatorDelegation memory delegations;
        DelegationHistory memory history;

        for (uint256 i; i < validators.length; i++) {
            address validatorAddress = validators[i];
            // first of all claim all rewards
            _transferDelegatorRewards(validatorAddress, delegator);

            delegations = _validatorDelegations[validatorAddress][delegator];
            ValidatorPool memory validatorPool = _validatorPools[validatorAddress];
            Delegation[] storage newDelegations = _delegationHistory[validatorAddress][delegator].delegations;

            {
                if (delegations.delegateQueue.length - delegations.delegateGap > 0) {
                    uint112 staked = delegations.delegateQueue[delegations.delegateQueue.length - 1].amount;
                    // merge all records in one with the earliest epoch and latest staked amount
                    newDelegations.push(
                        Delegation(delegations.delegateQueue[delegations.delegateGap].epoch, staked, uint256(staked) * BALANCE_COMPACT_PRECISION, 0)
                    );
                    _stakerAmounts[validatorAddress][delegator] = staked;
                    _stakerShares[validatorAddress][delegator] = uint256(staked) * BALANCE_COMPACT_PRECISION;
                }
            }

            {
                uint112 undelegated;
                for (uint256 j = delegations.undelegateGap; j < delegations.undelegateQueue.length; j++) {
                    undelegated += delegations.undelegateQueue[j].amount;
                    history.lastUnlockEpoch = delegations.undelegateQueue[j].epoch;
                }
                _delegationHistory[validatorAddress][delegator].lastUnlockEpoch = history.lastUnlockEpoch;
                _delegationHistory[validatorAddress][delegator].unlockedAmount = uint256(undelegated) * BALANCE_COMPACT_PRECISION;
                validatorPool.unlocked += uint256(undelegated) * BALANCE_COMPACT_PRECISION;
            }

            delete _validatorDelegations[validatorAddress][delegator];
            _validatorPools[validatorAddress] = validatorPool;
            _delegationHistory[validatorAddress][delegator].delegations = newDelegations;
        }
    }

    // modified method from EpochStaking
    function _transferDelegatorRewards(address validator, address delegator) internal {
        // next epoch to claim all rewards including pending
        uint64 beforeEpochExclude = _MIGRATION_EPOCH;
        // claim rewards and undelegates
        uint256 availableFunds = _processDelegateQueue(validator, delegator, beforeEpochExclude);
        // for transfer claim mode just all rewards to the user
        _safeTransferWithGasLimit(payable(delegator), availableFunds);
        // emit event
        emit Claimed(validator, delegator, availableFunds, beforeEpochExclude);
    }

    function _processDelegateQueue(address validator, address delegator, uint64 beforeEpochExclude) internal view returns (uint256 availableFunds) {
        ValidatorDelegation memory delegation = _validatorDelegations[validator][delegator];
        uint64 delegateGap = delegation.delegateGap;
        // lets iterate delegations from delegateGap to queueLength
        for (; delegateGap < delegation.delegateQueue.length; delegateGap++) {
            // pull delegation
            DelegationOpDelegate memory delegateOp = delegation.delegateQueue[delegateGap];
            if (delegateOp.epoch >= beforeEpochExclude) {
                break;
            }
            (uint256 extracted, /* uint64 claimedAt */) = _extractClaimable(delegation, delegateGap, validator, beforeEpochExclude);
            availableFunds += extracted;
        }
    }

    // extract rewards from claimEpoch to nextDelegationEpoch or beforeEpoch
    function _extractClaimable(
        ValidatorDelegation memory delegation,
        uint64 gap,
        address validator,
        uint256 beforeEpoch
    ) internal view returns (uint256 availableFunds, uint64 lastEpoch) {
        DelegationOpDelegate memory delegateOp = delegation.delegateQueue[gap];
        // if delegateOp was created before field claimEpoch added
        if (delegateOp.claimEpoch == 0) {
            delegateOp.claimEpoch = delegateOp.epoch;
        }

        // we must extract claimable rewards before next delegation
        uint256 nextDelegationEpoch;
        if (gap < delegation.delegateQueue.length - 1) {
            nextDelegationEpoch = delegation.delegateQueue[gap + 1].epoch;
        }

        for (; delegateOp.claimEpoch < beforeEpoch && (nextDelegationEpoch == 0 || delegateOp.claimEpoch < nextDelegationEpoch); delegateOp.claimEpoch++) {
            ValidatorSnapshot memory validatorSnapshot = _validatorSnapshots[validator][delegateOp.claimEpoch];
            if (validatorSnapshot.totalDelegated == 0) {
                continue;
            }
            (uint256 delegatorFee, /*uint256 ownerFee*/, /*uint256 systemFee*/) = _calcValidatorSnapshotEpochPayout(validatorSnapshot);
            availableFunds += delegatorFee * delegateOp.amount / validatorSnapshot.totalDelegated;
        }
        return (availableFunds, delegateOp.claimEpoch);
    }

    function _calcValidatorSnapshotEpochPayout(ValidatorSnapshot memory validatorSnapshot) internal view returns (uint256 delegatorFee, uint256 ownerFee, uint256 systemFee) {
        // detect validator slashing to transfer all rewards to treasury
        if (validatorSnapshot.slashesCount >= _stakingConfig.getMisdemeanorThreshold()) {
            return (delegatorFee, ownerFee, systemFee = validatorSnapshot.totalRewards);
        } else if (validatorSnapshot.totalDelegated == 0) {
            return (delegatorFee, ownerFee = validatorSnapshot.totalRewards, systemFee);
        }
        ownerFee = validatorSnapshot.getOwnerFee();
        delegatorFee = validatorSnapshot.totalRewards - ownerFee;
    }

    function _safeTransferWithGasLimit(address payable recipient, uint256 amount) internal virtual {
        (bool success,) = recipient.call{value : amount, gas : TRANSFER_GAS_LIMIT}("");
        require(success, "transfer failed");
    }

    receive() external virtual payable {
    }
}