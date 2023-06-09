// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INiftyKit {
    struct Entry {
        uint256 value;
        bool isValue;
    }

    /**
     * @dev Emitted when collection is created
     */
    event CollectionCreated(
        uint96 indexed typeId,
        address indexed collectionAddress
    );

    /**
     * @dev Emitted when user rate is updated
     */
    event UserRateUpdated(address indexed user, uint256 indexed rate);

    /**
     * @dev Emitted when user rate is removed
     */
    event UserRateRemoved(address indexed user, uint256 indexed rate);

    /**
     * @dev Returns the commission amount.
     */
    function commission(address collection, uint256 amount)
        external
        view
        returns (uint256);

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