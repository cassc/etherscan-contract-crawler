// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.16;

// Interface for the Penalty contract
interface IPenalty {
    // Errors
    error ValidatorSettled();

    // Events
    event UpdatedAdditionalPenaltyAmount(bytes pubkey, uint256 amount);
    event UpdatedMEVTheftPenaltyPerStrike(uint256 mevTheftPenalty);
    event UpdatedPenaltyOracleAddress(address penaltyOracleAddress);
    event UpdatedMissedAttestationPenaltyPerStrike(uint256 missedAttestationPenalty);
    event UpdatedValidatorExitPenaltyThreshold(uint256 totalPenaltyThreshold);
    event ForceExitValidator(bytes pubkey);
    event UpdatedStaderConfig(address staderConfig);
    event ValidatorMarkedAsSettled(bytes pubkey);

    // returns the address of the Rated.network penalty oracle
    function ratedOracleAddress() external view returns (address);

    // returns the penalty amount for a single violation
    function mevTheftPenaltyPerStrike() external view returns (uint256);

    //returns the penalty amount for missing attestation below a certain threshold
    function missedAttestationPenaltyPerStrike() external view returns (uint256);

    // returns the totalPenalty threshold after which validator is force exited
    function validatorExitPenaltyThreshold() external view returns (uint256);

    // returns the additional penalty amount of a validator given its pubkey root
    function additionalPenaltyAmount(bytes32 _pubkeyRoot) external view returns (uint256);

    // returns the total penalty amount of a validator given its pubkey
    function totalPenaltyAmount(bytes calldata _pubkey) external view returns (uint256);

    // Setters

    // Sets the address of the Rated.network penalty oracle.
    function updateRatedOracleAddress(address _penaltyOracleAddress) external;

    function updateStaderConfig(address _staderConfig) external;

    // Sets the penalty amount for a single violation.
    //This is the amount that will be imposed for each violation after first violation
    function updateMEVTheftPenaltyPerStrike(uint256 _mevTheftPenaltyPerStrike) external;

    // sets the penalty amount for missing attestation below a threshold for a cycle
    function updateMissedAttestationPenaltyPerStrike(uint256 _missedAttestationPenaltyPerStrike) external;

    // update the value of totalPenaltyThreshold
    function updateValidatorExitPenaltyThreshold(uint256 _validatorExitPenaltyThreshold) external;

    /**
     * @notice Sets the additional penalty amount given by the DAO for a given validator public key.
     * @param _pubkey The validator public key for which to set the additional penalty amount.
     * @param _amount The additional penalty amount to set for the given validator public key.
     */
    function setAdditionalPenaltyAmount(bytes calldata _pubkey, uint256 _amount) external;

    // Getters

    // Returns the additional penalty amount given by the DAO for a given public key.
    function getAdditionalPenaltyAmount(bytes calldata _pubkey) external view returns (uint256);

    /**
     * @notice update the total penalty amount for a given public key and store in a map.
     * @param _pubkey The public key of the validator for which to calculate the penalty.
     */
    function updateTotalPenaltyAmount(bytes[] calldata _pubkey) external;

    /**
     * @notice Calculates the penalty for changing the fee recipient address for a given public key
     *         based on data from the Rated.network penalty oracle.
     * @param _pubkeyRoot The public key root for which to calculate the penalty.
     * @return The penalty for changing the fee recipient address.
     */
    function calculateMEVTheftPenalty(bytes32 _pubkeyRoot) external returns (uint256);

    /**
     * @notice calculate penalty for missing attestation below a certain threshold
     * @param _pubkeyRoot The public key root for which to calculate the penalty.
     * @return penalty for missing attestation
     */
    function calculateMissedAttestationPenalty(bytes32 _pubkeyRoot) external returns (uint256);

    /**
     * @notice make the totalPenalty amount as 0 and marked validator as settled
     * @param _poolId pool Id of the validator
     * @param _validatorId validator Id of a validator
     * @dev only validator withdraw vault can call
     */
    function markValidatorSettled(uint8 _poolId, uint256 _validatorId) external;
}