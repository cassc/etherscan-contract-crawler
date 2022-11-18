// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./lib/IWCNFTErrorCodes.sol";
import "./lib/WCNFTToken.sol";

contract HilmaafKlint is
    ReentrancyGuard,
    WCNFTToken,
    IWCNFTErrorCodes,
    DefaultOperatorFilterer,
    ERC721A
{
    struct RefundData {
        address receiver; // address to send wei to
        uint256 amount; // amount in wei
    }

    struct User {
        uint216 contribution; // cumulative sum of ETH bids
        uint32 tokensClaimed; // tracker for claimed tokens
        bool refundClaimed; // has user been refunded yet
    }

    mapping(address => User) public userData;

    uint256 public numberOfBids; // used externally to make sure we have all bids
    uint256 public price;

    uint256 public constant MAX_SUPPLY = 386;
    uint256 public minimumContribution = 0.15 ether;

    string public provenance;
    string private _baseURIextended;
    address payable public immutable shareholderAddress;
    bool public auctionActive;

    /// Emitted when a bid has been placed
    event Bid(
        address indexed bidder,
        uint256 bidAmount,
        uint256 bidderTotal,
        uint256 bucketTotal,
        uint256 numberOfBids
    );

    /// Attempted access to inactive auction sale
    error AuctionIsNotActive();

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

    /// Refund failed
    error RefundFailed();

    /// Bid is less than the clearing price
    error BidIsLessThanClearingPrice();

    /// Refund amount exceeds contribution
    error RefundAmountExceedsContribution();

    constructor(address payable shareholderAddress_)
        ERC721A("Hilma af Klint - Paintings for the Temple", "HAK")
        WCNFTToken()
    {
        if (shareholderAddress_ == address(0)) revert ZeroAddressProvided();

        // set immutable variables
        shareholderAddress = shareholderAddress_;
    }

    /**
     * @dev checks to see if amount of tokens to be minted would exceed the maximum supply allowed
     * @param numberOfTokens the number of tokens to be minted
     */
    modifier supplyAvailable(uint256 numberOfTokens) {
        if (_totalMinted() + numberOfTokens > MAX_SUPPLY)
            revert ExceedsMaximumSupply();
        _;
    }

    /***************************************************************************
     * Auction
     */

    modifier isAuctionActive() {
        if (!auctionActive) revert AuctionIsNotActive();
        _;
    }

    modifier isPriceSet() {
        if (price == 0) revert PriceHasNotBeenSet();
        _;
    }

    /**
     * @notice begin the auction.
     * @dev cannot be reactivated after price has been set.
     * @param _b set 'true' to start auction, set 'false' to stop auction.
     */
    function setAuctionActive(bool _b) external onlyRole(SUPPORT_ROLE) {
        if (price != 0) revert PriceHasBeenSet();
        auctionActive = _b;
    }

    /**
     * @notice place a bid in ETH or add to your existing bid. Calling this
     *   multiple times will increase your bid amount. All bids placed are final
     *   and cannot be reversed.
     */
    function bid() external payable isAuctionActive {
        User storage bidder = userData[msg.sender]; // get user's current bid total
        uint256 contribution_ = bidder.contribution; // bidder.contribution is uint216
        unchecked {
            // does not overflow
            numberOfBids++;
            contribution_ += msg.value;
        }

        if (contribution_ < minimumContribution)
            revert LowerThanMinimumBidAmount();
        bidder.contribution = uint216(contribution_);

        emit Bid(
            msg.sender,
            msg.value,
            contribution_,
            address(this).balance,
            numberOfBids
        );
    }

    /**
     * @notice set the minimum contribution required to place a bid
     * @dev set this price in wei, not eth!
     * @param minimumContributionInWei_ new price, set in wei
     */
    function setMinimumContribution(uint256 minimumContributionInWei_)
        external
        onlyRole(SUPPORT_ROLE)
    {
        minimumContribution = minimumContributionInWei_;
    }

    /**
     * @notice set the clearing price after all bids have been placed.
     * @dev set this price in wei, not eth!
     * @param priceInWei_ new price, set in wei
     */
    function setPrice(uint256 priceInWei_)
        external
        onlyRole(SUPPORT_ROLE)
    {
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
     * @notice send tokens to a batch of addresses.
     * @param addresses array of addresses to send tokens to.
     */
    function sendTokens(address[] calldata addresses)
        external
        onlyRole(SUPPORT_ROLE)
        isPriceSet
    {
        for (uint256 index; index < addresses.length; index++) {
            address to = addresses[index];
            User storage user = userData[to];
            uint32 claimed = user.tokensClaimed;

            // check for errors
            claimed += 1;
            if (claimed > 1) revert SendingMoreThanPurchased();
            if (user.contribution < price) revert BidIsLessThanClearingPrice();
            user.tokensClaimed = claimed;

            _internalMint(to, 1);
        }
    }

    /**
     * @notice send refunds to a batch of addresses.
     * @dev amount is in wei
     * @param refundData array of refund information { receiver / amount }.
     */
    function sendRefund(RefundData[] calldata refundData)
        external
        onlyRole(SUPPORT_ROLE)
        isPriceSet
    {
        for (uint256 index; index < refundData.length; index++) {
            address to = refundData[index].receiver;
            uint256 refundAmount = refundData[index].amount;
            User storage user = userData[to];

            // check for errors
            if (user.refundClaimed) revert RefundClaimed();
            if (user.contribution < refundAmount)
                revert RefundAmountExceedsContribution();
            user.refundClaimed = true;

            (bool success, ) = to.call{value: refundAmount}("");
            if (!success) revert RefundFailed();
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
        supplyAvailable(numberOfTokens)
        nonReentrant
    {
        _safeMint(to, numberOfTokens);
    }

    /***************************************************************************
     * Tokens
     */

    /**
     * @dev sets the base uri for {_baseURI}
     * @param baseURI_ the base uri
     */
    function setBaseURI(string memory baseURI_)
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
    function setProvenance(string memory provenance_)
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
        override(ERC721A, WCNFTToken)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     * @param tokenId the token id to burn
     * @param approvalCheck check to see whether msg.sender is approved to burn the token
     */
    function _burn(uint256 tokenId, bool approvalCheck)
        internal
        virtual
        override
    {
        super._burn(tokenId, approvalCheck);
        _resetTokenRoyalty(tokenId);
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


    /***************************************************************************
     * Operator Filterer
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}