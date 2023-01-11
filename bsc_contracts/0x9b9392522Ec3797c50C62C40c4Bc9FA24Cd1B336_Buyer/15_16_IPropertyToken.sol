// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IPropertyToken {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function emergencyTransfer(
        uint256 collectionID,
        uint256 listing_id,
        address new_owner,
        bool _active
    ) external;

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */

    struct Listing {
        uint256 listing_id;
        address owner;
        bool is_active;
        uint256 token_id;
        uint256 price;
    }

    function getListing(
        uint256 collectionID,
        uint256 listing_id
    ) external view returns (Listing memory listing);
}