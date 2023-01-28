//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../state/operatorsRegistry/Operators.sol";

/// @title Operators Registry Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the list of operators and their keys
interface IOperatorsRegistryV1 {
    /// @notice A new operator has been added to the registry
    /// @param index The operator index
    /// @param name The operator display name
    /// @param operatorAddress The operator address
    event AddedOperator(uint256 indexed index, string name, address indexed operatorAddress);

    /// @notice The operator status has been changed
    /// @param index The operator index
    /// @param active True if the operator is active
    event SetOperatorStatus(uint256 indexed index, bool active);

    /// @notice The operator limit has been changed
    /// @param index The operator index
    /// @param newLimit The new operator staking limit
    event SetOperatorLimit(uint256 indexed index, uint256 newLimit);

    /// @notice The operator stopped validator count has been changed
    /// @param index The operator index
    /// @param newStoppedValidatorCount The new stopped validator count
    event SetOperatorStoppedValidatorCount(uint256 indexed index, uint256 newStoppedValidatorCount);

    /// @notice The operator address has been changed
    /// @param index The operator index
    /// @param newOperatorAddress The new operator address
    event SetOperatorAddress(uint256 indexed index, address indexed newOperatorAddress);

    /// @notice The operator display name has been changed
    /// @param index The operator index
    /// @param newName The new display name
    event SetOperatorName(uint256 indexed index, string newName);

    /// @notice The operator or the admin added new validator keys and signatures
    /// @dev The public keys and signatures are concatenated
    /// @dev A public key is 48 bytes long
    /// @dev A signature is 96 bytes long
    /// @dev [P1, S1, P2, S2, ..., PN, SN] where N is the bytes length divided by (96 + 48)
    /// @param index The operator index
    /// @param publicKeysAndSignatures The concatenated public keys and signatures
    event AddedValidatorKeys(uint256 indexed index, bytes publicKeysAndSignatures);

    /// @notice The operator or the admin removed a public key and its signature from the registry
    /// @param index The operator index
    /// @param publicKey The BLS public key that has been removed
    event RemovedValidatorKey(uint256 indexed index, bytes publicKey);

    /// @notice The stored river address has been changed
    /// @param river The new river address
    event SetRiver(address indexed river);

    /// @notice The operator edited its keys after the snapshot block
    /// @dev This means that we cannot assume that its key set is checked by the snapshot
    /// @dev This happens only if the limit was meant to be increased
    /// @param index The operator index
    /// @param currentLimit The current operator limit
    /// @param newLimit The new operator limit that was attempted to be set
    /// @param latestKeysEditBlockNumber The last block number at which the operator changed its keys
    /// @param snapshotBlock The block number of the snapshot
    event OperatorEditsAfterSnapshot(
        uint256 indexed index,
        uint256 currentLimit,
        uint256 newLimit,
        uint256 indexed latestKeysEditBlockNumber,
        uint256 indexed snapshotBlock
    );

    /// @notice The call didn't alter the limit of the operator
    /// @param index The operator index
    /// @param limit The limit of the operator
    event OperatorLimitUnchanged(uint256 indexed index, uint256 limit);

    /// @notice The calling operator is inactive
    /// @param index The operator index
    error InactiveOperator(uint256 index);

    /// @notice A funded key deletion has been attempted
    error InvalidFundedKeyDeletionAttempt();

    /// @notice The index provided are not sorted properly (descending order)
    error InvalidUnsortedIndexes();

    /// @notice The provided operator and limits array have different lengths
    error InvalidArrayLengths();

    /// @notice The provided operator and limits array are empty
    error InvalidEmptyArray();

    /// @notice The provided key count is 0
    error InvalidKeyCount();

    /// @notice The provided concatenated keys do not have the expected length
    error InvalidKeysLength();

    /// @notice The index that is removed is out of bounds
    error InvalidIndexOutOfBounds();

    /// @notice The value for the operator limit is too high
    /// @param index The operator index
    /// @param limit The new limit provided
    /// @param keyCount The operator key count
    error OperatorLimitTooHigh(uint256 index, uint256 limit, uint256 keyCount);

    /// @notice The value for the limit is too low
    /// @param index The operator index
    /// @param limit The new limit provided
    /// @param fundedKeyCount The operator funded key count
    error OperatorLimitTooLow(uint256 index, uint256 limit, uint256 fundedKeyCount);

    /// @notice The provided list of operators is not in increasing order
    error UnorderedOperatorList();

    /// @notice Initializes the operators registry
    /// @param _admin Admin in charge of managing operators
    /// @param _river Address of River system
    function initOperatorsRegistryV1(address _admin, address _river) external;

