// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./lib/IWCNFTErrorCodes.sol";
import "./lib/WCNFTToken.sol";
import "./lib/ERC721AOpensea.sol";
import "./lib/SteppedDutchAuction.sol";

contract EkosGenesisArtCollection is
    ReentrancyGuard,
    SteppedDutchAuction,
    WCNFTToken,
    IWCNFTErrorCodes,
    ERC721AOpensea
{
    struct User {
        uint216 contribution; // cumulative sum of ETH bids
        uint32 tokensClaimed; // tracker for claimed tokens
        bool refundClaimed; // has user been refunded yet
    }

    struct ReceiverData {
        address to; // address to send tokens to
        uint32 numberOfTokens; // number of tokens to send
    }

    mapping(address => User) public userData;
    uint256 public numberOfBids; // used externally to make sure we have all bids
    uint256 public price;
    uint256 public constant MAX_SUPPLY = 995;
    uint256 public auctionTotal;
    uint256 public minimumPreBuyPrice;

    string public provenance;
    string private _baseURIextended;
    address payable public immutable shareholderAddress;
    bool public preBuyActive;

    /// Emitted when a bid has been placed
    event Bid(
        address indexed bidder,
        uint256 bidAmount,
        uint256 bidderTotal,
        uint256 auctionTotal,
        uint256 numberOfBids,
        uint256 currentAuctionPrice
    );

    /// Emitted when a deposit is made in the pre buy phase
    event Deposit(
        address indexed depositor,
        uint256 depositAmount,
        uint256 depositTotal,
        uint256 auctionTotal,
        uint256 currentPreBuyPrice
    );

    /// Emitted when a refund has failed
    event RefundFailed(address to, uint256 refundValue);

    /// Clearing price has been set
    error PriceHasBeenSet();

    /// Clearing price has not been set
    error PriceHasNotBeenSet();

    /// Bid is less than minimum amount
    error LowerThanMinimumBidAmount();

    /// User can still add bids
    error UserCanStillAddBids();

    /// Trying to send more tokens than they purchased
    error SendingMoreThanPurchased();

    /// Address has already claimed their refund
    error RefundClaimed();

    /// Already sent tokens to this address
    error TokensAlreadySent();

    /// Pre buy phase is not active
    error PreBuyIsNotActive();

    /// Pre buy phase is active
    error PreBuyIsActive();

    /// Deposit is less than minimum amount
    error LowerThanMinimumDepositAmount();

    /// Dutch auction has started
    error DutchAuctionHasStarted();

    constructor(address payable shareholderAddress_)
        ERC721A("EkosGenesisArtCollection", "EGA")
        WCNFTToken()
    {
        if (shareholderAddress_ == address(0)) revert ZeroAddressProvided();

        // set immutable variables
        shareholderAddress = shareholderAddress_;
    }

    /**
     * @dev checks to see if amount of tokens to be minted would exceed the
     *   maximum supply allowed
     * @param numberOfTokens the number of tokens to be minted
     */
    modifier supplyAvailable(uint256 numberOfTokens) {
        if (_totalMinted() + numberOfTokens > MAX_SUPPLY)
            revert ExceedsMaximumSupply();
        _;
    }

    /**
     * @dev checks if pre buy is active
     */
    modifier isPreBuyActive() {
        if (!preBuyActive) revert PreBuyIsNotActive();
        _;
    }

    /***************************************************************************
     * Pre buy phase
     */

    /**
     * @notice allows pre buy phase. Cannot be executed if price has been set or
     *   if auction is active.
     * @param state the state of the pre buy phase
     */
    function setPreBuyActive(bool state) external onlyRole(SUPPORT_ROLE) {
        if (auctionActive) revert DutchAuctionIsActive();
        if (price != 0) revert PriceHasBeenSet();
        preBuyActive = state;
    }

    /**
     * @notice set the minimum deposit price for pre buy phase
     * @dev set this price in wei, not eth!
     * @param minimumPreBuyPriceInWei new price, set in wei
     */
    function setMinimumPreBuyPrice(uint256 minimumPreBuyPriceInWei)
        external
        onlyRole(SUPPORT_ROLE)
    {
        minimumPreBuyPrice = minimumPreBuyPriceInWei;
    }

    /**
     * @notice place a deposit in ETH or add to your existing deposit. Calling this
     *   multiple times will increase your deposit amount. All bids placed are final
     *   and cannot be reversed.
     */
    function deposit() external payable isPreBuyActive {
        User storage bidder = userData[msg.sender]; // get user's current bid total
        uint256 contribution_ = bidder.contribution; // bidder.contribution is uint216
        uint256 auctionTotal_ = auctionTotal;
        unchecked {
            // does not overflow
            contribution_ += msg.value;
            auctionTotal_ += msg.value;
            auctionTotal = auctionTotal_;
        }

        if (contribution_ < minimumPreBuyPrice)
            revert LowerThanMinimumDepositAmount();
        bidder.contribution = uint216(contribution_);
        emit Deposit(
            msg.sender,
            msg.value,
            contribution_,
            auctionTotal_,
            minimumPreBuyPrice
        );
    }

    /***************************************************************************
     * Auction
     */

    /**
     * @notice See {SteppedDutchAuction-_createNewAuction}.
     */
    function createNewAuction(
        uint256 startPrice,
        uint256 finalPrice,
        uint256 priceStep,
        uint256 timeStepSeconds
    ) external onlyRole(SUPPORT_ROLE) {
        if (startTime > 0) revert DutchAuctionHasStarted();

        _createNewAuction(startPrice, finalPrice, priceStep, timeStepSeconds);
    }

    /**
     * @notice See {SteppedDutchAuction-_startAuction}. Cannot be executed if
     *   price has been set or if pre buy phase is active.
     */
    function startAuction() external onlyRole(SUPPORT_ROLE) {
        if (preBuyActive) revert PreBuyIsActive();
        if (price != 0) revert PriceHasBeenSet();
        _startAuction();
    }

    /**
     * @notice See {SteppedDutchAuction-_resumeAuction}. Cannot be executed if
     *   price has been set.
     */
    function resumeAuction() external onlyRole(SUPPORT_ROLE) {
        if (price != 0) revert PriceHasBeenSet();
        _resumeAuction();
    }

    /**
     * @notice See {SteppedDutchAuction-_endAuction}.
     */
    function endAuction() external onlyRole(SUPPORT_ROLE) {
        _endAuction();
    }

    /**
     * @notice place a bid in ETH or add to your existing bid. Calling this
     *   multiple times will increase your bid amount. All bids placed are final
     *   and cannot be reversed.
     */
    function bid() external payable isAuctionActive {
        User storage bidder = userData[msg.sender]; // get user's current bid total
        uint256 contribution_ = bidder.contribution; // bidder.contribution is uint216
        uint256 auctionTotal_ = auctionTotal;
        unchecked {
            // does not overflow
            numberOfBids++;
            contribution_ += msg.value;
            auctionTotal_ += msg.value;
            auctionTotal = auctionTotal_;
        }

        uint256 currentAuctionPrice = getAuctionPrice();
        if (contribution_ < currentAuctionPrice)
            revert LowerThanMinimumBidAmount();
        bidder.contribution = uint216(contribution_);
        emit Bid(
            msg.sender,
            msg.value,
            contribution_,
            auctionTotal_,
            numberOfBids,
            currentAuctionPrice
        );
    }

    /**
     * @notice set the clearing price after all bids have been placed.
     * @dev set this price in wei, not eth!
     * @param priceInWei_ new price, set in wei
     */
    function setPrice(uint256 priceInWei_) external onlyOwner {
        if (auctionActive) revert UserCanStillAddBids();
        price = priceInWei_;
    }

    /**
     * @dev handles all minting.
     * @param to address to mint tokens to.
     * @param numberOfTokens number of tokens to mint.
     */
    function _internalMint(address to, uint256 numberOfTokens)
        internal
        supplyAvailable(numberOfTokens)
    {
        _safeMint(to, numberOfTokens);
    }

    /**
     * @dev get the maximum number of tokens purchased by an address, after the
     *   clearing price has been set.
     * @param a address to query.
     */
    function amountPurchased(address a) external view returns (uint256) {
        if (price == 0) revert PriceHasNotBeenSet();
        return userData[a].contribution / price;
    }

    /**
     * @dev use to get amountPurchased() for arbitrary contribution and price
     * @param _contribution theoretical bid contribution
     * @param _price theoretical clearing price
     */
    function _amountPurchased(uint256 _contribution, uint256 _price)
        internal
        pure
        returns (uint256)
    {
        return _contribution / _price;
    }

    /**
     * @dev handles multiple send tokens and refund methods.
     * @param receiver address to send tokens and refund.
     */
    function _sendTokensAndRefund(ReceiverData calldata receiver) internal {
        uint256 price_ = price;

        address to = receiver.to;
        uint32 numberOfTokens = receiver.numberOfTokens;
        User storage user = userData[to]; // get user data
        uint256 userContribution = user.contribution;

        // send tokens first, calculate the maximum amount of tokens purchased
        uint256 maxNumberOfTokens = _amountPurchased(userContribution, price_);
        if (numberOfTokens > maxNumberOfTokens)
            revert SendingMoreThanPurchased();

        if (numberOfTokens > 0) {
            if (user.tokensClaimed != 0) revert TokensAlreadySent();
            user.tokensClaimed = uint32(numberOfTokens);
            _internalMint(to, numberOfTokens);
        }

        // send refund
        if (user.refundClaimed) revert RefundClaimed();
        user.refundClaimed = true;
        uint256 refundValue = userContribution - (price_ * numberOfTokens);

        if (refundValue > 0) {
            bool success;
            assembly {
                success := call(30000, to, refundValue, 0, 0, 0, 0)
            }
            if (!success) emit RefundFailed(to, refundValue);
        }
    }

    /**
     * @notice send refunds and tokens to an address.
     * @dev can only be called after the clearing price has been set.
     * @param receiver address to send tokens and refund.
     */
    function sendTokensAndRefund(ReceiverData calldata receiver)
        external
        onlyOwner
        nonReentrant
    {
        if (price == 0) revert PriceHasNotBeenSet();

        _sendTokensAndRefund(receiver);
    }

    /**
     * @notice send refunds and tokens to a batch of addresses.
     * @param receivers array of addresses to send tokens and refunds.
     */
    function sendTokensAndRefundBatch(ReceiverData[] calldata receivers)
        external
        onlyOwner
        nonReentrant
    {
        if (price == 0) revert PriceHasNotBeenSet();

        uint256 receiversLength = receivers.length;
        for (uint256 i; i < receiversLength; i++) {
            _sendTokensAndRefund(receivers[i]);
        }
    }

    /***************************************************************************
     * Admin
     */

    /**
     * @dev reserves a number of tokens
     * @param to recipient address
     * @param numberOfTokens the number of tokens to be minted
     */
    function devMint(address to, uint256 numberOfTokens)
        external
        onlyRole(SUPPORT_ROLE)
        nonReentrant
    {
        _internalMint(to, numberOfTokens);
    }

    /***************************************************************************
     * Tokens
     */

    /**
     * @dev sets the base uri for {_baseURI}
     * @param baseURI_ the base uri
     */
    function setBaseURI(string calldata baseURI_)
        external
        onlyRole(SUPPORT_ROLE)
    {
        _baseURIextended = baseURI_;
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * @dev sets the provenance hash
     * @param provenance_ the provenance hash
     */
    function setProvenance(string calldata provenance_)
        external
        onlyRole(SUPPORT_ROLE)
    {
        provenance = provenance_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     * @param interfaceId the interface id
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AOpensea, WCNFTToken)
        returns (bool)
    {
        return
            ERC721AOpensea.supportsInterface(interfaceId) ||
            WCNFTToken.supportsInterface(interfaceId);
    }

    /***************************************************************************
     * Withdraw
     */

    /**
     * @dev withdraws ether from the contract to the shareholder address
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = shareholderAddress.call{
            value: address(this).balance
        }("");
        if (!success) revert WithdrawFailed();
    }
}