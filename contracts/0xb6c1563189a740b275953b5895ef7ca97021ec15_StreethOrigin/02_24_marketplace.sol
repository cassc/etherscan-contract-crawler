// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./streethorigin.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IMediaModified {
    mapping(uint256 => address) public tokenCreators;
    address public marketContract;
}

contract StreethersMarketplace is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint256 public nftCount;
    
    // Use OpenZeppelin's SafeMath library to prevent overflows.
    using SafeMath for uint256;

    // ============ Constants ============

    // The minimum amount of time left in an auction after a new bid is created; 15 min.
    uint16 public constant TIME_BUFFER = 900;
    // The MATIC needed above the current bid for a new bid to be valid; 0.001 MATIC.
    uint8 public constant MIN_BID_INCREMENT_PERCENT = 10;
    // Interface constant for ERC721, to check values in constructor.
    bytes4 private constant ERC721_INTERFACE_ID = 0x80ac58cd;
    // Allows external read `getVersion()` to return a version for the auction.
    uint256 private constant RESERVE_AUCTION_VERSION = 1;

    // ============ Immutable Storage ============

    // The address of the ERC721 contract for tokens auctioned via this contract.
    address public immutable nftContract;
    // The address of the WMATIC contract, so that MATIC can be transferred via
    // WMATIC if native MATIC transfers fail.
    address public immutable tokenContract;
    // The address that initially is able to recover assets.
    address public immutable adminRecoveryAddress;

    // team addresses
    mapping(address => bool) private whitelistMap;

    bool private _adminRecoveryEnabled;

    bool private _paused;
    
    mapping(uint256 => uint) public getTokenId;
    mapping(uint => uint256) public price;
    mapping(uint => bool) public listedMap;
    // A mapping of all of the auctions currently running.
    mapping(uint256 => Auction) public auctions;
    mapping(uint => address) public ownerMap;

    // ============ Structs ============

    struct Auction {
        // The value of the current highest bid.
        uint256 amount;
        // The amount of time that the auction should run for,
        // after the first bid was made.
        uint256 duration;
        // The time of the first bid.
        uint256 firstBidTime;
        // The minimum price of the first bid.
        uint256 reservePrice;
        uint8 CreatorFeePercent;
        // The address of the auction's Creator. The Creator
        // can cancel the auction if it hasn't had a bid yet.
        address Creator;
        // The address of the current highest bid.
        address bidder;
        // The address that should receive funds once the NFT is sold.
        address fundsRecipient;
    }

    // ============ Events ============

    // All of the details of a new auction,
    // with an index created for the tokenId.
    event AuctionCreated(
        uint256 indexed tokenId,
        uint256 auctionStart,
        uint256 duration,
        uint256 reservePrice,
        address Creator
    );

    // All of the details of a new bid,
    // with an index created for the tokenId.
    event AuctionBid(
        uint256 indexed tokenId,
        address nftContractAddress,
        address sender,
        uint256 value,
        uint256 duration
    );

    // All of the details of an auction's cancelation,
    // with an index created for the tokenId.
    event AuctionCanceled(
        uint256 indexed tokenId,
        address nftContractAddress,
        address Creator
    );

    // All of the details of an auction's close,
    // with an index created for the tokenId.
    event AuctionEnded(
        uint256 indexed tokenId,
        address nftContractAddress,
        address Creator,
        address winner,
        uint256 amount
    );

    // When the Creator recevies fees, emit the details including the amount,
    // with an index created for the tokenId.
    event CreatorFeePercentTransfer(
        uint256 indexed tokenId,
        address indexed Creator,
        uint256 amount
    );

    // Emitted in the case that the contract is paused.
    event Paused(address account);
    // Emitted when the contract is unpaused.
    event Unpaused(address account);
    event Purchase(address indexed previousOwner, address indexed newOwner, uint256 price, uint nftID);
    event Minted(address indexed minter, uint256 price, uint nftID, string uri);
    event Burned(uint nftID);
    event PriceUpdate(address indexed owner, uint256 oldPrice, uint256 newPrice, uint nftID);
    event NftListStatus(address indexed owner, uint nftID, bool isListed);
    event Withdrawn(uint256 amount, address wallet);
    event TokensWithdrawn(uint256 amount, address wallet);
    event Received(address, uint);
    event WhitelistAddress(address updatedAddress);
    event UnwhitelistAddress(address updatedAddress);

    // ============ Modifiers ============

    // Reverts if the sender is not admin, or admin
    // functionality has been turned off.
    modifier onlyAdminRecovery() {
        require(
            // The sender must be the admin address, and
            // adminRecovery must be set to true.
            adminRecoveryAddress == msg.sender && adminRecoveryEnabled(),
            "Caller does not have admin privileges"
        );
        _;
    }

    // Reverts if the sender is not the auction's Creator.
    modifier onlyCreator(uint256 tokenId) {
        require(
            auctions[tokenId].Creator == msg.sender,
            "Can only be called by auction Creator"
        );
        _;
    }

    // Reverts if the sender is not the auction's Creator or winner.
    modifier onlyCreatorOrWinner(uint256 tokenId) {
        require(
            auctions[tokenId].Creator == msg.sender || auctions[tokenId].bidder == msg.sender,
            "Can only be called by auction Creator"
        );
        _;
    }

    // Reverts if the contract is paused.
    modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    // Reverts if the auction does not exist.
    modifier auctionExists(uint256 tokenId) {
        // The auction exists if the Creator is not null.
        require(!auctionCreatorIsNull(tokenId), "Auction doesn't exist");
        _;
    }

    // Reverts if the auction exists.
    modifier auctionNonExistant(uint256 tokenId) {
        // The auction does not exist if the Creator is null.
        require(auctionCreatorIsNull(tokenId), "Auction already exists");
        _;
    }

    // Reverts if the auction is expired.
    modifier auctionNotExpired(uint256 tokenId) {
        require(
            // Auction is not expired if there's never been a bid, or if the
            // current time is less than the time at which the auction ends.
            auctions[tokenId].firstBidTime == 0 ||
                block.timestamp < auctionEnds(tokenId),
            "Auction expired"
        );
        _;
    }

    // Reverts if the auction is not complete.
    // Auction is complete if there was a bid, and the time has run out.
    modifier auctionComplete(uint256 tokenId) {
        require(
            // Auction is complete if there has been a bid, and the current time
            // is greater than the auction's end time.
            auctions[tokenId].firstBidTime > 0 &&
                block.timestamp >= auctionEnds(tokenId),
            "Auction hasn't completed"
        );
        _;
    }

    // ============ Constructor ============

    constructor(
        address nftContract_,
        address tokenContract_,
        address adminRecoveryAddress_
    ) {
        require(address(0) != nftContract_, "Zero Address Validation");
        require(address(0) != tokenContract_, "Zero Address Validation");
        require(address(0) != adminRecoveryAddress_, "Zero Address Validation");

        require(
            IERC165(nftContract_).supportsInterface(ERC721_INTERFACE_ID),
            "Contract at nftContract_ address does not support NFT interface"
        );
        // Initialize immutable memory.
        nftContract = nftContract_;
        tokenContract = tokenContract_;
        adminRecoveryAddress = adminRecoveryAddress_;
        // Initialize mutable memory.
        _paused = false;
        _adminRecoveryEnabled = true;
    }

    function openTrade(uint _id, uint256 _price)
    public
    {
        require(ownerMap[_id] == msg.sender, "sender is not owner");
        require(listedMap[_id] == false, "Already opened");
        StreethOrigin(nftContract).approve(address(this), _id);
        StreethOrigin(nftContract).transferFrom(msg.sender, address(this), _id);
        listedMap[_id] = true;
        price[_id] = _price;
    }

    function closeTrade(uint _id)
    public
    {
        require(ownerMap[_id] == msg.sender, "sender is not owner");
        require(listedMap[_id] == true, "Already colsed");
        StreethOrigin(nftContract).transferFrom(address(this), msg.sender, _id);
        listedMap[_id] = false;
    }
    
    function buy(uint[] memory _ids) external {
        for (uint i = 0; i < _ids.length; i ++) {
            _validate(_ids[i]);
            address _previousOwner = ownerMap[_ids[i]];
            address _newOwner = msg.sender;

            // 2.5% commission cut
            uint256 _commissionValue = price[_ids[i]].mul(25).div(1000);
            uint256 _sellerValue = price[_ids[i]].sub(_commissionValue);

            IERC20(tokenContract).safeTransferFrom(msg.sender, _previousOwner, _sellerValue);
            IERC20(tokenContract).safeTransferFrom(msg.sender, adminRecoveryAddress, _commissionValue);
            StreethOrigin(nftContract).transferFrom(address(this), _newOwner, _ids[i]);
            ownerMap[_ids[i]] = msg.sender;
            listedMap[_ids[i]] = false;
            emit Purchase(_previousOwner, _newOwner, price[_ids[i]], _ids[i]);
        }
    }

    function _validate(uint _id) internal view {
        bool isItemListed = listedMap[_id];
        require(price[_id] != 0, "Item is not minted yet");
        require(isItemListed, "Item not listed currently");
        require(msg.sender != StreethOrigin(nftContract).ownerOf(_id), "Can not buy what you own");
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelistMap[_address];
    }

    function _unWhitelist(address[] memory _removedAddresses) public onlyAdminRecovery {
        for (uint256 i = 0; i < _removedAddresses.length; i++) {
            whitelistMap[_removedAddresses[i]] = false;
            emit UnwhitelistAddress(_removedAddresses[i]);
        }
    }

    function _whitelist(address[] memory _newAddresses) public onlyAdminRecovery {
        for (uint256 i = 0; i < _newAddresses.length; i++) {
            whitelistMap[_newAddresses[i]] = true;
            emit WhitelistAddress(_newAddresses[i]);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawToken() public onlyOwner {
        uint256 balance = IERC20(tokenContract).balanceOf(address(this));
        IERC20(tokenContract).transfer(msg.sender, balance);
    }
    
    function updatePrice(uint _tokenId, uint256 _price) public returns (bool) {
        uint oldPrice = price[_tokenId];
        require(msg.sender == ownerMap[_tokenId], "Error, you are not the owner");
        price[_tokenId] = _price;

        emit PriceUpdate(msg.sender, oldPrice, _price, _tokenId);
        return true;
    }

    function updateListingStatus(uint _tokenId, bool shouldBeListed) public returns (bool) {
        require(msg.sender == StreethOrigin(nftContract).ownerOf(_tokenId), "Error, you are not the owner");

        listedMap[_tokenId] = shouldBeListed;

        emit NftListStatus(msg.sender, _tokenId, shouldBeListed);

        return true;
    }

    // ============ Create Auction ============

    function createAuction(
        uint256 tokenId,
        uint256 startDate,
        uint256 duration,
        uint256 reservePrice
    ) public nonReentrant whenNotPaused auctionNonExistant(tokenId) {
        // Check basic input requirements are reasonable.
        require(msg.sender != address(0));
        // Initialize the auction details, including null values.
        
        ownerMap[tokenId] = msg.sender;
        openTrade(tokenId, reservePrice);

        require(startDate >= block.timestamp, "Can't create auction in the past!");
        auctions[tokenId] = Auction({
            duration: duration,
            reservePrice: reservePrice,
            CreatorFeePercent: 50,
            Creator: msg.sender,
            fundsRecipient: adminRecoveryAddress,
            amount: 0,
            firstBidTime: startDate,
            bidder: address(0)
        });
        
        // Transfer the NFT into this auction contract, from whoever owns it.

        // Emit an event describing the new auction.
        emit AuctionCreated(
            tokenId,
            startDate,
            duration,
            reservePrice,
            msg.sender
        );
    }

    // ============ Create Bid ============

    function createBid(uint256 tokenId, uint256 amount)
        external
        nonReentrant
        whenNotPaused
        auctionExists(tokenId)
        auctionNotExpired(tokenId)
    {
        // Validate that the user's expected bid value matches the MATIC deposit.
        IERC20(tokenContract).safeTransferFrom(msg.sender, address(this), amount);
        require(amount > 0, "Amount must be greater than 0");
        require(auctions[tokenId].firstBidTime <= block.timestamp, "Auction is not yet started");
        // Check if the current bid amount is 0.
        if (auctions[tokenId].amount == 0) {
            // If so, it is the first bid.
            auctions[tokenId].firstBidTime = block.timestamp;
            // We only need to check if the bid matches reserve bid for the first bid,
            // since future checks will need to be higher than any previous bid.
            require(
                amount >= auctions[tokenId].reservePrice,
                "Must bid reservePrice or more"
            );
        } else {
            // Check that the new bid is sufficiently higher than the previous bid, by
            // the percentage defined as MIN_BID_INCREMENT_PERCENT.
            require(
                amount >=
                    auctions[tokenId].amount.add(
                        // Add 10% of the current bid to the current bid.
                        auctions[tokenId]
                            .amount
                            .mul(MIN_BID_INCREMENT_PERCENT)
                            .div(100)
                    ),
                "Must bid more than last bid by MIN_BID_INCREMENT_PERCENT amount"
            );

            IERC20(tokenContract).safeTransferFrom(address(this), auctions[tokenId].bidder, auctions[tokenId].amount);
        }
        // Update the current auction.
        auctions[tokenId].amount = amount;
        auctions[tokenId].bidder = payable(msg.sender);
        // Compare the auction's end time with the current time plus the 15 minute extension,
        // to see whMATICer we're near the auctions end and should extend the auction.
        if (auctionEnds(tokenId) < block.timestamp.add(TIME_BUFFER)) {
            // We add onto the duration whenever time increment is required, so
            // that the auctionEnds at the current time plus the buffer.
            auctions[tokenId].duration += block.timestamp.add(TIME_BUFFER).sub(
                auctionEnds(tokenId)
            );
        }
        // Emit the event that a bid has been made.
        emit AuctionBid(tokenId, nftContract, msg.sender, amount, auctions[tokenId].duration);
    }

    // ============ End Auction ============

    function endAuction(uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
        auctionComplete(tokenId)
        onlyCreatorOrWinner(tokenId)
    {
        // Store relevant auction data in memory for the life of this function.
        address winner = auctions[tokenId].bidder;
        uint256 amount = auctions[tokenId].amount;
        address Creator = auctions[tokenId].Creator;
        // Remove all auction data for this token from storage.
        delete auctions[tokenId];
        // We don't use safeTransferFrom, to prevent reverts at this point,
        // which would break the auction.
        if(winner == address(0)) {
            StreethOrigin(nftContract).transferFrom(address(this), Creator, tokenId);
            ownerMap[tokenId] = Creator;
        } else {
            StreethOrigin(nftContract).transferFrom(address(this), winner, tokenId);
            uint256 _commissionValue = amount.mul(25).div(1000);
            IERC20(tokenContract).safeTransferFrom(address(this), adminRecoveryAddress, _commissionValue);
            IERC20(tokenContract).safeTransferFrom(address(this), Creator, amount.sub(_commissionValue));
            ownerMap[tokenId] = winner;
        }
        listedMap[tokenId] = false;
        // Emit an event describing the end of the auction.
        emit AuctionEnded(
            tokenId,
            nftContract,
            Creator,
            winner,
            amount
        );
    }

    // ============ Cancel Auction ============

    function cancelAuction(uint256 tokenId)
        external
        nonReentrant
        auctionExists(tokenId)
        onlyCreator(tokenId)
    {
        // Check that there hasn't already been a bid for this NFT.
        require(
            uint256(auctions[tokenId].amount) == 0,
            "Auction already started"
        );
        // Pull the creator address before removing the auction.
        address Creator = auctions[tokenId].Creator;
        // Remove all data about the auction.
        delete auctions[tokenId];
        // Transfer the NFT back to the Creator.
        StreethOrigin(nftContract).transferFrom(address(this), Creator, tokenId);
        listedMap[tokenId] = false;
        ownerMap[tokenId] = Creator;
        // Emit an event describing that the auction has been canceled.
        emit AuctionCanceled(tokenId, nftContract, Creator);
    }

    function mint(string memory _tokenURI, uint256 _price) public {
        require(!_paused, "Can't mint on the paused status");
        require(isWhitelisted(msg.sender), "Not whitelisted");

        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();
        nftCount = newTokenId;
        price[newTokenId] = _price;
        ownerMap[newTokenId] = msg.sender;
        listedMap[newTokenId] = false;

        StreethOrigin(nftContract).mint(newTokenId, msg.sender, _tokenURI);

        emit Minted(msg.sender, _price, newTokenId, _tokenURI);

        openTrade(newTokenId, _price);
    }

    // ============ Admin Functions ============

    // Irrevocably turns off admin recovery.
    function turnOffAdminRecovery() external onlyAdminRecovery {
        _adminRecoveryEnabled = false;
    }

    function pauseContract() external onlyAdminRecovery {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpauseContract() external onlyAdminRecovery {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    // ============ Miscellaneous Public and External ============

    // Returns true if the contract is paused.
    function paused() public view returns (bool) {
        return _paused;
    }

    // Returns true if admin recovery is enabled.
    function adminRecoveryEnabled() public view returns (bool) {
        return _adminRecoveryEnabled;
    }

    // Returns the version of the deployed contract.
    function getVersion() external pure returns (uint256 version) {
        version = RESERVE_AUCTION_VERSION;
    }

    // ============ Private Functions ============

    // Returns true if the auction's Creator is set to the null address.
    function auctionCreatorIsNull(uint256 tokenId) private view returns (bool) {
        // The auction does not exist if the Creator is the null address,
        // since the NFT would not have been transferred in `createAuction`.
        return auctions[tokenId].Creator == address(0);
    }

    // Returns the timestamp at which an auction will finish.
    function auctionEnds(uint256 tokenId) private view returns (uint256) {
        // Derived by adding the auction's duration to the time of the first bid.
        // NOTE: duration can be extended conditionally after each new bid is added.
        return auctions[tokenId].firstBidTime.add(auctions[tokenId].duration);
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}