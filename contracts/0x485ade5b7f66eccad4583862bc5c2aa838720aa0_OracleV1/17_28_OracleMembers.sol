//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibSanitize.sol";

/// @title Oracle Members Storage
/// @notice Utility to manage the Oracle Members in storage
/// @dev There can only be up to 256 oracle members. This is due to how report statuses are stored in Reports Positions
library OracleMembers {
    /// @notice Storage slot of the Oracle Members
    bytes32 internal constant ORACLE_MEMBERS_SLOT = bytes32(uint256(keccak256("river.state.oracleMembers")) - 1);

    /// @notice The structure in storage
    struct Slot {
        /// @custom:attribute The array of oracle members
        address[] value;
    }

    /// @notice Retrieve the list of oracle members
    /// @return List of oracle members
    function get() internal view returns (address[] memory) {
        bytes32 slot = ORACLE_MEMBERS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value;
    }

    /// @notice Add a new oracle member to the list
    /// @param _newOracleMember Address of the new oracle member
    function push(address _newOracleMember) internal {
        LibSanitize._notZeroAddress(_newOracleMember);

        bytes32 slot = ORACLE_MEMBERS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value.push(_newOracleMember);
    }

    /// @notice Set an address in the oracle member list
    /// @param _index The index to edit
    /// @param _newOracleAddress The new value of the oracle member
    function set(uint256 _index, address _newOracleAddress) internal {
        bytes32 slot = ORACLE_MEMBERS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value[_index] = _newOracleAddress;
    }

    /// @notice Retrieve the index of the oracle member
    /// @param _memberAddress The address to lookup
    /// @return The index of the member, -1 if not found
    function indexOf(address _memberAddress) internal view returns (int256) {
        bytes32 slot = ORACLE_MEMBERS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        for (uint256 idx = 0; idx < r.value.length;) {
            if (r.value[idx] == _memberAddress) {
                return int256(idx);
            }
            unchecked {
                ++idx;
            }
        }

        return int256(-1);
    }

    /// @notice Delete the oracle member at the given index
    /// @param _idx The index of the member to remove
    function deleteItem(uint256 _idx) internal {
        bytes32 slot = ORACLE_MEMBERS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        uint256 lastIdx = r.value.length - 1;
        if (lastIdx != _idx) {
            r.value[_idx] = r.value[lastIdx];
        }

        r.value.pop();
    }
}