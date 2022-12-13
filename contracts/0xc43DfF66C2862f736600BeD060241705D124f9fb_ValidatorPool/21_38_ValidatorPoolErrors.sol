// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library ValidatorPoolErrors {
    error CallerNotValidator(address caller);
    error ConsensusRunning();
    error ETHDKGRoundRunning();
    error OnlyStakingContractsAllowed();
    error MaxIntervalWithoutSnapshotsMustBeNonZero();
    error MaxNumValidatorsIsTooLow(uint256 current, uint256 minMaxValidatorsAllowed);
    error MinimumBlockIntervalNotMet(uint256 currentBlockNumber, uint256 targetBlockNumber);
    error NotEnoughValidatorSlotsAvailable(uint256 requiredSlots, uint256 availableSlots);
    error RegistrationParameterLengthMismatch(
        uint256 validatorsLength,
        uint256 stakerTokenIDsLength
    );
    error SenderShouldOwnPosition(uint256 positionId);
    error LengthGreaterThanAvailableValidators(uint256 length, uint256 availableValidators);
    error ProfitsOnlyClaimableWhileConsensusRunning();
    error TokenBalanceChangedDuringOperation();
    error EthBalanceChangedDuringOperation();
    error SenderNotInExitingQueue(address sender);
    error WaitingPeriodNotMet();
    error AddressNotAccusable(address addr);
    error InvalidIndex(uint256 index);
    error AddressAlreadyValidator(address addr);
    error AddressNotValidator(address addr);
    error PayoutTooLow();
    error InsufficientFundsInStakePosition(uint256 stakeAmount, uint256 minimumRequiredAmount);
}