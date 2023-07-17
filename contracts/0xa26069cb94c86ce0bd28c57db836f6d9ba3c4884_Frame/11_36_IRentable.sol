//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRentable {
    struct Rental {
        address renter;
        uint256 rentalExpiryBlock;
    }

    /**
     * @notice Triggered when a renter has been set
     * @param _tokenId           Token identifier which is setting a renter
     * @param _renter            The new renter address
     * @param _rentalExpiryBlock The block the rental expires at
     */
    event RenterSet(uint256 indexed _tokenId, address indexed _renter, uint256 _rentalExpiryBlock);

    /**
     * @notice Set a renter for a tokenId
     * @param _tokenId        Token identifier which is setting a renter
     * @param _renter         The new renter address
     * @param _numberOfBlocks The number of blocks to rent for
     */
    function setRenter(
        uint256 _tokenId,
        address _renter,
        uint256 _numberOfBlocks
    ) external payable;

    /**
     * @notice Get a renter for a tokenId
     * @param _tokenId        Token identifier which is setting a renter
     */
    function getRenter(uint256 _tokenId) external view returns (Rental memory);

    /**
     * @notice Set the rental price per block for a tokenId
     * @param _tokenId        Token identifier which is setting a renter
     * @param _rentalPrice    The rental price per block
     */
    function setRentalPricePerBlock(uint256 _tokenId, uint256 _rentalPrice) external;

    /**
     * @notice Get the rental price per block for a tokenId
     * @param _tokenId        Token identifier which is setting a renter
     */
    function getRentalPricePerBlock(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Calculate rental cost to send to setRenter function
     * @param _tokenId        Token identifier to calculate for
     * @param _numberOfBlocks Number of blocks to rent for
     */
    function calculateRentalCost(uint256 _tokenId, uint256 _numberOfBlocks)
        external
        view
        returns (uint256);

    /**
     * @notice Checks if a token is currently rented by anyone
     * @param _tokenId The token to check is rented
     */
    function isCurrentlyRented(uint256 _tokenId) external view returns (bool);

    /**
     * @notice Checks if a token is currently rented by address
     * @param _tokenId The token to check is rented
     * @param _address The address to check if it's rented by
     */
    function tokenIsRentedByAddress(uint256 _tokenId, address _address)
        external
        view
        returns (bool);
}