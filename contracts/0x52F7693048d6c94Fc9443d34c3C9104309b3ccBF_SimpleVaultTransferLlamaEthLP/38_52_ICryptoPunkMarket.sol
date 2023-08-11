// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Interface for CryptoPunkMarket
 */
interface ICryptoPunkMarket {
    /**
     * @notice offer made on a punk
     * @param isForSale indicates whether punk may be bought instantly
     * @param punkIndex the index of punk
     * @param minValue the minimum price of punk in WEI
     * @param onlySellTo if specified, is the only address a punk may be sold to
     */
    struct Offer {
        bool isForSale;
        uint256 punkIndex;
        address seller;
        uint256 minValue;
        address onlySellTo;
    }

    /**
     * @notice bid on a punk
     * @param hasBid deprecated  (used nowhere in CryptoPunkMarket contract)
     * @param punkIndex the index of the punk
     * @param bidder the address which made the bid
     * @param value the value of the bid in WEI
     */
    struct Bid {
        bool hasBid;
        uint256 punkIndex;
        address bidder;
        uint256 value;
    }

    /**
     * @notice returns  highest bid on a punk
     * @param punkIndex the index of the punk
     * @return highest bid on the punk
     */
    function punkBids(uint256 punkIndex) external view returns (Bid memory);

    /**
     * @notice public mapping(uint => Offer) punksOfferedForSale;
     * @param punkIndex the index of the punk
     * @return offer currently active on the punk
     */
    function punksOfferedForSale(
        uint256 punkIndex
    ) external view returns (Offer memory);

    /**
     * @notice public mapping(uint => address) punkIndexToAddress;
     * @param punkIndex index of the punk
     * @return address to which the punk belongs to (or is assigned to)
     */
    function punkIndexToAddress(
        uint256 punkIndex
    ) external view returns (address);

    /**
     * @notice mapping(address => uint256) pendingWithdrawals mapping
     * @param withdrawer address to which withdrawal is owed
     * @return uint amount pending in ETH
     */
    function pendingWithdrawals(
        address withdrawer
    ) external view returns (uint256);

    /**
     * @notice purchase a punk
     * @param punkIndex index of punk
     */
    function buyPunk(uint256 punkIndex) external payable;

    /**
     * @notice opens punk to instant purchase
     * @param punkIndex the index of the punk
     * @param minSalePriceInWei the minimum sale price of the punk in WEI
     */
    function offerPunkForSale(
        uint256 punkIndex,
        uint256 minSalePriceInWei
    ) external;

    /**
     * @notice closes punk to instance purchase
     * @param punkIndex index of punk
     */
    function punkNoLongerForSale(uint256 punkIndex) external;

    /**
     * @notice withdraws pending amount after punk sale
     */
    function withdraw() external;

    /**
     * @notice transfers a punk without a sale
     * @param to address to transfer punk to
     * @param punkIndex index of punk
     */
    function transferPunk(address to, uint256 punkIndex) external;

    /**
     * @notice accept a bid on a punk
     * @dev note that the minPrice parameter checks that the bid to be accepted must be larger than some
     * price defined by the caller of acceptBidForPunk to ensure the punk is not undersold.
     * @param punkIndex index of punk
     * @param minPrice minimum price of the bid in WEI
     */
    function acceptBidForPunk(uint256 punkIndex, uint256 minPrice) external;

    /**
     * @notice withdraw a bid on a punk
     * @param punkIndex punk index
     */
    function withdrawBidForPunk(uint256 punkIndex) external;

    /**
     * @notice enter a bid on a punk
     * @dev the bid amount is the msg.value attached to this call
     * @param punkIndex punk index
     */
    function enterBidForPunk(uint256 punkIndex) external payable;
}