// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/**
 * @title IOption interface
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @dev Interface for managing options contracts
 */
interface IOption {
    /**
     * @notice Get the expiry time of the option
     * @dev Returns the expiry time of the option in seconds since the Unix epoch
     * @return The expiry time of the option
     */
    function getExpiryTime() external view returns (uint256);

    /**
     * @notice Initialize the option contract with the specified parameters
     * @dev Initializes the option contract with the specified strike price, exercise timestamp, and option type
     * @param _strikePrice The strike price of the option
     * @param _exerciseTimestamp The exercise timestamp of the option
     * @param _type The type of the option (i.e., call or put)
     */
    function initialize(uint256 _strikePrice, uint256 _exerciseTimestamp, uint8 _type) external;

    /**
     * @notice Set up the option contract with the specified parameters
     * @dev Sets up the option contract with the specified option ID, start block, uHODL and bHODL token addresses, fund address, and Bullet and Sniper token addresses
     * @param _optionID The ID of the option contract
     * @param _startBlock The start block of the option contract
     * @param _uHODLAddress The address of the uHODL token contract
     * @param _bHODLTokenAddress The address of the bHODL token contract
     * @param _fund The address of the fund contract
     * @param _bullet The address of the BULLET token contract
     * @param _sniper The address of the SNIPER token contract
     */
    function setup(
        uint256 _optionID,
        uint256 _startBlock,
        address _uHODLAddress,
        address _bHODLTokenAddress,
        address _fund,
        address _bullet,
        address _sniper
    ) external;

    /**
     * @notice Update the strike price of the option
     * @dev Updates the strike price of the option to the specified value
     * @param _strikePrice The new strike price of the option
     */
    function updateStrike(uint256 _strikePrice) external;

    /**
     * @notice Set all fee and reward ratios for the option contract
     * @dev Sets all fee and reward ratios for the option contract to the specified values
     * @param _entryFeeRatio The entry fee ratio to set in basis points
     * @param _exerciseFeeRatio The exercise fee ratio to set in basis points
     * @param _withdrawFeeRatio The withdraw fee ratio to set in basis points
     * @param _redeemFeeRatio The redeem fee ratio to set in basis points
     * @param _bulletToRewardRatio The BULLET-to-reward ratio to in base 100
     */
    function setAllRatio(
        uint16 _entryFeeRatio,
        uint16 _exerciseFeeRatio,
        uint16 _withdrawFeeRatio,
        uint16 _redeemFeeRatio,
        uint16 _bulletToRewardRatio
    ) external;

    /**
     * @notice Set the entry fee ratio for the option contract
     * @dev Sets the entry fee ratio for the option contract to the specified value
     * @param _feeRatio The entry fee ratio to set
     */
    function setOptionEntryFeeRatio(uint16 _feeRatio) external;

    /**
     * @notice Set the exercise fee ratio for the option contract
     * @dev Sets the exercise fee ratio for the option contract to the specified value
     * @param _feeRatio The exercise fee ratio to set
     */
    function setOptionExerciseFeeRatio(uint16 _feeRatio) external;

    /**
     * @notice Set the withdraw fee ratio for the option contract
     * @dev Sets the withdraw fee ratio for the option contract to the specified value
     * @param _feeRatio The withdraw fee ratio to set
     */
    function setOptionWithdrawFeeRatio(uint16 _feeRatio) external;

    /**
     * @notice Set the redeem fee ratio for the option contract
     * @dev Sets the redeem fee ratio for the option contract to the specified value
     * @param _feeRatio The redeem fee ratio to set
     */
    function setOptionRedeemFeeRatio(uint16 _feeRatio) external;

    /**
     * @notice Set the BULLET-to-reward ratio for the option contract
     * @dev Sets the BULLET-to-reward ratio for the option contract to the specified value
     * @param _feeRatio The BULLET-to-reward ratio to set
     */
    function setOptionBulletToRewardRatio(uint16 _feeRatio) external;

    /**
     * @notice Set the fund address for the option contract
     * @dev Sets the fund address for the option contract to the specified value
     * @param _fund The fund address to set
     */
    function setFund(address _fund) external;

    /**
     * @notice Exits the option by unstaking and redeeming all rewards.
     * @dev This function unstakes the user's tokens, redeems their SNIPER tokens, and withdraws their rewards.
     */
    function exitAll() external;

    /**
     * @notice Enters an options contract by depositing a certain amount of tokens.
     * @dev This function is used to enter an options contract. The sender should have approved the transfer.
     *      The amount of tokens is transferred to this contract, the entry fee is calculated, distributed,
     *      and subtracted from the amount. The remaining amount is used to mint BULLET and SNIPER tokens,
     *      which are passed to the fund and the staking pool, respectively.
     * @param _amount The amount of tokens to enter.
     */
    function enter(uint256 _amount) external;

    /**
     * @notice Exercises the option by burning option tokens and receiving base tokens.
     * @dev This function burns a specific amount of BULLET tokens and calculates the amount of base tokens
     *      to transfer depending on the option type (call or put). It also calculates and applies the exercise fee.
     * @param _targetAmount The amount of option tokens to exercise.
     */
    function exercise(uint256 _targetAmount) external;

    /**
     * @notice Unwinds a specific amount of options.
     * @dev This funciton burns the user's SNIPER and BULLET for the option to withdraw collateral.
     * @param _unwindAmount The amount of options to unwind.
     */
    function unwind(uint256 _unwindAmount) external;
}