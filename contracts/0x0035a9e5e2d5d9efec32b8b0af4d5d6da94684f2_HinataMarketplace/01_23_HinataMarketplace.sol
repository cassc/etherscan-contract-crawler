// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../interfaces/ICollectionFactory.sol";

contract HinataMarketplace is
    Initializable,
    IERC721ReceiverUpgradeable,
    IERC1155ReceiverUpgradeable,
    UUPSUpgradeable,
    AccessControl,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event ListingCreated(
        uint256 indexed listingId,
        address indexed seller,
        address payToken,
        uint128 price,
        uint128 reservePrice,
        uint64 startTime,
        uint64 duration,
        uint64 quantity,
        ListingType listingType,
        address[] collections,
        uint256[] tokenIds,
        uint256[] tokenAmounts
    );

    event ListingPurchased(uint256 indexed listingId, address seller, address buyer);

    event ListingUpdated(
        uint256 indexed listingId,
        uint128 newPrice,
        uint64 newStartTime,
        uint64 newDuration,
        uint64 newQuantity
    );

    event ListingRestarted(uint256 indexed listingId, uint64 startTime);

    event ListingCancelled(uint256 indexed listingId);

    event BidUpdated(uint256 indexed listingId, address indexed bidder, uint256 bidAmount);

    enum ListingType {
        FIXED_PRICE,
        INVENTORIED_FIXED_PRICE,
        TIME_LIMITED_WINNER_TAKE_ALL_AUCTION,
        TIERED_1_OF_N_AUCTION,
        TIME_LIMITED_PRICE_PER_TICKET_RAFFLE,
        TIME_LIMITED_1_OF_N_WINNING_TICKETS_RAFFLE
    }

    struct Listing {
        uint256 id;
        address seller;
        address payToken;
        uint128 price;
        uint128 reservePrice;
        uint64 startTime;
        uint64 duration;
        uint64 quantity;
        ListingType listingType;
        address[] collections;
        uint256[] tokenIds;
        uint256[] tokenAmounts;
    }

    struct Bidding {
        address bidder;
        uint256 bidAmount;
    }

    uint256 private constant MAX_DURATION = 120 * 86400;
    uint256 public marketFee;
    address public beneficiary;
    ICollectionFactory public factory;

    mapping(address => bool) public acceptPayTokens;

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Bidding) public biddings;
    mapping(uint256 => bool) public usedIDs;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Ownable: caller is not the owner");
        _;
    }

    modifier checkSeller(uint256 listingId, bool should) {
        require(
            (listings[listingId].seller == msg.sender) == should,
            should ? "HinataMarket: NOT_SELLER" : "HinataMarket: IS_SELLER"
        );
        _;
    }

    function initialize(
        address[] memory owners,
        address factory_,
        address beneficiary_,
        uint256 marketFee_
    ) public initializer {
        require(factory_ != address(0), "HinataMarket: INVALID_FACTORY");
        require(beneficiary_ != address(0), "HinataMarket: INVALID_BENEFICIARY");
        require(marketFee_ <= 10000, "HinataMarket: INVALID_FEE");

        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        factory = ICollectionFactory(factory_);
        beneficiary = beneficiary_;
        marketFee = marketFee_;

        uint256 len = owners.length;
        for (uint256 i; i < len; i += 1) {
            _setupRole(DEFAULT_ADMIN_ROLE, owners[i]);
        }
    }

    function _authorizeUpgrade(address) internal override onlyAdmin {}

    function setAcceptPayToken(address payToken, bool accept) external onlyAdmin {
        require(payToken != address(0), "HinataMarket: INVALID_PAY_TOKEN");
        acceptPayTokens[payToken] = accept;
    }

    function setBeneficiary(address beneficiary_) external onlyAdmin {
        require(beneficiary_ != address(0), "HinataMarket: INVALID_BENEFICIARY");
        beneficiary = beneficiary_;
    }

    function setMarketFee(uint256 marketFee_) external onlyAdmin {
        require(marketFee_ <= 10000, "HinataMarket: INVALID_FEE");
        marketFee = marketFee_;
    }

    function setFactory(address factory_) external onlyAdmin {
        factory = ICollectionFactory(factory_);
    }

    function withdrawFunds(address token, address to) external onlyAdmin {
        IERC20Upgradeable erc20Token = IERC20Upgradeable(token);
        erc20Token.safeTransfer(to, erc20Token.balanceOf(address(this)));
    }

    function createListing(Listing memory listing) external nonReentrant {
        require(!usedIDs[listing.id], "HinataMarket: ALREADY_USED_ID");
        require(acceptPayTokens[listing.payToken], "HinataMarket: INVALID_PAY_TOKEN");
        require(listing.reservePrice >= listing.price, "HinataMarket: RESERVE_PRICE_LOW");
        if (listing.listingType == ListingType.INVENTORIED_FIXED_PRICE) {
            require(
                listing.quantity > 0 && _isValidatedListing(listing.tokenAmounts, listing.quantity),
                "HinataMarket: INVALID_LISTING"
            );
        }

        listing.seller = msg.sender;
        if (listing.startTime < uint64(block.timestamp))
            listing.startTime = uint64(block.timestamp);

        listings[listing.id] = listing;
        usedIDs[listing.id] = true;

        listing.tokenAmounts = _transferNFTs(listing.id, msg.sender, address(this));

        emit ListingCreated(
            listing.id,
            msg.sender,
            listing.payToken,
            listing.price,
            listing.reservePrice,
            listing.startTime,
            listing.duration,
            listing.quantity,
            listing.listingType,
            listing.collections,
            listing.tokenIds,
            listing.tokenAmounts
        );
    }

    function restartListing(uint256 listingId) external checkSeller(listingId, true) {
        Listing storage listing = listings[listingId];
        require(!_isActiveListing(listingId), "HinataMarket: STILL_ACTIVE");
        listing.startTime = uint64(block.timestamp);
        emit ListingRestarted(listingId, listing.startTime);
    }

    function updateListing(
        uint256 listingId,
        uint128 newPrice,
        uint64 newStartTime,
        uint64 newDuration,
        uint64 newQuantity
    ) external checkSeller(listingId, true) {
        Listing storage listing = listings[listingId];
        if (listing.price != newPrice) {
            require(listing.price > newPrice, "HinataMarket: NEW_PRIICE_BIG");
            listing.price = newPrice;
        }
        if (listing.startTime != newStartTime) {
            require(block.timestamp < listing.startTime, "HinataMarket: ALREADY_STARTED");
            require(block.timestamp < newStartTime, "HinataMarket: NEW_TIME_PAST");
            listing.startTime = newStartTime;
        }

        if (listing.duration != newDuration) listing.duration = newDuration;
        if (listing.quantity != newQuantity) {
            require(
                _isValidatedListing(listing.tokenAmounts, newQuantity),
                "HinataMarket: NEW_QUANTITY_INVALID"
            );
            listing.quantity = newQuantity;
        }

        emit ListingUpdated(listingId, newPrice, newStartTime, newDuration, newQuantity);
    }

    function cancelListing(uint256 listingId) external checkSeller(listingId, true) nonReentrant {
        Listing storage listing = listings[listingId];
        Bidding storage bidding = biddings[listingId];
        if (bidding.bidder != address(0)) {
            require(
                listing.reservePrice > listing.price && bidding.bidAmount < listing.reservePrice,
                "HinataMarket: VALID_BID_EXISTS"
            );
            IERC20Upgradeable(listing.payToken).safeTransfer(bidding.bidder, bidding.bidAmount);
        }

        _transferNFTs(listingId, address(this), msg.sender);

        delete listings[listingId];
        delete biddings[listingId];
        emit ListingCancelled(listingId);
    }

    function purchaseListing(uint256 listingId)
        external
        checkSeller(listingId, false)
        nonReentrant
    {
        Listing storage listing = listings[listingId];
        if (
            listing.listingType == ListingType.TIERED_1_OF_N_AUCTION ||
            listing.listingType == ListingType.TIME_LIMITED_WINNER_TAKE_ALL_AUCTION
        ) {
            revert("HinataMarket: NOT_FOR_AUCTION");
        }
        if (listing.listingType == ListingType.TIME_LIMITED_PRICE_PER_TICKET_RAFFLE) {
            require(
                block.timestamp < listing.startTime + listing.duration,
                "HinataMarket: STILL_ACTIVE"
            );
        }
        _transferNFTs(listingId, address(this), msg.sender);

        _proceedRoyalty(
            listing.seller,
            msg.sender,
            listing.payToken,
            listing.price,
            listing.collections,
            listing.tokenAmounts,
            false
        );

        delete listings[listingId];
        emit ListingPurchased(listingId, listing.seller, msg.sender);
    }

    function bid(uint256 listingId, uint256 bidAmount)
        external
        checkSeller(listingId, false)
        nonReentrant
    {
        Listing storage listing = listings[listingId];
        Bidding storage bidding = biddings[listingId];
        if (
            listing.listingType != ListingType.TIERED_1_OF_N_AUCTION &&
            listing.listingType != ListingType.TIME_LIMITED_WINNER_TAKE_ALL_AUCTION
        ) {
            revert("HinataMarket: ONLY_FOR_AUCTION");
        }
        require(_isActiveListing(listingId), "HinataMarket: INACTIVE_LISTING");
        require(bidAmount >= listing.price, "HinataMarket: TOO_LOW_BID");

        if (bidding.bidder != address(0)) {
            require(bidAmount > bidding.bidAmount, "HinataMarket: LOWER_THAN_HIGHEST");
            if (bidding.bidder != msg.sender)
                IERC20Upgradeable(listing.payToken).safeTransfer(bidding.bidder, bidding.bidAmount);
        }
        address oldBidder = bidding.bidder;
        uint256 oldBidAmount = bidding.bidAmount;
        biddings[listingId] = Bidding(msg.sender, bidAmount);
        if (msg.sender == oldBidder) bidAmount -= oldBidAmount;
        IERC20Upgradeable(listing.payToken).safeTransferFrom(msg.sender, address(this), bidAmount);
        emit BidUpdated(listingId, msg.sender, bidAmount);
    }

    function completeAuction(uint256 listingId) external checkSeller(listingId, true) nonReentrant {
        Listing storage listing = listings[listingId];
        Bidding storage bidding = biddings[listingId];
        if (
            listing.listingType != ListingType.TIERED_1_OF_N_AUCTION &&
            listing.listingType != ListingType.TIME_LIMITED_WINNER_TAKE_ALL_AUCTION
        ) {
            revert("HinataMarket: ONLY_FOR_AUCTION");
        }
        require(bidding.bidder != address(0), "HinataMarket: NO_ACTIVE_BID");

        _transferNFTs(listingId, address(this), bidding.bidder);
        _proceedRoyalty(
            listing.seller,
            address(this),
            listing.payToken,
            bidding.bidAmount,
            listing.collections,
            listing.tokenAmounts,
            true
        );

        delete listings[listingId];
        delete biddings[listingId];
        emit ListingPurchased(listingId, msg.sender, bidding.bidder);
    }

    /// @dev Returns true if the NFT is on listing.
    function _isActiveListing(uint256 listingId) internal view returns (bool) {
        Listing storage listing = listings[listingId];
        return
            listing.startTime > 0 &&
            block.timestamp >= listing.startTime &&
            (
                (
                    listing.duration == 0
                        ? block.timestamp <= listing.startTime + MAX_DURATION
                        : block.timestamp <= listing.startTime + listing.duration
                )
            );
    }

    function _isValidatedListing(uint256[] memory tokenAmounts, uint64 quantity)
        private
        pure
        returns (bool)
    {
        uint256 len = tokenAmounts.length;
        for (uint256 i; i < len; i += 1) {
            if (tokenAmounts[i] % quantity > 0) {
                return false;
            }
        }
        return true;
    }

    function _transferNFTs(
        uint256 listingId,
        address from,
        address to
    ) internal returns (uint256[] memory tokenAmounts) {
        Listing storage listing = listings[listingId];
        require(
            listing.collections.length == listing.tokenIds.length &&
                listing.collections.length == listing.tokenAmounts.length,
            "HinataMarket: INVALID_ARGUMENTS"
        );

        tokenAmounts = new uint256[](listing.collections.length);
        for (uint256 i; i < listing.tokenIds.length; i += 1) {
            if (factory.getCollection(listing.collections[i]).is721) {
                IERC721Upgradeable(listing.collections[i]).safeTransferFrom(
                    from,
                    to,
                    listing.tokenIds[i]
                );
                tokenAmounts[i] = 1;
            } else {
                IERC1155Upgradeable(listing.collections[i]).safeTransferFrom(
                    from,
                    to,
                    listing.tokenIds[i],
                    listing.tokenAmounts[i],
                    ""
                );
                tokenAmounts[i] = listing.tokenAmounts[i];
            }
        }
    }

    function _proceedRoyalty(
        address seller,
        address buyer,
        address payToken,
        uint256 price,
        address[] memory collections,
        uint256[] memory tokenAmounts,
        bool isFromContract
    ) internal {
        uint256 fee = (price * marketFee) / 10000;
        // to seller
        if (fee > 0) {
            if (isFromContract) IERC20Upgradeable(payToken).safeTransfer(beneficiary, fee);
            else IERC20Upgradeable(payToken).safeTransferFrom(buyer, beneficiary, fee);
        }

        // to collection royalty beneficiares
        uint256 royaltyPercentage;
        uint256 sumAmount;
        for (uint256 i; i < collections.length; i += 1) {
            ICollectionFactory.Collection memory collection = factory.getCollection(collections[i]);
            sumAmount += tokenAmounts[i];
            if (royaltyPercentage < collection.royaltySum)
                royaltyPercentage = collection.royaltySum;
        }
        uint256 royalty = (price * royaltyPercentage) / 10000;
        if (price - royalty - fee > 0) {
            if (isFromContract)
                IERC20Upgradeable(payToken).safeTransfer(seller, price - royalty - fee);
            else IERC20Upgradeable(payToken).safeTransferFrom(buyer, seller, price - royalty - fee);
        }
        if (royalty == 0) return;

        for (uint256 i; i < collections.length; i += 1) {
            ICollectionFactory.Collection memory collection = factory.getCollection(collections[i]);
            ICollectionFactory.Royalty[] memory royalties = factory.getCollectionRoyalties(
                collections[i]
            );
            for (uint256 j; j < royalties.length; j += 1)
                if (isFromContract)
                    IERC20Upgradeable(payToken).safeTransfer(
                        royalties[j].beneficiary,
                        (((royalty * tokenAmounts[i]) / sumAmount) * royalties[j].percentage) /
                            collection.royaltySum
                    );
                else
                    IERC20Upgradeable(payToken).safeTransferFrom(
                        buyer,
                        royalties[j].beneficiary,
                        (((royalty * tokenAmounts[i]) / sumAmount) * royalties[j].percentage) /
                            collection.royaltySum
                    );
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}