// SPDX-License-Identifier: CC0
pragma solidity ^0.8.10;

import "./IERC4907.sol";

/**
 * @dev Required interface of an ERC4907Rentable compliant contract.
 */
interface IERC4907Rentable is IERC4907 {
    /**
     * @dev This emits when the rental rate of an NFT changes.
     */
    event UpdateRate(uint256 indexed tokenId, uint256 rate);

    /**
     * @notice Rent an NFT for a period of time
     * @dev Emit the {UpdateUser} event. This function is called by the renter,
     *  while {setUser} is called by the owner or approved operators.
     * @param tokenId The identifier for an NFT
     * @param duration The duration of rental
     */
    function rent(uint256 tokenId, uint64 duration) external payable;

    /**
     * @notice Set the rental price per second for an NFT
     * @dev Emit the {UpdateRate} event.
     * @param tokenId The identifier for an NFT
     * @param rate The rental price per second
     */
    function setRate(uint256 tokenId, uint256 rate) external;

    /**
     * @notice Query the rental price for an NFT
     * @dev A zero rate indicates the NFT is not available for rent.
     * @param tokenId The identifier for an NFT
     * @return The rental price per second, or zero if not available for rent
     */
    function rateOf(uint256 tokenId) external view returns (uint256);
}