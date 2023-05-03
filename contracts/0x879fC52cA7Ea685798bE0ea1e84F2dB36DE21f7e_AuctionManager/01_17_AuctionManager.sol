// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openzeppelin
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
// Interfaces
import "./interfaces/INFTPayoutsUpgradeable.sol";
import "./interfaces/IOriginsNFT.sol";

// Errors
error FailedToCreateEnglishAuction(uint8 errorCode);
error FailedToBidToEnglishAuction(uint8 errorCode);
error FailedToClaimEnglishAuctionNFT(uint8 errorCode);
error FailedToEndEnglishAuction(uint8 errorCode);
error InvalidFeeTier();
error InvalidFeeTierRecipient();
error InvalidFeeTiersSum();
error InvalidTokenID();
error InvalidWithdrawAmount();
error ZeroAddress();

/**
 * @title AuctionManager
 * @dev Auction Manager for OriginsNFT contract
 * @author kazunetakeda25
 */
contract AuctionManager is
    Initializable,
    IERC721ReceiverUpgradeable,
    ReentrancyGuardUpgradeable,
    Ownable2StepUpgradeable,
    PausableUpgradeable
{
    using ERC165CheckerUpgradeable for address;

    struct EnglishAuction {
        uint256 startTimestamp; // Start timestamp
        uint256 endTimestamp; // End timestamp
        uint256 startPrice; // Start price
        uint256 reservedPrice; // Reserved price
        uint256 bidIncrementThreshold; // Bid increment threshold
        address creator; // Auction creator
        bool openToBid; // Open to bid for everyone
        Bid highestBid; // Highest Bid
    }

    struct Bid {
        address bidder; // Bidder address
        uint256 bidAmount; // Bid amount in ETH
    }

    struct FeeTier {
        address feeRecipient; // Fee recipient address
        uint256 feeTier; // 1% = 100
    }

    IOriginsNFT private _originsNFT; // Origins NFT contract
    uint256 private _serviceFees; // Service fees collected
    FeeTier[] private _feeTiers; // Service fee tier
    mapping(uint256 => EnglishAuction) private _englishAuctions; // English auctions
    mapping(uint256 => Bid[]) private _bids; // Bids per english auction
    mapping(address => bool) private _allowedBidders; // Allowed auction bidders
    mapping(uint256 => bool) private _auctionCreated; // Auction created for specific token ID
    mapping(uint256 => bool) private _tokenClaimed; // Token claimed

    // Events
    event OriginsNFTChanged(
        address indexed previousContract,
        address indexed newContract
    ); // Event emitted when Origins NFT contract changed
    event EnglishAuctionCreated(
        uint256 tokenId,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 startPrice,
        uint256 reservedPrice,
        uint256 bidIncrementThreshold,
        address indexed creator,
        bool openToBid
    ); // Event emmited when english auction created
    event BidPlacedToEnglishAuction(
        uint256 tokenId,
        address indexed bidder,
        uint256 bidAmount
    ); // Event emitted when a bid place to an english auction
    event ClaimedFromEnglishAuction(
        uint256 tokenId,
        address indexed winner,
        uint256 bidAmount
    ); // Event emitted when NFT is claimed from the english auction
    event AuctionEnded(
        uint256 tokenId,
        address indexed winner,
        uint256 bidAmount
    ); // Event emitted when auction ended
    event FeeTierChanged(FeeTier[] feeTiers); // Event emitted when fee tiers changed

    /**
     * @dev Modifier to check if the auction is valid
     * @param tokenId_ (uint256) Token ID
     */
    modifier onlyValidAuction(uint256 tokenId_) {
        _onlyValidAuction(tokenId_);
        _;
    }

    /**
     * @dev Initializer
     * @param originsNFT_ (address) Origins NFT contract address
     * @param feeTiers_ (FeeTier[] calldata) Service fee tiers
     */
    function initialize(
        address originsNFT_,
        FeeTier[] calldata feeTiers_
    ) public initializer {
        __Ownable2Step_init();
        setOriginsNFT(originsNFT_);
        _setFeeTiers(feeTiers_);
    }

    /**
     * @dev Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Create batch english auctions with token IDs from `startTokenId_` to `endTokenId_` (admin only)
     * @param startTokenId_ (uint256) Start token ID to create auctions
     * @param startTokenId_ (uint256) End token ID to create auctions
     * @param startTimestamp_ (uint256) Start time of the auctions in timestamp
     * @param endTimestamp_ (uint256) End time of the auctions in timestamp
     * @param startPrice_ (uint256) Start price of the auctions in ETH
     * @param reservedPrice_ (uint256) Reserved price of the auctions in ETH
     * @param bidIncrementThreshold_ (uint256) Amount to increment when place next bid
     * @param openToBid_ (bool) If true, autions are open to everyone, false for only whitelisted bidders
     */
    function createEnglishAuctions(
        uint256 startTokenId_,
        uint256 endTokenId_,
        uint256 startTimestamp_,
        uint256 endTimestamp_,
        uint256 startPrice_,
        uint256 reservedPrice_,
        uint256 bidIncrementThreshold_,
        bool openToBid_
    ) external nonReentrant whenNotPaused onlyOwner {
        for (uint256 i = startTokenId_; i <= endTokenId_; i++) {
            if (_auctionCreated[i]) {
                revert FailedToCreateEnglishAuction(1); // AUCTION_ALREADY_CREATED
            }
        }

        if (
            startTimestamp_ < block.timestamp ||
            endTimestamp_ <= startTimestamp_
        ) {
            revert FailedToCreateEnglishAuction(2); // INVALID_TIME_RANGE
        }

        if (startPrice_ == 0) {
            revert FailedToCreateEnglishAuction(3); // INVALID_START_PRICE
        }

        if (reservedPrice_ < startPrice_) {
            revert FailedToCreateEnglishAuction(4); // INVALID_RESERVED_PRICE
        }

        if (bidIncrementThreshold_ == 0 || bidIncrementThreshold_ >= 10000) {
            revert FailedToCreateEnglishAuction(5); // INVALID_BID_INCREAMENT_THRESHOLD
        }

        Bid memory highestBidder = Bid(address(0), 0);
        EnglishAuction memory auction = EnglishAuction(
            startTimestamp_,
            endTimestamp_,
            startPrice_,
            reservedPrice_,
            bidIncrementThreshold_,
            msg.sender,
            openToBid_,
            highestBidder
        );

        for (uint256 i = startTokenId_; i <= endTokenId_; i++) {
            _englishAuctions[i] = auction;

            _auctionCreated[i] = true;

            emit EnglishAuctionCreated(
                i,
                startTimestamp_,
                endTimestamp_,
                startPrice_,
                reservedPrice_,
                bidIncrementThreshold_,
                msg.sender,
                openToBid_
            );
        }
    }

    /**
     * @dev Place bid to an english auction
     * @param tokenId_ (uint256) Token ID
     */
    function placeBidToEnglishAuction(
        uint256 tokenId_
    ) external payable nonReentrant whenNotPaused onlyValidAuction(tokenId_) {
        EnglishAuction storage auction = _englishAuctions[tokenId_];

        if (!auction.openToBid && !_allowedBidders[msg.sender]) {
            revert FailedToBidToEnglishAuction(0); // NOT_ALLOWED_TO_BID
        }

        if (
            block.timestamp < auction.startTimestamp ||
            block.timestamp >= auction.endTimestamp
        ) {
            revert FailedToBidToEnglishAuction(1); // AUCTION_ENDED_OR_NOT_STARTED
        }

        uint256 minBidAmount = auction.highestBid.bidAmount > 0
            ? auction.highestBid.bidAmount
            : auction.startPrice;

        if (auction.highestBid.bidAmount > 0) {
            minBidAmount =
                (minBidAmount * (10000 + auction.bidIncrementThreshold)) /
                10000;
        }

        if (msg.value < minBidAmount) {
            revert FailedToBidToEnglishAuction(2); // INVALID_BID_AMOUNT
        }

        if (msg.sender == auction.creator) {
            revert FailedToBidToEnglishAuction(3); // CREATOR_CANNOT_BID
        }

        uint256 prevHighestBidAmount = auction.highestBid.bidAmount;
        address prevHighestBidder = auction.highestBid.bidder;

        Bid memory bid = Bid(msg.sender, msg.value);

        _bids[tokenId_].push(bid);
        auction.highestBid = bid;

        if (msg.value >= auction.reservedPrice) {
            auction.endTimestamp = block.timestamp;
        }

        // Refund previous bid amount
        if (prevHighestBidAmount > 0 && prevHighestBidder != address(0)) {
            payable(address(prevHighestBidder)).transfer(prevHighestBidAmount);
        }

        emit BidPlacedToEnglishAuction(tokenId_, msg.sender, msg.value);
    }

    /**
     * @dev End an english auction
     * @param tokenId_ (uint256) Token ID
     */
    function endEnglishAuction(
        uint256 tokenId_
    ) external nonReentrant onlyValidAuction(tokenId_) {
        EnglishAuction storage auction = _englishAuctions[tokenId_];

        if (msg.sender != auction.creator) {
            revert FailedToEndEnglishAuction(0); // NOT_AUCTION_CREATOR
        }

        address winner = auction.highestBid.bidder;
        uint256 winningAmount = auction.highestBid.bidAmount;

        if (block.timestamp < auction.endTimestamp) {
            auction.endTimestamp = block.timestamp;
        }

        _auctionCreated[tokenId_] = false;

        if (winner != address(0)) {
            emit AuctionEnded(tokenId_, winner, winningAmount);
        } else {
            emit AuctionEnded(tokenId_, address(0), 0);
        }
    }

    /**
     * @dev Claim english auction NFT when auction is over
     * @param tokenId_ (uint256) Token ID
     */
    function claimEnglishAuctionNFT(
        uint256 tokenId_
    ) external nonReentrant whenNotPaused onlyValidAuction(tokenId_) {
        EnglishAuction storage auction = _englishAuctions[tokenId_];
        Bid memory highestBid = auction.highestBid;

        if (msg.sender != highestBid.bidder) {
            revert FailedToClaimEnglishAuctionNFT(0); // NOT_AUCTION_WINNER
        }

        if (block.timestamp < auction.endTimestamp) {
            revert FailedToClaimEnglishAuctionNFT(1); // AUCTION_NOT_ENDED
        }

        if (_tokenClaimed[tokenId_]) {
            revert FailedToClaimEnglishAuctionNFT(2); // NFT_ALREADY_CLAIMED
        }

        _auctionCreated[tokenId_] = false;
        _tokenClaimed[tokenId_] = true;

        _originsNFT.mint(msg.sender, tokenId_);

        address nftContract = address(_originsNFT);

        address creator = INFTPayoutsUpgradeable(nftContract).creator(tokenId_);
        uint256 bidAmountWithoutFee = (highestBid.bidAmount * 10000) /
            (10000 + getServiceFeePercent());
        uint256 serviceFee = highestBid.bidAmount - bidAmountWithoutFee;
        uint256 payoutCount;

        if (
            address(_originsNFT).supportsInterface(
                type(INFTPayoutsUpgradeable).interfaceId
            )
        ) {
            payoutCount = INFTPayoutsUpgradeable(nftContract).payoutCount(
                tokenId_,
                creator == msg.sender
            );
        }

        address[] memory payoutReceivers = new address[](payoutCount);
        uint256[] memory payoutShares = new uint256[](payoutCount);

        _serviceFees += serviceFee;

        if (payoutCount == 0) {
            payable(auction.creator).transfer(bidAmountWithoutFee);
        } else {
            (payoutReceivers, payoutShares) = INFTPayoutsUpgradeable(
                nftContract
            ).payoutInfo(tokenId_, bidAmountWithoutFee, creator == msg.sender);
            for (uint256 i; i < payoutCount; ) {
                payable(payoutReceivers[i]).transfer(payoutShares[i]);

                unchecked {
                    ++i;
                }
            }
        }

        FeeTier[] storage feeTiers = _feeTiers;
        uint256 feeTiersLength = feeTiers.length;
        uint256 feeTiersSum;

        for (uint256 i; i < feeTiersLength; ) {
            unchecked {
                feeTiersSum = feeTiersSum + _feeTiers[i].feeTier;
                ++i;
            }
        }

        for (uint256 i; i < feeTiersLength; ) {
            if (_feeTiers[i].feeRecipient == address(this)) continue;

            uint256 fee = (serviceFee * _feeTiers[i].feeTier) / feeTiersSum;
            payable(feeTiers[i].feeRecipient).transfer(fee);

            unchecked {
                ++i;
            }
        }

        emit ClaimedFromEnglishAuction(
            tokenId_,
            msg.sender,
            highestBid.bidAmount
        );
    }

    /**
     * @dev Withdraw `amount_` of ETH. Only able to withdraw maximum of `_serviceFees` amount.
     * @param amount_ (uint256) ETH amount to withdraw
     */
    function withdrawETH(uint256 amount_) external nonReentrant onlyOwner {
        if (amount_ > address(this).balance) {
            revert InvalidWithdrawAmount();
        }

        if (_serviceFees < amount_) {
            revert InvalidWithdrawAmount();
        }

        _serviceFees -= amount_;

        payable(address(msg.sender)).transfer(amount_);
    }

    /**
     * @dev Add to allowed bidders list
     * @param accounts_ (address[] calldata) Accounts to be added
     */
    function AddToAllowedBidders(
        address[] calldata accounts_
    ) external onlyOwner {
        uint256 length = accounts_.length;
        for (uint256 i; i < length; ++i) {
            _allowedBidders[accounts_[i]] = true;
        }
    }

    /**
     * @dev Remove from allowed bidders list
     * @param accounts_ (address[] calldata) Accounts to be removed
     */
    function RemoveFromAllowedBidders(
        address[] calldata accounts_
    ) external onlyOwner {
        uint256 length = accounts_.length;
        for (uint256 i; i < length; ++i) {
            _allowedBidders[accounts_[i]] = false;
        }
    }

    /**
     * @dev Set service fee tiers
     * @param feeTiers_ (FeeTier[] calldata) New service fee tiers
     */
    function setFeeTiers(FeeTier[] calldata feeTiers_) external onlyOwner {
        _setFeeTiers(feeTiers_);
    }

    /**
     * @dev Set Origins NFT contract address
     * @param originsNFT_ (address) Origins NFT contract address
     */
    function setOriginsNFT(address originsNFT_) public onlyOwner {
        if (originsNFT_ == address(0)) {
            revert ZeroAddress();
        }
        IOriginsNFT prev = _originsNFT;
        _originsNFT = IOriginsNFT(originsNFT_);

        emit OriginsNFTChanged(address(prev), originsNFT_);
    }

    /**
     * @dev Get auction object detail
     * @param tokenId_ (uint256) Token ID
     * @return (uint256) Start time
     * @return (uint256) End time
     * @return (uint256) Start price
     * @return (uint256) Reserved price
     * @return (uint256) Bid increment threshold
     * @return (address) Auction creator
     * @return (bool) Open to bid
     */
    function getAuction(
        uint256 tokenId_
    )
        external
        view
        onlyValidAuction(tokenId_)
        returns (uint256, uint256, uint256, uint256, uint256, address, bool)
    {
        EnglishAuction storage auction = _englishAuctions[tokenId_];

        return (
            auction.startTimestamp,
            auction.endTimestamp,
            auction.startPrice,
            auction.reservedPrice,
            auction.bidIncrementThreshold,
            auction.creator,
            auction.openToBid
        );
    }

    /**
     * @dev Get a list of all bids of an auction
     * @param tokenId_ (uint256) Token ID
     * @return bidders (address[] memory) Bid addresses
     * @return bids (uint256[] memory) Bid amounts
     */
    function getAuctionBids(
        uint256 tokenId_
    )
        external
        view
        onlyValidAuction(tokenId_)
        returns (address[] memory, uint256[] memory)
    {
        uint256 length = _bids[tokenId_].length;

        address[] memory bidders = new address[](length);
        uint256[] memory bids = new uint256[](length);

        for (uint256 i; i < length; ++i) {
            bidders[i] = _bids[tokenId_][i].bidder;
            bids[i] = _bids[tokenId_][i].bidAmount;
        }

        return (bidders, bids);
    }

    /**
     * @dev Get next bid price of an english auction
     * @param tokenId_ (uint256) Token ID
     * @return (uint256) Price in ETH
     */
    function getEnglishAuctionPrice(
        uint256 tokenId_
    ) public view onlyValidAuction(tokenId_) returns (uint256) {
        EnglishAuction memory auction = _englishAuctions[tokenId_];

        return
            auction.highestBid.bidAmount == 0
                ? auction.startPrice
                : auction.highestBid.bidAmount;
    }

    /**
     * @dev Get service fee tiers
     * @return (FeeTier[] memory) Fee tiers
     */
    function getFeeTiers() external view returns (FeeTier[] memory) {
        return _feeTiers;
    }

    /**
     * @dev Get service fee percent
     * @return (uint256) Service fee percent
     */
    function getServiceFeePercent() public view returns (uint256) {
        uint256 feeTiersLength = _feeTiers.length;
        uint256 feeTiersSum;

        unchecked {
            for (uint256 i; i < feeTiersLength; ++i) {
                feeTiersSum = feeTiersSum + _feeTiers[i].feeTier;
            }
        }

        return feeTiersSum;
    }

    /**
     * @dev Check if token claimed
     * @param tokenId_ (uint256) Token ID
     * @return (bool) True for claimed
     */
    function tokenClaimed(uint256 tokenId_) public view returns (bool) {
        return _tokenClaimed[tokenId_];
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    /**
     * @dev Set service fee tiers
     * @param feeTiers_ (FeeTier[] calldata) Fee tiers
     */
    function _setFeeTiers(FeeTier[] calldata feeTiers_) private {
        uint256 feeTiersLength = feeTiers_.length;
        uint256 feeTiersSum;

        for (uint256 i; i < feeTiersLength; ) {
            if (feeTiers_[i].feeRecipient == address(0)) {
                revert InvalidFeeTierRecipient();
            }

            if (feeTiers_[i].feeTier == 0) {
                revert InvalidFeeTier();
            }

            unchecked {
                feeTiersSum = feeTiersSum + feeTiers_[i].feeTier;
                ++i;
            }
        }

        if (feeTiersSum > 9999) {
            revert InvalidFeeTiersSum();
        }

        delete _feeTiers;

        for (uint256 i; i < feeTiersLength; ) {
            _feeTiers.push(
                FeeTier(feeTiers_[i].feeRecipient, feeTiers_[i].feeTier)
            );

            unchecked {
                ++i;
            }
        }

        emit FeeTierChanged(feeTiers_);
    }

    /**
     * @dev Check if auction is valid
     * @param tokenId_ (uint256) Token ID
     */
    function _onlyValidAuction(uint256 tokenId_) private view {
        if (!_auctionCreated[tokenId_]) {
            revert InvalidTokenID();
        }
    }
}