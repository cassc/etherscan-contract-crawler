// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title NFTKEY Life interface
 */
interface ILife {
    struct Listing {
        bool isForSale;
        uint256 bioId;
        address seller;
        uint256 minValue;
        address onlySellTo;
        uint256 timestamp;
    }

    struct Bid {
        bool hasBid;
        uint256 bioId;
        address bidder;
        uint256 value;
        uint256 timestamp;
    }

    event BioMinted(uint256 indexed bioId, address indexed owner, uint8[] bioDNA, bytes32 bioHash);
    event BioListed(
        uint256 indexed bioId,
        uint256 minValue,
        address indexed fromAddress,
        address indexed toAddress
    );
    event BioDelisted(uint256 indexed bioId, address indexed fromAddress);
    event BioBidEntered(uint256 indexed bioId, uint256 value, address indexed fromAddress);
    event BioBidWithdrawn(uint256 indexed bioId, uint256 value, address indexed fromAddress);
    event BioBidRemoved(uint256 indexed bioId, address indexed fromAddress);
    event BioBought(
        uint256 indexed bioId,
        uint256 value,
        address indexed fromAddress,
        address indexed toAddress
    );
    event BioBidAccepted(
        uint256 indexed bioId,
        uint256 value,
        address indexed fromAddress,
        address indexed toAddress
    );

    /**
     * @dev Gets DNA encoding of a Bio by token Id
     * @param bioId Bio token Id
     * @return Bio DNA encoding
     */
    function getBioDNA(uint256 bioId) external view returns (uint8[] memory);

    /**
     * @dev Gets DNA encoding of a Bios
     * @param from From Bio id
     * @param size Query size
     * @return Bio DNAs
     */
    function getBioDNAs(uint256 from, uint256 size) external view returns (uint8[][] memory);

    /**
     * @dev Gets current Bio Price
     * @return Current Bio Price
     */
    function getBioPrice() external view returns (uint256);

    /**
     * @dev Check if a Bio is already minted or not
     * @param bioDNA Bio DNA encoding
     * @return If Bio exist, or if similar Bio exist
     */
    function isBioExist(uint8[] memory bioDNA) external view returns (bool);

    /**
     * @dev Mint Bio
     * @param bioDNA Bio DNA encoding
     */
    function mintBio(uint8[] memory bioDNA) external payable;

    /**
     * @dev Get Bio listing information
     * @param bioId Bio token id
     * @return Bio Listing detail
     */
    function getBioListing(uint256 bioId) external view returns (Listing memory);

    /**
     * @dev Get Bio listings
     * @param from From Bio id
     * @param size Query size
     * @return Bio Listings
     */
    function getBioListings(uint256 from, uint256 size) external view returns (Listing[] memory);

    /**
     * @dev Get Bio bid information
     * @param bioId Bio token id
     * @return Bio bid detail
     */
    function getBioBid(uint256 bioId) external view returns (Bid memory);

    /**
     * @dev Get Bio bids
     * @param from From Bio id
     * @param size Query size
     * @return Bio bids
     */
    function getBioBids(uint256 from, uint256 size) external view returns (Bid[] memory);

    /**
     * @dev List a Bio for sale
     * @param bioId Bio token id
     * @param minValue Bio minimum value
     */
    function listBioForSale(uint256 bioId, uint256 minValue) external;

    /**
     * @dev List a Bio for sale to a certain address
     * @param bioId Bio token id
     * @param minValue Bio minimum value
     * @param toAddress Address to sell this Bio to
     */
    function listBioForSaleToAddress(
        uint256 bioId,
        uint256 minValue,
        address toAddress
    ) external;

    /**
     * @dev Delist a Bio
     * @param bioId Bio token id
     */
    function delistBio(uint256 bioId) external;

    /**
     * @dev Buy a Bio
     * @param bioId Bio token id
     */
    function buyBio(uint256 bioId) external payable;

    /**
     * @dev Put bid on a Bio
     * @param bioId Bio token id
     */
    function enterBidForBio(uint256 bioId) external payable;

    /**
     * @dev Accept s bid for a Bio
     * @param bioId Bio token id
     */
    function acceptBidForBio(uint256 bioId) external;

    /**
     * @dev Withdraw s bid for a Bio
     * @param bioId Bio token id
     */
    function withdrawBidForBio(uint256 bioId) external;

    /**
     * @dev Returns service fee.
     * @return The first value is fraction, the second one is fraction base
     */
    function serviceFee() external view returns (uint8, uint8);

    /**
     * @dev Get pending withdrawals
     * @param toAddress Address to check withdrawals
     */
    function pendingWithdrawals(address toAddress) external view returns (uint256);

    /**
     * @dev Withdraw ether from this contract
     */
    function withdraw() external;
}