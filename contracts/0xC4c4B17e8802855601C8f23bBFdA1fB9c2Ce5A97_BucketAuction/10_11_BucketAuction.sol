// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "interfaces/IERC721Mintable.sol";

contract BucketAuction is ReentrancyGuard, AccessControl, Ownable {
    bytes32 public constant SUPPORT_ROLE = keccak256('SUPPORT');
    bytes32 public constant REFUND_ROLE = keccak256('REFUND');

    uint256 public minimumContribution = 0.1 ether;
    uint256 public maxSupply = 3000;

    string public provenance;
    string private _baseURIextended;

    // The block number when the auction end ends.
    uint256 public endTimestamp;

    // The block number when the auction starts.
    uint256 public startTimestamp;

    struct User {
        uint216 contribution; // cumulative sum of ETH bids
        uint32 tokensClaimed; // tracker for claimed tokens
        bool refundClaimed; // has user been refunded yet
    }
    mapping(address => User) public userData;

    uint256 public price;

    address payable public withdrawAddress;
    address payable public immutable erc721;
    uint256 public totalMinted;

    event Bid(address bidder, uint256 bidAmount, uint256 bidderTotal, uint256 bucketTotal);
    event NewMinimumContribution(uint256 minimumContributionInWei);
    event NewPrice(uint256 price);
    event TokensAndRefund(address to, uint256 refandValue, uint256 numNft);
    event NewStartAndEndTime(uint256 startTimestamp, uint256 endTimestamp);
    event NewMaxSupply(uint256 maxSupply);
    event NewWithdrawAddress(address withdrawAddress);

    constructor(address payable withdrawAddress_, address payable _erc721) {
        require(withdrawAddress_ != address(0));

        // set immutable variables
        withdrawAddress = withdrawAddress_;
        erc721 = _erc721;

        // set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPORT_ROLE, msg.sender);
    }

    modifier isAuctionActive() {
        require(block.timestamp >= startTimestamp && block.timestamp <= endTimestamp, "Auction has not started");
        _;
    }

    modifier isAuctionEnded() {
        require(block.timestamp > endTimestamp && endTimestamp != 0, "Auction has started");
        _;
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
        emit NewMinimumContribution(minimumContribution);
    }

    /**
    * @notice set the clearing price after all bids have been placed.
    * @dev set this price in wei, not eth!
    * @param priceInWei_ new price, set in wei
    */
    function setPrice(uint256 priceInWei_) external onlyRole(SUPPORT_ROLE) isAuctionEnded {
        price = priceInWei_;
        emit NewPrice(priceInWei_);
    }

    /**
    * @dev handles all minting.
    * @param to address to mint tokens to.
    * @param numberOfTokens number of tokens to mint.
    */
    function _internalMint(address to, uint256 numberOfTokens) internal {
        uint256 ts = totalMinted; // ignore burn counter here
        require(ts + numberOfTokens <= maxSupply, 'Number would exceed max supply');
        totalMinted = totalMinted + numberOfTokens;
        IERC721Mintable(erc721).mintBucketSmurf(to, numberOfTokens);
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
        emit TokensAndRefund(to, refundValue, n);
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
    * @notice get refund amount for the users
    * @param addresses array of addresses to send tokens to.
    */
    function getRefundAmount(address[] calldata addresses) public view returns(uint256) {
        uint256 res = 0;
        for (uint256 i; i < addresses.length; i++) {
            User storage user = userData[addresses[i]]; // get user data
            uint256 userContribution = user.contribution;
            uint256 refundValue = _refundAmount(userContribution, price);
            res = res + refundValue;
        }
        return res;
    }

    /**
    * @notice get withdraw amount
    * @param addresses array of addresses with bids
    */
    function getWithdrawAmount(address[] calldata addresses) public view returns(uint256) {
        uint256 ref = getRefundAmount(addresses);
        return  address(this).balance - ref;
    }

    ////////////////
    // tokens
    ////////////////
    /**
     * @dev withdraw function for owner.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = withdrawAddress.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /**
     * @dev withdraw function for owner.
     */
    function withdraw(uint256 amount) external onlyOwner {
        (bool success, ) = withdrawAddress.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startTimestamp: the new start timestamp
     * @param _hours: the duration in hours
     */
    function updateStartAndEndTimestamp(uint _startTimestamp, uint _hours) external onlyOwner {
        require(block.timestamp <= _startTimestamp || startTimestamp > 0, "New startBlock must be higher than current block");

        startTimestamp = _startTimestamp;
        uint256 _endTimestamp = _startTimestamp + _hours * 1 hours;
        endTimestamp = _endTimestamp;

        emit NewStartAndEndTime(_startTimestamp, _endTimestamp);
    }

    /**
     * @notice It sets the maximum supply limit
     * @dev This function is only callable by owner.
     * @param _maxSupply: the new max supply
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        // require(block.number < startBlock || _startBlock == 0, "Auction has started");
        maxSupply = _maxSupply;
        emit NewMaxSupply(_maxSupply);
    }

    /**
     * @notice It sets the withdraw address
     * @dev This function is only callable by owner.
     * @param _withdrawAddress: the new withdraw address
     */
    function setWithdrawAddress(address payable _withdrawAddress) external onlyOwner {
        // require(block.number < startBlock || _startBlock == 0, "Auction has started");
        withdrawAddress = _withdrawAddress;
        emit NewWithdrawAddress(_withdrawAddress);
    }
}