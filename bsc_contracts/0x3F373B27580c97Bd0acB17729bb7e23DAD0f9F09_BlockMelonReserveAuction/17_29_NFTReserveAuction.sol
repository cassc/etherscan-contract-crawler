// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/IAdminRole.sol";
import "../utils/ERC721TokenReceiver.sol";
import "../payment/BlockMelonNFTPaymentManager.sol";

/**
 * @notice An abstraction layer for a token market.
 */
abstract contract NFTReserveAuction is
    ContextUpgradeable,
    BlockMelonNFTPaymentManager,
    ERC721TokenReceiver
{
    using AddressUpgradeable for address;

    struct Auction {
        address tokenContract;
        uint256 tokenId;
        address payable seller;
        uint256 duration;
        uint256 extensionDuration;
        uint256 endTime;
        address payable bidder;
        uint256 price;
    }

    event ReserveAuctionConfigUpdated(
        uint256 minPercentIncrementInBasisPoints,
        uint256 duration
    );
    event AuctionCreated(
        address indexed seller,
        address indexed tokenContract,
        uint256 indexed tokenId,
        uint256 duration,
        uint256 extensionDuration,
        uint256 reservePrice,
        uint256 auctionId
    );
    event AuctionUpdated(
        uint256 indexed auctionId,
        uint256 indexed newReservePrice
    );
    event ReserveAuctionBidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 price,
        uint256 endTime
    );
    event AuctionFinalized(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed bidder,
        uint256 blockMelonRevenue,
        uint256 creatorRevenue,
        uint256 sellerRevenue,
        uint256 firstOwnerRevenue
    );
    event AuctionCanceled(uint256 indexed auctionId);
    event AuctionCanceledByAdmin(uint256 indexed auctionId, string reason);
    event AdminContractUpdated(address indexed adminContract);

    /// @dev Indicates the maximum duration of an acution
    uint256 private constant MAX_DURATION = 365 days;
    /// @dev Indicates the extension duration of an acution
    uint256 private constant EXTENSION_DURATION = 15 minutes;
    uint256 private constant BASIS_POINTS = 10000;
    ///@dev The contract address which manages admin accounts
    IAdminRole public adminContract;
    /// @dev Keeps track of each NFT auction per token contract
    mapping(address => mapping(uint256 => uint256))
        private _nftContractToTokenIdToAuctionId;
    /// @dev Mapping from each auction id to its auction data
    mapping(uint256 => Auction) private _auctionIdToAuction;
    /// @dev Indicates the minimum required amount for a bid increment [bps]
    uint256 private _minPercentIncrementInBasisPoints;
    /// @dev Indicates the duration of an acution
    uint256 private _duration;
    /// @dev The id of the current auction
    uint256 private _auctionId;

    modifier onlyValidAuctionConfig(uint256 price) {
        require(price > 0, "Price must be > 0");
        _;
    }

    modifier onlyBlockMelonAdmin() {
        require(
            adminContract.isAdmin(_msgSender()),
            "caller is not a BlockMelon admin"
        );
        _;
    }

    function __NFTReserveAuction_init_unchained() internal onlyInitializing {
        _auctionId = 1;
        _duration = 24 hours;
        _minPercentIncrementInBasisPoints = 1000; // 10% by default
    }

    function _updateAdminContract(address _adminContract) internal {
        require(_adminContract.isContract(), "adminContract is not a contract");
        adminContract = IAdminRole(_adminContract);

        emit AdminContractUpdated(_adminContract);
    }

    /**
     * @notice Returns auction details for a given auctionId.
     */
    function getAuction(uint256 auctionId)
        public
        view
        returns (Auction memory)
    {
        return _auctionIdToAuction[auctionId];
    }

    /**
     * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
     * @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
     */
    function getAuctionIdFor(address tokenContract, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _nftContractToTokenIdToAuctionId[tokenContract][tokenId];
    }

    /**
     * @notice Returns the current configuration for reserve auctions.
     */
    function getReserveAuctionConfig()
        public
        view
        returns (uint256 minPercentIncrementInBasisPoints, uint256 duration)
    {
        minPercentIncrementInBasisPoints = _minPercentIncrementInBasisPoints;
        duration = _duration;
    }

    function _getNextAndIncrementAuctionId() internal returns (uint256) {
        return _auctionId++;
    }

    function _updateReserveAuctionConfig(
        uint256 minPercentIncrementInBasisPoints,
        uint256 duration
    ) internal {
        require(
            minPercentIncrementInBasisPoints <= BASIS_POINTS,
            "Min increment must be <= 100%"
        );
        require(duration <= MAX_DURATION, "Duration must be <= 365 days");
        require(
            duration >= EXTENSION_DURATION,
            "Duration must be >= EXTENSION_DURATION"
        );
        _minPercentIncrementInBasisPoints = minPercentIncrementInBasisPoints;
        _duration = duration;

        emit ReserveAuctionConfigUpdated(
            minPercentIncrementInBasisPoints,
            duration
        );
    }

    /**
     * @notice Creates an auction for the given NFT.
     *         The NFT is held in escrow until the auction is finalized or canceled.
     */
    function createReserveAuction(
        address tokenContract,
        uint256 tokenId,
        uint256 price
    ) public onlyValidAuctionConfig(price) nonReentrant {
        // If an auction is already in progress then the NFT would be in escrow and the modifier would have failed
        uint256 auctionId = _getNextAndIncrementAuctionId();
        _nftContractToTokenIdToAuctionId[tokenContract][tokenId] = auctionId;

        _auctionIdToAuction[auctionId] = Auction(
            tokenContract,
            tokenId,
            payable(_msgSender()),
            _duration,
            EXTENSION_DURATION,
            0, // endTime is only known once the reserve price is met
            payable(address(0)), // bidder is only known once a bid has been placed
            price
        );

        IERC721Upgradeable(tokenContract).safeTransferFrom(
            _msgSender(),
            address(this),
            tokenId
        );

        emit AuctionCreated(
            _msgSender(),
            tokenContract,
            tokenId,
            _duration,
            EXTENSION_DURATION,
            price,
            auctionId
        );
    }

    /**
     * @notice If an auction has been created but has not yet received bids, the configuration
     *          such as the reserve price may be changed by the seller.
     */
    function updateAuction(uint256 auctionId, uint256 newReservePrice)
        public
        onlyValidAuctionConfig(newReservePrice)
    {
        Auction storage auction = _auctionIdToAuction[auctionId];
        require(auction.seller == payable(_msgSender()), "Not your auction");
        require(auction.endTime == 0, "Auction in progress");

        auction.price = newReservePrice;

        emit AuctionUpdated(auctionId, newReservePrice);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
     * The NFT is returned to the seller from escrow.
     */
    function cancelAuction(uint256 auctionId) public nonReentrant {
        Auction memory auction = _auctionIdToAuction[auctionId];
        require(auction.seller == payable(_msgSender()), "Not your auction");
        require(auction.endTime == 0, "Auction in progress");

        delete _nftContractToTokenIdToAuctionId[auction.tokenContract][
            auction.tokenId
        ];
        delete _auctionIdToAuction[auctionId];

        IERC721Upgradeable(auction.tokenContract).safeTransferFrom(
            address(this),
            auction.seller,
            auction.tokenId
        );

        emit AuctionCanceled(auctionId);
    }

    /**
     * @notice A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
     * If this is the first bid on the auction, the countdown will begin.
     * If there is already an outstanding bid, the previous bidder will be refunded at this time
     * and if the bid is placed in the final moments of the auction, the countdown may be extended.
     */
    function placeBid(uint256 auctionId) public payable nonReentrant {
        Auction storage auction = _auctionIdToAuction[auctionId];
        require(auction.price != 0, "Auction not found");

        if (auction.endTime == 0) {
            // If this is the first bid, ensure it's >= the reserve price
            require(
                auction.price <= msg.value,
                "Bid must be at least the reserve price"
            );
        } else {
            // If this bid outbids another, confirm that the bid is at least x% greater than the last
            require(auction.endTime >= block.timestamp, "Auction is over");
            require(
                auction.bidder != payable(_msgSender()),
                "You already have an outstanding bid"
            );
            uint256 minAmount = _getMinBidAmountForReserveAuction(
                auction.price
            );
            require(msg.value >= minAmount, "Bid amount too low");
        }

        if (auction.endTime == 0) {
            auction.price = msg.value;
            auction.bidder = payable(_msgSender());
            // On the first bid, the endTime is now + duration
            auction.endTime = block.timestamp + auction.duration;
        } else {
            // Cache and update bidder state before a possible reentrancy (via the value transfer)
            uint256 originalAmount = auction.price;
            address payable originalBidder = auction.bidder;
            auction.price = msg.value;
            auction.bidder = payable(_msgSender());

            // When a bid outbids another, check to see if a time extension should apply.
            if (auction.endTime - block.timestamp < auction.extensionDuration) {
                auction.endTime = block.timestamp + auction.extensionDuration;
            }

            // Refund the previous bidder
            _sendValueToRecipient(originalBidder, originalAmount);
        }

        emit ReserveAuctionBidPlaced(
            auctionId,
            _msgSender(),
            msg.value,
            auction.endTime
        );
    }

    /**
     * @notice Once the countdown has expired for an auction, anyone can settle the auction.
     * This will send the NFT to the highest bidder and distribute funds.
     */
    function finalizeReserveAuction(uint256 auctionId) public nonReentrant {
        Auction memory auction = _auctionIdToAuction[auctionId];
        require(auction.endTime > 0, "Auction was already settled");
        require(auction.endTime < block.timestamp, "Auction still in progress");

        delete _nftContractToTokenIdToAuctionId[auction.tokenContract][
            auction.tokenId
        ];
        delete _auctionIdToAuction[auctionId];

        // cache the first owner address before transfer, as _transfer may set it
        address payable firstOwnerAddress = _getFirstOwnerPaymentInfo(
            auction.tokenContract,
            auction.tokenId
        );

        IERC721Upgradeable(auction.tokenContract).safeTransferFrom(
            address(this),
            auction.bidder,
            auction.tokenId
        );

        Revenues memory revs = _payRecipients(
            auction.tokenContract,
            auction.seller,
            firstOwnerAddress,
            auction.tokenId,
            auction.price
        );

        emit AuctionFinalized(
            auctionId,
            auction.seller,
            auction.bidder,
            revs.marketRevenue,
            revs.creatorRevenue,
            revs.sellerRevenue,
            revs.firstOwnerRevenue
        );
    }

    /**
     * @notice Returns the minimum amount a bidder must spend to participate in an auction.
     */
    function getMinBidAmount(uint256 auctionId) public view returns (uint256) {
        Auction storage auction = _auctionIdToAuction[auctionId];
        if (auction.endTime == 0) {
            return auction.price;
        }
        return _getMinBidAmountForReserveAuction(auction.price);
    }

    /**
     * @dev Determines the minimum bid amount when outbidding another user.
     */
    function _getMinBidAmountForReserveAuction(uint256 currentBidAmount)
        private
        view
        returns (uint256)
    {
        uint256 minIncrement = (currentBidAmount *
            _minPercentIncrementInBasisPoints) / BASIS_POINTS;
        if (minIncrement == 0) {
            // The next bid must be at least 1 wei greater than the current.
            return currentBidAmount++;
        }
        return minIncrement + currentBidAmount;
    }

    /**
     * @notice Allows BlockMelon to cancel an auction, refunding the bidder and returning the NFT to the seller.
     * This should only be used for extreme cases such as DMCA takedown requests. The reason should always be provided.
     */
    function adminCancelAuction(uint256 auctionId, string memory reason)
        public
        onlyBlockMelonAdmin
    {
        require(
            bytes(reason).length > 0,
            "Include a reason for this cancellation"
        );
        Auction memory auction = _auctionIdToAuction[auctionId];
        require(auction.price > 0, "Auction not found");

        delete _nftContractToTokenIdToAuctionId[auction.tokenContract][
            auction.tokenId
        ];
        delete _auctionIdToAuction[auctionId];

        IERC721Upgradeable(auction.tokenContract).safeTransferFrom(
            address(this),
            auction.seller,
            auction.tokenId
        );

        if (auction.bidder != address(0)) {
            _sendValueToRecipient(auction.bidder, auction.price);
        }

        emit AuctionCanceledByAdmin(auctionId, reason);
    }

    uint256[50] private __gap;
}