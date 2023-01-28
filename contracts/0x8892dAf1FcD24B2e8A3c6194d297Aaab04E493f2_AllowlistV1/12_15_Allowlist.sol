//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Allowlist Storage
/// @notice Utility to manage the Allowlist mapping in storage
library Allowlist {
    /// @notice Storage slot of the Allowlist mapping
    bytes32 internal constant ALLOWLIST_SLOT = bytes32(uint256(keccak256("river.state.allowlist")) - 1);

    /// @notice Structure stored in storage slot
    struct Slot {
        /// @custom:attribute Mapping keeping track of permissions per account
        mapping(address => uint256) value;
    }

    /// @notice Retrieve the Allowlist value of an account
    /// @param _account The account to verify
    /// @return The Allowlist value
    function get(address _account) internal view returns (uint256) {
        bytes32 slot = ALLOWLIST_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value[_account];
    }

    /// @notice Sets the Allowlist value of an account
    /// @param _account The account value to set
    /// @param _status The value to set
    function set(address _account, uint256 _status) internal {
        bytes32 slot = ALLOWLIST_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value[_account] = _status;
    }
}