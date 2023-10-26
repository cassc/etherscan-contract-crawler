//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Balance Storage
/// @notice Utility to manage the Balance in storage
library BalanceOf {
    /// @notice Storage slot of the Balance
    bytes32 internal constant BALANCE_OF_SLOT = bytes32(uint256(keccak256("river.state.balanceOf")) - 1);

    /// @notice The structure in storage
    struct Slot {
        /// @custom:attribute The mapping from an owner to its balance
        mapping(address => uint256) value;
    }

    /// @notice Retrieve balance of an owner
    /// @param _owner The owner of the balance
    /// @return The balance of the owner
    function get(address _owner) internal view returns (uint256) {
        bytes32 slot = BALANCE_OF_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value[_owner];
    }

    /// @notice Set the balance of an owner
    /// @param _owner The owner to change the balance of
    /// @param _newValue New balance value for the owner
    function set(address _owner, uint256 _newValue) internal {
        bytes32 slot = BALANCE_OF_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value[_owner] = _newValue;
    }
}