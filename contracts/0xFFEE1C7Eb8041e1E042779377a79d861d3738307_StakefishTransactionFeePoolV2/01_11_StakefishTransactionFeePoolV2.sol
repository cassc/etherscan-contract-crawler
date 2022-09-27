// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "Address.sol";
import "ReentrancyGuard.sol";
import "Initializable.sol";
import "UUPSUpgradeable.sol";

import "IStakefishTransactionFeePoolV2.sol";
import "StakefishTransactionStorageV2.sol";

contract StakefishTransactionFeePoolV2 is
    IStakefishTransactionFeePoolV2,
    StakefishTransactionStorageV2,
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuard
{
    using Address for address payable;

    // Upgradable contract.
    constructor() initializer {
    }

    function initialize(address operatorAddress_, address adminAddress_) initializer external {
        require(operatorAddress_ != address(0));
        require(adminAddress_ != address(0));
        adminAddress = adminAddress_;
        operatorAddress = operatorAddress_;
        validatorCount = 0;
        stakefishCommissionRateBasisPoints = 2000;
        isOpenForWithdrawal = true;
    }

    // IMPORTANT CODE! ONLY DEV ACCOUNT CAN UPGRADE CONTRACT
    function _authorizeUpgrade(address) internal override adminOnly {}

    // idempotent: can be called multiple times
    function updateComputationCache() internal {
        require(cache.lastCacheUpdateTime <= block.timestamp, "Time cannot flow backward");

        cache.totalValidatorUptime += (block.timestamp - cache.lastCacheUpdateTime) * validatorCount;
        cache.lastCacheUpdateTime = block.timestamp;
    }

    function decodeValidatorInfo(uint256 data) public pure returns (address, uint256) {
        address ownerAddress = address(uint160(data));
        uint256 joinPoolTimestamp = data >> 224;
        return (ownerAddress, joinPoolTimestamp);
    }

    function encodeValidatorInfo(address ownerAddress, uint256 joinPoolTimestamp) public pure returns (uint256) {
        return uint256(uint160(ownerAddress)) | (joinPoolTimestamp << 224);
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
            validatorOwnerAndJoinTime[validatorPubKey] == 0,
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
        users[depositor].totalStartTimestamps += uint128(joinTime);
        validatorOwnerAndJoinTime[validatorPubKey] = encodeValidatorInfo(depositor, joinTime);

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
        (address depositor, uint256 joinTime) = decodeValidatorInfo(validatorOwnerAndJoinTime[validatorPubKey]);
        require(
            depositor != address(0),
            "Validator not in pool"
        );


        require(leaveTime <= block.timestamp, "Invalid validator leaveTime");

        // Note that this computation is slightly inaccurate, as it over counts (block.timestamp - leaveTime)
        // for the parting validator. We adjust it after calling updateComputationCache().
        updateComputationCache();
        cache.totalValidatorUptime -= (block.timestamp - leaveTime);
        validatorCount -= 1;

        // Remove the given validator from the UserSummary by reducing validatorCount by 1.
        // However, we need to track the amount of removed uptime here, so we can add it back in computePayout.
        users[depositor].totalStartTimestamps -= uint128(joinTime);
        users[depositor].validatorCount -= 1;

        // If join events and leave events are processed in order, then leaveTime should always be greater than
        // the averageStartTimestamp in the pool.
        require(leaveTime >= joinTime, "leave pool time must be after join pool time");
        users[depositor].partedUptime += uint128(leaveTime - joinTime);
        delete validatorOwnerAndJoinTime[validatorPubKey];

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
        require(depositorAddresses.length == 1 || depositorAddresses.length * 48 == validatorPubkeyArray.length, "Invalid depositorAddresses length");
        uint256 bulkCount = validatorPubkeyArray.length / 48;

        if (depositorAddresses.length == 1) {
            bytes memory validatorPubkey;
            address depositor = depositorAddresses[0];
            require(depositor != address(0), "depositorAddress must be set");
            uint256 validatorInfo = encodeValidatorInfo(depositor, ts);
            for(uint256 i = 0; i < bulkCount; i++) {
                validatorPubkey = validatorPubkeyArray[i * 48 : (i + 1) * 48];
                require(validatorOwnerAndJoinTime[validatorPubkey] == 0, "Validator already in pool");
                validatorOwnerAndJoinTime[validatorPubkey] = validatorInfo;
            }
            // If we have a single depositor, we can further optimize gas usages by only reading and
            // storing the below only once outside of the for-loop.
            users[depositor].validatorCount += uint128(bulkCount);
            users[depositor].totalStartTimestamps += uint128(ts * bulkCount);
        } else {
            address depositor;
            bytes memory validatorPubkey;
            uint128 ts128 = uint128(ts);
            for(uint256 i = 0; i < bulkCount; i++) {
                depositor = depositorAddresses[i];
                require(depositor != address(0), "depositorAddress must be set");
                validatorPubkey = validatorPubkeyArray[i * 48 : (i + 1) * 48];
                require(validatorOwnerAndJoinTime[validatorPubkey] == 0, "Validator already in pool");

                users[depositor].validatorCount += 1;
                users[depositor].totalStartTimestamps += ts128;
                validatorOwnerAndJoinTime[validatorPubkey] = encodeValidatorInfo(depositor, ts);
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
        require(validatorPubkeyArray.length % 48 == 0, "Validator length not multiple of 48");
        address[] memory depositorAddresses = new address[](validatorPubkeyArray.length / 48);

        for(uint256 i = 0; i < depositorAddresses.length; i++) {
            // TODO: gas optimization opportunity: do not call updateComputationCache() for each validator.
            address depositorAddress = _partPool(validatorPubkeyArray[i*48:(i+1)*48], ts);
            depositorAddresses[i] = depositorAddress;
        }

        emit ValidatorBulkParted(validatorPubkeyArray, depositorAddresses, ts);
    }

    // @returns (pendingRewards, collectedRewards)
    function computePayout(address depositor) internal view returns (uint256, uint256) {
        if (cache.totalValidatorUptime == 0) {
            // no validators in pool yet
            return (0, users[depositor].collectedReward);
        }

        uint256 totalValidatorUptime = cache.totalValidatorUptime;
        if (block.timestamp > cache.lastCacheUpdateTime) {
            totalValidatorUptime += (block.timestamp - cache.lastCacheUpdateTime) * validatorCount;
        }

        uint256 totalContractValue = address(this).balance + lifetimeCollectedCommission + lifetimePaidUserRewards;
        uint256 totalUserValue = totalContractValue * (10000 - stakefishCommissionRateBasisPoints) / 10000;
        uint256 totalUserUptime =
            block.timestamp * users[depositor].validatorCount - users[depositor].totalStartTimestamps
            + users[depositor].partedUptime;
        uint256 totalPayout = totalUserValue * totalUserUptime / totalValidatorUptime;

        if (totalPayout > users[depositor].collectedReward) {
            return (totalPayout - users[depositor].collectedReward, users[depositor].collectedReward);
        } else {
            return (0, users[depositor].collectedReward);
        }
    }

    // This function estimates user pending reward based on the latest block timestamp.
    // In order to keep this function to be a view function, it does not update the computation cache.
    function pendingReward(address depositorAddress) external override view returns (uint256, uint256) {
        require(depositorAddress != address(0), "depositorAddress must be set");
        return computePayout(depositorAddress);
    }

    function _collectReward(
        address depositorAddress,
        address payable beneficiary,
        uint256 amountRequested
    ) internal {
        if (beneficiary == address(0)) {
            beneficiary = payable(depositorAddress);
        }

        (uint256 pending, ) = computePayout(depositorAddress);
        if (amountRequested == 0 || pending <= amountRequested) {
            users[depositorAddress].collectedReward += uint128(pending);
            lifetimePaidUserRewards += pending;
            emit ValidatorRewardCollected(depositorAddress, beneficiary, pending, msg.sender);
            beneficiary.sendValue(pending);
        } else {
            users[depositorAddress].collectedReward += uint128(amountRequested);
            lifetimePaidUserRewards += amountRequested;
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

    function _transferValidator(
        bytes calldata validatorPubKey,
        address to,
        uint256 transferTimestamp)
        internal
    {
        (address validatorOwner, uint256 joinTime) = decodeValidatorInfo(validatorOwnerAndJoinTime[validatorPubKey]);
        require(validatorOwner != address(0), "Validator not in pool");
        require(to != address(0), "to address must be set to nonzero");
        require(to != validatorOwner, "cannot transfer validator owner to oneself");
        require(transferTimestamp >= joinTime, "Validator transferTimestamp is before join pool time");
        require(transferTimestamp <= block.timestamp, "Validator transferTimestamp is in the future");

        _partPool(validatorPubKey, transferTimestamp);
        _joinPool(validatorPubKey, to, transferTimestamp);

        emit ValidatorTransferred(validatorPubKey, validatorOwner, to, transferTimestamp);
    }

    /*
    // This function is not enabled for now to keep the current product simple.

    function transferValidatorByOwner(bytes calldata validatorPubKey, address to) external override nonReentrant {
        (address validatorOwner, ) = decodeValidatorInfo(validatorOwnerAndJoinTime[validatorPubKey]);
        require(validatorOwner == msg.sender, "Only the validator owner can transfer the validator");
        _transferValidator(validatorPubKey, to, block.timestamp);
    }
    */

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
        uint256 totalContractValue = address(this).balance + lifetimeCollectedCommission + lifetimePaidUserRewards;
        uint256 totalCommission = totalContractValue * stakefishCommissionRateBasisPoints / 10000;
        uint256 pendingCommission = totalCommission - lifetimeCollectedCommission;
        if (amountRequested == 0 || pendingCommission <= amountRequested) {
            lifetimeCollectedCommission += pendingCommission;
            emit CommissionCollected(beneficiary, pendingCommission);
            beneficiary.sendValue(pendingCommission);
        } else {
            lifetimeCollectedCommission += amountRequested;
            emit CommissionCollected(beneficiary, amountRequested);
            beneficiary.sendValue(amountRequested);
        }
    }

    function transferValidatorByAdmin(
        bytes calldata validatorPubkeys,
        address[] calldata toAddresses,
        uint256 transferTimestamp
    ) external override nonReentrant adminOnly {
        require(validatorPubkeys.length == toAddresses.length * 48, "validatorPubkeys byte array length incorrect");
        for (uint256 i = 0; i < toAddresses.length; i++) {
            _transferValidator(
                validatorPubkeys[i * 48 : (i + 1) * 48],
                toAddresses[i],
                transferTimestamp
            );
        }
    }

    // Used to transfer claim history from another contract into this one.
    // @param addresses: array of user addresses
    // @param claimAmount: amount paid to the user outside of the contract
    // Warning: the balance from the previous contract must be transferred over as well.
    function transferClaimHistory(address[] calldata addresses, uint256[] calldata claimAmount)
        external
        override
        adminOnly
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            lifetimePaidUserRewards += claimAmount[i];
            users[addresses[i]].collectedReward += uint128(claimAmount[i]);
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

    function getPoolState() external override view returns (uint256, uint256, uint256, uint256, uint256) {
        return (
            cache.lastCacheUpdateTime,
            cache.totalValidatorUptime,
            validatorCount,
            lifetimeCollectedCommission,
            lifetimePaidUserRewards
        );
    }

    function getUserState(address user) external override view returns (uint256, uint256, uint256, uint256) {
        return (
            users[user].validatorCount,
            users[user].totalStartTimestamps,
            users[user].partedUptime,
            users[user].collectedReward
        );
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

    // Enable contract to receive value
    receive() external override payable {
        // Not emitting any events because this contract will receive many transactions.
        // Notes: depending on how transaction fees are implemented, this function may or may not
        // be called. When a contract is the destination of a coinbase transaction (i.e. miner block
        // reward) or a selfdestruct operation, this function is bypassed.
    }
}