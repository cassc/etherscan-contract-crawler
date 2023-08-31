// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IERC721ACH {
    /**
     * @dev Enumerated list of all available hook types for the ERC721ACH contract.
     */
    enum HookType {
        /// @notice Hook for custom logic before a token transfer occurs.
        BeforeTokenTransfers,
        /// @notice Hook for custom logic after a token transfer occurs.
        AfterTokenTransfers,
        /// @notice Hook for custom logic for ownerOf() function.
        OwnerOf
    }

    /**
     * @notice An event that gets emitted when a hook is updated.
     * @param setter The address that set the hook.
     * @param hookType The type of the hook that was set.
     * @param hookAddress The address of the contract that implements the hook.
     */
    event UpdatedHook(
        address indexed setter,
        HookType hookType,
        address indexed hookAddress
    );

    /**
     * @notice Sets the contract address for a specified hook type.
     * @param hookType The type of hook to set, as defined in the HookType enum.
     * @param hookAddress The address of the contract implementing the hook interface.
     */
    function setHook(HookType hookType, address hookAddress) external;

    /**
     * @notice Returns the contract address for a specified hook type.
     * @param hookType The type of hook to set, as defined in the HookType enum.
     * @return The address of the contract implementing the hook interface.
     */
    function getHook(HookType hookType) external view returns (address);
}