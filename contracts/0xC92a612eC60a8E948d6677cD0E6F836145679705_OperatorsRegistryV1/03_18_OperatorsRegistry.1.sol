//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/IOperatorRegistry.1.sol";

import "./libraries/LibUint256.sol";

import "./Initializable.sol";
import "./Administrable.sol";

import "./state/operatorsRegistry/Operators.sol";
import "./state/operatorsRegistry/ValidatorKeys.sol";
import "./state/shared/RiverAddress.sol";

/// @title Operators Registry (v1)
/// @author Kiln
/// @notice This contract handles the list of operators and their keys
contract OperatorsRegistryV1 is IOperatorsRegistryV1, Initializable, Administrable {
    /// @notice Maximum validators given to an operator per selection loop round
    uint256 internal constant MAX_VALIDATOR_ATTRIBUTION_PER_ROUND = 5;

    /// @inheritdoc IOperatorsRegistryV1
    function initOperatorsRegistryV1(address _admin, address _river) external init(0) {
        _setAdmin(_admin);
        RiverAddress.set(_river);
        emit SetRiver(_river);
    }

    /// @notice Prevent unauthorized calls
    modifier onlyRiver() virtual {
        if (msg.sender != RiverAddress.get()) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @notice Prevents anyone except the admin or the given operator to make the call. Also checks if operator is active
    /// @notice The admin is able to call this method on behalf of any operator, even if inactive
    /// @param _index The index identifying the operator
    modifier onlyOperatorOrAdmin(uint256 _index) {
        if (msg.sender == _getAdmin()) {
            _;
            return;
        }
        Operators.Operator storage operator = Operators.get(_index);
        if (!operator.active) {
            revert InactiveOperator(_index);
        }
        if (msg.sender != operator.operator) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @inheritdoc IOperatorsRegistryV1
    function getRiver() external view returns (address) {
        return RiverAddress.get();
    }

    /// @inheritdoc IOperatorsRegistryV1
    function getOperator(uint256 _index) external view returns (Operators.Operator memory) {
        return Operators.get(_index);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function getOperatorCount() external view returns (uint256) {
        return Operators.getCount();
    }

    /// @inheritdoc IOperatorsRegistryV1
    function getValidator(uint256 _operatorIndex, uint256 _validatorIndex)
        external
        view
        returns (bytes memory publicKey, bytes memory signature, bool funded)
    {
        (publicKey, signature) = ValidatorKeys.get(_operatorIndex, _validatorIndex);
        funded = _validatorIndex < Operators.get(_operatorIndex).funded;
    }

    /// @inheritdoc IOperatorsRegistryV1
    function listActiveOperators() external view returns (Operators.Operator[] memory) {
        return Operators.getAllActive();
    }

    /// @inheritdoc IOperatorsRegistryV1
    function addOperator(string calldata _name, address _operator) external onlyAdmin returns (uint256) {
        Operators.Operator memory newOperator = Operators.Operator({
            active: true,
            operator: _operator,
            name: _name,
            limit: 0,
            funded: 0,
            keys: 0,
            stopped: 0,
            latestKeysEditBlockNumber: block.number
        });

        uint256 operatorIndex = Operators.push(newOperator) - 1;

        emit AddedOperator(operatorIndex, _name, _operator);
        return operatorIndex;
    }

    /// @inheritdoc IOperatorsRegistryV1
    function setOperatorAddress(uint256 _index, address _newOperatorAddress) external onlyOperatorOrAdmin(_index) {
        LibSanitize._notZeroAddress(_newOperatorAddress);
        Operators.Operator storage operator = Operators.get(_index);

        operator.operator = _newOperatorAddress;

        emit SetOperatorAddress(_index, _newOperatorAddress);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function setOperatorName(uint256 _index, string calldata _newName) external onlyOperatorOrAdmin(_index) {
        LibSanitize._notEmptyString(_newName);
        Operators.Operator storage operator = Operators.get(_index);
        operator.name = _newName;

        emit SetOperatorName(_index, _newName);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function setOperatorStatus(uint256 _index, bool _newStatus) external onlyAdmin {
        Operators.Operator storage operator = Operators.get(_index);
        operator.active = _newStatus;

        emit SetOperatorStatus(_index, _newStatus);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function setOperatorStoppedValidatorCount(uint256 _index, uint256 _newStoppedValidatorCount) external onlyAdmin {
        Operators.Operator storage operator = Operators.get(_index);

        if (_newStoppedValidatorCount > operator.funded) {
            revert LibErrors.InvalidArgument();
        }

        operator.stopped = _newStoppedValidatorCount;

        emit SetOperatorStoppedValidatorCount(_index, _newStoppedValidatorCount);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function setOperatorLimits(
        uint256[] calldata _operatorIndexes,
        uint256[] calldata _newLimits,
        uint256 _snapshotBlock
    ) external onlyAdmin {
        if (_operatorIndexes.length != _newLimits.length) {
            revert InvalidArrayLengths();
        }
        if (_operatorIndexes.length == 0) {
            revert InvalidEmptyArray();
        }
        for (uint256 idx = 0; idx < _operatorIndexes.length;) {
            uint256 operatorIndex = _operatorIndexes[idx];
            uint256 newLimit = _newLimits[idx];

            // prevents duplicates
            if (idx > 0 && !(operatorIndex > _operatorIndexes[idx - 1])) {
                revert UnorderedOperatorList();
            }

            Operators.Operator storage operator = Operators.get(operatorIndex);

            uint256 currentLimit = operator.limit;
            if (newLimit == currentLimit) {
                emit OperatorLimitUnchanged(operatorIndex, newLimit);
                unchecked {
                    ++idx;
                }
                continue;
            }

            // we enter this condition if the operator edited its keys after the off-chain key audit was made
            // we will skip any limit update on that operator unless it was a decrease in the initial limit
            if (_snapshotBlock < operator.latestKeysEditBlockNumber && newLimit > currentLimit) {
                emit OperatorEditsAfterSnapshot(
                    operatorIndex, currentLimit, newLimit, operator.latestKeysEditBlockNumber, _snapshotBlock
                    );
                unchecked {
                    ++idx;
                }
                continue;
            }

            // otherwise, we check for limit invariants that shouldn't happen if the off-chain key audit
            // was made properly, and if everything is respected, we update the limit

            if (newLimit > operator.keys) {
                revert OperatorLimitTooHigh(operatorIndex, newLimit, operator.keys);
            }

            if (newLimit < operator.funded) {
                revert OperatorLimitTooLow(operatorIndex, newLimit, operator.funded);
            }

            operator.limit = newLimit;
            emit SetOperatorLimit(operatorIndex, newLimit);

            unchecked {
                ++idx;
            }
        }
    }

    /// @inheritdoc IOperatorsRegistryV1
    function addValidators(uint256 _index, uint256 _keyCount, bytes calldata _publicKeysAndSignatures)
        external
        onlyOperatorOrAdmin(_index)
    {
        if (_keyCount == 0) {
            revert InvalidKeyCount();
        }

        if (
            _publicKeysAndSignatures.length
                != _keyCount * (ValidatorKeys.PUBLIC_KEY_LENGTH + ValidatorKeys.SIGNATURE_LENGTH)
        ) {
            revert InvalidKeysLength();
        }

        Operators.Operator storage operator = Operators.get(_index);

        for (uint256 idx = 0; idx < _keyCount;) {
            bytes memory publicKeyAndSignature = LibBytes.slice(
                _publicKeysAndSignatures,
                idx * (ValidatorKeys.PUBLIC_KEY_LENGTH + ValidatorKeys.SIGNATURE_LENGTH),
                ValidatorKeys.PUBLIC_KEY_LENGTH + ValidatorKeys.SIGNATURE_LENGTH
            );
            ValidatorKeys.set(_index, operator.keys + idx, publicKeyAndSignature);
            unchecked {
                ++idx;
            }
        }
        Operators.setKeys(_index, operator.keys + _keyCount);

        emit AddedValidatorKeys(_index, _publicKeysAndSignatures);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function removeValidators(uint256 _index, uint256[] calldata _indexes) external onlyOperatorOrAdmin(_index) {
        uint256 indexesLength = _indexes.length;
        if (indexesLength == 0) {
            revert InvalidKeyCount();
        }

        Operators.Operator storage operator = Operators.get(_index);

        uint256 totalKeys = operator.keys;

        if (!(_indexes[0] < totalKeys)) {
            revert InvalidIndexOutOfBounds();
        }

        uint256 lastIndex = _indexes[indexesLength - 1];

        if (lastIndex < operator.funded) {
            revert InvalidFundedKeyDeletionAttempt();
        }

        bool limitEqualsKeyCount = operator.keys == operator.limit;
        Operators.setKeys(_index, totalKeys - indexesLength);

        uint256 idx;
        for (; idx < indexesLength;) {
            uint256 keyIndex = _indexes[idx];

            if (idx > 0 && !(keyIndex < _indexes[idx - 1])) {
                revert InvalidUnsortedIndexes();
            }

            unchecked {
                ++idx;
            }

            uint256 lastKeyIndex = totalKeys - idx;

            (bytes memory removedPublicKey,) = ValidatorKeys.get(_index, keyIndex);
            (bytes memory lastPublicKeyAndSignature) = ValidatorKeys.getRaw(_index, lastKeyIndex);
            ValidatorKeys.set(_index, keyIndex, lastPublicKeyAndSignature);
            ValidatorKeys.set(_index, lastKeyIndex, new bytes(0));

            emit RemovedValidatorKey(_index, removedPublicKey);
        }

        if (limitEqualsKeyCount) {
            operator.limit = operator.keys;
        } else if (lastIndex < operator.limit) {
            operator.limit = lastIndex;
        }
    }

    /// @inheritdoc IOperatorsRegistryV1
    function pickNextValidators(uint256 _count)
        external
        onlyRiver
        returns (bytes[] memory publicKeys, bytes[] memory signatures)
    {
        return _pickNextValidatorsFromActiveOperators(_count);
    }

    /// @notice Internal utility to concatenate bytes arrays together
    /// @param _arr1 First array
    /// @param _arr2 Second array
    /// @return The result of the concatenation of _arr1 + _arr2
    function _concatenateByteArrays(bytes[] memory _arr1, bytes[] memory _arr2)
        internal
        pure
        returns (bytes[] memory)
    {
        bytes[] memory res = new bytes[](_arr1.length + _arr2.length);
        for (uint256 idx = 0; idx < _arr1.length;) {
            res[idx] = _arr1[idx];
            unchecked {
                ++idx;
            }
        }
        for (uint256 idx = 0; idx < _arr2.length;) {
            res[idx + _arr1.length] = _arr2[idx];
            unchecked {
                ++idx;
            }
        }
        return res;
    }

    /// @notice Internal utility to verify if an operator has fundable keys during the selection process
    /// @param _operator The Operator structure in memory
    /// @return True if at least one fundable key is available
    function _hasFundableKeys(Operators.CachedOperator memory _operator) internal pure returns (bool) {
        return (_operator.funded + _operator.picked) < _operator.limit;
    }

    /// @notice Internal utility to get the count of active validators during the selection process
    /// @param _operator The Operator structure in memory
    /// @return The count of active validators for the operator
    function _getActiveKeyCount(Operators.CachedOperator memory _operator) internal pure returns (uint256) {
        return (_operator.funded + _operator.picked) - _operator.stopped;
    }

    /// @notice Internal utility to retrieve _count or lower fundable keys
    /// @dev The selection process starts by retrieving the full list of active operators with at least one fundable key.
    /// @dev
    /// @dev An operator is considered to have at least one fundable key when their staking limit is higher than their funded key count.
    /// @dev
    /// @dev    isFundable = operator.active && operator.limit > operator.funded
    /// @dev
    /// @dev The internal utility will loop on all operators and select the operator with the lowest active validator count.
    /// @dev The active validator count is computed by subtracting the stopped validator count to the funded validator count.
    /// @dev
    /// @dev    activeValidatorCount = operator.funded - operator.stopped
    /// @dev
    /// @dev During the selection process, we keep in memory all previously selected operators and the number of given validators inside a field
    /// @dev called picked that only exists on the CachedOperator structure in memory.
    /// @dev
    /// @dev    isFundable = operator.active && operator.limit > (operator.funded + operator.picked)
    /// @dev    activeValidatorCount = (operator.funded + operator.picked) - operator.stopped
    /// @dev
    /// @dev When we reach the requested key count or when all available keys are used, we perform a final loop on all the operators and extract keys
    /// @dev if any operator has a positive picked count. We then update the storage counters and return the arrays with the public keys and signatures.
    /// @param _count Amount of keys required. Contract is expected to send _count or lower.
    /// @return publicKeys An array of fundable public keys
    /// @return signatures An array of signatures linked to the public keys
    function _pickNextValidatorsFromActiveOperators(uint256 _count)
        internal
        returns (bytes[] memory publicKeys, bytes[] memory signatures)
    {
        Operators.CachedOperator[] memory operators = Operators.getAllFundable();

        if (operators.length == 0) {
            return (new bytes[](0), new bytes[](0));
        }

        while (_count > 0) {
            // loop on operators to find the first that has fundable keys, taking into account previous loop round attributions
            uint256 selectedOperatorIndex = 0;
            for (; selectedOperatorIndex < operators.length;) {
                if (_hasFundableKeys(operators[selectedOperatorIndex])) {
                    break;
                }
                unchecked {
                    ++selectedOperatorIndex;
                }
            }

            // if we reach the end, we have allocated all keys
            if (selectedOperatorIndex == operators.length) {
                break;
            }

            // we start from the next operator and we try to find one that has fundable keys but a lower (funded + picked) - stopped value
            for (uint256 idx = selectedOperatorIndex + 1; idx < operators.length;) {
                if (
                    _getActiveKeyCount(operators[idx]) < _getActiveKeyCount(operators[selectedOperatorIndex])
                        && _hasFundableKeys(operators[idx])
                ) {
                    selectedOperatorIndex = idx;
                }
                unchecked {
                    ++idx;
                }
            }

            // we take the smallest value between limit - (funded + picked), _requestedAmount and MAX_VALIDATOR_ATTRIBUTION_PER_ROUND
            uint256 pickedKeyCount = LibUint256.min(
                LibUint256.min(
                    operators[selectedOperatorIndex].limit
                        - (operators[selectedOperatorIndex].funded + operators[selectedOperatorIndex].picked),
                    MAX_VALIDATOR_ATTRIBUTION_PER_ROUND
                ),
                _count
            );

            // we update the cached picked amount
            operators[selectedOperatorIndex].picked += pickedKeyCount;

            // we update the requested amount count
            _count -= pickedKeyCount;
        }

        // we loop on all operators
        for (uint256 idx = 0; idx < operators.length; ++idx) {
            // if we picked keys on any operator, we extract the keys from storage and concatenate them in the result
            // we then update the funded value
            if (operators[idx].picked > 0) {
                (bytes[] memory _publicKeys, bytes[] memory _signatures) =
                    ValidatorKeys.getKeys(operators[idx].index, operators[idx].funded, operators[idx].picked);
                publicKeys = _concatenateByteArrays(publicKeys, _publicKeys);
                signatures = _concatenateByteArrays(signatures, _signatures);
                (Operators.get(operators[idx].index)).funded += operators[idx].picked;
            }
        }
    }
}