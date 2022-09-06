// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract NftAuction is
    AccessControlEnumerable,
    Pausable,
    ReentrancyGuard,
    ERC721Holder
{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    bytes32 public constant ARTIST_ROLE = keccak256("ARTIST_ROLE");

    Offer[] public offers;

    mapping(address => mapping(uint256 => bool)) public offerExistence; // offerExistence[nftAddress][tokenId]

    mapping(address => mapping(uint256 => uint256)) public refunds; // refunds[address][tokenId] = amount

    uint256 public maxFee; // basis points

    struct Offer {
        uint256 tokenId;
        IERC721 nft;
        uint256 minBid;
        uint256 maxBid;
        uint256 currentBid;
        uint256 startTimestamp;
        uint256 endTimestamp;
        address bidder;
        uint256 artistFee; // basis points
        bool exists;
        bool closed;
        address payable artistAddress;
        address payable charityAddress;
    }

    event CreateOffer(
        uint256 offerId,
        uint256 tokenId,
        address nft,
        uint256 minBid,
        uint256 maxBid,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 artistFee,
        address artistAddress,
        address charityAddress
    );

    event MakeBid(uint256 offerId, uint256 amount);

    event WithdrawRefund(uint256 offerId, uint256 amount);

    event CloseOffer(uint256 offerId, address recipient, uint256 amount);

    event CancelOffer(uint256 offerId);

    event ChangeMaxFee(uint256 maxFee);

    modifier onlyArtistOrAdmin() {
        require(
            hasRole(ARTIST_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(ADMIN_ROLE, msg.sender),
            "Artist or admin only"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(ADMIN_ROLE, msg.sender),
            "Admin only"
        );
        _;
    }

    modifier completedOfferOnly(uint256 offerId) {
        require(
            offers.length > offerId && offers[offerId].exists,
            "Offer does not exist"
        );
        require(!offers[offerId].closed, "Offer already closed");
        require(
            block.timestamp >= offers[offerId].endTimestamp ||
                (offers[offerId].maxBid > 0 &&
                    offers[offerId].currentBid >= offers[offerId].maxBid),
            "Offer is active"
        );
        _;
    }

    constructor(uint256 _maxFee) {
        maxFee = _maxFee;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function createOffer(
        uint256 tokenId,
        IERC721 nft,
        uint256 minBid,
        uint256 maxBid,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 artistFee,
        address payable artistAddress,
        address payable charityAddress
    ) external onlyArtistOrAdmin whenNotPaused {
        address nftAddress = address(nft);

        require(
            !offerExistence[nftAddress][tokenId],
            "Offer for this token already exists"
        );
        require(artistFee <= maxFee, "Fee is too high");
        require(artistAddress != address(0), "Wrong artist address");
        require(charityAddress != address(0), "Wrong charity address");
        require(
            maxBid == 0 || maxBid >= minBid,
            "Max bid must be equal or bigger than min bid"
        );
        require(
            endTimestamp >= block.timestamp,
            "End timestamp can not be in past"
        );
        require(
            endTimestamp > startTimestamp,
            "End timestamp must be bigger than start timestamp"
        );

        // Send NFT token to auction contract
        nft.transferFrom(msg.sender, address(this), tokenId);

        offers.push(
            Offer({
                tokenId: tokenId,
                nft: nft,
                minBid: minBid,
                maxBid: maxBid,
                currentBid: 0,
                startTimestamp: startTimestamp,
                endTimestamp: endTimestamp,
                bidder: address(0),
                artistFee: artistFee,
                exists: true,
                closed: false,
                artistAddress: artistAddress,
                charityAddress: charityAddress
            })
        );

        offerExistence[nftAddress][tokenId] = true;

        emit CreateOffer(
            offers.length - 1,
            tokenId,
            nftAddress,
            minBid,
            maxBid,
            startTimestamp,
            endTimestamp,
            artistFee,
            artistAddress,
            charityAddress
        );
    }

    /**
     * Close completed offer with active bid and send NFT token to max bidder
     */
    function closeOffer(uint256 offerId)
        external
        whenNotPaused
        completedOfferOnly(offerId)
    {
        require(offers[offerId].currentBid > 0, "Offer has no bids");

        offers[offerId].closed = true;
        offerExistence[address(offers[offerId].nft)][
            offers[offerId].tokenId
        ] = false; // allow to create offers for this token in the future

        purchaseItem(offers[offerId].bidder, offerId);

        emit CloseOffer(
            offerId,
            offers[offerId].bidder,
            offers[offerId].currentBid
        );
    }

    /**
     * Cancel completed offer w/o active bids and return NFT token to artist
     */
    function cancelOffer(uint256 offerId)
        external
        whenNotPaused
        completedOfferOnly(offerId)
    {
        require(offers[offerId].currentBid == 0, "Offer has bids");

        offers[offerId].closed = true;
        offerExistence[address(offers[offerId].nft)][
            offers[offerId].tokenId
        ] = false; // allow to create offers for this token in the future

        offers[offerId].nft.transferFrom(
            address(this),
            offers[offerId].artistAddress,
            offers[offerId].tokenId
        );

        emit CancelOffer(offerId);
    }

    function getOffersCount() external view returns (uint256) {
        return offers.length;
    }

    function getOffers() external view returns (Offer[] memory) {
        return offers;
    }

    function makeBid(uint256 offerId) external payable whenNotPaused {
        require(
            offers.length > offerId && offers[offerId].exists,
            "Offer does not exist"
        );
        require(!offers[offerId].closed, "Offer closed");
        require(
            block.timestamp >= offers[offerId].startTimestamp,
            "Offer is not open yet"
        );
        require(
            block.timestamp < offers[offerId].endTimestamp,
            "Offer has ended"
        );
        require(
            offers[offerId].maxBid == 0 ||
                offers[offerId].currentBid < offers[offerId].maxBid,
            "Max bid already placed"
        );
        require(
            msg.value >= offers[offerId].minBid,
            "Amount must be equal or bigger than min bid"
        );
        require(
            msg.value > offers[offerId].currentBid,
            "Amount must be bigger than current bid"
        );

        if (offers[offerId].currentBid > 0) {
            addRefund(
                offerId,
                offers[offerId].bidder,
                offers[offerId].currentBid
            );
        }

        offers[offerId].currentBid = msg.value;
        offers[offerId].bidder = msg.sender;

        emit MakeBid(offerId, msg.value);
    }

    function withdrawRefund(uint256 offerId)
        external
        whenNotPaused
        nonReentrant
    {
        uint256 refundAmount = refunds[msg.sender][offerId];

        require(refundAmount > 0, "No funds found for refund");

        refunds[msg.sender][offerId] = 0;

        Address.sendValue(payable(msg.sender), refundAmount);

        emit WithdrawRefund(offerId, refundAmount);
    }

    function addRefund(
        uint256 offerId,
        address bidder,
        uint256 value
    ) internal {
        refunds[bidder][offerId] += value;
    }

    function getRefunds(address bidder)
        external
        view
        returns (uint256[] memory)
    {
        uint256 offersLength = offers.length;
        uint256[] memory bidderRefunds = new uint256[](offersLength);

        for (uint256 offerId = 0; offerId < offersLength; offerId++) {
            bidderRefunds[offerId] = refunds[bidder][offerId];
        }

        return bidderRefunds;
    }

    function getRefund(address bidder, uint256 offerId)
        external
        view
        returns (uint256)
    {
        return refunds[bidder][offerId];
    }

    function purchaseItem(address recipient, uint256 offerId)
        internal
        nonReentrant
    {
        offers[offerId].nft.transferFrom(
            address(this),
            recipient,
            offers[offerId].tokenId
        ); // do not use safe transfer to prevent stuck of money in auction contract

        uint256 artistAmount = (offers[offerId].currentBid *
            offers[offerId].artistFee) / 10000;
        uint256 charityAmount = offers[offerId].currentBid - artistAmount;

        Address.sendValue(offers[offerId].artistAddress, artistAmount);
        Address.sendValue(offers[offerId].charityAddress, charityAmount);
    }

    function changeMaxFee(uint256 _maxFee) external onlyAdmin {
        maxFee = _maxFee;

        emit ChangeMaxFee(maxFee);
    }

    function pause() external onlyAdmin {
        super._pause();
    }

    function unpause() external onlyAdmin {
        super._unpause();
    }
}