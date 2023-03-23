pragma solidity ^0.8.10;

import { IDataStructures } from './IDataStructures.sol';

// SPDX-License-Identifier: BUSL-1.1

interface IAccountManager {
    /// @dev Get LifecycleStatus of a KNOT by public key
    /// @param _blsPublicKey - Public Key of the Validator
    function blsPublicKeyToLifecycleStatus(bytes calldata _blsPublicKey) external view returns (IDataStructures.LifecycleStatus);

    /// @dev Get Account by public key
    /// @param _blsPublicKey - Public key of the validator
    function getAccountByPublicKey(bytes calldata _blsPublicKey) external view returns (IDataStructures.Account memory);

    /// @notice Get all last known state about a KNOT
    /// @param _blsPublicKey Public key of the validator
    function getLastKnownStateByPublicKey(bytes calldata _blsPublicKey) external view returns (IDataStructures.ETH2DataReport memory);

    /// @dev Get the number of deposits registered on this contract
    function numberOfAccounts() external view returns (uint256);

    /// @dev Get the specific Account from the Account array
    /// @param _index - Index of the account to be fetched
    function getAccount(uint256 _index) external view returns(IDataStructures.Account memory);

    /// @dev Get the block Account happened
    /// @param _blsPublicKey - public key of the user
    function getDepositBlock(bytes calldata _blsPublicKey) external view returns (uint256);

    /// @notice Returns the last known active balance for a KNOT that came from a balance reporting adaptor
    /// @param _blsPublicKey - public key of the validator
    function getLastKnownActiveBalance(bytes calldata _blsPublicKey) external view returns (uint64);

    /// @notice Returns the last report epoch for a KNOT that came from a balance reporting adaptor
    /// @param _blsPublicKey - public key of the validator
    function getLastReportEpoch(bytes calldata _blsPublicKey) external view returns (uint64);

    /// @dev External function to check if the derivative tokens were claimed
    /// @param _blsPublicKey - BLS public key used for validation
    function claimedTokens(bytes calldata _blsPublicKey) external view returns (bool);

    /// @notice Obtain the original BLS signature generated for the 32 ETH deposit to the Ethereum Foundation deposit contract
    function getSignatureByBLSKey(bytes calldata _blsPublicKey) external view returns (bytes memory);

    /// @dev Function to check if the key is already deposited
    /// @param _blsPublicKey - BLS public key of the validator
    function isKeyDeposited(bytes calldata _blsPublicKey) external view returns (bool);

    /// @dev Check if validator initials have been registered
    /// @param _blsPublicKey - BLS public key of the validator
    function areInitialsRegistered(bytes calldata _blsPublicKey) external view returns (bool);
}