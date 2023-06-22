// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "Address.sol";
import "ReentrancyGuard.sol";
import "Initializable.sol";
import "UUPSUpgradeable.sol";

import "IStakefishTransactionFeePoolV3.sol";
import "IStakefishNFTManager.sol";
import "StakefishTransactionStorageV3.sol";
import "StakefishTransactionStorageV3Additional.sol";

contract StakefishTransactionFeePoolV3 is
    IStakefishTransactionFeePoolV3,
    StakefishTransactionStorageV3,
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuard,
    StakefishTransactionStorageV3Additional
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

        // V3 storage variables
        accRewardPerValidator = 0;
        accLifetimeStakefishCommission = 0;
        amountTransferredToColdWallet = 0;
        nftManagerAddress = address(0x0);
        lastRewardUpdateBlock = block.number;
        lastLifetimeReward = getLifetimeReward();
    }

    function initialize_version3() initializer external {
        amountTransferredToColdWallet = 0;
    }

    // If the pool starts from scratch, accLifetimeStakefishCommission correctly starts from 0.
    // However, the fee pool is upgraded from a simpler commission accounting logic, and we need
    // to initialize accLifetimeStakefishCommission to the correct value.
    // This function is idempotent and can be call many times without issues.
    // TODO(yz): clean up this code after use.
    function initializeAccLifetimeStakefishComission() external adminOnly {
        // We updated commission from 20% to 25% in this transaction:j
        // https://etherscan.io/tx/0x879c4eb3975d58e258626df9a50eaf51d92fb60feb6e82643a263dc1f5348001
        // This is the getLifetimeReward as of block 17020824
        uint256 preChangeLifetimeReward = 2960947228478966516822;

        updatePool();
        uint256 curLifetimeReward = getLifetimeReward();

        accLifetimeStakefishCommission =
            1e6 * // scale up by 1e6 to avoid precision loss due to divisions.
            (
                preChangeLifetimeReward * 2000 / 10000 +
                (curLifetimeReward - preChangeLifetimeReward) * stakefishCommissionRateBasisPoints / 10000
            );
    }

    // IMPORTANT CODE! ONLY DEV ACCOUNT CAN UPGRADE CONTRACT
    function _authorizeUpgrade(address) internal override adminOnly {}

    // Used to upgrade in place from V2 to V3.
    function migrateFromV2(address[] calldata userlist) external nonReentrant operatorOnly {
        // This check serves two purposes:
        // 1. It ensures that contract state does not change during migration.
        // 2. It requires the admin to close pool before this can be called, even though this function is operatorOnly.
        require(isOpenForWithdrawal == false, "Pool must be closed for withdrawal");
        // Note that UserSummary is repurposed from V2 and the fields:
        // - validatorCount and collectedReward contain values we want to keep from V2.
        // - lifetimeCredit and debit have junk values after upgrade.
        // We must re-write the lifetimeCredit and debit fields for every users during the v2->v3 upgrade.

        // To simplify calculations, we assume that all validators joined at the same time upon Ethereum merge.
        for (uint256 i = 0; i < userlist.length; i++) {
            // user.lifetimeCredit contains user.totalStartTimestamps from V2. Need to erase it.
            // user.debit contains user.partedUptime from V2. Need to erase it.
            users[userlist[i]].lifetimeCredit = 0;
            users[userlist[i]].debit = 0;

            // If we call accruePayout, it would eagerly update the user's lifetimeCredit and debit fields.
            // However, this is unnecessary because validator count did not change for any user.
            // accruePayout(userlist[i]);
        }
        updatePool();
    }

    function decodeValidatorInfo(uint256 data) public pure returns (address, uint256) {
        address ownerAddress = address(uint160(data));
        uint256 joinPoolTimestamp = data >> 224;
        return (ownerAddress, joinPoolTimestamp);
    }

    function encodeValidatorInfo(address ownerAddress, uint256 joinPoolTimestamp) public pure returns (uint256) {
        return uint256(uint160(ownerAddress)) | (joinPoolTimestamp << 224);
    }

    // Total rewards that have been sent into this contract since contract creation.
    function getLifetimeReward() public view returns (uint256) {
        return address(this).balance
            + amountTransferredToColdWallet // this amount is saved to cold wallet
            + lifetimePaidUserRewards // this amount is paid to users
            + lifetimeCollectedCommission; // this amount is paid to stakefish
    }

    // Reference: pancake swap updatePool function
    // https://github.com/pancakeswap/pancake-smart-contracts/blob/master/projects/farms-pools/contracts/MasterChef.sol#L209
    // This concludes a time period and updates accRewardPerValidator.
    function updatePool() internal {
        if (block.number <= lastRewardUpdateBlock || validatorCount == 0) {
            return;
        }
        uint256 curLifetimeReward = getLifetimeReward();

        accRewardPerValidator +=
            1e6 * // scale up by 1e6 to avoid precision loss due to divisions.
            (curLifetimeReward - lastLifetimeReward) / validatorCount // add in the new reward from last period
            * (10000 - stakefishCommissionRateBasisPoints) / 10000; // adjust for stakefish commission

        accLifetimeStakefishCommission +=
            1e6 * // scale up by 1e6 to avoid precision loss due to divisions.
            (curLifetimeReward - lastLifetimeReward) // add in the new reward from last period
            * stakefishCommissionRateBasisPoints / 10000; // multiply by stakefish commission rate

        lastRewardUpdateBlock = block.number;
        lastLifetimeReward = curLifetimeReward;
    }

    function getAccRewardPerValidator() public view returns (uint256) {
        return accRewardPerValidator / 1e6; // scale down by 1e6, which was multiplied to avoid precision loss.
    }

    // Used by stakefish to check how much commission they have earned.
    // Read-only function without having to call updatePool().
    function getAccLifetimeStakefishCommission() public view returns (uint256) {
        uint256 curLifetimeReward = getLifetimeReward();
        // we cannot call update pool in a view function, so we add in new commission from the last period manually.
        return (
            accLifetimeStakefishCommission
            + 1e6 * (curLifetimeReward - lastLifetimeReward) * stakefishCommissionRateBasisPoints / 10000
        ) / 1e6;
    }

    // Simulate a payout by adding pending payout to user lifetimeCredits
    function accruePayout(address depositor) internal {
        uint256 userValidatorCount = users[depositor].validatorCount;
        if (userValidatorCount > 0) {
            uint256 pending = userValidatorCount * getAccRewardPerValidator() - users[depositor].debit;
            users[depositor].lifetimeCredit += uint128(pending); // simulate a payout
        }
    }

    // Reference: pancake swap deposit function
    // https://github.com/pancakeswap/pancake-smart-contracts/blob/master/projects/farms-pools/contracts/MasterChef.sol#L228
    /**
     * Operator Functions
     */
    function joinPool(
        bytes calldata validatorPubKey,
        address depositor
    ) external nonReentrant operatorOnly {
        // One validator joined, the previous time period ends.
        updatePool();
        _joinPool(validatorPubKey, depositor);
        emit ValidatorJoined(validatorPubKey, depositor, block.timestamp);
    }

    // This function implementation references:
    // https://github.com/pancakeswap/pancake-smart-contracts/blob/master/projects/farms-pools/contracts/MasterChef.sol#L228
    function _joinPool(
        bytes calldata validatorPubKey,
        address depositor
    ) internal {
        require(
            validatorOwnerAndJoinTime[validatorPubKey] == 0,
            "Validator already in pool"
        );
        require(
            depositor != address(0),
            "depositorAddress must be set"
        );

        // If the user already has some validators in the pool, we simulate a payout for existing validators.
        accruePayout(depositor);

        // Add the given validator to the UserSummary.
        users[depositor].validatorCount += 1;
        validatorCount += 1;
        validatorOwnerAndJoinTime[validatorPubKey] = encodeValidatorInfo(depositor, block.timestamp);
        users[depositor].debit = uint128(users[depositor].validatorCount * getAccRewardPerValidator());
    }

    function partPool(
        bytes calldata validatorPubKey
    ) external nonReentrant operatorOnly {
        // One validator left, the previous time period ends.
        updatePool();
        address depositor = _partPool(validatorPubKey);
        emit ValidatorParted(validatorPubKey, depositor, block.timestamp);
    }

    function _partPool(
        bytes calldata validatorPubKey
    ) internal returns (address depositorAddress) {
        (address depositor, ) = decodeValidatorInfo(validatorOwnerAndJoinTime[validatorPubKey]);
        require(
            depositor != address(0),
            "Validator not in pool"
        );

        // Simulate a payout for the existing validators.
        accruePayout(depositor);

        validatorCount -= 1;
        users[depositor].validatorCount -= 1;
        delete validatorOwnerAndJoinTime[validatorPubKey];
        users[depositor].debit = uint128(users[depositor].validatorCount * getAccRewardPerValidator());

        return depositor;
    }

    // These two functions are added for V2 compatibility--they allow the oracle to call joinPool and partPool with the V2 abi.
    // These two functions are not in the interface and are only used by the oracle for backward compatibility purposes.
    function joinPool(bytes calldata validatorPubKey, address depositor, uint256)
        external override nonReentrant operatorOnly
    {
        updatePool();
        _joinPool(validatorPubKey, depositor);
        emit ValidatorJoined(validatorPubKey, depositor, block.timestamp);
    }
    function partPool(bytes calldata validatorPubKey, uint256) external override nonReentrant operatorOnly {
        updatePool();
        address depositor = _partPool(validatorPubKey);
        emit ValidatorParted(validatorPubKey, depositor, block.timestamp);
    }

    function bulkJoinPool(
        bytes calldata validatorPubkeyArray,
        address[] calldata depositorAddresses,
        uint256
    ) external override nonReentrant operatorOnly {
        require(depositorAddresses.length == 1 || depositorAddresses.length * 48 == validatorPubkeyArray.length, "Invalid depositorAddresses length");

        updatePool();
        uint256 validatorCount = validatorPubkeyArray.length / 48;
        if (depositorAddresses.length == 1) {
            for(uint256 i = 0; i < validatorCount; i++) {
                _joinPool(validatorPubkeyArray[i*48:(i+1)*48], depositorAddresses[0]);
                emit ValidatorJoined(validatorPubkeyArray[i*48:(i+1)*48], depositorAddresses[0], block.timestamp);
            }
        } else {
            for(uint256 i = 0; i < validatorCount; i++) {
                _joinPool(validatorPubkeyArray[i*48:(i+1)*48], depositorAddresses[i]);
                emit ValidatorJoined(validatorPubkeyArray[i*48:(i+1)*48], depositorAddresses[i], block.timestamp);
            }
        }
    }

    function bulkPartPool(
        bytes calldata validatorPubkeyArray,
        uint256
    ) external override nonReentrant operatorOnly {
        require(validatorPubkeyArray.length % 48 == 0, "pubKeyArray length not multiple of 48");

        updatePool();
        uint256 validatorCount = validatorPubkeyArray.length / 48;
        for(uint256 i = 0; i < validatorCount; i++) {
            address depositor = _partPool(validatorPubkeyArray[i*48:(i+1)*48]);
            emit ValidatorParted(validatorPubkeyArray[i*48:(i+1)*48], depositor, block.timestamp);
        }
    }

    // @return (pendingRewards, collectedRewards)
    function computePayout(address depositor) internal view returns (uint256, uint256) {
        // this is a view function so we cannot call updatePool() or accruePayout().
        uint256 accRewardPerValidatorWithCurPeriod = getAccRewardPerValidator();
        if (block.number > lastRewardUpdateBlock && validatorCount > 0) {
            // If the accRewardPerValidator is not up-to-date, we need to include rewards from the current time period.
            uint256 curLifetimeReward = getLifetimeReward();
            accRewardPerValidatorWithCurPeriod +=
                (curLifetimeReward - lastLifetimeReward) / validatorCount * (10000 - stakefishCommissionRateBasisPoints) / 10000;
        }

        uint256 totalPayout = users[depositor].validatorCount * accRewardPerValidatorWithCurPeriod
            + users[depositor].lifetimeCredit - users[depositor].debit;

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

    // Reference: Pancake swap withdraw function
    // https://github.com/pancakeswap/pancake-smart-contracts/blob/master/projects/farms-pools/contracts/MasterChef.sol#L249
    function _collectReward(
        address depositorAddress,
        address payable beneficiary,
        uint256 amountRequested
    ) internal {
        if (beneficiary == address(0)) {
            beneficiary = payable(depositorAddress);
        }

        accruePayout(depositorAddress);
        users[depositorAddress].debit = uint128(users[depositorAddress].validatorCount * getAccRewardPerValidator());

        uint256 pending = users[depositorAddress].lifetimeCredit - users[depositorAddress].collectedReward;
        if (amountRequested == 0) {
            users[depositorAddress].collectedReward += uint128(pending);
            lifetimePaidUserRewards += pending;
            emit ValidatorRewardCollected(depositorAddress, beneficiary, pending, msg.sender);
            require(pending <= address(this).balance, "Contact [email protected] to top up the contract");
            beneficiary.sendValue(pending);
        } else {
            require(amountRequested <= pending, "Not enough pending rewards");
            users[depositorAddress].collectedReward += uint128(amountRequested);
            lifetimePaidUserRewards += amountRequested;
            emit ValidatorRewardCollected(depositorAddress, beneficiary, amountRequested, msg.sender);
            require(amountRequested <= address(this).balance, "Contact [email protected] to top up the contract");
            beneficiary.sendValue(amountRequested);
        }
    }

    // collect rewards from the tip pool, up to amountRequested.
    // If amountRequested is unspecified, collect all rewards.
    function collectReward(address payable beneficiary, uint256 amountRequested) external override nonReentrant {
        require(isOpenForWithdrawal, "Pool is not open for withdrawal right now");
        updatePool();
        _collectReward(msg.sender, beneficiary, amountRequested);
    }

    function collectRewardForNFT(
        address payable beneficiary,
        address nftWallet,
        uint256 amountRequested)
    external override nonReentrant {
        IStakefishNFTManager nftManager = IStakefishNFTManager(nftManagerAddress);
        require(msg.sender == nftManager.validatorOwner(nftWallet), "Only validator NFT owner can collect reward");
        if (beneficiary == address(0)) {
            beneficiary = payable(msg.sender);
        }
        updatePool();
        _collectReward(nftWallet, beneficiary, amountRequested);
    }

    function batchCollectReward(
        address payable beneficiary,
        address[] calldata wallet,
        uint256[] calldata amountRequested)
    external override nonReentrant {
        require(wallet.length == amountRequested.length, "wallet and amountRequested must have the same length");
        if (beneficiary == address(0)) {
            beneficiary = payable(msg.sender);
        }
        IStakefishNFTManager nftManager = IStakefishNFTManager(nftManagerAddress);
        updatePool();
        for (uint256 i = 0; i < wallet.length; i++) {
            if(msg.sender == wallet[i] || msg.sender == nftManager.validatorOwner(wallet[i])) {
                _collectReward(wallet[i], beneficiary, amountRequested[i]);
            } else {
                revert("Only validator or NFT owner can collect reward");
            }
        }
    }

    function _transferValidator(bytes calldata validatorPubKey, address to) internal {
        (address validatorOwner, ) = decodeValidatorInfo(validatorOwnerAndJoinTime[validatorPubKey]);
        require(validatorOwner != address(0), "Validator not in pool");
        require(to != address(0), "to address must be set to nonzero");
        require(to != validatorOwner, "cannot transfer validator owner to oneself");

        _partPool(validatorPubKey);
        _joinPool(validatorPubKey, to);

        emit ValidatorTransferred(validatorPubKey, validatorOwner, to, block.timestamp);
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
        updatePool();
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
        updatePool();
        uint256 totalCommission = accLifetimeStakefishCommission / 1e6;
        uint256 pendingCommission = totalCommission - lifetimeCollectedCommission;
        if (amountRequested == 0) {
            lifetimeCollectedCommission += pendingCommission;
            emit CommissionCollected(beneficiary, pendingCommission);
            beneficiary.sendValue(pendingCommission);
        } else {
            require(amountRequested <= pendingCommission, "Not enough pending commission");
            lifetimeCollectedCommission += amountRequested;
            emit CommissionCollected(beneficiary, amountRequested);
            beneficiary.sendValue(amountRequested);
        }
    }

    function transferValidatorByAdmin(
        bytes calldata validatorPubkeys,
        address[] calldata toAddresses
    ) external override nonReentrant adminOnly {
        require(validatorPubkeys.length == toAddresses.length * 48, "validatorPubkeys byte array length incorrect");
        for (uint256 i = 0; i < toAddresses.length; i++) {
            _transferValidator(
                validatorPubkeys[i * 48 : (i + 1) * 48],
                toAddresses[i]
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

    function setNFTManager(address nftManager) external override nonReentrant adminOnly {
        require(nftManager != address(0), "NFT manager address must be set to nonzero");
        nftManagerAddress = nftManager;
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
        updatePool();
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

    function saveToColdWallet(address wallet, uint256 amount) external nonReentrant override adminOnly {
        require(amount <= address(this).balance, "Not enough balance");
        amountTransferredToColdWallet += amount;
        payable(wallet).sendValue(amount);
    }

    function loadFromColdWallet() external payable nonReentrant override adminOnly {
        require(msg.value <= amountTransferredToColdWallet, "Too much transferred from cold wallet");
        amountTransferredToColdWallet -= msg.value;
    }

    function totalValidators() external override view returns (uint256) {
        return validatorCount;
    }

    function getPoolState() external override view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool) {
        return (
            lastRewardUpdateBlock,
            getAccRewardPerValidator(),
            validatorCount,
            lifetimeCollectedCommission,
            lifetimePaidUserRewards,
            amountTransferredToColdWallet,
            isOpenForWithdrawal
        );
    }

    function getUserState(address user) external override view returns (uint256, uint256, uint256, uint256) {
        return (
            users[user].validatorCount,
            users[user].lifetimeCredit,
            users[user].debit,
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

    // This contract should not receive value directly.
    // All value should be sent to the proxy contract.
    // receive() external override payable { }
}