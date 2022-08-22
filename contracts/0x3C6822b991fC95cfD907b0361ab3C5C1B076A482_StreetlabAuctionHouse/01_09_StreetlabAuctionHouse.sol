// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @title Allows the owner of an NFT to list it in auction.
 * @notice NFTs in auction are escrowed in the contract.
 */
contract StreetlabAuctionHouse is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /**
     * @notice Emitted when a bid is placed.
     * @param auctionId The id of the auction this bid was for.
     * @param bidder The address of the bidder.
     * @param amount The amount of the bid.
     * @param endTime The new end time of the auction (which may have been set or extended by this bid).
     */
    event ReserveAuctionBidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount,
        uint256 endTime
    );
    /**
     * @notice Emitted when an auction is cancelled.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was cancelled.
     */
    event ReserveAuctionCanceled(uint256 indexed auctionId);
    /**
     * @notice Emitted when an auction is canceled by a Foundation admin.
     * @dev When this occurs, the highest bidder (if there was a bid) is automatically refunded.
     * @param auctionId The id of the auction that was cancelled.
     * @param reason The reason for the cancellation.
     */
    event ReserveAuctionCanceledByAdmin(
        uint256 indexed auctionId,
        string reason
    );
    /**
     * @notice Emitted when an NFT is listed for auction.
     * @param seller The address of the seller.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param startTime The time at which this auction will start accepting bids.
     * '0' will start on first bid.
     * @param duration The duration of the auction.
     * @param extensionDuration The duration of the auction extension window.
     * @param reservePrice The reserve price to kick off the auction.
     * @param allowlistMerkleRoot Root hash of addresses for allowlist.
     * @param auctionId The id of the auction that was created.
     */
    event ReserveAuctionCreated(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 startTime,
        uint256 duration,
        uint256 extensionDuration,
        uint256 reservePrice,
        bytes32 allowlistMerkleRoot,
        uint256 auctionId
    );
    /**
     * @notice Emitted when an auction that has already ended is finalized,
     * indicating that the NFT has been transferred and revenue from the sale distributed.
     * @param auctionId The id of the auction that was finalized.
     * @param seller The address of the seller.
     * @param bidder The address of the highest bidder that won the NFT.
     * @param amount The final bid amount.
     */
    event ReserveAuctionFinalized(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed bidder,
        uint256 amount
    );
    /**
     * @notice Emitted when an auction is invalidated due to other market activity.
     * @dev This occurs when the NFT is sold another way, such as with `buy` or `acceptOffer`.
     * @param auctionId The id of the auction that was invalidated.
     */
    event ReserveAuctionInvalidated(uint256 indexed auctionId);
    /**
     * @notice Emitted when the auction's reserve price is changed.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was updated.
     * @param reservePrice The new reserve price for the auction.
     */
    event ReserveAuctionPriceUpdated(
        uint256 indexed auctionId,
        uint256 reservePrice
    );
    /**
     * @notice Emitted when the auction's allowlist merkle root is changed.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was updated.
     * @param allowlistMerkleRoot Root hash of addresses for allowlist.
     */
    event ReserveAuctionAllowlistUpdated(
        uint256 indexed auctionId,
        bytes32 allowlistMerkleRoot
    );

    /// @notice Confirms that the reserve price is not zero.
    modifier onlyValidAuctionConfig(uint256 reservePrice) {
        require(
            reservePrice != 0,
            "reserve price must be set to non zero value"
        );
        _;
    }

    /// @notice The auction configuration for a specific NFT.
    struct ReserveAuction {
        /// @notice The address of the NFT contract.
        address nftContract;
        /// @notice The id of the NFT.
        uint256 tokenId;
        /// @notice The owner of the NFT which listed it in auction.
        address payable seller;
        /// @notice The time at which this auction will start accepting bids.
        /// @dev If set to '0', auction starts on first bid.
        uint256 startTime;
        /// @notice The time at which this auction will not accept any new bids.
        /// @dev This is `0` until the first bid is placed.
        uint256 endTime;
        /// @notice The current highest bidder in this auction.
        /// @dev This is `address(0)` until the first bid is placed.
        address payable bidder;
        /// @notice The latest price of the NFT in this auction.
        /// @dev This is set to the reserve price, and then to the highest bid once the auction has started.
        uint256 amount;
        /// @dev Root hash of addresses for allowlist
        bytes32 allowlistMerkleRoot;
        /// @notice Whether anyone can bid or only genesis holders
        bool publicBid;
    }

    /**
     * @notice A global id for auctions of any type.
     */
    uint256 private nextAuctionId;

    /// @notice The auction configuration for a specific auction id.
    mapping(address => mapping(uint256 => uint256))
        private nftContractToTokenIdToAuctionId;
    /// @notice The auction id for a specific NFT.
    /// @dev This is deleted when an auction is finalized or canceled.
    mapping(uint256 => ReserveAuction) private auctionIdToAuction;

    /// @notice How long an auction lasts for once the first bid has been received.
    uint256 private immutable DURATION;

    /// @notice The window for auction extensions, any bid placed in the final 15 minutes
    /// of an auction will reset the time remaining to 15 minutes.
    uint256 private constant EXTENSION_DURATION = 15 minutes;

    /// @notice Caps the max duration that may be configured so that overflows will not occur.
    uint256 private constant MAX_MAX_DURATION = 1000 days;

    /// @notice Minimum percentage increment of the outstanding bid to place a new bid.
    uint256 private immutable MIN_PERCENT_INCREMENT_DENOMINATOR;

    /// @notice Streetlab Genesis contract address
    address private immutable STREETLAB_GENESIS_ADDRESS;

    /**
     * @notice Configures the duration for auctions.
     * @param duration The duration for auctions, in seconds.
     */
    constructor(
        uint256 duration,
        uint256 minPercentIncrement,
        address streetlabGenesis
    ) {
        // constructor(uint256 duration) {
        require(duration <= MAX_MAX_DURATION, "exceeds max duration");
        require(duration >= EXTENSION_DURATION, "less than extension duration");
        DURATION = duration;
        MIN_PERCENT_INCREMENT_DENOMINATOR = minPercentIncrement;
        STREETLAB_GENESIS_ADDRESS = streetlabGenesis;
    }

    /**
     * @notice Called once to configure the contract after the initial proxy deployment.
     * @dev This farms the initialize call out to inherited contracts as needed to initialize mutable variables.
     */
    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        _initializeNFTMarketAuction();
    }

    /**
     * @notice Called once to configure the contract after the initial proxy deployment.
     * @dev This sets the initial auction id to 1, making the first auction cheaper
     * and id 0 represents no auction found.
     */
    function _initializeNFTMarketAuction() internal onlyInitializing {
        nextAuctionId = 1;
    }

    /**
     * @notice Returns id to assign to the next auction.
     */
    function _getNextAndIncrementAuctionId() internal returns (uint256) {
        // AuctionId cannot overflow 256 bits.
        unchecked {
            return nextAuctionId++;
        }
    }

    /**
     * @notice Allows Foundation to cancel an auction, refunding the bidder and returning the NFT to
     * the seller (if not active buy price set).
     * This should only be used for extreme cases such as DMCA takedown requests.
     * @param auctionId The id of the auction to cancel.
     * @param reason The reason for the cancellation (a required field).
     */
    function adminCancelReserveAuction(
        uint256 auctionId,
        string calldata reason
    ) external onlyOwner nonReentrant {
        require(bytes(reason).length != 0, "cannot cancel without reason");
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        require(auction.amount != 0, "no such auction");

        delete nftContractToTokenIdToAuctionId[auction.nftContract][
            auction.tokenId
        ];
        delete auctionIdToAuction[auctionId];

        // Return the NFT to the owner.
        _transferFromEscrowIfAvailable(
            auction.nftContract,
            auction.tokenId,
            auction.seller
        );

        if (auction.bidder != address(0)) {
            // Refund the highest bidder if any bids were placed in this auction.
            AddressUpgradeable.sendValue(
                payable(auction.bidder),
                auction.amount
            );
        }

        emit ReserveAuctionCanceledByAdmin(auctionId, reason);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
     * @dev The NFT is transferred back to the owner unless there is still a buy price set.
     * @param auctionId The id of the auction to cancel.
     */
    function cancelReserveAuction(uint256 auctionId) external nonReentrant {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        require(
            auction.seller == msg.sender,
            "only auction owner can update it"
        );
        require(auction.endTime == 0, "cannot update auction in progress");

        // Remove the auction.
        delete nftContractToTokenIdToAuctionId[auction.nftContract][
            auction.tokenId
        ];
        delete auctionIdToAuction[auctionId];

        // Transfer the NFT unless it still has a buy price set.
        _transferFromEscrowIfAvailable(
            auction.nftContract,
            auction.tokenId,
            auction.seller
        );

        emit ReserveAuctionCanceled(auctionId);
    }

    /**
     * @notice Creates an auction for the given NFT.
     * The NFT is held in escrow until the auction is finalized or canceled.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param reservePrice The initial reserve price for the auction.
     * @param startTime The time at which this auction will start accepting bids.
     * '0' will start on first bid.
     * @param allowlistMerkleRoot Merkle tree root hash of addresses for allowlist
     */
    function createReserveAuction(
        address nftContract,
        uint256 tokenId,
        uint256 reservePrice,
        uint256 startTime,
        bytes32 allowlistMerkleRoot
    ) external nonReentrant onlyValidAuctionConfig(reservePrice) {
        uint256 auctionId = _getNextAndIncrementAuctionId();

        // If the `msg.sender` is not the owner of the NFT, transferring into escrow should fail.
        _transferToEscrow(nftContract, tokenId);

        // This check must be after _transferToEscrow in case auto-settle was required
        require(
            nftContractToTokenIdToAuctionId[nftContract][tokenId] == 0,
            "auction already listed"
        );
        // Store the auction details
        nftContractToTokenIdToAuctionId[nftContract][tokenId] = auctionId;
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        auction.nftContract = nftContract;
        auction.tokenId = tokenId;
        auction.startTime = startTime != 0 ? startTime : block.timestamp;
        auction.seller = payable(msg.sender);
        auction.amount = reservePrice;
        auction.allowlistMerkleRoot = allowlistMerkleRoot;

        emit ReserveAuctionCreated(
            msg.sender,
            nftContract,
            tokenId,
            auction.startTime,
            DURATION,
            EXTENSION_DURATION,
            reservePrice,
            allowlistMerkleRoot,
            auctionId
        );
    }

    /**
     * @notice Once the countdown has expired for an auction, anyone can settle the auction.
     * This will send the NFT to the highest bidder and distribute revenue for this sale.
     * @param auctionId The id of the auction to settle.
     */
    function finalizeReserveAuction(uint256 auctionId) external nonReentrant {
        require(
            auctionIdToAuction[auctionId].endTime != 0,
            "cannot finalize already settled auction"
        );
        _finalizeReserveAuction({auctionId: auctionId, keepInEscrow: false});
    }

    /**
     * @notice Place a bid in an auction.
     * A bidder may place a bid which is at least the amount defined by `getMinBidAmount`.
     * If this is the first bid on the auction, the countdown will begin.
     * If there is already an outstanding bid, the previous bidder will be refunded at this time
     * and if the bid is placed in the final moments of the auction, the countdown may be extended.
     * @dev `amount` - `msg.value` is withdrawn from the bidder's FETH balance.
     * @param auctionId The id of the auction to bid on.
     */
    /* solhint-disable-next-line code-complexity */
    function placeBid(uint256 auctionId, bytes32[] calldata proof)
        external
        payable
        nonReentrant
    {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        uint256 amount = msg.value;
        require(auction.amount != 0, "no such auction");

        uint256 startTime = auction.startTime;
        uint256 endTime = auction.endTime;

        require(startTime <= block.timestamp, "auction is not started");

        if (endTime == 0) {
            require(
                amount >= auction.amount,
                "cannot bid lower than reserve price"
            );

            // Be a genesis holder 1 duration past startTime
            if (startTime + DURATION < block.timestamp) {
                auction.publicBid = true;
            } else {
                require(
                    IERC721Upgradeable(STREETLAB_GENESIS_ADDRESS).balanceOf(msg.sender) >
                        0 ||
                        (proof.length > 0 &&
                            auction.allowlistMerkleRoot != 0 &&
                            _isInAllowList(
                                msg.sender,
                                auction.allowlistMerkleRoot,
                                proof
                            )),
                    "not allowed to bid"
                );
            }

            // Store the bid details.
            auction.amount = amount;
            auction.bidder = payable(msg.sender);

            // On the first bid, set the endTime to now + duration.
            unchecked {
                // Duration is always set to 24hrs so the below can't overflow.
                endTime = block.timestamp + DURATION;
            }
            auction.endTime = endTime;
        } else {
            require(endTime >= block.timestamp, "cannot bid on ended auction");
            require(
                auction.publicBid ||
                    IERC721Upgradeable(STREETLAB_GENESIS_ADDRESS).balanceOf(msg.sender) >
                    0 ||
                    (proof.length > 0 &&
                        auction.allowlistMerkleRoot != 0 &&
                        _isInAllowList(
                            msg.sender,
                            auction.allowlistMerkleRoot,
                            proof
                        )),
                "not allowed to bid"
            );
            require(
                auction.bidder != msg.sender,
                "cannot rebid over outstanding bid"
            );
            uint256 minIncrement = _getMinIncrement(auction.amount);
            require(amount >= minIncrement, "bid must be at least min amount");

            // Cache and update bidder state
            uint256 originalAmount = auction.amount;
            address payable originalBidder = auction.bidder;
            auction.amount = amount;
            auction.bidder = payable(msg.sender);

            unchecked {
                // When a bid outbids another, check to see if a time extension should apply.
                // We confirmed that the auction has not ended, so endTime is always >= the current timestamp.
                // Current time plus extension duration (always 15 mins) cannot overflow.
                uint256 endTimeWithExtension = block.timestamp +
                    EXTENSION_DURATION;
                if (endTime < endTimeWithExtension) {
                    endTime = endTimeWithExtension;
                    auction.endTime = endTime;
                }
            }

            // Refund the previous bidder
            AddressUpgradeable.sendValue(originalBidder, originalAmount);
        }

        emit ReserveAuctionBidPlaced(auctionId, msg.sender, amount, endTime);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, the reservePrice may be
     * changed by the seller.
     * @param auctionId The id of the auction to change.
     * @param reservePrice The new reserve price for this auction.
     */
    function updateReservePrice(uint256 auctionId, uint256 reservePrice)
        external
        onlyValidAuctionConfig(reservePrice)
    {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        require(
            auction.seller == msg.sender,
            "only auction owner can update it"
        );
        require(auction.endTime == 0, "cannot update auction in progress");
        require(auction.amount != reservePrice, "price already set");

        // Update the current reserve price.
        auction.amount = reservePrice;

        emit ReserveAuctionPriceUpdated(auctionId, reservePrice);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, the reservePrice may be
     * changed by the seller.
     * @param auctionId The id of the auction to change.
     * @param allowlistMerkleRoot Merkle tree root hash of addresses for allowlist
     */
    function updateAllowlist(uint256 auctionId, bytes32 allowlistMerkleRoot)
        external
    {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        require(
            auction.seller == msg.sender,
            "only auction owner can update it"
        );

        // Update the current reserve price.
        auction.allowlistMerkleRoot = allowlistMerkleRoot;

        emit ReserveAuctionAllowlistUpdated(auctionId, allowlistMerkleRoot);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, the reservePrice may be
     * changed by the seller.
     * @param account address to verify
     * @param root merkle root to verify against
     * @param proof merkle proof to verify
     * @return true if in allowlist merkle root, false otherwise
     */
    function _isInAllowList(
        address account,
        bytes32 root,
        bytes32[] calldata proof
    ) internal pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProofUpgradeable.verify(proof, root, leaf);
    }

    /**
     * @notice Settle an auction that has already ended.
     * This will send the NFT to the highest bidder and distribute revenue for this sale.
     * @param keepInEscrow If true, the NFT will be kept in escrow to save gas by avoiding
     * redundant transfers if the NFT should remain in escrow, such as when the new owner
     * sets a buy price or lists it in a new auction.
     */
    function _finalizeReserveAuction(uint256 auctionId, bool keepInEscrow)
        private
    {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];

        require(
            auction.endTime < block.timestamp,
            "cannot finalize auction in progress"
        );

        // Remove the auction.
        delete nftContractToTokenIdToAuctionId[auction.nftContract][
            auction.tokenId
        ];
        delete auctionIdToAuction[auctionId];

        if (!keepInEscrow) {
            // The seller was authorized when the auction was originally created
            _transferERC721(
                auction.nftContract,
                auction.tokenId,
                auction.bidder,
                address(0)
            );
        }

        // Distribute revenue for this sale.
        AddressUpgradeable.sendValue(auction.seller, auction.amount);

        emit ReserveAuctionFinalized(
            auctionId,
            auction.seller,
            auction.bidder,
            auction.amount
        );
    }

    /**
     * @dev If an auction is found:
     *  - If the auction is over, it will settle the auction and confirm the new seller won the auction.
     *  - If the auction has not received a bid, it will invalidate the auction.
     *  - If the auction is in progress, this will revert.
     */
    function _transferFromEscrow(
        address nftContract,
        uint256 tokenId,
        address recipient,
        address authorizeSeller
    ) internal {
        uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][
            tokenId
        ];
        if (auctionId != 0) {
            ReserveAuction storage auction = auctionIdToAuction[auctionId];
            if (auction.endTime == 0) {
                // The auction has not received any bids yet so it may be invalided.

                require(
                    authorizeSeller == address(0) ||
                        auction.seller == authorizeSeller,
                    "not matching seller"
                );

                // Remove the auction.
                delete nftContractToTokenIdToAuctionId[nftContract][tokenId];
                delete auctionIdToAuction[auctionId];

                emit ReserveAuctionInvalidated(auctionId);
            } else {
                // If the auction has ended, the highest bidder will be the new owner
                // and if the auction is in progress, this will revert.

                // `authorizeSeller != address(0)` does not apply here since an unsettled auction must go
                // through this path to know who the authorized seller should be.
                require(
                    auction.bidder == authorizeSeller,
                    "not matching seller"
                );

                // Finalization will revert if the auction has not yet ended.
                _finalizeReserveAuction({
                    auctionId: auctionId,
                    keepInEscrow: true
                });
            }
            // The seller authorization has been confirmed.
            authorizeSeller = address(0);
        }

        _transferERC721(nftContract, tokenId, recipient, authorizeSeller);
    }

    /**
     * @dev Checks if there is an auction for this NFT before allowing the transfer to continue.
     */
    function _transferFromEscrowIfAvailable(
        address nftContract,
        uint256 tokenId,
        address recipient
    ) internal {
        if (nftContractToTokenIdToAuctionId[nftContract][tokenId] == 0) {
            // No auction was found
            IERC721Upgradeable(nftContract).transferFrom(
                address(this),
                recipient,
                tokenId
            );
        }
    }

    function _transferToEscrow(address nftContract, uint256 tokenId) internal {
        uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][
            tokenId
        ];
        if (auctionId == 0) {
            // NFT is not in auction
            IERC721Upgradeable(nftContract).transferFrom(
                msg.sender,
                address(this),
                tokenId
            );
            return;
        }
        // Using storage saves gas since most of the data is not needed
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        if (auction.endTime == 0) {
            // Reserve price set, confirm the seller is a match
            require(auction.seller == msg.sender, "not matching seller");
        } else {
            // Auction in progress, confirm the highest bidder is a match
            require(auction.bidder == msg.sender, "not matching seller");

            // Finalize auction but leave NFT in escrow, reverts if the auction has not ended
            _finalizeReserveAuction({auctionId: auctionId, keepInEscrow: true});
        }
    }

    /**
     * @notice Returns the minimum amount a bidder must spend to participate in an auction.
     * Bids must be greater than or equal to this value or they will revert.
     * @param auctionId The id of the auction to check.
     * @return minimum The minimum amount for a bid to be accepted.
     */
    function getMinBidAmount(uint256 auctionId)
        external
        view
        returns (uint256 minimum)
    {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        if (auction.endTime == 0) {
            return auction.amount;
        }
        return _getMinIncrement(auction.amount);
    }

    /**
     * @notice Returns auction details for a given auctionId.
     * @param auctionId The id of the auction to lookup.
     */
    function getReserveAuctionFromId(uint256 auctionId)
        public
        view
        returns (ReserveAuction memory auction)
    {
        ReserveAuction storage auctionStorage = auctionIdToAuction[auctionId];
        auction = ReserveAuction(
            auctionStorage.nftContract,
            auctionStorage.tokenId,
            auctionStorage.seller,
            auctionStorage.startTime,
            auctionStorage.endTime,
            auctionStorage.bidder,
            auctionStorage.amount,
            auctionStorage.allowlistMerkleRoot,
            auctionStorage.publicBid
        );
    }

    /**
     * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
     * @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @return auctionId The id of the auction, or 0 if no auction is found.
     */
    function getReserveAuctionIdFor(address nftContract, uint256 tokenId)
        public
        view
        returns (uint256 auctionId)
    {
        auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    }

    /**
     * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
     * @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     */
    function getReserveAuction(address nftContract, uint256 tokenId)
        external
        view
        returns (ReserveAuction memory auction)
    {
        return
            getReserveAuctionFromId(
                getReserveAuctionIdFor(nftContract, tokenId)
            );
    }

    /**
     * @dev Returns the seller that has the given NFT in escrow for an auction,
     * or bubbles the call up for other considerations.
     */
    function _getSellerFor(address nftContract, uint256 tokenId)
        internal
        view
        returns (address payable seller)
    {
        seller = auctionIdToAuction[
            nftContractToTokenIdToAuctionId[nftContract][tokenId]
        ].seller;
        if (seller == address(0)) {
            seller = payable(IERC721Upgradeable(nftContract).ownerOf(tokenId));
        }
    }

    function _isInActiveAuction(address nftContract, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][
            tokenId
        ];
        return
            auctionId != 0 &&
            auctionIdToAuction[auctionId].endTime >= block.timestamp;
    }

    /**
     * @dev Determines the minimum amount when increasing an existing offer or bid.
     */
    function _getMinIncrement(uint256 currentAmount)
        internal
        view
        returns (uint256)
    {
        uint256 minIncrement = currentAmount;
        unchecked {
            minIncrement /= MIN_PERCENT_INCREMENT_DENOMINATOR;
        }
        if (minIncrement == 0) {
            // Since minIncrement reduces from the currentAmount, this cannot overflow.
            // The next amount must be at least 1 wei greater than the current.
            return currentAmount + 1;
        }

        return minIncrement + currentAmount;
    }

    function _transferERC721(
        address nftContract,
        uint256 tokenId,
        address recipient,
        address authorizeSeller
    ) internal {
        require(authorizeSeller == address(0), "seller not found");
        IERC721Upgradeable(nftContract).transferFrom(address(this), recipient, tokenId);
    }

    /**
     * @notice This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}