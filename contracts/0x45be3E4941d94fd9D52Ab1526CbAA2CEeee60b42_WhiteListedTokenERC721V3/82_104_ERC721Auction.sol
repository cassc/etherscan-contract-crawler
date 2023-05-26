// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../tge/interfaces/IBEP20.sol";
import "../tokens/HasSecondarySale.sol";
import "../proxy/ServiceFeeProxy.sol";
import "../roles/AdminRole.sol";
import "../libs/BidLibrary.sol";
import "../managers/TradeTokenManager.sol";
import "../managers/NftTokenManager.sol";
import "../service_fee/RoyaltiesStrategy.sol";

/**
 * @notice Primary sale auction contract for Refinable NFTs
 */
contract ERC721Auction is Context, ReentrancyGuard, AdminRole, RoyaltiesStrategy {
    using SafeMath for uint256;
    using Address for address payable;
    using BidLibrary for BidLibrary.Bid[];

    /// @notice Event emitted only on construction. To be used by indexers
    event AuctionContractDeployed();

    event PauseToggled(bool isPaused);

    event Destroy();

    event AuctionCreated(bytes32 auctionId, address token, uint256 indexed tokenId, address payToken);

    event AuctionCreateTimeLimitUpdated(uint256 auctionCreateTimeLimit);

    event AuctionStartTimeUpdated(bytes32 auctionId, address token, uint256 indexed tokenId, uint256 startTime);

    event AuctionEndTimeUpdated(bytes32 auctionId, address token, uint256 indexed tokenId, uint256 endTime);

    event MinBidIncrementBpsUpdated(uint256 minBidIncrementBps);

    event MaxBidStackCountUpdated(uint256 maxBidStackCount);

    event BidWithdrawalLockTimeUpdated(uint256 bidWithdrawalLockTime);

    event BidPlaced(
        bytes32 auctionId,
        address token,
        uint256 indexed tokenId,
        address payToken,
        address indexed bidder,
        uint256 bidAmount,
        uint256 actualBidAmount
    );

    event BidWithdrawn(
        bytes32 auctionId,
        address token,
        uint256 indexed tokenId,
        address payToken,
        address indexed bidder,
        uint256 bidAmount
    );

    event BidRefunded(
        address indexed bidder,
        uint256 bidAmount,
        address payToken
    );

    event AuctionResulted(
        bytes32 auctionId,
        address token,
        uint256 indexed tokenId,
        address payToken,
        address indexed winner,
        uint256 winningBidAmount
    );

    event AuctionCancelled(bytes32 auctionId, address token, uint256 indexed tokenId);

    /// @notice Parameters of an auction
    struct Auction {
        address token;
        address royaltyToken;
        uint256 tokenId;
        address owner;
        address payToken;
        uint256 startPrice;
        uint256 startTime;
        uint256 endTime;
        bool created;
    }

    address public serviceFeeProxy;

    address public tradeTokenManager;

    /// @notice ERC721 Auction ID -> Auction Parameters
    mapping(bytes32 => Auction) public auctions;

    /// @notice ERC721 Auction ID -> Bid Parameters
    mapping(bytes32 => BidLibrary.Bid[]) public bids;

    /// @notice globally and across all auctions, the amount by which a bid has to increase
    uint256 public minBidIncrementBps = 250;

    //@notice global auction create time limit
    uint256 public auctionCreateTimeLimit = 30 days;

    /// @notice global bid withdrawal lock time
    uint256 public bidWithdrawalLockTime = 3 days;

    /// @notice global limit time betwen bid time and auction end time
    uint256 public bidLimitBeforeEndTime = 5 minutes;

    /// @notice max bidders stack count
    uint256 public maxBidStackCount = 1;

    /// @notice for switching off auction creations, bids and withdrawals
    bool public isPaused;

    bytes4 private constant _INTERFACE_ID_HAS_SECONDARY_SALE = 0x5595380a;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
    bytes4 private constant _INTERFACE_ID_ROYALTY = 0x7b296bd9;
    bytes4 private constant _INTERFACE_ID_ROYALTY_V2 = 0x9e4a83d4;

    modifier whenNotPaused() {
        require(!isPaused, "Auction: Function is currently paused");
        _;
    }

    modifier onlyCreatedAuction(bytes32 _auctionId) {
        require(
            auctions[_auctionId].created == true,
            "Auction: Auction does not exist"
        );
        _;
    }

    /**
     * @notice Auction Constructor
    * @param _serviceFeeProxy service fee proxy
     */
    constructor(
        address _serviceFeeProxy,
        address _tradeTokenManager
    ) public {
        serviceFeeProxy = _serviceFeeProxy;
        tradeTokenManager = _tradeTokenManager;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        emit AuctionContractDeployed();
    }

    /**
     * @notice Creates a new auction for a given token
     * @dev Only the owner of a token can create an auction and must have approved the contract
     * @dev End time for the auction must be in the future.
     * @param _token Token Address that follows ERC721 standard
     * @param _tokenId Token ID of the token being auctioned
     * @param _startPrice Starting bid price of the token being auctioned
     * @param _startTimestamp Unix epoch in seconds for the auction start time
     * @param _endTimestamp Unix epoch in seconds for the auction end time.
     */
    function createAuction(
        address _token,
        address _royaltyToken,
        uint256 _tokenId,
        address _payToken,
        uint256 _startPrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) external whenNotPaused {
        require(
            _startTimestamp <= _getNow().add(auctionCreateTimeLimit),
            "Auction: Exceed auction start time limit"
        );
        require(
            IERC721(_token).supportsInterface(_INTERFACE_ID_ERC721),
            "Auction: Invalid NFT"
        );

        if (_royaltyToken != address(0)) {
            require(
                IERC721(_royaltyToken).supportsInterface(_INTERFACE_ID_ROYALTY_V2),
                "Auction: Invalid royalty contract"
            );
            require(
                IRoyalty(_royaltyToken).getTokenContract() == _token,
                "Auction: Royalty Token address does not match buy token"
            );
        }

        // Check owner of the token is the creator and approved
        require(
            IERC721(_token).ownerOf(_tokenId) == msg.sender,
            "Auction: Caller is not the owner"
        );
        require(
            IERC721(_token).isApprovedForAll(msg.sender, address(this)),
            "Auction: Owner has not approved"
        );

        if (_payToken != address(0)) {
            require(
                TradeTokenManager(tradeTokenManager).supportToken(_payToken) == true,
                "Auction: Pay Token is not allowed"
            );
        }

        bytes32 auctionId = getAuctionId(_token, _tokenId, msg.sender);

        // Check the auction already created, can only list 1 token at a time
        require(
            auctions[auctionId].created == false,
            "Auction: Auction has been already created"
        );
        // Check end time not before start time and that end is in the future
        require(
            _endTimestamp > _startTimestamp && _endTimestamp > _getNow(),
            "Auction: Auction time is incorrect"
        );

        // Setup the auction
        auctions[auctionId] = Auction({
        token : _token,
        royaltyToken : _royaltyToken,
        tokenId : _tokenId,
        owner : msg.sender,
        payToken : _payToken,
        startPrice : _startPrice,
        startTime : _startTimestamp,
        endTime : _endTimestamp,
        created : true
        });

        emit AuctionCreated(auctionId, _token, _tokenId, _payToken);
    }

    /**
     * @notice Places a new bid, out bidding the existing bidder if found and criteria is reached
     * @dev Only callable when the auction is open
     * @dev Bids from smart contracts are prohibited to prevent griefing with always reverting receiver
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     */
    function placeBid(bytes32 _auctionId)
    external
    payable
    nonReentrant
    whenNotPaused
    onlyCreatedAuction(_auctionId)
    {
        require(
            msg.sender.isContract() == false,
            "Auction: No contracts permitted"
        );

        // Ensure auction is in flight
        require(
            _getNow() >= auctions[_auctionId].startTime && _getNow() <= auctions[_auctionId].endTime,
            "Auction: Bidding outside of the auction window"
        );

        uint256 bidAmount;

        if (auctions[_auctionId].payToken == address(0)) {
            bidAmount = msg.value;
        } else {
            bidAmount = IBEP20(auctions[_auctionId].payToken).allowance(msg.sender, address(this));
            require(
                IBEP20(auctions[_auctionId].payToken).transferFrom(msg.sender, address(this), bidAmount) == true,
                "Auction: Token transfer failed"
            );
        }

        // Ensure bid adheres to outbid increment and threshold
        uint256 actualBidAmount = bidAmount.mul(10 ** 4).div(ServiceFeeProxy(serviceFeeProxy).getBuyServiceFeeBps(msg.sender).add(10 ** 4));
        uint256 minBidRequired;
        BidLibrary.Bid[] storage bidList = bids[_auctionId];

        if (bidList.length != 0) {
            minBidRequired =
            bidList[bidList.length - 1].actualBidAmount.mul(minBidIncrementBps.add(10 ** 4)).div(10 ** 4);
        } else {
            minBidRequired = auctions[_auctionId].startPrice;
        }

        require(
            actualBidAmount >= minBidRequired,
            "Auction: Failed to outbid min price"
        );

        // assign top bidder and bid time
        BidLibrary.Bid memory newHighestBid = BidLibrary.Bid({
        bidder : _msgSender(),
        bidAmount : bidAmount,
        actualBidAmount : actualBidAmount,
        bidTime : _getNow()
        });

        bidList.push(newHighestBid);

        //Refund old bid if bidlist overflows thans max bid stack count
        if (bidList.length > maxBidStackCount) {
            BidLibrary.Bid memory oldBid = bidList[0];
            if (oldBid.bidder != address(0)) {
                _refundBid(oldBid.bidder, oldBid.bidAmount, auctions[_auctionId].payToken);
            }

            bidList.removeByIndex(0);
        }

        //Increase auction end time if bid time is more than 5 mins before end time
        if (auctions[_auctionId].endTime <= newHighestBid.bidTime.add(bidLimitBeforeEndTime)) {
            _updateAuctionEndTime(_auctionId, auctions[_auctionId].endTime.add(bidLimitBeforeEndTime));
        }

        emit BidPlaced(
            _auctionId,
            auctions[_auctionId].token,
            auctions[_auctionId].tokenId,
            auctions[_auctionId].payToken,
            _msgSender(),
            bidAmount,
            actualBidAmount
        );
    }

    /**
     * @notice Given a sender who is in the bid list of auction, allows them to withdraw their bid
     * @dev Only callable by the existing top bidder
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     */
    function withdrawBid(bytes32 _auctionId)
    external
    nonReentrant
    whenNotPaused
    onlyCreatedAuction(_auctionId)
    {
        BidLibrary.Bid[] storage bidList = bids[_auctionId];
        require(bidList.length > 0, "Auction: There is no bid");

        uint256 withdrawIndex = bidList.length;
        for (uint256 i = 0; i < bidList.length; i++) {
            if (bidList[i].bidder == _msgSender()) {
                withdrawIndex = i;
            }
        }

        require(withdrawIndex != bidList.length, "Auction: Caller is not bidder");

        BidLibrary.Bid storage withdrawableBid = bidList[withdrawIndex];

        // Check withdrawal after delay time
        require(
            _getNow() >= auctions[_auctionId].endTime.add(bidWithdrawalLockTime),
            "Auction: Cannot withdraw until auction ends"
        );

        if (withdrawableBid.bidder != address(0)) {
            _refundBid(withdrawableBid.bidder, withdrawableBid.bidAmount, auctions[_auctionId].payToken);
        }

        bidList.removeByIndex(withdrawIndex);

        emit BidWithdrawn(
            _auctionId,
            auctions[_auctionId].token,
            auctions[_auctionId].tokenId,
            auctions[_auctionId].payToken,
            _msgSender(),
            withdrawableBid.bidAmount
        );
    }

    /**
     * @notice Results a finished auction
     * @dev Only admin or smart contract
     * @dev Auction can only be resulted if there has been a bidder and reserve met.
     * @dev If there have been no bids, the auction needs to be cancelled instead using `cancelAuction()`
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     */
    function endAuction(bytes32 _auctionId)
    external
    nonReentrant
    onlyCreatedAuction(_auctionId)
    {
        Auction memory auction = auctions[_auctionId];

        require(
            isAdmin(msg.sender) || (auction.owner == msg.sender),
            "Auction: Only admin or auction owner can result the auction"
        );

        // Check the auction has ended
        require(
            _getNow() > auction.endTime,
            "Auction: Auction has not ended"
        );

        // Ensure this contract is approved to move the token
        require(
            IERC721(auction.token).isApprovedForAll(auction.owner, address(this)),
            "Auction: Auction not approved"
        );

        // Get info on who the highest bidder is
        BidLibrary.Bid[] storage bidList = bids[_auctionId];

        require(bidList.length > 0, "Auction: There is no bid");

        BidLibrary.Bid memory highestBid = bidList[bidList.length - 1];

        bool isSecondarySale;
        if (IERC165(auction.token).supportsInterface(_INTERFACE_ID_HAS_SECONDARY_SALE)) {
            isSecondarySale = HasSecondarySale(auction.token).checkSecondarySale(auction.tokenId);
        } else if (auction.royaltyToken != address(0) && IERC165(auction.royaltyToken).supportsInterface(_INTERFACE_ID_ROYALTY_V2)) {
            isSecondarySale = HasSecondarySale(auction.royaltyToken).checkSecondarySale(auction.tokenId);
        }
        // Work out platform fee from above reserve amount
        uint256 totalServiceFee = highestBid.bidAmount.sub(highestBid.actualBidAmount).add(
            highestBid.actualBidAmount.mul(
                ServiceFeeProxy(serviceFeeProxy).getSellServiceFeeBps(auction.owner, isSecondarySale)
            ).div(10 ** 4)
        );

        // Send platform fee
        address payable serviceFeeRecipient = ServiceFeeProxy(serviceFeeProxy).getServiceFeeRecipient();
        bool platformTransferSuccess;
        bool ownerTransferSuccess;
        uint256 royalties;
        if (
            IERC165(auction.token).supportsInterface(_INTERFACE_ID_FEES)
            || IERC165(auction.token).supportsInterface(_INTERFACE_ID_ROYALTY)
            || IERC165(auction.token).supportsInterface(_INTERFACE_ID_ROYALTY_V2)
        ) {
            royalties = _payOutRoyaltiesByStrategy(
                auction.token,
                auction.tokenId,
                auction.payToken,
                address(this),
                highestBid.bidAmount.sub(totalServiceFee),
                isSecondarySale
            );
        } else if (auction.royaltyToken != address(0) && IERC165(auction.royaltyToken).supportsInterface(_INTERFACE_ID_ROYALTY_V2)) {
            require(
                IRoyalty(auction.royaltyToken).getTokenContract() == auction.token,
                "Auction: Royalty Token address does not match buy token"
            );
            royalties = _payOutRoyaltiesByStrategy(
                auction.royaltyToken,
                auction.tokenId,
                auction.payToken,
                address(this),
                highestBid.bidAmount.sub(totalServiceFee),
                isSecondarySale
            );
        }
        uint256 remain = highestBid.bidAmount.sub(totalServiceFee).sub(royalties);
        if (auction.payToken == address(0)) {
            (platformTransferSuccess,) =
            serviceFeeRecipient.call{value : totalServiceFee}("");
            // Send remaining to designer
            if (remain > 0) {
                (ownerTransferSuccess,) =
                auction.owner.call{
                value : remain
                }("");
            }
        } else {
            platformTransferSuccess = IBEP20(auction.payToken).transfer(serviceFeeRecipient, totalServiceFee);
            if (remain > 0) {
                ownerTransferSuccess = IBEP20(auction.payToken).transfer(auction.owner, remain);
            }
        }

        require(
            platformTransferSuccess,
            "Auction: Failed to send fee"
        );
        if (remain > 0) {
            require(
                ownerTransferSuccess,
                "Auction: Failed to send winning bid"
            );
        }
        // Transfer the token to the winner
        IERC721(auction.token).safeTransferFrom(auction.owner, highestBid.bidder, auction.tokenId);

        if (IERC165(auction.token).supportsInterface(_INTERFACE_ID_HAS_SECONDARY_SALE))
            HasSecondarySale(auction.token).setSecondarySale(auction.tokenId);

        if (auction.royaltyToken != address(0) && IERC165(auction.royaltyToken).supportsInterface(_INTERFACE_ID_HAS_SECONDARY_SALE))
            HasSecondarySale(auction.royaltyToken).setSecondarySale(auction.tokenId);

        // Refund bid amount to bidders who isn't the top unfortunately
        for (uint256 i = 0; i < bidList.length - 1; i++) {
            _refundBid(bidList[i].bidder, bidList[i].bidAmount, auction.payToken);
        }

        // Clean up the highest bid
        delete bids[_auctionId];
        delete auctions[_auctionId];

        emit AuctionResulted(
            _auctionId,
            auction.token,
            auction.tokenId,
            auction.payToken,
            highestBid.bidder,
            highestBid.bidAmount
        );
    }

    /**
     * @notice Cancels and inflight and un-resulted auctions, returning the funds to bidders if found
     * @dev Only admin
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     */
    function cancelAuction(bytes32 _auctionId)
    external
    nonReentrant
    onlyCreatedAuction(_auctionId)
    {
        Auction memory auction = auctions[_auctionId];

        require(
            isAdmin(msg.sender) || (auction.owner == msg.sender),
            "Auction: Only admin or auction owner can result the auction"
        );

        // refund bid amount to existing bidders
        BidLibrary.Bid[] storage bidList = bids[_auctionId];

        if (bidList.length > 0) {
            for (uint256 i = 0; i < bidList.length; i++) {
                _refundBid(bidList[i].bidder, bidList[i].bidAmount, auction.payToken);
            }
        }

        // Remove auction and bids
        delete bids[_auctionId];
        delete auctions[_auctionId];

        emit AuctionCancelled(_auctionId, auction.token, auction.tokenId);
    }

    /**
     * @notice Update the auction create time limit by which how far ahead can auctions be created
     * @dev Only admin
     * @param _auctionCreateTimeLimit New auction create time limit
     */
    function updateAuctionCreateTimeLimit(uint256 _auctionCreateTimeLimit)
    external
    onlyAdmin
    {
        auctionCreateTimeLimit = _auctionCreateTimeLimit;
        emit AuctionCreateTimeLimitUpdated(_auctionCreateTimeLimit);
    }

    /**
     * @notice Update the amount by which bids have to increase, across all auctions
     * @dev Only admin
     * @param _minBidIncrementBps New bid step in WEI
     */
    function updateMinBidIncrementBps(uint256 _minBidIncrementBps)
    external
    onlyAdmin
    {
        minBidIncrementBps = _minBidIncrementBps;
        emit MinBidIncrementBpsUpdated(_minBidIncrementBps);
    }

    /**
     * @notice Update the global max bid stack count
     * @dev Only admin
     * @param _maxBidStackCount max bid stack count
     */
    function updateMaxBidStackCount(uint256 _maxBidStackCount)
    external
    onlyAdmin
    {
        maxBidStackCount = _maxBidStackCount;
        emit MaxBidStackCountUpdated(_maxBidStackCount);
    }

    /**
     * @notice Update the global bid withdrawal lockout time
     * @dev Only admin
     * @param _bidWithdrawalLockTime New bid withdrawal lock time
     */
    function updateBidWithdrawalLockTime(uint256 _bidWithdrawalLockTime)
    external
    onlyAdmin
    {
        bidWithdrawalLockTime = _bidWithdrawalLockTime;
        emit BidWithdrawalLockTimeUpdated(_bidWithdrawalLockTime);
    }

    /**
     * @notice Update the current start time for an auction
     * @dev Only admin
     * @dev Auction must exist
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     * @param _startTime New start time (unix epoch in seconds)
     */
    function updateAuctionStartTime(bytes32 _auctionId, uint256 _startTime)
    external
    onlyAdmin
    onlyCreatedAuction(_auctionId)
    {
        auctions[_auctionId].startTime = _startTime;
        emit AuctionStartTimeUpdated(_auctionId, auctions[_auctionId].token, auctions[_auctionId].tokenId, _startTime);
    }

    /**
     * @notice Update the current end time for an auction
     * @dev Only admin
     * @dev Auction must exist
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     * @param _endTimestamp New end time (unix epoch in seconds)
     */
    function updateAuctionEndTime(bytes32 _auctionId, uint256 _endTimestamp)
    external
    onlyAdmin
    onlyCreatedAuction(_auctionId)
    {
        require(
            auctions[_auctionId].startTime < _endTimestamp && _endTimestamp > _getNow(),
            "Auction: Auction time is incorrect"
        );

        _updateAuctionEndTime(_auctionId, _endTimestamp);
    }

    /**
     * @notice Method for getting all info about the auction
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     */
    function getAuction(bytes32 _auctionId)
    external
    view
    returns (Auction memory)
    {
        return auctions[_auctionId];
    }

    /**
     * @notice Method for getting all info about the bids
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     */
    function getBidList(bytes32 _auctionId) public view returns (BidLibrary.Bid[] memory) {
        return bids[_auctionId];
    }

    /**
     * @notice Method for getting auction id to query the auctions mapping
     * @param _token Token Address that follows ERC1155 standard
     * @param _tokenId Token ID of the token being auctioned
     * @param _owner Owner address of the token Id
    */
    function getAuctionId(address _token, uint256 _tokenId, address _owner) public pure returns (bytes32) {
        return sha256(abi.encodePacked(_token, _tokenId, _owner));
    }

    /**
     * @notice Method for the block timestamp
    */
    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice Used for sending back escrowed funds from a previous bid
     * @param _bidder Address of the last highest bidder
     * @param _bidAmount Ether amount in WEI that the bidder sent when placing their bid
     */
    function _refundBid(address payable _bidder, uint256 _bidAmount, address _payToken) private {
        // refund previous best (if bid exists)
        bool successRefund;
        if (_payToken == address(0)) {
            (successRefund,) = _bidder.call{value : _bidAmount}("");
        } else {
            successRefund = IBEP20(_payToken).transfer(_bidder, _bidAmount);
        }
        require(
            successRefund,
            "Auction: Failed to refund"
        );
        emit BidRefunded(_bidder, _bidAmount, _payToken);
    }

    /**
     * @notice Private method used for update auction end time
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     * @param _endTimestamp timestamp of end time
     */
    function _updateAuctionEndTime(bytes32 _auctionId, uint256 _endTimestamp) private {
        auctions[_auctionId].endTime = _endTimestamp;
        emit AuctionEndTimeUpdated(_auctionId, auctions[_auctionId].token, auctions[_auctionId].tokenId, _endTimestamp);
    }

    /**
     * @notice Toggling the pause of the contract
     * @dev Only admin
    */
    function toggleIsPaused() external onlyAdmin {
        isPaused = !isPaused;
        emit PauseToggled(isPaused);
    }

    /**
     * @notice Destroy the smart contract
     * @dev Only admin
     */
    function destroy() external onlyAdmin {
        address payable serviceFeeRecipient = ServiceFeeProxy(serviceFeeProxy).getServiceFeeRecipient();
        selfdestruct(serviceFeeRecipient);
        emit Destroy();
    }
}