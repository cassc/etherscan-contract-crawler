//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Approvals Per Owner Storage
/// @notice Utility to manage the Approvals Per Owner in storage
library ApprovalsPerOwner {
    /// @notice Storage slot of the Approvals Per Owner
    bytes32 internal constant APPROVALS_PER_OWNER_SLOT =
        bytes32(uint256(keccak256("river.state.approvalsPerOwner")) - 1);

    /// @notice The structure in storage
    struct Slot {
        /// @custom:attribute The mapping from an owner to an operator to the approval amount
        mapping(address => mapping(address => uint256)) value;
    }

    /// @notice Retrieve the approval for an owner to an operator
    /// @param _owner The account that gave the approval
    /// @param _operator The account receiving the approval
    /// @return The value of the approval
    function get(address _owner, address _operator) internal view returns (uint256) {
        bytes32 slot = APPROVALS_PER_OWNER_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value[_owner][_operator];
    }

    /// @notice Set the approval value for an owner to an operator
    /// @param _owner The account that gives the approval
    /// @param _operator The account receiving the approval
    /// @param _newValue The value of the approval
    function set(address _owner, address _operator, uint256 _newValue) internal {
        bytes32 slot = APPROVALS_PER_OWNER_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value[_owner][_operator] = _newValue;
    }
}