//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/IOperatorRegistry.1.sol";
import "./interfaces/IRiver.1.sol";

import "./libraries/LibUint256.sol";

import "./Initializable.sol";
import "./Administrable.sol";

import "./state/operatorsRegistry/Operators.1.sol";
import "./state/operatorsRegistry/Operators.2.sol";
import "./state/operatorsRegistry/ValidatorKeys.sol";
import "./state/operatorsRegistry/TotalValidatorExitsRequested.sol";
import "./state/operatorsRegistry/CurrentValidatorExitsDemand.sol";
import "./state/shared/RiverAddress.sol";

import "./state/migration/OperatorsRegistry_FundedKeyEventRebroadcasting_KeyIndex.sol";
import "./state/migration/OperatorsRegistry_FundedKeyEventRebroadcasting_OperatorIndex.sol";

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

    /// @notice Internal migration utility to migrate all operators to OperatorsV2 format
    function _migrateOperators_V1_1() internal {
        uint256 opCount = OperatorsV1.getCount();

        for (uint256 idx = 0; idx < opCount;) {
            OperatorsV1.Operator memory oldOperatorValue = OperatorsV1.get(idx);

            OperatorsV2.push(
                OperatorsV2.Operator({
                    limit: uint32(oldOperatorValue.limit),
                    funded: uint32(oldOperatorValue.funded),
                    requestedExits: 0,
                    keys: uint32(oldOperatorValue.keys),
                    latestKeysEditBlockNumber: uint64(oldOperatorValue.latestKeysEditBlockNumber),
                    active: oldOperatorValue.active,
                    name: oldOperatorValue.name,
                    operator: oldOperatorValue.operator
                })
            );

            unchecked {
                ++idx;
            }
        }
    }

    /// MIGRATION: FUNDED VALIDATOR KEY EVENT REBROADCASTING
    /// As the event for funded keys was moved from River to this contract because we needed to be able to bind
    /// operator indexes to public keys, we need to rebroadcast the past funded validator keys with the new event
    /// to keep retro-compatibility

    /// Emitted when the event rebroadcasting is done and we attempt to broadcast new events
    error FundedKeyEventMigrationComplete();

    /// Utility to force the broadcasting of events. Will keep its progress in storage to prevent being DoSed by the number of keys
    /// @param _amountToEmit The amount of events to emit at maximum in this call
    function forceFundedValidatorKeysEventEmission(uint256 _amountToEmit) external {
        uint256 operatorIndex = OperatorsRegistry_FundedKeyEventRebroadcasting_OperatorIndex.get();
        if (operatorIndex == type(uint256).max) {
            revert FundedKeyEventMigrationComplete();
        }
        if (OperatorsV2.getCount() == 0) {
            OperatorsRegistry_FundedKeyEventRebroadcasting_OperatorIndex.set(type(uint256).max);
            return;
        }
        uint256 keyIndex = OperatorsRegistry_FundedKeyEventRebroadcasting_KeyIndex.get();
        while (_amountToEmit > 0 && operatorIndex != type(uint256).max) {
            OperatorsV2.Operator memory operator = OperatorsV2.get(operatorIndex);

            (bytes[] memory publicKeys,) = ValidatorKeys.getKeys(
                operatorIndex, keyIndex, LibUint256.min(_amountToEmit, operator.funded - keyIndex)
            );
            emit FundedValidatorKeys(operatorIndex, publicKeys, true);
            if (keyIndex + publicKeys.length == operator.funded) {
                keyIndex = 0;
                if (operatorIndex == OperatorsV2.getCount() - 1) {
                    operatorIndex = type(uint256).max;
                } else {
                    ++operatorIndex;
                }
            } else {
                keyIndex += publicKeys.length;
            }
            _amountToEmit -= publicKeys.length;
        }
        OperatorsRegistry_FundedKeyEventRebroadcasting_OperatorIndex.set(operatorIndex);
        OperatorsRegistry_FundedKeyEventRebroadcasting_KeyIndex.set(keyIndex);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function initOperatorsRegistryV1_1() external init(1) {
        _migrateOperators_V1_1();
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
        OperatorsV2.Operator storage operator = OperatorsV2.get(_index);
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
    function getOperator(uint256 _index) external view returns (OperatorsV2.Operator memory) {
        return OperatorsV2.get(_index);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function getOperatorStoppedValidatorCount(uint256 _idx) external view returns (uint32) {
        return _getStoppedValidatorsCount(_idx);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function getTotalStoppedValidatorCount() external view returns (uint32) {
        return _getTotalStoppedValidatorCount();
    }

    /// @inheritdoc IOperatorsRegistryV1
    function getTotalValidatorExitsRequested() external view returns (uint256) {
        return TotalValidatorExitsRequested.get();
    }

    /// @inheritdoc IOperatorsRegistryV1
    function getCurrentValidatorExitsDemand() external view returns (uint256) {
        return CurrentValidatorExitsDemand.get();
    }

    /// @inheritdoc IOperatorsRegistryV1
    function getStoppedAndRequestedExitCounts() external view returns (uint32, uint256) {
        return
            (_getTotalStoppedValidatorCount(), TotalValidatorExitsRequested.get() + CurrentValidatorExitsDemand.get());
    }

    /// @inheritdoc IOperatorsRegistryV1
    function getOperatorCount() external view returns (uint256) {
        return OperatorsV2.getCount();
    }

    /// @inheritdoc IOperatorsRegistryV1
    function getStoppedValidatorCountPerOperator() external view returns (uint32[] memory) {
        uint32[] memory completeList = OperatorsV2.getStoppedValidators();
        uint256 listLength = completeList.length;

        if (listLength > 0) {
            assembly {
                // no need to use free memory pointer as we reuse the same memory range

                // erase previous word storing length
                mstore(completeList, 0)

                // move memory pointer up by a word
                completeList := add(completeList, 0x20)

                // store updated length at new memory pointer location
                mstore(completeList, sub(listLength, 1))
            }
        }

        return completeList;
    }

    /// @inheritdoc IOperatorsRegistryV1
    function getValidator(uint256 _operatorIndex, uint256 _validatorIndex)
        external
        view
        returns (bytes memory publicKey, bytes memory signature, bool funded)
    {
        (publicKey, signature) = ValidatorKeys.get(_operatorIndex, _validatorIndex);
        funded = _validatorIndex < OperatorsV2.get(_operatorIndex).funded;
    }

    /// @inheritdoc IOperatorsRegistryV1
    function listActiveOperators() external view returns (OperatorsV2.Operator[] memory) {
        return OperatorsV2.getAllActive();
    }

    /// @inheritdoc IOperatorsRegistryV1
    function reportStoppedValidatorCounts(uint32[] calldata _stoppedValidatorCounts, uint256 _depositedValidatorCount)
        external
        onlyRiver
    {
        _setStoppedValidatorCounts(_stoppedValidatorCounts, _depositedValidatorCount);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function addOperator(string calldata _name, address _operator) external onlyAdmin returns (uint256) {
        OperatorsV2.Operator memory newOperator = OperatorsV2.Operator({
            active: true,
            operator: _operator,
            name: _name,
            limit: 0,
            funded: 0,
            keys: 0,
            requestedExits: 0,
            latestKeysEditBlockNumber: uint64(block.number)
        });

        uint256 operatorIndex = OperatorsV2.push(newOperator) - 1;

        emit AddedOperator(operatorIndex, _name, _operator);
        return operatorIndex;
    }

    /// @inheritdoc IOperatorsRegistryV1
    function setOperatorAddress(uint256 _index, address _newOperatorAddress) external onlyOperatorOrAdmin(_index) {
        LibSanitize._notZeroAddress(_newOperatorAddress);
        OperatorsV2.Operator storage operator = OperatorsV2.get(_index);

        operator.operator = _newOperatorAddress;

        emit SetOperatorAddress(_index, _newOperatorAddress);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function setOperatorName(uint256 _index, string calldata _newName) external onlyOperatorOrAdmin(_index) {
        LibSanitize._notEmptyString(_newName);
        OperatorsV2.Operator storage operator = OperatorsV2.get(_index);
        operator.name = _newName;

        emit SetOperatorName(_index, _newName);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function setOperatorStatus(uint256 _index, bool _newStatus) external onlyAdmin {
        OperatorsV2.Operator storage operator = OperatorsV2.get(_index);
        operator.active = _newStatus;

        emit SetOperatorStatus(_index, _newStatus);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function setOperatorLimits(
        uint256[] calldata _operatorIndexes,
        uint32[] calldata _newLimits,
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
            uint32 newLimit = _newLimits[idx];

            // prevents duplicates
            if (idx > 0 && !(operatorIndex > _operatorIndexes[idx - 1])) {
                revert UnorderedOperatorList();
            }

            OperatorsV2.Operator storage operator = OperatorsV2.get(operatorIndex);

            uint32 currentLimit = operator.limit;
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
    function addValidators(uint256 _index, uint32 _keyCount, bytes calldata _publicKeysAndSignatures)
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

        OperatorsV2.Operator storage operator = OperatorsV2.get(_index);

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
        OperatorsV2.setKeys(_index, operator.keys + _keyCount);

        emit AddedValidatorKeys(_index, _publicKeysAndSignatures);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function removeValidators(uint256 _index, uint256[] calldata _indexes) external onlyOperatorOrAdmin(_index) {
        uint256 indexesLength = _indexes.length;
        if (indexesLength == 0) {
            revert InvalidKeyCount();
        }

        OperatorsV2.Operator storage operator = OperatorsV2.get(_index);

        uint32 totalKeys = operator.keys;

        if (!(_indexes[0] < totalKeys)) {
            revert InvalidIndexOutOfBounds();
        }

        uint256 lastIndex = _indexes[indexesLength - 1];

        if (lastIndex < operator.funded) {
            revert InvalidFundedKeyDeletionAttempt();
        }

        bool limitEqualsKeyCount = operator.keys == operator.limit;
        OperatorsV2.setKeys(_index, totalKeys - uint32(indexesLength));

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
            operator.limit = uint32(lastIndex);
        }
    }

    /// @inheritdoc IOperatorsRegistryV1
    function pickNextValidatorsToDeposit(uint256 _count)
        external
        onlyRiver
        returns (bytes[] memory publicKeys, bytes[] memory signatures)
    {
        return _pickNextValidatorsToDepositFromActiveOperators(_count);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function requestValidatorExits(uint256 _count) external {
        uint256 currentValidatorExitsDemand = CurrentValidatorExitsDemand.get();
        uint256 exitRequestsToPerform = LibUint256.min(currentValidatorExitsDemand, _count);
        if (exitRequestsToPerform == 0) {
            revert NoExitRequestsToPerform();
        }
        uint256 savedCurrentValidatorExitsDemand = currentValidatorExitsDemand;
        currentValidatorExitsDemand -= _pickNextValidatorsToExitFromActiveOperators(exitRequestsToPerform);

        _setCurrentValidatorExitsDemand(savedCurrentValidatorExitsDemand, currentValidatorExitsDemand);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function demandValidatorExits(uint256 _count, uint256 _depositedValidatorCount) external onlyRiver {
        uint256 currentValidatorExitsDemand = CurrentValidatorExitsDemand.get();
        uint256 totalValidatorExitsRequested = TotalValidatorExitsRequested.get();
        _count = LibUint256.min(
            _count, _depositedValidatorCount - (totalValidatorExitsRequested + currentValidatorExitsDemand)
        );
        if (_count > 0) {
            _setCurrentValidatorExitsDemand(currentValidatorExitsDemand, currentValidatorExitsDemand + _count);
        }
    }

    /// @notice Internal utility to retrieve the total stopped validator count
    /// @return The total stopped validator count
    function _getTotalStoppedValidatorCount() internal view returns (uint32) {
        uint32[] storage stoppedValidatorCounts = OperatorsV2.getStoppedValidators();
        if (stoppedValidatorCounts.length == 0) {
            return 0;
        }
        return stoppedValidatorCounts[0];
    }

    /// @notice Internal utility to set the current validator exits demand
    /// @param _currentValue The current value
    /// @param _newValue The new value
    function _setCurrentValidatorExitsDemand(uint256 _currentValue, uint256 _newValue) internal {
        CurrentValidatorExitsDemand.set(_newValue);
        emit SetCurrentValidatorExitsDemand(_currentValue, _newValue);
    }

    /// @notice Internal structure to hold variables for the _setStoppedValidatorCounts method
    struct SetStoppedValidatorCountInternalVars {
        uint256 stoppedValidatorCountsLength;
        uint32[] currentStoppedValidatorCounts;
        uint256 currentStoppedValidatorCountsLength;
        uint32 totalStoppedValidatorCount;
        uint32 count;
        uint256 currentValidatorExitsDemand;
        uint256 cachedCurrentValidatorExitsDemand;
        uint256 totalRequestedExits;
        uint256 cachedTotalRequestedExits;
    }

    /// @notice Internal utiltiy to set the stopped validator array after sanity checks
    /// @param _stoppedValidatorCounts The stopped validators counts for every operator + the total count in index 0
    /// @param _depositedValidatorCount The current deposited validator count
    function _setStoppedValidatorCounts(uint32[] calldata _stoppedValidatorCounts, uint256 _depositedValidatorCount)
        internal
    {
        SetStoppedValidatorCountInternalVars memory vars;
        // we check that the array is not empty
        vars.stoppedValidatorCountsLength = _stoppedValidatorCounts.length;
        if (vars.stoppedValidatorCountsLength == 0) {
            revert InvalidEmptyStoppedValidatorCountsArray();
        }

        OperatorsV2.Operator[] storage operators = OperatorsV2.getAll();

        // we check that the cells containing operator stopped values are no more than the current operator count
        if (vars.stoppedValidatorCountsLength - 1 > operators.length) {
            revert StoppedValidatorCountsTooHigh();
        }

        vars.currentStoppedValidatorCounts = OperatorsV2.getStoppedValidators();
        vars.currentStoppedValidatorCountsLength = vars.currentStoppedValidatorCounts.length;

        // we check that the number of stopped values is not decreasing
        if (vars.stoppedValidatorCountsLength < vars.currentStoppedValidatorCountsLength) {
            revert StoppedValidatorCountArrayShrinking();
        }

        vars.totalStoppedValidatorCount = _stoppedValidatorCounts[0];
        vars.count = 0;

        // create value to track unsollicited validator exits (e.g. to cover cases when Node Operator exit a validator without being requested to)
        vars.currentValidatorExitsDemand = CurrentValidatorExitsDemand.get();
        vars.cachedCurrentValidatorExitsDemand = vars.currentValidatorExitsDemand;
        vars.totalRequestedExits = TotalValidatorExitsRequested.get();
        vars.cachedTotalRequestedExits = vars.totalRequestedExits;

        uint256 idx = 1;
        for (; idx < vars.currentStoppedValidatorCountsLength;) {
            // if the previous array was long enough, we check that the values are not decreasing
            if (_stoppedValidatorCounts[idx] < vars.currentStoppedValidatorCounts[idx]) {
                revert StoppedValidatorCountsDecreased();
            }

            // we check that the count of stopped validators is not above the funded validator count of an operator
            if (_stoppedValidatorCounts[idx] > operators[idx - 1].funded) {
                revert StoppedValidatorCountAboveFundedCount(
                    idx - 1, _stoppedValidatorCounts[idx], operators[idx - 1].funded
                );
            }

            // if the stopped validator count is greater than its requested exit count, we update the requested exit count
            if (_stoppedValidatorCounts[idx] > operators[idx - 1].requestedExits) {
                emit UpdatedRequestedValidatorExitsUponStopped(
                    idx - 1, operators[idx - 1].requestedExits, _stoppedValidatorCounts[idx]
                );
                uint256 unsollicitedExits = _stoppedValidatorCounts[idx] - operators[idx - 1].requestedExits;
                vars.totalRequestedExits += unsollicitedExits;
                operators[idx - 1].requestedExits = _stoppedValidatorCounts[idx];

                // we decrease the demand, considering unsollicited exits as if the exit requests were performed for them
                vars.currentValidatorExitsDemand -= LibUint256.min(unsollicitedExits, vars.currentValidatorExitsDemand);
            }

            // we recompute the total to ensure it's not an invalid sum
            vars.count += _stoppedValidatorCounts[idx];
            unchecked {
                ++idx;
            }
        }

        for (; idx < vars.stoppedValidatorCountsLength;) {
            // if the previous array was long enough, we check that the values are not decreasing
            if (_stoppedValidatorCounts[idx] > operators[idx - 1].funded) {
                revert StoppedValidatorCountAboveFundedCount(
                    idx - 1, _stoppedValidatorCounts[idx], operators[idx - 1].funded
                );
            }

            // if the stopped validator count is greater than its requested exit count, we update the requested exit count
            if (_stoppedValidatorCounts[idx] > operators[idx - 1].requestedExits) {
                emit UpdatedRequestedValidatorExitsUponStopped(
                    idx - 1, operators[idx - 1].requestedExits, _stoppedValidatorCounts[idx]
                );
                uint256 unsollicitedExits = _stoppedValidatorCounts[idx] - operators[idx - 1].requestedExits;
                vars.totalRequestedExits += unsollicitedExits;
                operators[idx - 1].requestedExits = _stoppedValidatorCounts[idx];

                // we decrease the demand, considering unsollicited exits as if the exit requests were performed for them
                vars.currentValidatorExitsDemand -= LibUint256.min(unsollicitedExits, vars.currentValidatorExitsDemand);
            }
            // we recompute the total to ensure it's not an invalid sum
            vars.count += _stoppedValidatorCounts[idx];
            unchecked {
                ++idx;
            }
        }

        if (vars.totalRequestedExits != vars.cachedTotalRequestedExits) {
            TotalValidatorExitsRequested.set(vars.totalRequestedExits);
            emit SetTotalValidatorExitsRequested(vars.cachedTotalRequestedExits, vars.totalRequestedExits);
        }

        if (vars.currentValidatorExitsDemand != vars.cachedCurrentValidatorExitsDemand) {
            CurrentValidatorExitsDemand.set(vars.currentValidatorExitsDemand);
            emit SetCurrentValidatorExitsDemand(
                vars.cachedCurrentValidatorExitsDemand, vars.currentValidatorExitsDemand
            );
        }

        // we check that the total is matching the sum of the individual values
        if (vars.totalStoppedValidatorCount != vars.count) {
            revert InvalidStoppedValidatorCountsSum();
        }
        // we check that the total is not higher than the current deposited validator count
        if (vars.totalStoppedValidatorCount > _depositedValidatorCount) {
            revert StoppedValidatorCountsTooHigh();
        }
        // we set the new stopped validators counts
        OperatorsV2.setRawStoppedValidators(_stoppedValidatorCounts);
        emit UpdatedStoppedValidators(_stoppedValidatorCounts);
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
    function _hasFundableKeys(OperatorsV2.CachedOperator memory _operator) internal pure returns (bool) {
        return (_operator.funded + _operator.picked) < _operator.limit;
    }

    /// @notice Internal utility to retrieve the actual stopped validator count of an operator from the reported array
    /// @param _operatorIndex The operator index
    /// @return The count of stopped validators
    function _getStoppedValidatorsCount(uint256 _operatorIndex) internal view returns (uint32) {
        return OperatorsV2._getStoppedValidatorCountAtIndex(OperatorsV2.getStoppedValidators(), _operatorIndex);
    }

    /// @notice Internal utility to get the count of active validators during the deposit selection process
    /// @param _operator The Operator structure in memory
    /// @return The count of active validators for the operator
    function _getActiveValidatorCountForDeposits(OperatorsV2.CachedOperator memory _operator)
        internal
        view
        returns (uint256)
    {
        return (_operator.funded + _operator.picked) - _getStoppedValidatorsCount(_operator.index);
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
    function _pickNextValidatorsToDepositFromActiveOperators(uint256 _count)
        internal
        returns (bytes[] memory publicKeys, bytes[] memory signatures)
    {
        (OperatorsV2.CachedOperator[] memory operators, uint256 fundableOperatorCount) = OperatorsV2.getAllFundable();

        if (fundableOperatorCount == 0) {
            return (new bytes[](0), new bytes[](0));
        }

        while (_count > 0) {
            // loop on operators to find the first that has fundable keys, taking into account previous loop round attributions
            uint256 selectedOperatorIndex = 0;
            for (; selectedOperatorIndex < fundableOperatorCount;) {
                if (_hasFundableKeys(operators[selectedOperatorIndex])) {
                    break;
                }
                unchecked {
                    ++selectedOperatorIndex;
                }
            }

            // if we reach the end, we have allocated all keys
            if (selectedOperatorIndex == fundableOperatorCount) {
                break;
            }

            // we start from the next operator and we try to find one that has fundable keys but a lower (funded + picked) - stopped value
            for (uint256 idx = selectedOperatorIndex + 1; idx < fundableOperatorCount;) {
                if (
                    _getActiveValidatorCountForDeposits(operators[idx])
                        < _getActiveValidatorCountForDeposits(operators[selectedOperatorIndex])
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
            operators[selectedOperatorIndex].picked += uint32(pickedKeyCount);

            // we update the requested amount count
            _count -= pickedKeyCount;
        }

        // we loop on all operators
        for (uint256 idx = 0; idx < fundableOperatorCount; ++idx) {
            // if we picked keys on any operator, we extract the keys from storage and concatenate them in the result
            // we then update the funded value
            if (operators[idx].picked > 0) {
                (bytes[] memory _publicKeys, bytes[] memory _signatures) =
                    ValidatorKeys.getKeys(operators[idx].index, operators[idx].funded, operators[idx].picked);
                emit FundedValidatorKeys(operators[idx].index, _publicKeys, false);
                publicKeys = _concatenateByteArrays(publicKeys, _publicKeys);
                signatures = _concatenateByteArrays(signatures, _signatures);
                (OperatorsV2.get(operators[idx].index)).funded += operators[idx].picked;
            }
        }
    }

    /// @notice Internal utility to get the count of active validators during the exit selection process
    /// @param _operator The Operator structure in memory
    /// @return The count of active validators for the operator
    function _getActiveValidatorCountForExitRequests(OperatorsV2.CachedExitableOperator memory _operator)
        internal
        pure
        returns (uint32)
    {
        return _operator.funded - (_operator.requestedExits + _operator.picked);
    }

    /// @notice Internal utility to pick the next validator counts to exit for every operator
    /// @param _count The count of validators to request exits for
    function _pickNextValidatorsToExitFromActiveOperators(uint256 _count) internal returns (uint256) {
        (OperatorsV2.CachedExitableOperator[] memory operators, uint256 exitableOperatorCount) =
            OperatorsV2.getAllExitable();

        if (exitableOperatorCount == 0) {
            return 0;
        }

        uint256 initialExitRequestDemand = _count;
        uint256 totalRequestedExitsValue = TotalValidatorExitsRequested.get();
        uint256 totalRequestedExitsCopy = totalRequestedExitsValue;

        // we loop to find the highest count of active validators, the number of operators that have this amount and the second highest amount
        while (_count > 0) {
            uint32 highestActiveCount = 0;
            uint32 secondHighestActiveCount = 0;
            uint32 siblings = 0;

            for (uint256 idx = 0; idx < exitableOperatorCount;) {
                uint32 activeCount = _getActiveValidatorCountForExitRequests(operators[idx]);

                if (activeCount == highestActiveCount) {
                    ++siblings;
                } else if (activeCount > highestActiveCount) {
                    secondHighestActiveCount = highestActiveCount;
                    highestActiveCount = activeCount;
                    siblings = 1;
                } else if (activeCount > secondHighestActiveCount) {
                    secondHighestActiveCount = activeCount;
                }

                unchecked {
                    ++idx;
                }
            }

            // we exited all exitable validators
            if (highestActiveCount == 0) {
                break;
            }
            // The optimal amount is how much we should dispatch to all the operators with the highest count for them to get the same amount
            // of active validators as the second highest count. We then take the minimum between this value and the total we need to exit
            uint32 optimalTotalDispatchCount =
                uint32(LibUint256.min((highestActiveCount - secondHighestActiveCount) * siblings, _count));

            // We lookup the operators again to assign the exit requests
            uint256 rest = optimalTotalDispatchCount % siblings;
            uint32 baseExitRequestAmount = optimalTotalDispatchCount / siblings;
            for (uint256 idx = 0; idx < exitableOperatorCount;) {
                if (_getActiveValidatorCountForExitRequests(operators[idx]) == highestActiveCount) {
                    uint32 additionalRequestedExits = baseExitRequestAmount + (rest > 0 ? 1 : 0);
                    operators[idx].picked += additionalRequestedExits;
                    if (rest > 0) {
                        --rest;
                    }
                }
                unchecked {
                    ++idx;
                }
            }

            totalRequestedExitsValue += optimalTotalDispatchCount;
            _count -= optimalTotalDispatchCount;
        }

        // We loop over the operators and apply the change, also emit the exit request event
        for (uint256 idx = 0; idx < exitableOperatorCount;) {
            if (operators[idx].picked > 0) {
                uint256 opIndex = operators[idx].index;
                uint32 newRequestedExits = operators[idx].requestedExits + operators[idx].picked;

                OperatorsV2.get(opIndex).requestedExits = newRequestedExits;
                emit RequestedValidatorExits(opIndex, newRequestedExits);
            }

            unchecked {
                ++idx;
            }
        }

        if (totalRequestedExitsValue != totalRequestedExitsCopy) {
            TotalValidatorExitsRequested.set(totalRequestedExitsValue);
            emit SetTotalValidatorExitsRequested(totalRequestedExitsCopy, totalRequestedExitsValue);
        }

        return initialExitRequestDemand - _count;
    }
}