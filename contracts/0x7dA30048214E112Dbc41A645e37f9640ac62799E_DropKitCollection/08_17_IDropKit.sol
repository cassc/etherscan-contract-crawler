// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDropKit {
    /**
     * @dev Emitted when collection is created
     */
    event CollectionCreated(address indexed collectionAddress);

    /**
     * @dev Returns the commission amount.
     */
    function commission(uint256 amount) external view returns (uint256);

    /**
     * @dev Add fees from Collection
     */
    function addFees(uint256 amount) external;

    /**
     * @dev Add fees claimed by the Collection
     */
    function addFeesClaimed(uint256 amount) external;

    /**
     * @dev Get fees accrued by the account
     */
    function getFees(address account) external view returns (uint256);
}