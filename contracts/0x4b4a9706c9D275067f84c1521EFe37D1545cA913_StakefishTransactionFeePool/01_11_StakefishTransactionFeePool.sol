// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "Address.sol";
import "ReentrancyGuard.sol";
import "Initializable.sol";
import "UUPSUpgradeable.sol";

import "IStakefishTransactionFeePool.sol";
import "StakefishTransactionStorage.sol";

contract StakefishTransactionFeePool is
    IStakefishTransactionFeePool,
    StakefishTransactionStorage,
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuard
{
    using Address for address payable;

    // Upgradable contract.
    constructor() initializer {
    }

    function initialize(address operatorAddress_, address adminAddress_, address devAddress_) initializer external {
        require(operatorAddress_ != address(0));
        require(adminAddress_ != address(0));
        require(devAddress_ != address(0));
        adminAddress = adminAddress_;
        operatorAddress = operatorAddress_;
        developerAddress = devAddress_;
        validatorCount = 0;
        stakefishCommissionRateBasisPoints = 2000;
        isOpenForWithdrawal = true;
    }

    // IMPORTANT CODE! ONLY DEV ACCOUNT CAN UPGRADE CONTRACT
    function _authorizeUpgrade(address) internal override devOnly {}

    // idempotent: can be called multiple times
    function updateComputationCache() internal {
        require(cache.lastCacheUpdateTime <= block.timestamp, "Time cannot flow backward");

        // compute the most up-to-date stakefish commission and post-commission balance for delegators.
        uint256 balanceDiffSinceLastUpdate = address(this).balance
            - cache.totalUncollectedCommission
            - cache.totalUncollectedUserBalance
            - cache.totalUnsentUserRewards;
        uint256 commission = balanceDiffSinceLastUpdate * stakefishCommissionRateBasisPoints / 10000;
        cache.totalUncollectedCommission += commission;
        cache.totalUncollectedUserBalance += balanceDiffSinceLastUpdate - commission;

        // compute the most up-to-date total uptime in the pool
        cache.totalValidatorUptime += (block.timestamp - cache.lastCacheUpdateTime) * validatorCount;
        cache.lastCacheUpdateTime = block.timestamp;
    }

    /**
     * Operator Functions
     */
    function joinPool(
        bytes calldata validatorPubKey,
        address depositor,
        uint256 joinTime
    ) external override nonReentrant operatorOnly {
        _joinPool(validatorPubKey, depositor, joinTime);
        // Emit events so our Oracle can keep track of a list of validators in the pool.
        emit ValidatorJoined(validatorPubKey, depositor, joinTime);
    }

    function _joinPool(
        bytes calldata validatorPubKey,
        address depositor,
        uint256 joinTime
    ) internal {
        require(
            validatorsInPool[validatorPubKey] == address(0),
            "Validator already in pool"
        );
        require(
            depositor != address(0),
            "depositorAddress must be set"
        );

        uint256 curTime = block.timestamp;
        require(joinTime <= curTime, "Invalid validator joinTime");

        // Add the given validator to the UserSummary.
        users[depositor].validatorCount += 1;
        users[depositor].totalStartTimestamps += joinTime;
        validatorsInPool[validatorPubKey] = depositor;

        updateComputationCache();
        // Add uptime for this validator.
        cache.totalValidatorUptime += curTime - joinTime;
        validatorCount += 1;
    }

    function partPool(
        bytes calldata validatorPubKey,
        uint256 leaveTime
    ) external override nonReentrant operatorOnly {
        address depositor = _partPool(validatorPubKey, leaveTime);
        emit ValidatorParted(validatorPubKey, depositor, leaveTime);
    }

    function _partPool(
        bytes calldata validatorPubKey,
        uint256 leaveTime
    ) internal returns (address depositorAddress) {
        address depositor = validatorsInPool[validatorPubKey];
        require(
            depositor != address(0),
            "Validator not in pool"
        );

        uint256 curTime = block.timestamp;
        require(leaveTime <= curTime, "Invalid validator leaveTime");

        updateComputationCache();

        // Remove the given validator from the UserSummary.
        validatorCount -= 1;
        uint256 averageStartTime = users[depositor].totalStartTimestamps / users[depositor].validatorCount;
        users[depositor].totalStartTimestamps -= averageStartTime;
        users[depositor].validatorCount -= 1;
        delete validatorsInPool[validatorPubKey];

        // Payout ethers corresponding to payoutUptime
        uint256 payoutUptime = curTime - averageStartTime;
        uint256 payoutAmount = computePayout(payoutUptime);
        cache.totalValidatorUptime -= payoutUptime;
        cache.totalUncollectedUserBalance -= payoutAmount;
        cache.totalUnsentUserRewards += payoutAmount;
        users[depositor].pendingReward += payoutAmount;

        return depositor;
    }

    // Bulk add all given validators into the pool.
    // @param validatorPubKeys: the list of validator public keys to add; must be a multiple of 48.
    // @param depositor: the depositor addresses; must have length equal to validatorPubKeys.length/48 or 1;
    //                   if length is 1, then the same depositor address is used for all validators.
    function bulkJoinPool(
        bytes calldata validatorPubkeyArray,
        address[] calldata depositorAddresses,
        uint256 ts
    ) external override nonReentrant operatorOnly {
        require(ts <= block.timestamp, "Invalid validator join timestamp");
        uint256 bulkCount = validatorPubkeyArray.length / 48;
        require(depositorAddresses.length == 1 || depositorAddresses.length == bulkCount, "Invalid depositorAddresses length");

        if (depositorAddresses.length == 1) {
            bytes memory validatorPubkey;
            address depositor = depositorAddresses[0];
            require(depositor != address(0), "depositorAddress must be set");
            for(uint256 i = 0; i < bulkCount; i++) {
                validatorPubkey = validatorPubkeyArray[i * 48 : (i + 1) * 48];
                require(
                    validatorsInPool[validatorPubkey] == address(0),
                    "Validator already in pool"
                );
                validatorsInPool[validatorPubkey] = depositor;
            }
            // If we have a single depositor, we can further optimize gas usages by only reading and
            // storing the below only once outside of the for-loop.
            users[depositor].validatorCount += bulkCount;
            users[depositor].totalStartTimestamps += ts * bulkCount;
        } else {
            address depositor;
            bytes memory validatorPubkey;
            for(uint256 i = 0; i < bulkCount; i++) {
                depositor = depositorAddresses[i];
                require(depositor != address(0), "depositorAddress must be set");
                validatorPubkey = validatorPubkeyArray[i * 48 : (i + 1) * 48];
                require(
                    validatorsInPool[validatorPubkey] == address(0),
                    "Validator already in pool"
                );

                users[depositor].validatorCount += 1;
                users[depositor].totalStartTimestamps += ts;
                validatorsInPool[validatorPubkey] = depositor;
            }
        }

        updateComputationCache();
        cache.totalValidatorUptime += (block.timestamp - ts) * bulkCount;
        validatorCount += bulkCount;
        emit ValidatorBulkJoined(validatorPubkeyArray, depositorAddresses, ts);
    }

    function bulkPartPool(
        bytes calldata validatorPubkeyArray,
        uint256 ts
    ) external override nonReentrant operatorOnly {
        address[] memory depositorAddresses = new address[](validatorPubkeyArray.length / 48);

        for(uint256 i = 0; i < depositorAddresses.length; i++) {
            // TODO: gas optimization opportunity: do not call updateComputationCache() for each validator.
            address depositorAddress = _partPool(validatorPubkeyArray[i*48:(i+1)*48], ts);
            depositorAddresses[i] = depositorAddress;
        }

        emit ValidatorBulkParted(validatorPubkeyArray, depositorAddresses, ts);
    }

    // This function assumes that cached is up-to-date.
    // To get accurate payout computations, call updateComputationCache() first.
    function computePayout(uint256 payoutUptime) internal view returns (uint256) {
        return cache.totalUncollectedUserBalance * payoutUptime / cache.totalValidatorUptime;
    }

    // This function estimates user pending reward based on the latest block timestamp.
    // In order to keep this function to be a view function, it does not update the computation cache.
    function pendingReward(address depositorAddress) external override view returns (uint256, uint256) {
        require(depositorAddress != address(0), "depositorAddress must be set");

        if (users[depositorAddress].validatorCount > 0) {
            uint256 balanceDiffSinceLastUpdate = address(this).balance
                - cache.totalUncollectedCommission
                - cache.totalUncollectedUserBalance
                - cache.totalUnsentUserRewards;
            uint256 commission = balanceDiffSinceLastUpdate * stakefishCommissionRateBasisPoints / 10000;
            uint256 uncollectedUserBalance = cache.totalUncollectedUserBalance + balanceDiffSinceLastUpdate - commission;

            uint256 totalValidatorUptime =
                cache.totalValidatorUptime + (block.timestamp - cache.lastCacheUpdateTime) * validatorCount;

            uint256 payoutAmount = 0;
            // This check is to avoid division by 0 when the pool is totally empty.
            if (totalValidatorUptime > 0) {
                uint256 payoutUptime =
                    block.timestamp * users[depositorAddress].validatorCount - users[depositorAddress].totalStartTimestamps;
                payoutAmount = uncollectedUserBalance * payoutUptime / totalValidatorUptime;
            }
            return (
                payoutAmount + users[depositorAddress].pendingReward,
                users[depositorAddress].collectedReward
            );
        } else {
            return (users[depositorAddress].pendingReward, users[depositorAddress].collectedReward);
        }
    }

    function _collectReward(
        address depositorAddress,
        address payable beneficiary,
        uint256 amountRequested
    ) internal {
        if (beneficiary == address(0)) {
            beneficiary = payable(depositorAddress);
        }

        uint256 userValidatorCount = users[depositorAddress].validatorCount;
        if (userValidatorCount > 0) {
            uint256 payoutUptime =
                block.timestamp * userValidatorCount - users[depositorAddress].totalStartTimestamps;
            uint256 payoutAmount = computePayout(payoutUptime);

            cache.totalValidatorUptime -= payoutUptime;
            cache.totalUncollectedUserBalance -= payoutAmount;
            cache.totalUnsentUserRewards += payoutAmount;
            users[depositorAddress].totalStartTimestamps = block.timestamp * userValidatorCount;
            users[depositorAddress].pendingReward += payoutAmount;
        }

        if (amountRequested == 0 || users[depositorAddress].pendingReward <= amountRequested) {
            uint256 amount = users[depositorAddress].pendingReward;
            cache.totalUnsentUserRewards -= amount;
            users[depositorAddress].collectedReward += amount;
            users[depositorAddress].pendingReward -= amount;
            emit ValidatorRewardCollected(depositorAddress, beneficiary, amount, msg.sender);
            beneficiary.sendValue(amount);
        } else {
            cache.totalUnsentUserRewards -= amountRequested;
            users[depositorAddress].collectedReward += amountRequested;
            users[depositorAddress].pendingReward -= amountRequested;
            emit ValidatorRewardCollected(depositorAddress, beneficiary, amountRequested, msg.sender);
            beneficiary.sendValue(amountRequested);
        }
    }

    // collect rewards from the tip pool, up to amountRequested.
    // If amountRequested is unspecified, collect all rewards.
    function collectReward(address payable beneficiary, uint256 amountRequested) external override nonReentrant {
        require(isOpenForWithdrawal, "Pool is not open for withdrawal right now");
        updateComputationCache();
        _collectReward(msg.sender, beneficiary, amountRequested);
    }

    /**
     * Admin Functions
     */
    function setCommissionRate(uint256 commissionRate) external override nonReentrant adminOnly {
        stakefishCommissionRateBasisPoints = commissionRate;
        emit CommissionRateChanged(stakefishCommissionRateBasisPoints);
    }

    // Collect accumulated commission fees, up to amountRequested.
    // If amountRequested is unspecified, collect all fees.
    function collectPoolCommission(address payable beneficiary, uint256 amountRequested)
        external
        override
        nonReentrant
        adminOnly
    {
        updateComputationCache();

        if (amountRequested == 0 || cache.totalUncollectedCommission < amountRequested) {
          uint256 payout = cache.totalUncollectedCommission;
          cache.totalUncollectedCommission = 0;
          beneficiary.sendValue(payout);
        } else {
          cache.totalUncollectedCommission -= amountRequested;
          beneficiary.sendValue(amountRequested);
        }
    }

    // Used by admins to handle emergency situations where we want to temporarily pause all withdrawals.
    function closePoolForWithdrawal() external override nonReentrant adminOnly {
        require(isOpenForWithdrawal, "Pool is already closed for withdrawal");
        isOpenForWithdrawal = false;
    }

    function openPoolForWithdrawal() external override nonReentrant adminOnly {
        require(!isOpenForWithdrawal, "Pool is already open for withdrawal");
        isOpenForWithdrawal = true;
    }

    function changeOperator(address newOperator) external override nonReentrant adminOnly {
        require(newOperator != address(0));
        operatorAddress = newOperator;
        emit OperatorChanged(operatorAddress);
    }

    function emergencyWithdraw (
        address[] calldata depositorAddresses,
        address[] calldata beneficiaries,
        uint256 maxAmount
    )
        external
        override
        nonReentrant
        adminOnly
    {
        require(beneficiaries.length == depositorAddresses.length || beneficiaries.length == 1, "beneficiaries length incorrect");
        updateComputationCache();
        if (beneficiaries.length == 1) {
            for (uint256 i = 0; i < depositorAddresses.length; i++) {
                _collectReward(depositorAddresses[i], payable(beneficiaries[0]), maxAmount);
            }
        } else {
            for (uint256 i = 0; i < depositorAddresses.length; i++) {
                _collectReward(depositorAddresses[i], payable(beneficiaries[i]), maxAmount);
            }
        }
    }

    // general public

    function totalValidators() external override view returns (uint256) {
        return validatorCount;
    }

    function getPoolState() external override view returns (ComputationCache memory) {
        return cache;
    }

    /**
     * Modifiers
     */
    modifier operatorOnly() {
        require(
            msg.sender == operatorAddress,
            "Only stakefish operator allowed"
        );
        _;
    }

    modifier adminOnly() {
        require(
            msg.sender == adminAddress,
            "Only stakefish admin allowed"
        );
        _;
    }

    modifier devOnly() {
        require(
            msg.sender == developerAddress,
            "Only stakefish dev allowed"
        );
        _;
    }

    // Enable contract to receive value
    receive() external override payable {
        // Not emitting any events because this contract will receive many transactions.
        // Notes: depending on how transaction fees are implemented, this function may or may not
        // be called. When a contract is the destination of a coinbase transaction (i.e. miner block
        // reward) or a selfdestruct operation, this function is bypassed.
    }
}