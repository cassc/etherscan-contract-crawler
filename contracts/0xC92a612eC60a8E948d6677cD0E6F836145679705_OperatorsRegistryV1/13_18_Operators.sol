//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibSanitize.sol";

/// @title Operators Storage
/// @notice Utility to manage the Operators in storage
library Operators {
    /// @notice Storage slot of the Operators
    bytes32 internal constant OPERATORS_SLOT = bytes32(uint256(keccak256("river.state.operators")) - 1);

    /// @notice The Operator structure in storage
    struct Operator {
        /// @custom:attribute True if the operator is active and allowed to operate on River
        bool active;
        /// @custom:attribute Display name of the operator
        string name;
        /// @custom:attribute Address of the operator
        address operator;
        /// @dev The following values respect this invariant:
        /// @dev     keys >= limit >= funded >= stopped

        /// @custom:attribute Staking limit of the operator
        uint256 limit;
        /// @custom:attribute The count of funded validators
        uint256 funded;
        /// @custom:attribute The total count of keys of the operator
        uint256 keys;
        /// @custom:attribute The count of stopped validators. Stopped validators are validators
        ///                   that exited the consensus layer (voluntary or slashed)
        uint256 stopped;
        uint256 latestKeysEditBlockNumber;
    }

    /// @notice The Operator structure when loaded in memory
    struct CachedOperator {
        /// @custom:attribute True if the operator is active and allowed to operate on River
        bool active;
        /// @custom:attribute Display name of the operator
        string name;
        /// @custom:attribute Address of the operator
        address operator;
        /// @custom:attribute Staking limit of the operator
        uint256 limit;
        /// @custom:attribute The count of funded validators
        uint256 funded;
        /// @custom:attribute The total count of keys of the operator
        uint256 keys;
        /// @custom:attribute The count of stopped validators
        uint256 stopped;
        /// @custom:attribute The count of stopped validators. Stopped validators are validators
        ///                   that exited the consensus layer (voluntary or slashed)
        uint256 index;
        /// @custom:attribute The amount of picked keys, buffer used before changing funded in storage
        uint256 picked;
    }

    /// @notice The structure at the storage slot
    struct SlotOperator {
        /// @custom:attribute Array containing all the operators
        Operator[] value;
    }

    /// @notice The operator was not found
    /// @param index The provided index
    error OperatorNotFound(uint256 index);

    /// @notice Retrieve the operator in storage
    /// @param _index The index of the operator
    /// @return The Operator structure
    function get(uint256 _index) internal view returns (Operator storage) {
        bytes32 slot = OPERATORS_SLOT;

        SlotOperator storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        if (r.value.length <= _index) {
            revert OperatorNotFound(_index);
        }

        return r.value[_index];
    }

    /// @notice Retrieve the operator count in storage
    /// @return The count of operators in storage
    function getCount() internal view returns (uint256) {
        bytes32 slot = OPERATORS_SLOT;

        SlotOperator storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value.length;
    }

    /// @notice Retrieve all the active operators
    /// @return The list of active operator structures
    function getAllActive() internal view returns (Operator[] memory) {
        bytes32 slot = OPERATORS_SLOT;

        SlotOperator storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        uint256 activeCount = 0;
        uint256 operatorCount = r.value.length;

        for (uint256 idx = 0; idx < operatorCount;) {
            if (r.value[idx].active) {
                unchecked {
                    ++activeCount;
                }
            }
            unchecked {
                ++idx;
            }
        }

        Operator[] memory activeOperators = new Operator[](activeCount);

        uint256 activeIdx = 0;
        for (uint256 idx = 0; idx < operatorCount;) {
            if (r.value[idx].active) {
                activeOperators[activeIdx] = r.value[idx];
                unchecked {
                    ++activeIdx;
                }
            }
            unchecked {
                ++idx;
            }
        }

        return activeOperators;
    }

    /// @notice Retrieve all the active and fundable operators
    /// @return The list of active and fundable operators
    function getAllFundable() internal view returns (CachedOperator[] memory) {
        bytes32 slot = OPERATORS_SLOT;

        SlotOperator storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        uint256 activeCount = 0;
        uint256 operatorCount = r.value.length;

        for (uint256 idx = 0; idx < operatorCount;) {
            if (_hasFundableKeys(r.value[idx])) {
                unchecked {
                    ++activeCount;
                }
            }
            unchecked {
                ++idx;
            }
        }

        CachedOperator[] memory activeOperators = new CachedOperator[](activeCount);

        uint256 activeIdx = 0;
        for (uint256 idx = 0; idx < operatorCount;) {
            Operator memory op = r.value[idx];
            if (_hasFundableKeys(op)) {
                activeOperators[activeIdx] = CachedOperator({
                    active: op.active,
                    name: op.name,
                    operator: op.operator,
                    limit: op.limit,
                    funded: op.funded,
                    keys: op.keys,
                    stopped: op.stopped,
                    index: idx,
                    picked: 0
                });
                unchecked {
                    ++activeIdx;
                }
            }
            unchecked {
                ++idx;
            }
        }

        return activeOperators;
    }

    /// @notice Add a new operator in storage
    /// @param _newOperator Value of the new operator
    /// @return The size of the operator array after the operation
    function push(Operator memory _newOperator) internal returns (uint256) {
        LibSanitize._notZeroAddress(_newOperator.operator);
        LibSanitize._notEmptyString(_newOperator.name);
        bytes32 slot = OPERATORS_SLOT;

        SlotOperator storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value.push(_newOperator);

        return r.value.length;
    }

    /// @notice Atomic operation to set the key count and update the latestKeysEditBlockNumber field at the same time
    /// @param _index The operator index
    /// @param _newKeys The new value for the key count
    function setKeys(uint256 _index, uint256 _newKeys) internal {
        Operator storage op = get(_index);

        op.keys = _newKeys;
        op.latestKeysEditBlockNumber = block.number;
    }

    /// @notice Checks if an operator is active and has fundable keys
    /// @param _operator The operator details
    /// @return True if active and fundable
    function _hasFundableKeys(Operators.Operator memory _operator) internal pure returns (bool) {
        return (_operator.active && _operator.limit > _operator.funded);
    }
}