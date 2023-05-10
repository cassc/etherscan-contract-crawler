// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/utils/DeterministicAddress.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/interfaces/IERC20Transferable.sol";
import "contracts/interfaces/IETHDKG.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableSnapshots.sol";
import "contracts/utils/auth/ImmutableETHDKG.sol";
import "contracts/utils/auth/ImmutablePublicStaking.sol";
import "contracts/utils/auth/ImmutableValidatorStaking.sol";
import "contracts/utils/auth/ImmutableALCA.sol";

abstract contract ValidatorPoolStorage is
    ImmutableFactory,
    ImmutableSnapshots,
    ImmutableETHDKG,
    ImmutablePublicStaking,
    ImmutableValidatorStaking,
    ImmutableALCA
{
    // POSITION_LOCK_PERIOD describes the maximum interval a PublicStaking Position may be locked after
    // being given back to validator exiting the pool
    uint256 public constant POSITION_LOCK_PERIOD = 172800;
    // Interval in AliceNet Epochs that a validator exiting the pool should before claiming is
    // PublicStaking position
    uint256 public constant CLAIM_PERIOD = 3;

    // Maximum number the ethereum blocks allowed without a validator committing a snapshot
    uint256 internal _maxIntervalWithoutSnapshots;

    // Minimum amount to stake
    uint256 internal _stakeAmount;
    // Max number of validators allowed in the pool
    uint256 internal _maxNumValidators;
    // Value in WEIs to be discounted of dishonest validator in case of slashing event. This value
    // is usually sent back to the disputer
    uint256 internal _disputerReward;

    // Boolean flag to be read by the snapshot contract in order to decide if the validator set
    // needs to be changed or not (i.e if a validator is going to be removed or added).
    bool internal _isMaintenanceScheduled;
    // Boolean flag to keep track if the consensus is running in the side chain or not. Validators
    // can only join or leave the pool in case this value is false.
    bool internal _isConsensusRunning;

    // The internal iterable mapping that tracks all ACTIVE validators in the Pool
    ValidatorDataMap internal _validators;

    // Mapping that keeps track of the validators leaving the Pool. Validators assets are hold by
    // `CLAIM_PERIOD` epochs before the user being able to claim the assets back in the form a new
    // PublicStaking position.
    mapping(address => ExitingValidatorData) internal _exitingValidatorsData;

    // Mapping to keep track of the active validators IPs.
    mapping(address => string) internal _ipLocations;

    constructor()
        ImmutableFactory(msg.sender)
        ImmutableSnapshots()
        ImmutableETHDKG()
        ImmutablePublicStaking()
        ImmutableValidatorStaking()
        ImmutableALCA()
    {}
}