    /// @notice Retrieve the River address
    /// @return The address of River
    function getRiver() external view returns (address);

    /// @notice Get operator details
    /// @param _index The index of the operator
    /// @return The details of the operator
    function getOperator(uint256 _index) external view returns (Operators.Operator memory);

    /// @notice Get operator count
    /// @return The operator count
    function getOperatorCount() external view returns (uint256);

    /// @notice Get the details of a validator
    /// @param _operatorIndex The index of the operator
    /// @param _validatorIndex The index of the validator
    /// @return publicKey The public key of the validator
    /// @return signature The signature used during deposit
    /// @return funded True if validator has been funded
    function getValidator(uint256 _operatorIndex, uint256 _validatorIndex)
        external
        view
        returns (bytes memory publicKey, bytes memory signature, bool funded);

    /// @notice Retrieve the active operator set
    /// @return The list of active operators and their details
    function listActiveOperators() external view returns (Operators.Operator[] memory);

    /// @notice Adds an operator to the registry
    /// @dev Only callable by the administrator
    /// @param _name The name identifying the operator
    /// @param _operator The address representing the operator, receiving the rewards
    /// @return The index of the new operator
    function addOperator(string calldata _name, address _operator) external returns (uint256);

    /// @notice Changes the operator address of an operator
    /// @dev Only callable by the administrator or the previous operator address
    /// @param _index The operator index
    /// @param _newOperatorAddress The new address of the operator
    function setOperatorAddress(uint256 _index, address _newOperatorAddress) external;

    /// @notice Changes the operator name
    /// @dev Only callable by the administrator or the operator
    /// @param _index The operator index
    /// @param _newName The new operator name
    function setOperatorName(uint256 _index, string calldata _newName) external;

    /// @notice Changes the operator status
    /// @dev Only callable by the administrator
    /// @param _index The operator index
    /// @param _newStatus The new status of the operator
    function setOperatorStatus(uint256 _index, bool _newStatus) external;

    /// @notice Changes the operator stopped validator count
    /// @dev Only callable by the administrator
    /// @param _index The operator index
    /// @param _newStoppedValidatorCount The new stopped validator count of the operator
    function setOperatorStoppedValidatorCount(uint256 _index, uint256 _newStoppedValidatorCount) external;

    /// @notice Changes the operator staking limit
    /// @dev Only callable by the administrator
    /// @dev The operator indexes must be in increasing order and contain no duplicate
    /// @dev The limit cannot exceed the total key count of the operator
    /// @dev The _indexes and _newLimits must have the same length.
    /// @dev Each limit value is applied to the operator index at the same index in the _indexes array.
    /// @param _operatorIndexes The operator indexes, in increasing order and duplicate free
    /// @param _newLimits The new staking limit of the operators
    /// @param _snapshotBlock The block number at which the snapshot was computed
    function setOperatorLimits(
        uint256[] calldata _operatorIndexes,
        uint256[] calldata _newLimits,
        uint256 _snapshotBlock
    ) external;

    /// @notice Adds new keys for an operator
    /// @dev Only callable by the administrator or the operator address
    /// @param _index The operator index
    /// @param _keyCount The amount of keys provided
    /// @param _publicKeysAndSignatures Public keys of the validator, concatenated
    function addValidators(uint256 _index, uint256 _keyCount, bytes calldata _publicKeysAndSignatures) external;

    /// @notice Remove validator keys
    /// @dev Only callable by the administrator or the operator address
    /// @dev The indexes must be provided sorted in decreasing order and duplicate-free, otherwise the method will revert
    /// @dev The operator limit will be set to the lowest deleted key index if the operator's limit wasn't equal to its total key count
    /// @dev The operator or the admin cannot remove funded keys
    /// @dev When removing validators, the indexes of specific unfunded keys can be changed in order to properly
    /// @dev remove the keys from the storage array. Beware of this specific behavior when chaining calls as the
    /// @dev targeted public key indexes can point to a different key after a first call was made and performed
    /// @dev some swaps
    /// @param _index The operator index
    /// @param _indexes The indexes of the keys to remove
    function removeValidators(uint256 _index, uint256[] calldata _indexes) external;

    /// @notice Retrieve validator keys based on operator statuses
    /// @param _count Max amount of keys requested
    /// @return publicKeys An array of public keys
    /// @return signatures An array of signatures linked to the public keys
    function pickNextValidators(uint256 _count)
        external
        returns (bytes[] memory publicKeys, bytes[] memory signatures);
}