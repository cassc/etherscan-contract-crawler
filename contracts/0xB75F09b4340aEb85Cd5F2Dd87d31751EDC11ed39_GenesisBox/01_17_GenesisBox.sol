// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import "erc721a/contracts/ERC721A.sol";

contract GenesisBox is ERC721A, ERC2981, ReentrancyGuard, AccessControl, Ownable {
    bytes32 public constant SUPPORT_ROLE = keccak256('SUPPORT');
    bytes32 public constant REFUND_ROLE = keccak256('REFUND');

    uint256 public constant MAX_SUPPLY = 24000;
    uint256 public minimumContribution = 0.123 ether;

    string public provenance;
    string private _baseURIextended;

    struct User {
        uint216 contribution; // cumulative sum of ETH bids
        uint32 tokensClaimed; // tracker for claimed tokens
        bool refundClaimed; // has user been refunded yet
    }
    mapping(address => User) public userData;

    uint256 public price;

    address payable public immutable withdrawAddress;
    bool public auctionActive;

    event Bid(address bidder, uint256 bidAmount, uint256 bidderTotal, uint256 bucketTotal);

    constructor(address payable withdrawAddress_) ERC721A("Genesis Box", "GBOX") {
        require(withdrawAddress_ != address(0));

        // set immutable variables
        withdrawAddress = withdrawAddress_;

        // set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPORT_ROLE, msg.sender);
    }

    modifier isAuctionActive() {
        require(auctionActive, "Auction is not active");
        _;
    }

    /**
    * @notice begin the auction.
    * @dev cannot be reactivated after price has been set.
    * @param _b set 'true' to start auction, set 'false' to stop auction.
    */
    function setAuctionActive(bool _b) external onlyRole(SUPPORT_ROLE) {
        require(price == 0, "Price has been set");
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
        unchecked { // does not overflow
            contribution_ += msg.value;
        }
        require(contribution_ >= minimumContribution, "Lower than min bid amount");
        bidder.contribution = uint216(contribution_);
        emit Bid(msg.sender, msg.value, contribution_, address(this).balance);
    }

    
    /**
    * @notice set the minimum contribution required to place a bid
    * @dev set this price in wei, not eth!
    * @param minimumContributionInWei_ new price, set in wei
    */
    function setMinimumContribution(uint256 minimumContributionInWei_) external onlyRole(SUPPORT_ROLE) {
        minimumContribution = minimumContributionInWei_;
    }

    /**
    * @notice set the clearing price after all bids have been placed.
    * @dev set this price in wei, not eth!
    * @param priceInWei_ new price, set in wei
    */
    function setPrice(uint256 priceInWei_) external onlyRole(SUPPORT_ROLE) {
        require(!auctionActive, "Users can still add bids");
        price = priceInWei_;
    }

    /**
    * @dev handles all minting.
    * @param to address to mint tokens to.
    * @param numberOfTokens number of tokens to mint.
    */
    function _internalMint(address to, uint256 numberOfTokens) internal {
        uint256 ts = _totalMinted(); // ignore burn counter here
        require(ts + numberOfTokens <= MAX_SUPPLY, 'Number would exceed max supply');
        _safeMint(to, numberOfTokens);
    }

    /**
    * @dev handles multiple send tokens methods.
    * @param to address to send tokens to.
    * @param n number of tokens to send.
    */
    function _sendTokens(address to, uint256 n) internal {
        uint256 price_ = price; // storage to memory
        require(price_ != 0, "Price has not been set");

        User storage user = userData[to]; // get user data
        uint256 claimed_ = user.tokensClaimed; // user.tokensClaimed is uint32
        claimed_ += n; 
        
        require(
            claimed_ <= _amountPurchased(user.contribution, price_), 
            "Trying to send more than they purchased."
        );
        user.tokensClaimed = uint32(claimed_);
        _internalMint(to, n);
    }

    /**
    * @notice get the number of tokens purchased by an address, after the
    *   clearing price has been set.
    * @param a address to query.
    */
    function amountPurchased(address a) public view returns (uint256) {
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
    * @notice get the refund amount for an account, after the clearing price
    *   has been set.
    * @param a address to query.
    */
    function refundAmount(address a) public view returns (uint256) {
        return userData[a].contribution % price;
    }

    /**
    * @dev helper to get refundAmount() for arbitrary contribution and price 
    * @param _contribution theoretical bid contribution
    * @param _price theoretical clearing price
    */
    function _refundAmount(uint256 _contribution, uint256 _price) 
        internal
        pure
        returns (uint256)
    {
        return _contribution % _price;
    }

    // functions for project owner to pay to send tokens/refund

    /**
    * @notice mint tokens to an address.
    * @dev purchased amount for an address can be sent in multiple calls.
    *   Can only be called after clearing price has been set.
    * @param to address to send tokens to.
    * @param n number of tokens to send.
    */
    function sendTokens(address to, uint256 n) public onlyRole(REFUND_ROLE) {
        _sendTokens(to, n);
    }

    /**
    * @notice send all of an address's purchased tokens.
    * @dev if some tokens have already been sent, the remainder must be sent
    *   using sendTokens().
    * @param to address to send tokens to.
    */
    function sendAllTokens(address to) public onlyRole(REFUND_ROLE) {
        _sendTokens(to, amountPurchased(to));
    }

    /**
    * @notice send refund to an address. Refunds are unsuccessful bids or
    *   an address's remaining eth after all their tokens have been paid for.
    * @dev can only be called after the clearing price has been set.
    * @param to the address to refund.
    */
    function sendRefund(address to) public onlyRole(REFUND_ROLE) nonReentrant {
        uint256 price_ = price; // storage to memory
        require(price_ != 0, "Price has not been set");
        
        User storage user = userData[to]; // get user data
        require(!user.refundClaimed, "Address has already claimed their refund.");
        user.refundClaimed = true; 
        
        uint256 refundValue = _refundAmount(user.contribution, price_);
        (bool success, ) = to.call{value: refundValue}("");
        require(success, "Refund failed.");
    }

    /**
    * @notice send refunds to a batch of addresses.
    * @param addresses array of addresses to refund.
    */
    function sendRefundBatch(address[] calldata addresses) external onlyRole(REFUND_ROLE) {
        for (uint256 i; i < addresses.length; i++) {
            sendRefund(addresses[i]);
        }
    }

    /**
    * @notice send tokens to a batch of addresses.
    * @param addresses array of addresses to send tokens to.
    */
    function sendTokensBatch(address[] calldata addresses) external onlyRole(REFUND_ROLE) {
        for (uint256 i; i < addresses.length; i++) {
            _sendTokens(addresses[i], amountPurchased(addresses[i]));
        }
    }

    /**
    * @notice send refunds and tokens to an address.
    * @dev can only be called after the clearing price has been set.
    * @param to the address to refund.
    */
    function sendTokensAndRefund(address to) public onlyRole(REFUND_ROLE) nonReentrant {
        uint256 price_ = price;
        require(price_ != 0, "Price has not been set");

        User storage user = userData[to]; // get user data
        uint256 userContribution = user.contribution;

        // send refund
        require(!user.refundClaimed, "Already sent refunds to this address.");
        user.refundClaimed = true;
        uint256 refundValue = _refundAmount(userContribution, price_);
        (bool success, ) = to.call{value: refundValue}("");
        require(success, "Refund failed.");

        // send tokens
        uint256 n = _amountPurchased(userContribution, price_);
        if (n > 0) {
            require(user.tokensClaimed == 0, "Already sent tokens to this address.");
            user.tokensClaimed = uint32(n);
            _internalMint(to, n);
        }
    }

    /**
    * @notice send refunds and tokens to a batch of addresses.
    * @param addresses array of addresses to send tokens to.
    */
    function sendTokensAndRefundBatch(address[] calldata addresses) external onlyRole(REFUND_ROLE) {
        for (uint256 i; i < addresses.length; i++) {
            sendTokensAndRefund(addresses[i]);
        }
    }

    /**
    * @notice mint reserve tokens.
    * @param n number of tokens to mint.
    */
    function reserve(uint256 n) external onlyOwner {
        _internalMint(msg.sender, n);
    }

    /**
    * @notice burn a token you own.
    * @param tokenId token ID to burn.
    */
    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
        _resetTokenRoyalty(tokenId);
    }

    ////////////////
    // tokens
    ////////////////
    /**
     * @dev sets the base uri for {_baseURI}
     */
    function setBaseURI(string memory baseURI_) external onlyRole(SUPPORT_ROLE) {
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
     */
    function setProvenance(string memory provenance_) external onlyRole(SUPPORT_ROLE) {
        provenance = provenance_;
    }

    /**
     * @dev withdraw function for owner.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = withdrawAddress.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    ////////////////
    // royalty
    ////////////////
    /**
     * @dev See {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(SUPPORT_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyRole(SUPPORT_ROLE) {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev See {ERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(SUPPORT_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyRole(SUPPORT_ROLE) {
        _resetTokenRoyalty(tokenId);
    }
}