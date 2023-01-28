//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Shares Per Owner Storage
/// @notice Utility to manage the Shares Per Owner in storage
library SharesPerOwner {
    /// @notice Storage slot of the Shares Per Owner
    bytes32 internal constant SHARES_PER_OWNER_SLOT = bytes32(uint256(keccak256("river.state.sharesPerOwner")) - 1);

    /// @notice Structure in storage
    struct Slot {
        /// @custom:attribute The mapping from an owner to its share count
        mapping(address => uint256) value;
    }

    /// @notice Retrieve the share count for given owner
    /// @param _owner The address to get the balance of
    /// @return The amount of shares
    function get(address _owner) internal view returns (uint256) {
        bytes32 slot = SHARES_PER_OWNER_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value[_owner];
    }

    /// @notice Set the amount of shares for an owner
    /// @param _owner The owner of the shares to edit
    /// @param _newValue The new shares value for the owner
    function set(address _owner, uint256 _newValue) internal {
        bytes32 slot = SHARES_PER_OWNER_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value[_owner] = _newValue;
    }
}