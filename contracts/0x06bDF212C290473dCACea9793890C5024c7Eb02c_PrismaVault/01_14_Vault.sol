// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "SafeERC20.sol";
import "Address.sol";
import "PrismaOwnable.sol";
import "SystemStart.sol";
import "IPrismaToken.sol";
import "IEmissionSchedule.sol";
import "IIncentiveVoting.sol";
import "ITokenLocker.sol";
import "IBoostDelegate.sol";
import "IBoostCalculator.sol";

interface IEmissionReceiver {
    function notifyRegisteredId(uint256[] memory assignedIds) external returns (bool);
}

interface IRewards {
    function vaultClaimReward(address claimant, address receiver) external returns (uint256);

    function claimableReward(address account) external view returns (uint256);
}

/**
    @title Prisma Vault
    @notice The total supply of PRISMA is initially minted to this contract.
            The token balance held here can be considered "uncirculating". The
            vault gradually releases tokens to registered emissions receivers
            as determined by `EmissionSchedule` and `BoostCalculator`.
 */
contract PrismaVault is PrismaOwnable, SystemStart {
    using Address for address;
    using SafeERC20 for IERC20;

    IPrismaToken public immutable prismaToken;
    ITokenLocker public immutable locker;
    IIncentiveVoting public immutable voter;
    address public immutable deploymentManager;
    uint256 immutable lockToTokenRatio;

    IEmissionSchedule public emissionSchedule;
    IBoostCalculator public boostCalculator;

    // `prismaToken` balance within the treasury that is not yet allocated.
    // Starts as `prismaToken.totalSupply()` and decreases over time.
    uint128 public unallocatedTotal;
    // most recent week that `unallocatedTotal` was reduced by a call to
    // `emissionSchedule.getTotalWeeklyEmissions`
    uint64 public totalUpdateWeek;
    // number of weeks that PRISMA is locked for when transferred using
    // `transferAllocatedTokens`. updated weekly by the emission schedule.
    uint64 public lockWeeks;

    // id -> receiver data
    uint16[65535] public receiverUpdatedWeek;
    // id -> address of receiver
    // not bi-directional, one receiver can have multiple ids
    mapping(uint256 => Receiver) public idToReceiver;

    // week -> total amount of tokens to be released in that week
    uint128[65535] public weeklyEmissions;

    // receiver -> remaining tokens which have been allocated but not yet distributed
    mapping(address => uint256) public allocated;

    // account -> week -> PRISMA amount claimed in that week (used for calculating boost)
    mapping(address => uint128[65535]) accountWeeklyEarned;

    // pending rewards for an address (dust after locking, fees from delegation)
    mapping(address => uint256) private storedPendingReward;

    mapping(address => Delegation) public boostDelegation;

    struct Receiver {
        address account;
        bool isActive;
    }

    struct Delegation {
        bool isEnabled;
        uint16 feePct;
        IBoostDelegate callback;
    }

    struct InitialAllowance {
        address receiver;
        uint256 amount;
    }

    event NewReceiverRegistered(address receiver, uint256 id);
    event ReceiverIsActiveStatusModified(uint256 indexed id, bool isActive);
    event UnallocatedSupplyReduced(uint256 reducedAmount, uint256 unallocatedTotal);
    event UnallocatedSupplyIncreased(uint256 increasedAmount, uint256 unallocatedTotal);
    event IncreasedAllocation(address indexed receiver, uint256 increasedAmount);
    event EmissionScheduleSet(address emissionScheduler);
    event BoostCalculatorSet(address boostCalculator);
    event BoostDelegationSet(address indexed boostDelegate, bool isEnabled, uint256 feePct, address callback);

    constructor(
        address _prismaCore,
        IPrismaToken _token,
        ITokenLocker _locker,
        IIncentiveVoting _voter,
        address _stabilityPool,
        address _manager
    ) PrismaOwnable(_prismaCore) SystemStart(_prismaCore) {
        prismaToken = _token;
        locker = _locker;
        voter = _voter;
        lockToTokenRatio = _locker.lockToTokenRatio();
        deploymentManager = _manager;

        // ensure the stability pool is registered with receiver ID 0
        _voter.registerNewReceiver();
        idToReceiver[0] = Receiver({ account: _stabilityPool, isActive: true });
        emit NewReceiverRegistered(_stabilityPool, 0);
    }

    function setInitialParameters(
        IEmissionSchedule _emissionSchedule,
        IBoostCalculator _boostCalculator,
        uint256 totalSupply,
        uint64 initialLockWeeks,
        uint128[] memory _fixedInitialAmounts,
        InitialAllowance[] memory initialAllowances
    ) external {
        require(msg.sender == deploymentManager, "!deploymentManager");
        emissionSchedule = _emissionSchedule;
        boostCalculator = _boostCalculator;

        // mint totalSupply to vault - this reverts after the first call
        prismaToken.mintToVault(totalSupply);

        // set initial fixed weekly emissions
        uint256 totalAllocated;
        uint256 length = _fixedInitialAmounts.length;
        uint256 offset = getWeek() + 1;
        for (uint256 i = 0; i < length; i++) {
            uint128 amount = _fixedInitialAmounts[i];
            weeklyEmissions[i + offset] = amount;
            totalAllocated += amount;
        }

        // set initial transfer allowances for airdrops, vests, bribes
        length = initialAllowances.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 amount = initialAllowances[i].amount;
            address receiver = initialAllowances[i].receiver;
            totalAllocated += amount;
            // initial allocations are given as approvals
            prismaToken.increaseAllowance(receiver, amount);
        }

        unallocatedTotal = uint128(totalSupply - totalAllocated);
        totalUpdateWeek = uint64(_fixedInitialAmounts.length + offset - 1);
        lockWeeks = initialLockWeeks;

        emit EmissionScheduleSet(address(_emissionSchedule));
        emit BoostCalculatorSet(address(_boostCalculator));
        emit UnallocatedSupplyReduced(totalAllocated, unallocatedTotal);
    }

    /**
        @notice Register a new emission receiver
        @dev Once this function is called, the receiver ID is immediately
             eligible for votes within `IncentiveVoting`
        @param receiver Address of the receiver
        @param count Number of IDs to assign to the receiver
     */
    function registerReceiver(address receiver, uint256 count) external onlyOwner returns (bool) {
        uint256[] memory assignedIds = new uint256[](count);
        uint16 week = uint16(getWeek());
        for (uint256 i = 0; i < count; i++) {
            uint256 id = voter.registerNewReceiver();
            assignedIds[i] = id;
            receiverUpdatedWeek[id] = week;
            idToReceiver[id] = Receiver({ account: receiver, isActive: true });
            emit NewReceiverRegistered(receiver, id);
        }
        // notify the receiver contract of the newly registered ID
        // also serves as a sanity check to ensure the contract is capable of receiving emissions
        IEmissionReceiver(receiver).notifyRegisteredId(assignedIds);

        return true;
    }

    /**
        @notice Modify the active status of an existing receiver
        @dev Emissions directed to an inactive receiver are instead returned to
             the unallocated supply. This way potential emissions are not lost
             due to old emissions votes pointing at a receiver that was phased out.
        @param id ID of the receiver to modify the isActive status for
        @param isActive is this receiver eligible to receive emissions?
     */
    function setReceiverIsActive(uint256 id, bool isActive) external onlyOwner returns (bool) {
        Receiver memory receiver = idToReceiver[id];
        require(receiver.account != address(0), "ID not set");
        receiver.isActive = isActive;
        idToReceiver[id] = receiver;
        emit ReceiverIsActiveStatusModified(id, isActive);

        return true;
    }

    /**
        @notice Set the `emissionSchedule` contract
        @dev Callable only by the owner (the DAO admin voter, to change the emission schedule).
             The new schedule is applied from the start of the next epoch.
     */
    function setEmissionSchedule(IEmissionSchedule _emissionSchedule) external onlyOwner returns (bool) {
        _allocateTotalWeekly(emissionSchedule, getWeek());
        emissionSchedule = _emissionSchedule;
        emit EmissionScheduleSet(address(_emissionSchedule));

        return true;
    }

    function setBoostCalculator(IBoostCalculator _boostCalculator) external onlyOwner returns (bool) {
        boostCalculator = _boostCalculator;
        emit BoostCalculatorSet(address(_boostCalculator));

        return true;
    }

    /**
        @notice Transfer tokens out of the vault
     */
    function transferTokens(IERC20 token, address receiver, uint256 amount) external onlyOwner returns (bool) {
        if (address(token) == address(prismaToken)) {
            require(receiver != address(this), "Self transfer denied");
            uint256 unallocated = unallocatedTotal - amount;
            unallocatedTotal = uint128(unallocated);
            emit UnallocatedSupplyReduced(amount, unallocated);
        }
        token.safeTransfer(receiver, amount);

        return true;
    }

    /**
        @notice Receive PRISMA tokens and add them to the unallocated supply
     */
    function increaseUnallocatedSupply(uint256 amount) external returns (bool) {
        prismaToken.transferFrom(msg.sender, address(this), amount);
        uint256 unallocated = unallocatedTotal + amount;
        unallocatedTotal = uint128(unallocated);
        emit UnallocatedSupplyIncreased(amount, unallocated);

        return true;
    }

    function _allocateTotalWeekly(IEmissionSchedule _emissionSchedule, uint256 currentWeek) internal {
        uint256 week = totalUpdateWeek;
        if (week >= currentWeek) return;

        if (address(_emissionSchedule) == address(0)) {
            totalUpdateWeek = uint64(currentWeek);
            return;
        }

        uint256 lock;
        uint256 weeklyAmount;
        uint256 unallocated = unallocatedTotal;
        while (week < currentWeek) {
            ++week;
            (weeklyAmount, lock) = _emissionSchedule.getTotalWeeklyEmissions(week, unallocated);
            weeklyEmissions[week] = uint128(weeklyAmount);

            unallocated = unallocated - weeklyAmount;
            emit UnallocatedSupplyReduced(weeklyAmount, unallocated);
        }

        unallocatedTotal = uint128(unallocated);
        totalUpdateWeek = uint64(currentWeek);
        lockWeeks = uint64(lock);
    }

    /**
        @notice Allocate additional `prismaToken` allowance to an emission reciever
                based on the emission schedule
        @param id Receiver ID. The caller must be the receiver mapped to this ID.
        @return uint256 Additional `prismaToken` allowance for the receiver. The receiver
                        accesses the tokens using `Vault.transferAllocatedTokens`
     */
    function allocateNewEmissions(uint256 id) external returns (uint256) {
        Receiver memory receiver = idToReceiver[id];
        require(receiver.account == msg.sender, "Receiver not registered");
        uint256 week = receiverUpdatedWeek[id];
        uint256 currentWeek = getWeek();
        if (week == currentWeek) return 0;

        IEmissionSchedule _emissionSchedule = emissionSchedule;
        _allocateTotalWeekly(_emissionSchedule, currentWeek);

        if (address(_emissionSchedule) == address(0)) {
            receiverUpdatedWeek[id] = uint16(currentWeek);
            return 0;
        }

        uint256 amount;
        while (week < currentWeek) {
            ++week;
            amount = amount + _emissionSchedule.getReceiverWeeklyEmissions(id, week, weeklyEmissions[week]);
        }

        receiverUpdatedWeek[id] = uint16(currentWeek);
        if (receiver.isActive) {
            allocated[msg.sender] = allocated[msg.sender] + amount;
            emit IncreasedAllocation(msg.sender, amount);
            return amount;
        } else {
            // if receiver is not active, return allocation to the unallocated supply
            uint256 unallocated = unallocatedTotal + amount;
            unallocatedTotal = uint128(unallocated);
            emit UnallocatedSupplyIncreased(amount, unallocated);
            return 0;
        }
    }

    /**
        @notice Transfer `prismaToken` tokens previously allocated to the caller
        @dev Callable only by registered receiver contracts which were previously
             allocated tokens using `allocateNewEmissions`.
        @param claimant Address that is claiming the tokens
        @param receiver Address to transfer tokens to
        @param amount Desired amount of tokens to transfer. This value always assumes max boost.
        @return bool success
     */
    function transferAllocatedTokens(address claimant, address receiver, uint256 amount) external returns (bool) {
        if (amount > 0) {
            allocated[msg.sender] -= amount;
            _transferAllocated(0, claimant, receiver, address(0), amount);
        }
        return true;
    }

    /**
        @notice Claim earned tokens from multiple reward contracts, optionally with delegated boost
        @param receiver Address to transfer tokens to. Any earned 3rd-party rewards
                        are also sent to this address.
        @param boostDelegate Address to delegate boost from during this claim. Set as
                             `address(0)` to use the boost of the claimer.
        @param rewardContracts Array of addresses of registered receiver contracts where
                               the caller has pending rewards to claim.
        @param maxFeePct Maximum fee percent to pay to delegate, as a whole number out of 10000
        @return bool success
     */
    function batchClaimRewards(
        address receiver,
        address boostDelegate,
        IRewards[] calldata rewardContracts,
        uint256 maxFeePct
    ) external returns (bool) {
        require(maxFeePct <= 10000, "Invalid maxFeePct");

        uint256 total;
        uint256 length = rewardContracts.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 amount = rewardContracts[i].vaultClaimReward(msg.sender, receiver);
            allocated[address(rewardContracts[i])] -= amount;
            total += amount;
        }
        _transferAllocated(maxFeePct, msg.sender, receiver, boostDelegate, total);
        return true;
    }

    /**
        @notice Claim tokens earned from boost delegation fees
        @param receiver Address to transfer the tokens to
        @return bool Success
     */
    function claimBoostDelegationFees(address receiver) external returns (bool) {
        uint256 amount = storedPendingReward[msg.sender];
        require(amount >= lockToTokenRatio, "Nothing to claim");
        _transferOrLock(msg.sender, receiver, amount);
        return true;
    }

    function _transferAllocated(
        uint256 maxFeePct,
        address account,
        address receiver,
        address boostDelegate,
        uint256 amount
    ) internal {
        if (amount > 0) {
            uint256 week = getWeek();
            uint256 totalWeekly = weeklyEmissions[week];
            address claimant = boostDelegate == address(0) ? account : boostDelegate;
            uint256 previousAmount = accountWeeklyEarned[claimant][week];

            // if boost delegation is active, get the fee and optional callback address
            uint256 fee;
            IBoostDelegate delegateCallback;
            if (boostDelegate != address(0)) {
                Delegation memory data = boostDelegation[boostDelegate];
                delegateCallback = data.callback;
                require(data.isEnabled, "Invalid delegate");
                if (data.feePct == type(uint16).max) {
                    fee = delegateCallback.getFeePct(account, receiver, amount, previousAmount, totalWeekly);
                    require(fee <= 10000, "Invalid delegate fee");
                } else fee = data.feePct;
                require(fee <= maxFeePct, "fee exceeds maxFeePct");
            }

            // calculate adjusted amount with actual boost applied
            uint256 adjustedAmount = boostCalculator.getBoostedAmountWrite(
                claimant,
                amount,
                previousAmount,
                totalWeekly
            );
            {
                // remaining tokens from unboosted claims are added to the unallocated total
                // context avoids stack-too-deep
                uint256 boostUnclaimed = amount - adjustedAmount;
                if (boostUnclaimed > 0) {
                    uint256 unallocated = unallocatedTotal + boostUnclaimed;
                    unallocatedTotal = uint128(unallocated);
                    emit UnallocatedSupplyIncreased(boostUnclaimed, unallocated);
                }
            }
            accountWeeklyEarned[claimant][week] = uint128(previousAmount + amount);

            // apply boost delegation fee
            if (fee != 0) {
                fee = (adjustedAmount * fee) / 10000;
                adjustedAmount -= fee;
            }

            // add `storedPendingReward` to `adjustedAmount`
            // this happens after any boost modifiers or delegation fees, since
            // these effects were already applied to the stored value
            adjustedAmount += storedPendingReward[account];

            _transferOrLock(account, receiver, adjustedAmount);

            // apply delegate fee and optionally perform callback
            if (fee != 0) storedPendingReward[boostDelegate] += fee;
            if (address(delegateCallback) != address(0)) {
                require(
                    delegateCallback.delegatedBoostCallback(
                        account,
                        receiver,
                        amount,
                        adjustedAmount,
                        fee,
                        previousAmount,
                        totalWeekly
                    ),
                    "Delegate callback rejected"
                );
            }
        }
    }

    function _transferOrLock(address claimant, address receiver, uint256 amount) internal {
        uint256 _lockWeeks = lockWeeks;
        if (_lockWeeks == 0) {
            storedPendingReward[claimant] = 0;
            prismaToken.transfer(receiver, amount);
        } else {
            // lock for receiver and store remaining balance in `storedPendingReward`
            uint256 lockAmount = amount / lockToTokenRatio;
            storedPendingReward[claimant] = amount - lockAmount * lockToTokenRatio;
            if (lockAmount > 0) locker.lock(receiver, lockAmount, _lockWeeks);
        }
    }

    /**
        @notice Claimable PRISMA amount for `account` in `rewardContract` after applying boost
        @dev Returns (0, 0) if the boost delegate is invalid, or the delgate's callback fee
             function is incorrectly configured.
        @param account Address claiming rewards
        @param boostDelegate Address to delegate boost from when claiming. Set as
                             `address(0)` to use the boost of the claimer.
        @param rewardContract Address of the contract where rewards are being claimed
        @return adjustedAmount Amount received after boost, prior to paying delegate fee
        @return feeToDelegate Fee amount paid to `boostDelegate`

     */
    function claimableRewardAfterBoost(
        address account,
        address receiver,
        address boostDelegate,
        IRewards rewardContract
    ) external view returns (uint256 adjustedAmount, uint256 feeToDelegate) {
        uint256 amount = rewardContract.claimableReward(account);
        uint256 week = getWeek();
        uint256 totalWeekly = weeklyEmissions[week];
        address claimant = boostDelegate == address(0) ? account : boostDelegate;
        uint256 previousAmount = accountWeeklyEarned[claimant][week];

        uint256 fee;
        if (boostDelegate != address(0)) {
            Delegation memory data = boostDelegation[boostDelegate];
            if (!data.isEnabled) return (0, 0);
            fee = data.feePct;
            if (fee == type(uint16).max) {
                try data.callback.getFeePct(claimant, receiver, amount, previousAmount, totalWeekly) returns (
                    uint256 _fee
                ) {
                    fee = _fee;
                } catch {
                    return (0, 0);
                }
            }
            if (fee > 10000) return (0, 0);
        }

        adjustedAmount = boostCalculator.getBoostedAmount(claimant, amount, previousAmount, totalWeekly);
        fee = (adjustedAmount * fee) / 10000;

        return (adjustedAmount, fee);
    }

    /**
        @notice Enable or disable boost delegation, and set boost delegation parameters
        @param isEnabled is boost delegation enabled?
        @param feePct Fee % charged when claims are made that delegate to the caller's boost.
                      Given as a whole number out of 10000. If set to type(uint16).max, the fee
                      is set by calling `IBoostDelegate(callback).getFeePct` prior to each claim.
        @param callback Optional contract address to receive a callback each time a claim is
                        made which delegates to the caller's boost.
     */
    function setBoostDelegationParams(bool isEnabled, uint256 feePct, address callback) external returns (bool) {
        if (isEnabled) {
            require(feePct <= 10000 || feePct == type(uint16).max, "Invalid feePct");
            if (callback != address(0) || feePct == type(uint16).max) {
                require(callback.isContract(), "Callback must be a contract");
            }
            boostDelegation[msg.sender] = Delegation({
                isEnabled: true,
                feePct: uint16(feePct),
                callback: IBoostDelegate(callback)
            });
        } else {
            delete boostDelegation[msg.sender];
        }
        emit BoostDelegationSet(msg.sender, isEnabled, feePct, callback);

        return true;
    }

    /**
        @notice Get the remaining claimable amounts this week that will receive boost
        @param claimant address to query boost amounts for
        @return maxBoosted remaining claimable amount that will receive max boost
        @return boosted remaining claimable amount that will receive some amount of boost (including max boost)
     */
    function getClaimableWithBoost(address claimant) external view returns (uint256 maxBoosted, uint256 boosted) {
        uint256 week = getWeek();
        uint256 totalWeekly = weeklyEmissions[week];
        uint256 previousAmount = accountWeeklyEarned[claimant][week];
        return boostCalculator.getClaimableWithBoost(claimant, previousAmount, totalWeekly);
    }

    /**
        @notice Get the claimable amount that `claimant` has earned boost delegation fees
     */
    function claimableBoostDelegationFees(address claimant) external view returns (uint256 amount) {
        amount = storedPendingReward[claimant];
        // only return values `>= lockToTokenRatio` so we do not report "dust" stored for normal users
        return amount >= lockToTokenRatio ? amount : 0;
    }
}