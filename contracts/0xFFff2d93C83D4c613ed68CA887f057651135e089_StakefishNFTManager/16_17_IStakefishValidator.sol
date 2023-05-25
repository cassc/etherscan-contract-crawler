// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @title The interface for StakefishValidator
/// @notice Defines implementation of the wallet (deposit, withdraw, collect fees)
interface IStakefishValidator {

    event StakefishValidatorDeposited(bytes validatorPubKey);
    event StakefishValidatorExitRequest(bytes validatorPubKey);
    event StakefishValidatorStarted(bytes validatorPubKey, uint256 startTimestamp);
    event StakefishValidatorExited(bytes validatorPubKey, uint256 stopTimestamp);
    event StakefishValidatorWithdrawn(bytes validatorPubKey, uint256 amount);
    event StakefishValidatorCommissionTransferred(bytes validatorPubKey, uint256 amount);
    event StakefishValidatorFeePoolChanged(bytes validatorPubKey, address feePoolAddress);

    enum State { PreDeposit, PostDeposit, Active, ExitRequested, Exited, Withdrawn, Burnable }

    /// @dev aligns into 32 byte
    struct StateChange {
        State state;            // 1 byte
        bytes15 userData;       // 15 byte (future use)
        uint128 changedAt;      // 16 byte
    }

    /// @notice initializer
    function setup() external;

    function validatorIndex() external view returns (uint256);
    function pubkey() external view returns (bytes memory);

    /// @notice Inspect state of the change
    function lastStateChange() external view returns (StateChange memory);

    /// @notice Submits a Phase 0 DepositData to the eth2 deposit contract.
    /// @dev https://github.com/ethereum/consensus-specs/blob/master/solidity_deposit_contract/deposit_contract.sol#L33
    /// @param validatorPubKey A BLS12-381 public key.
    /// @param depositSignature A BLS12-381 signature.
    /// @param depositDataRoot The SHA-256 hash of the SSZ-encoded DepositData object.
    function makeEth2Deposit(
        bytes calldata validatorPubKey, // 48 bytes
        bytes calldata depositSignature, // 96 bytes
        bytes32 depositDataRoot
    ) external;

    /// @notice Operator updates the start state of the validator
    /// Updates validator state to running
    /// State.PostDeposit -> State.Running
    function validatorStarted(
        uint256 _startTimestamp,
        uint256 _validatorIndex,
        address _feePoolAddress) external;

    /// @notice Operator updates the exited from beaconchain.
    /// State.ExitRequested -> State.Exited
    /// emit ValidatorExited(pubkey, stopTimestamp);
    function validatorExited(uint256 _stopTimestamp) external;

    /// @notice NFT Owner requests a validator exit
    /// State.Running -> State.ExitRequested
    /// emit ValidatorExitRequest(pubkey)
    function requestExit() external;

    /// @notice user withdraw balance and charge a fee
    function withdraw() external;

    /// @notice ability to change fee pool
    function validatorFeePoolChange(address _feePoolAddress) external;

    /// @notice get pending fee pool rewards
    function pendingFeePoolReward() external view returns (uint256, uint256);

    /// @notice claim fee pool and forward to nft owner
    function claimFeePool(uint256 amountRequested) external;

    /// @notice get early access discount
    function earlyAccessDiscount() external view returns (uint);

    /// @notice volume discount
    function volumeDiscount() external view returns (uint);

    /// @notice calculates effect fee after discounts
    function effectiveFee() external view returns (uint256);

    /// @notice computes commission, useful for showing on UI
    function computeCommission(uint256 amount) external view returns (uint256);

    function render() external view returns (string memory);
}