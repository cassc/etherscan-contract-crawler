// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IDistributions.sol";

/**
 * @title Distributions
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @notice This contract manages different types of fees and their distributions. It is responsible for
 *         defining fee ratios and their allocations. It is upgradeable and only the contract owner has
 *         the permission to change these values. The types of fees include Entry, Exercise, Withdraw,
 *         Redeem, and HODL Withdraw fees. It also manages the ratio of Bullet to Reward and the
 *         distributions of these fees and bullet rewards.
 * @dev This contact uses the concept of "ratio" for managing fee ratios and uses an array of Distribution structs for allocating these fees. The
 *      Distribution struct has two properties: percentage and recipient's address. The contract emits
 *      various events when fee ratios or distributions are changed.
 */
contract Distributions is OwnableUpgradeable {
    /**
     * @notice The ratio of the entry fee for a DeOrder.
     * @dev Represents the percentage of the fee taken when a new DeOrder is created. Values are in basis points, so a value of 100 means 1%.
     */
    uint16 public entryFeeRatio;

    /**
     * @notice The ratio of the exercise fee.
     * @dev Represents the percentage of the fee taken when a DeOrder is exercised. Values are in basis points, so a value of 100 means 1%.
     */
    uint16 public exerciseFeeRatio;

    /**
     * @notice The ratio of the withdrawal fee when collecting from a DeOrder.
     * @dev Represents the percentage of the fee taken when funds are withdrawn from a DeOrder. Values are in basis points, so a value of 100 means 1%.
     */
    uint16 public withdrawFeeRatio;

    /**
     * @notice The ratio of the redeem fee.
     * @dev Represents the percentage of the fee taken when a DeOrder is redeemed. Values are in basis points, so a value of 100 means 1%.
     */
    uint16 public redeemFeeRatio;

    /**
     * @notice The ratio of bullet to reward.
     * @dev This is used to calculate rewards from bullets. For example, a value of 80 means for every 1 bullet, 0.8 rewards are given.
     */
    uint8 public bulletToRewardRatio;

    /**
     * @notice The ratio of HODL withdrawal fee.
     * @dev Represents the percentage of the fee taken when funds are withdrawn from a HODL. Values are in basis points, so a value of 100 means 1%.
     */
    uint16 public hodlWithdrawFeeRatio;

    /**
     * @notice Represents a fee distribution.
     * @dev A struct representing a fee distribution, containing the percentage of the fee and the address to which it should be distributed.
     */
    struct Distribution {
        uint8 percentage;
        address to;
    }

    /**
     * @notice An array representing the fee distribution.
     * @dev An array of Distribution structs representing how the fee is distributed among multiple addresses.
     */
    Distribution[] public feeDistribution;

    /**
     * @notice An array representing the bullet distribution.
     * @dev An array of Distribution structs representing how the bullet rewards are distributed among multiple addresses.
     */
    Distribution[] public bulletDistribution;

    /**
     * @notice An array representing the HODL withdrawal fee distribution.
     * @dev An array of Distribution structs representing how the HODL withdrawal fee is distributed among multiple addresses.
     */
    Distribution[] public hodlWithdrawFeeDistribution;

    /**
     * @notice The length of the fee distribution array.
     * @dev The current length (i.e., the number of recipients) of the fee distribution array.
     */
    uint256 public feeDistributionLength;

    /**
     * @notice The length of the bullet distribution array.
     * @dev The current length (i.e., the number of recipients) of the bullet distribution array.
     */
    uint256 public bulletDistributionLength;

    /**
     * @notice The length of the HODL withdrawal fee distribution array.
     * @dev The current length (i.e., the number of recipients) of the HODL withdrawal fee distribution array.
     */
    uint256 public hodlWithdrawFeeDistributionLength;

    /**
     * @notice Emitted when the entry fee ratio is updated.
     * @dev This event triggers when the existing entry fee ratio changes to a new value.
     * @param oldEntryFeeRatio The old entry fee ratio.
     * @param newEntryFeeRatio The new entry fee ratio.
     */
    event EntryFeeRatioChanged(uint16 oldEntryFeeRatio, uint16 newEntryFeeRatio);

    /**
     * @notice Emitted when the exercise fee ratio is updated.
     * @dev This event triggers when the existing exercise fee ratio changes to a new value.
     * @param oldExerciseFeeRatio The old exercise fee ratio.
     * @param newExerciseFeeRatio The new exercise fee ratio.
     */
    event ExerciseFeeRatioChanged(uint16 oldExerciseFeeRatio, uint16 newExerciseFeeRatio);

    /**
     * @notice Emitted when the withdraw fee ratio is updated.
     * @dev This event triggers when the existing withdraw fee ratio changes to a new value.
     * @param oldWithdrawFeeRatio The old withdraw fee ratio.
     * @param newWithdrawFeeRatio The new withdraw fee ratio.
     */
    event WithdrawFeeRatioChanged(uint16 oldWithdrawFeeRatio, uint16 newWithdrawFeeRatio);

    /**
     * @notice Emitted when the redeem fee ratio is updated.
     * @dev This event triggers when the existing redeem fee ratio changes to a new value.
     * @param oldRedeemFeeRatio The old redeem fee ratio.
     * @param newRedeemFeeRatio The new redeem fee ratio.
     */
    event RedeemFeeRatioChanged(uint16 oldRedeemFeeRatio, uint16 newRedeemFeeRatio);

    /**
     * @notice Emitted when the HODL withdraw fee ratio is updated.
     * @dev This event triggers when the existing HODL withdraw fee ratio changes to a new value.
     * @param oldHodlWithdrawFeeRatio The old HODL withdraw fee ratio.
     * @param newHodlWithdrawFeeRatio The new HODL withdraw fee ratio.
     */
    event HodlWithdrawFeeRatioChanged(uint16 oldHodlWithdrawFeeRatio, uint16 newHodlWithdrawFeeRatio);

    /**
     * @notice Emitted when the bullet-to-reward ratio is updated.
     * @dev This event triggers when the existing bullet-to-reward ratio changes to a new value.
     * @param oldBulletToRewardRatio The old bullet-to-reward ratio.
     * @param newBulletToRewardRatio The new bullet-to-reward ratio.
     */
    event BulletToRewardRatioChanged(uint8 oldBulletToRewardRatio, uint8 newBulletToRewardRatio);

    /**
     * @notice Emitted when the fee distribution is updated.
     * @dev This event triggers when the fee distribution list is changed. It includes the updated percentages and recipient addresses.
     * @param percentage The array of fee distribution percentages.
     * @param to The array of fee distribution recipients.
     */
    event FeeDistributionSet(uint8[] percentage, address[] to);

    /**
     * @notice Emitted when the bullet distribution is updated.
     * @dev This event triggers when the bullet distribution list is changed. It includes the updated percentages and recipient addresses.
     * @param percentage The array of bullet distribution percentages.
     * @param to The array of bullet distribution recipients.
     */
    event BulletDistributionSet(uint8[] percentage, address[] to);

    /**
     * @notice Emitted when the HODL withdraw fee distribution is updated.
     * @dev This event triggers when the HODL withdraw fee distribution list is changed. It includes the updated percentages and recipient addresses.
     * @param percentage The array of HODL withdraw fee distribution percentages.
     * @param to The array of HODL withdraw fee distribution recipients.
     */
    event HodlWithdrawFeeDistributionSet(uint8[] percentage, address[] to);

    /**
     * @notice Initializes the Distributions contract.
     * @dev Invokes the initialization function of the parent contract and sets the bulletToRewardRatio to 80.
     */
    function __Distributions_init() public initializer {
        __Ownable_init();
        bulletToRewardRatio = 80;
        exerciseFeeRatio = 20;
        withdrawFeeRatio = 20;
        hodlWithdrawFeeRatio = 20;
        redeemFeeRatio = 20;
        entryFeeRatio = 20;
    }

    /**
     * @notice Only the contract owner can call this function.
     * @dev Sets the exercise fee ratio.
     * @param _feeRatio The new exercise fee ratio.
     */
    function setExerciseFee(uint16 _feeRatio) external onlyOwner {
        require(0 <= _feeRatio && _feeRatio < 10000, "Distributions: Illegal value range");

        uint16 oldFeeRatio = exerciseFeeRatio;
        exerciseFeeRatio = _feeRatio;
        emit ExerciseFeeRatioChanged(oldFeeRatio, exerciseFeeRatio);
    }

    /**
     * @notice Only the contract owner can call this function.
     * @dev Sets the withdraw fee ratio.
     * @param _feeRatio The new withdraw fee ratio.
     */
    function setWithdrawFee(uint16 _feeRatio) external onlyOwner {
        require(0 <= _feeRatio && _feeRatio < 10000, "Distributions: Illegal value range");

        uint16 oldFeeRatio = withdrawFeeRatio;
        withdrawFeeRatio = _feeRatio;
        emit WithdrawFeeRatioChanged(oldFeeRatio, withdrawFeeRatio);
    }

    /**
     * @notice Only the contract owner can call this function.
     * @dev Sets the redeem fee ratio.
     * @param _feeRatio The new redeem fee ratio.
     */
    function setRedeemFee(uint16 _feeRatio) external onlyOwner {
        require(0 <= _feeRatio && _feeRatio < 10000, "Distributions: Illegal value range");

        uint16 oldFeeRatio = redeemFeeRatio;
        redeemFeeRatio = _feeRatio;
        emit RedeemFeeRatioChanged(oldFeeRatio, redeemFeeRatio);
    }

    /**
     * @notice Only the contract owner can call this function.
     * @dev Sets the HODL withdraw fee ratio.
     * @param _feeRatio The new HODL withdraw fee ratio.
     */
    function setHodlWithdrawFee(uint16 _feeRatio) external onlyOwner {
        require(0 <= _feeRatio && _feeRatio < 10000, "Distributions: Illegal value range");

        uint16 oldFeeRatio = hodlWithdrawFeeRatio;
        hodlWithdrawFeeRatio = _feeRatio;
        emit HodlWithdrawFeeRatioChanged(oldFeeRatio, hodlWithdrawFeeRatio);
    }

    /**
     * @notice Only the contract owner can call this function.
     * @dev Sets the bullet-to-reward ratio.
     * @param _bulletToRewardRatio The new bullet-to-reward ratio.
     */
    function setBulletToRewardRatio(uint8 _bulletToRewardRatio) external onlyOwner {
        require(0 <= _bulletToRewardRatio && _bulletToRewardRatio <= 80, "Distributions: Illegal value range");

        uint8 oldBulletToRewardRatio = bulletToRewardRatio;
        bulletToRewardRatio = _bulletToRewardRatio;
        emit BulletToRewardRatioChanged(oldBulletToRewardRatio, bulletToRewardRatio);
    }

    /**
     * @notice Only the contract owner can call this function.
     * @dev Sets the entry fee ratio.
     * @param _feeRatio The new entry fee ratio.
     */
    function setEntryFee(uint16 _feeRatio) external onlyOwner {
        require(0 <= _feeRatio && _feeRatio < 10000, "Distributions: Illegal value range");

        uint16 oldFeeRatio = entryFeeRatio;
        entryFeeRatio = _feeRatio;
        emit EntryFeeRatioChanged(oldFeeRatio, entryFeeRatio);
    }

    /**
     * @notice Only the contract owner can call this function.
     * @dev Sets the fee distribution percentages and recipients.
     * @param _percentage The array of fee distribution percentages.
     * @param _to The array of fee distribution recipients.
     */
    function setFeeDistribution(uint8[] memory _percentage, address[] memory _to) external onlyOwner {
        require(_percentage.length == _to.length, "Distributions: Array length does not match");
        uint8 sum;
        for (uint8 i = 0; i < _percentage.length; i++) {
            sum += _percentage[i];
        }
        require(sum == 100, "Distributions: Sum of percentages is not 100");
        delete feeDistribution;
        for (uint8 j = 0; j < _percentage.length; j++) {
            uint8 percentage = _percentage[j];
            address to = _to[j];
            Distribution memory distribution = Distribution({percentage: percentage, to: to});
            feeDistribution.push(distribution);
        }
        feeDistributionLength = _percentage.length;
        emit FeeDistributionSet(_percentage, _to);
    }

    /**
     * @notice Only the contract owner can call this function.
     * @dev Sets the bullet distribution percentages and recipients.
     * @param _percentage The array of bullet distribution percentages.
     * @param _to The array of bullet distribution recipients.
     */
    function setBulletDistribution(uint8[] memory _percentage, address[] memory _to) external onlyOwner {
        require(_percentage.length == _to.length, "Distributions: Array length does not match");
        uint8 sum;
        for (uint8 i = 0; i < _percentage.length; i++) {
            sum += _percentage[i];
        }
        require(sum == 100, "Distributions: Sum of percentages is not 100");
        delete bulletDistribution;
        for (uint8 j = 0; j < _percentage.length; j++) {
            uint8 percentage = _percentage[j];
            address to = _to[j];
            Distribution memory distribution = Distribution({percentage: percentage, to: to});
            bulletDistribution.push(distribution);
        }
        bulletDistributionLength = _percentage.length;
        emit BulletDistributionSet(_percentage, _to);
    }

    /**
     * @notice Only the contract owner can call this function.
     * @dev Sets the HODL withdraw fee distribution percentages and recipients.
     * @param _percentage The array of HODL withdraw fee distribution percentages.
     * @param _to The array of HODL withdraw fee distribution recipients.
     */
    function setHodlWithdrawFeeDistribution(uint8[] memory _percentage, address[] memory _to) external onlyOwner {
        require(_percentage.length == _to.length, "Distributions: Array length does not match");
        uint8 sum;
        for (uint8 i = 0; i < _percentage.length; i++) {
            sum += _percentage[i];
        }
        require(sum == 100, "Distributions: Sum of percentages is not 100");
        delete hodlWithdrawFeeDistribution;
        for (uint8 j = 0; j < _percentage.length; j++) {
            uint8 percentage = _percentage[j];
            address to = _to[j];
            Distribution memory distribution = Distribution({percentage: percentage, to: to});
            hodlWithdrawFeeDistribution.push(distribution);
        }
        hodlWithdrawFeeDistributionLength = _percentage.length;
        emit HodlWithdrawFeeDistributionSet(_percentage, _to);
    }

    /**
     * @notice Get the current entry fee ratio.
     * @dev Provides access to the value of the `entryFeeRatio` state variable.
     * @return The entry fee ratio.
     */
    function readEntryFeeRatio() public view returns (uint16) {
        return entryFeeRatio;
    }

    /**
     * @notice Get the current exercise fee ratio.
     * @dev Provides access to the value of the `exerciseFeeRatio` state variable.
     * @return The exercise fee ratio.
     */
    function readExerciseFeeRatio() public view returns (uint16) {
        return exerciseFeeRatio;
    }

    /**
     * @notice Get the current withdrawal fee ratio.
     * @dev Provides access to the value of the `withdrawFeeRatio` state variable.
     * @return The withdraw fee ratio.
     */
    function readWithdrawFeeRatio() public view returns (uint16) {
        return withdrawFeeRatio;
    }

    /**
     * @notice Get the current redeem fee ratio.
     * @dev Provides access to the value of the `redeemFeeRatio` state variable.
     * @return The redeem fee ratio.
     */
    function readRedeemFeeRatio() public view returns (uint16) {
        return redeemFeeRatio;
    }

    /**
     * @notice Get the current bullet-to-reward ratio.
     * @dev Provides access to the value of the `bulletToRewardRatio` state variable.
     * @return The bullet-to-reward ratio.
     */
    function readBulletToRewardRatio() public view returns (uint16) {
        return bulletToRewardRatio;
    }

    /**
     * @notice Get the current length of the fee distribution array.
     * @dev Provides access to the value of the `feeDistributionLength` state variable.
     * @return The length of the fee distribution array.
     */
    function readFeeDistributionLength() public view returns (uint256) {
        return feeDistributionLength;
    }

    /**
     * @notice Get the fee distribution at the given index.
     * @dev Provides access to the `feeDistribution` array at a given index `i`.
     * @param i The index of the fee distribution.
     * @return percentage The percentage of the fee distribution.
     * @return to The recipient of the fee distribution.
     */
    function readFeeDistribution(uint256 i) public view returns (uint8 percentage, address to) {
        percentage = feeDistribution[i].percentage;
        to = feeDistribution[i].to;
    }

    /**
     * @notice Get the current length of the bullet distribution array.
     * @dev Provides access to the value of the `bulletDistributionLength` state variable.
     * @return The length of the bullet distribution array.
     */
    function readBulletDistributionLength() public view returns (uint256) {
        return bulletDistributionLength;
    }

    /**
     * @notice Get the bullet distribution at the given index.
     * @dev Provides access to the `bulletDistribution` array at a given index `i`.
     * @param i The index of the bullet distribution.
     * @return percentage The percentage of the bullet distribution.
     * @return to The recipient of the bullet distribution.
     */
    function readBulletDistribution(uint256 i) public view returns (uint8 percentage, address to) {
        percentage = bulletDistribution[i].percentage;
        to = bulletDistribution[i].to;
    }
}