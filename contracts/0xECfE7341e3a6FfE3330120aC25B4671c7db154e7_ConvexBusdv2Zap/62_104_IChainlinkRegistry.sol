// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice Interface used by Chainlink to aggregate allocations and compute TVL
 */
interface IChainlinkRegistry {
    /**
     * @notice Get all IDs from registered asset allocations
     * @notice Each ID is a unique asset allocation and token index pair
     * @dev Should contain no duplicate IDs
     * @return list of all IDs
     */
    function getAssetAllocationIds() external view returns (bytes32[] memory);

    /**
     * @notice Get the LP Account's balance for an asset allocation ID
     * @param allocationId The ID to fetch the balance for
     * @return The balance for the LP Account
     */
    function balanceOf(bytes32 allocationId) external view returns (uint256);

    /**
     * @notice Get the symbol for an allocation ID's underlying token
     * @param allocationId The ID to fetch the symbol for
     * @return The underlying token symbol
     */
    function symbolOf(bytes32 allocationId)
        external
        view
        returns (string memory);

    /**
     * @notice Get the decimals for an allocation ID's underlying token
     * @param allocationId The ID to fetch the decimals for
     * @return The underlying token decimals
     */
    function decimalsOf(bytes32 allocationId) external view returns (uint256);
}