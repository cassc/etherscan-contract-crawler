//SPDX-License-Identifier: Unlicensed
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/payment/PullPayment.sol';

import './IERC721TokenCreator.sol';
import './IFirstDibsMarketSettings.sol';

contract FirstDibsAuction is PullPayment, AccessControl, ReentrancyGuard, IERC721Receiver {
    using SafeMath for uint256;
    using SafeMath for uint64;
    using Counters for Counters.Counter;

    bytes32 public constant BIDDER_ROLE = keccak256('BIDDER_ROLE');
    bytes32 public constant BIDDER_ROLE_ADMIN = keccak256('BIDDER_ROLE_ADMIN');

    /**
     * ========================
     * #Public state variables
     * ========================
     */
    bool public bidderRoleRequired; // if true, bids require bidder having BIDDER_ROLE role
    bool public globalPaused; // flag for pausing all auctions
    IERC721TokenCreator public iERC721TokenCreatorRegistry;
    IFirstDibsMarketSettings public iFirstDibsMarketSettings;
    // Mapping auction id => Auction
    mapping(uint256 => Auction) public auctions;
    // Map token address => tokenId => auctionId
    mapping(address => mapping(uint256 => uint256)) public auctionIds;

    /*
     * ========================
     * #Private state variables
     * ========================
     */
    Counters.Counter private auctionIdsCounter;

    /**
     * ========================
     * #Structs
     * ========================
     */
    struct AuctionSettings {
        uint32 buyerPremium; // percent; added on top of current bid
        uint32 duration; // defaults to globalDuration
        uint32 minimumBidIncrement; // defaults to globalMinimumBidIncrement
        uint32 commissionRate; // percent; defaults to globalMarketCommission
        uint128 creatorRoyaltyRate; // percent; defaults to globalCreatorRoyaltyRate
    }

    struct Bid {
        uint256 amount; // current winning bid of the auction
        uint256 buyerPremiumAmount; // current buyer premium associated with current bid
    }

    struct Auction {
        uint256 startTime; // auction start timestamp
        uint256 pausedTime; // when was the auction paused
        uint256 reservePrice; // minimum bid threshold for auction to begin
        uint256 tokenId; // id of the token
        bool paused; // is individual auction paused
        address nftAddress; // address of the token
        address payable payee; // address of auction proceeds recipient. NFT creator until secondary market is introduced.
        address payable currentBidder; // current winning bidder of the auction
        address auctionCreator; // address of the creator of the auction (whoever called the createAuction method)
        AuctionSettings settings;
        Bid currentBid;
    }

    /**
     * ========================
     * #Modifiers
     * ========================
     */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'caller is not an admin');
        _;
    }

    modifier onlyBidder() {
        if (bidderRoleRequired == true) {
            require(hasRole(BIDDER_ROLE, _msgSender()), 'bidder role required');
        }
        _;
    }

    modifier notPaused(uint256 auctionId) {
        require(!globalPaused, 'Auctions are globally paused');
        require(!auctions[auctionId].paused, 'Auction is paused.');
        _;
    }

    modifier auctionExists(uint256 auctionId) {
        require(auctions[auctionId].payee != address(0), "Auction doesn't exist");
        _;
    }

    modifier senderIsAuctionCreatorOrAdmin(uint256 auctionId) {
        require(
            _msgSender() == auctions[auctionId].auctionCreator ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            'Must be auction creator or admin'
        );
        _;
    }

    /**
     * ========================
     * #Events
     * ========================
     */
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address tokenSeller,
        uint256 reservePrice,
        bool isPaused,
        address auctionCreator,
        uint64 duration
    );

    event AuctionBid(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 bidAmount,
        uint256 bidBuyerPremium,
        uint64 duration,
        uint256 startTime
    );

    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed tokenSeller,
        address indexed winningBidder,
        uint256 winningBid,
        uint256 winningBidBuyerPremium,
        uint256 adminCommissionFee,
        uint256 royaltyFee,
        uint256 sellerPayment
    );

    event AuctionPaused(
        uint256 indexed auctionId,
        address indexed tokenSeller,
        address toggledBy,
        bool isPaused,
        uint64 duration
    );

    event AuctionCanceled(uint256 indexed auctionId, address canceledBy, uint256 refundedAmount);

    /**
     * ========================
     * constructor
     * ========================
     */
    constructor(address _marketSettings, address _creatorRegistry) public {
        require(
            _marketSettings != address(0),
            'constructor: 0 address not allowed for _marketSettings'
        );
        require(
            _creatorRegistry != address(0),
            'constructor: 0 address not allowed for _creatorRegistry'
        );
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); // deployer of the contract gets admin permissions
        _setupRole(BIDDER_ROLE, _msgSender());
        _setupRole(BIDDER_ROLE_ADMIN, _msgSender());
        _setRoleAdmin(BIDDER_ROLE, BIDDER_ROLE_ADMIN);
        iERC721TokenCreatorRegistry = IERC721TokenCreator(_creatorRegistry);
        iFirstDibsMarketSettings = IFirstDibsMarketSettings(_marketSettings);
        bidderRoleRequired = true;
    }

    /**
     * @dev setter for creator registry address
     * @param _iERC721TokenCreatorRegistry address of the IERC721TokenCreator contract to set for the auction
     */
    function setIERC721TokenCreatorRegistry(address _iERC721TokenCreatorRegistry)
        external
        onlyAdmin
    {
        require(
            _iERC721TokenCreatorRegistry != address(0),
            'setIERC721TokenCreatorRegistry: 0 address not allowed'
        );
        iERC721TokenCreatorRegistry = IERC721TokenCreator(_iERC721TokenCreatorRegistry);
    }

    /**
     * @dev setter for market settings address
     * @param _iFirstDibsMarketSettings address of the FirstDibsMarketSettings contract to set for the auction
     */
    function setIFirstDibsMarketSettings(address _iFirstDibsMarketSettings) external onlyAdmin {
        require(
            _iFirstDibsMarketSettings != address(0),
            'setIFirstDibsMarketSettings: 0 address not allowed'
        );
        iFirstDibsMarketSettings = IFirstDibsMarketSettings(_iFirstDibsMarketSettings);
    }

    /**
     * @dev setter for setting bidder role being required to bid
     * @param _bidderRole bool If true, bidder must have bidder role to bid
     */
    function setBidderRoleRequired(bool _bidderRole) external onlyAdmin {
        bidderRoleRequired = _bidderRole;
    }

    /**
     * @dev setter for global pause state
     * @param _paused) true to pause all auctions, false to unpause all auctions
     */
    function setGlobalPaused(bool _paused) external onlyAdmin {
        globalPaused = _paused;
    }

    /**
     * @dev External function which creates an auction with a reserve price,
     * custom start time, custom duration, and custom minimum bid increment.
     *
     * @param _nftAddress address of ERC-721 contract
     * @param _tokenId uint256
     * @param _reservePrice uint256 reserve price in ETH
     * @param _pausedArg create the auction in a paused state
     * @param _startTimeArg admin-only unix timestamp; allow bidding to start at this time
     * @param _auctionDurationArg (optional) auction duration in seconds
     * @param _minimumBidIncrementArg (optional) minimum bid increment in percentage points
     */
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _reservePrice,
        bool _pausedArg,
        uint64 _startTimeArg,
        uint32 _auctionDurationArg,
        uint8 _minimumBidIncrementArg
    ) external {
        adminCreateAuction(
            _nftAddress,
            _tokenId,
            _reservePrice,
            _pausedArg,
            _startTimeArg,
            _auctionDurationArg,
            _minimumBidIncrementArg,
            101, // adminCreateAuction function ignores values > 100
            101 // adminCreateAuction function ignores values > 100
        );
    }

    /**
     * @dev External function which creates an auction with a reserve price,
     * custom start time, custom duration, custom minimum bid increment,
     * custom commission rate, and custom creator royalty rate.
     *
     * @param _nftAddress address of ERC-721 contract (latest FirstDibsToken address)
     * @param _tokenId uint256
     * @param _reservePrice reserve price in ETH
     * @param _pausedArg create the auction in a paused state
     * @param _startTimeArg (optional) admin-only; unix timestamp; allow bidding to start at this time
     * @param _auctionDurationArg (optional) admin-only; auction duration in seconds
     * @param _minimumBidIncrementArg (optional) admin-only; minimum bid increment in percentage points
     * @param _commissionRateArg (optional) admin-only; pass in a custom marketplace commission rate
     * @param _creatorRoyaltyRateArg (optional) admin-only; pass in a custom creator royalty rate
     */
    function adminCreateAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _reservePrice,
        bool _pausedArg,
        uint64 _startTimeArg,
        uint32 _auctionDurationArg,
        uint8 _minimumBidIncrementArg,
        uint8 _commissionRateArg,
        uint8 _creatorRoyaltyRateArg
    ) public nonReentrant {
        require(!globalPaused, 'adminCreateAuction: auctions are globally paused');

        // May not create auctions unless you are the token owner or
        // an admin of this contract
        require(
            _msgSender() == IERC721(_nftAddress).ownerOf(_tokenId) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            'adminCreateAuction: must be token owner or admin'
        );

        require(
            auctionIds[_nftAddress][_tokenId] == 0,
            'adminCreateAuction: auction already exists'
        );

        require(_reservePrice > 0, 'adminCreateAuction: Reserve must be > 0');

        Auction memory auction = Auction({
            currentBid: Bid({ amount: 0, buyerPremiumAmount: 0 }),
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            payee: payable(IERC721(_nftAddress).ownerOf(_tokenId)), // payee is the token owner
            auctionCreator: _msgSender(),
            reservePrice: _reservePrice, // minimum bid threshold for auction to begin
            startTime: 0,
            currentBidder: address(0), // there is no bidder at auction creation
            paused: _pausedArg, // is individual auction paused
            pausedTime: 0, // when the auction was paused
            settings: AuctionSettings({ // Defaults to global market settings; admins may override
                buyerPremium: iFirstDibsMarketSettings.globalBuyerPremium(),
                duration: iFirstDibsMarketSettings.globalAuctionDuration(),
                minimumBidIncrement: iFirstDibsMarketSettings.globalMinimumBidIncrement(),
                commissionRate: iFirstDibsMarketSettings.globalMarketCommission(),
                creatorRoyaltyRate: iFirstDibsMarketSettings.globalCreatorRoyaltyRate()
            })
        });

        if (hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            if (_auctionDurationArg > 0) {
                require(
                    _auctionDurationArg >= iFirstDibsMarketSettings.globalTimeBuffer(),
                    'adminCreateAuction: duration must be >= time buffer'
                );
                auction.settings.duration = _auctionDurationArg;
            }

            if (_startTimeArg > 0) {
                require(
                    block.timestamp < _startTimeArg,
                    'adminCreateAuction: start time must be in the future'
                );
                auction.startTime = _startTimeArg;
                // since `bid` is gated by `notPaused` modifier
                // and a start time in the future means that a bid
                // must be allowed after that time, we can't have
                // the auction paused if there is a start time > 0
                auction.paused = false;
            }

            if (_minimumBidIncrementArg > 0) {
                auction.settings.minimumBidIncrement = _minimumBidIncrementArg;
            }

            if (_commissionRateArg <= 100) {
                auction.settings.commissionRate = _commissionRateArg;
            }

            if (_creatorRoyaltyRateArg <= 100) {
                auction.settings.creatorRoyaltyRate = _creatorRoyaltyRateArg;
            }
        }

        require(
            uint256(auction.settings.commissionRate).add(auction.settings.creatorRoyaltyRate) <=
                100,
            'adminCreateAuction: commission rate + royalty rate must be <= 100'
        );

        auctionIdsCounter.increment();
        auctions[auctionIdsCounter.current()] = auction;
        auctionIds[_nftAddress][_tokenId] = auctionIdsCounter.current();

        // transfer the NFT to the auction contract to hold in escrow for the duration of the auction
        IERC721(_nftAddress).safeTransferFrom(auction.payee, address(this), _tokenId);

        emit AuctionCreated(
            auctionIdsCounter.current(),
            _nftAddress,
            _tokenId,
            auction.payee,
            _reservePrice,
            auction.paused,
            _msgSender(),
            auction.settings.duration
        );
    }

    /**
     * @dev Retrieves the bid and buyer premium amount from the _amount based on _buyerPremiumRate
     *
     * @param _amount The entire amount (bid amount + buyer premium amount)
     * @param _buyerPremiumRate The buyer premium rate used to calculate _amount
     * @return The bid sent and the premium sent
     */
    function getSentBidAndPremium(uint256 _amount, uint64 _buyerPremiumRate)
        public
        pure
        returns (
            uint256, /*sentBid*/
            uint256 /*sentPremium*/
        )
    {
        uint256 bpRate = _buyerPremiumRate.add(100);
        uint256 _sentBid = uint256(_amount.mul(100).div(bpRate));
        uint256 _sentPremium = uint256(_amount.sub(_sentBid));
        return (_sentBid, _sentPremium);
    }

    /**
     * @dev Validates that the total amount sent is valid for the current state of the auction
     *  and returns the bid amount and buyer premium amount sent
     *
     * @param _auctionId The id of the auction on which to validate the amount sent
     * @param _totalAmount The total amount sent (bid amount + buyer premium amount)
     * @return boolean true if the amount satisfies the state of the auction; the sent bid; and the sent premium
     */
    function _validateAndGetBid(uint256 _auctionId, uint256 _totalAmount)
        internal
        view
        returns (
            uint256, /*sentBid*/
            uint256 /*sentPremium*/
        )
    {
        (uint256 _sentBid, uint256 _sentPremium) = getSentBidAndPremium(
            _totalAmount,
            auctions[_auctionId].settings.buyerPremium
        );
        if (auctions[_auctionId].currentBidder == address(0)) {
            // This is the first bid against reserve price
            require(
                _sentBid >= auctions[_auctionId].reservePrice,
                '_validateAndGetBid: reserve not met'
            );
        } else {
            // Subsequent bids must meet minimum bid increment
            require(
                _sentBid >=
                    auctions[_auctionId].currentBid.amount.add(
                        auctions[_auctionId]
                        .currentBid
                        .amount
                        .mul(auctions[_auctionId].settings.minimumBidIncrement)
                        .div(100)
                    ),
                '_validateAndGetBid: minimum bid not met'
            );
        }
        return (_sentBid, _sentPremium);
    }

    /**
     * @dev external function that can be called by any address which submits a bid to an auction
     * @param _auctionId uint256 id of the auction
     * @param _amount uint256 bid in WEI
     */
    function bid(uint256 _auctionId, uint256 _amount)
        external
        payable
        nonReentrant
        onlyBidder
        auctionExists(_auctionId)
        notPaused(_auctionId)
    {
        require(msg.value > 0, 'bid: value must be > 0');
        require(_amount == msg.value, 'bid: amount/value mismatch');
        // Auctions with a start time of 0 may accept bids
        // Auctions with a start time can't accept bids until now is greater than start time
        require(
            auctions[_auctionId].startTime == 0 ||
                block.timestamp >= auctions[_auctionId].startTime,
            'bid: auction not started'
        );
        // Auctions with a start time of 0 may accept bids
        // Auctions with an end time less than now may accept a bid
        require(
            auctions[_auctionId].startTime == 0 || block.timestamp < _endTime(_auctionId),
            'bid: auction expired'
        );
        require(
            auctions[_auctionId].payee != _msgSender(),
            'bid: token owner may not bid on own auction'
        );
        require(
            auctions[_auctionId].currentBidder != _msgSender(),
            'bid: sender is current highest bidder'
        );

        // Validate the amount sent and get sent bid and sent premium
        (uint256 _sentBid, uint256 _sentPremium) = _validateAndGetBid(_auctionId, _amount);

        // bid amount is OK, if not first bid, then transfer funds
        // back to previous bidder & update current bidder to the current sender
        if (auctions[_auctionId].startTime == 0) {
            auctions[_auctionId].startTime = uint64(block.timestamp);
        } else if (auctions[_auctionId].currentBidder != address(0)) {
            uint256 refundAmount = auctions[_auctionId].currentBid.amount.add(
                auctions[_auctionId].currentBid.buyerPremiumAmount
            );
            address priorBidder = auctions[_auctionId].currentBidder;
            _tryTransferThenEscrow(priorBidder, refundAmount);
        }
        auctions[_auctionId].currentBid.amount = _sentBid;
        auctions[_auctionId].currentBid.buyerPremiumAmount = _sentPremium;
        auctions[_auctionId].currentBidder = _msgSender();

        // extend countdown for bids within the time buffer of the auction
        if (
            // if auction ends less than globalTimeBuffer from now
            _endTime(_auctionId) < block.timestamp.add(iFirstDibsMarketSettings.globalTimeBuffer())
        ) {
            // increment the duration by the difference between the new end time and the old end time
            auctions[_auctionId].settings.duration += uint32(
                block.timestamp.add(iFirstDibsMarketSettings.globalTimeBuffer()).sub(
                    _endTime(_auctionId)
                )
            );
        }

        emit AuctionBid(
            _auctionId,
            _msgSender(),
            _sentBid,
            _sentPremium,
            auctions[_auctionId].settings.duration,
            auctions[_auctionId].startTime
        );
    }

    /**
     * @dev method for ending an auction which has expired. Distrubutes payment to all parties & send
     * token to winning bidder (or returns it to the auction creator if there was no winner)
     * @param _auctionId uint256 id of the token
     */
    function endAuction(uint256 _auctionId)
        external
        nonReentrant
        auctionExists(_auctionId)
        notPaused(_auctionId)
    {
        require(
            auctions[_auctionId].currentBidder != address(0),
            'endAuction: no bidders; use cancelAuction'
        );

        require(
            auctions[_auctionId].startTime > 0 && //  auction has started
                block.timestamp >= _endTime(_auctionId), // past the endtime of the auction,
            'endAuction: auction is not complete'
        );

        Auction memory auction = auctions[_auctionId];

        // send commission fee & buyer premium to commission address
        uint256 commissionFee = auction.currentBid.amount.mul(auction.settings.commissionRate).div(
            100
        );
        // don't attempt to transfer fees if there are none
        if (commissionFee.add(auction.currentBid.buyerPremiumAmount) > 0) {
            _tryTransferThenEscrow(
                iFirstDibsMarketSettings.commissionAddress(),
                commissionFee.add(auction.currentBid.buyerPremiumAmount)
            );
        }

        address nftCreator = iERC721TokenCreatorRegistry.tokenCreator(
            auction.nftAddress,
            auction.tokenId
        );

        // send payout to token owner & token creator (they might be the same)
        uint256 creatorRoyaltyFee = 0;
        if (nftCreator == auction.payee) {
            // Primary sale
            _asyncTransfer(auction.payee, auction.currentBid.amount.sub(commissionFee));
        } else {
            // Secondary sale
            // calculate & send creator royalty to escrow
            creatorRoyaltyFee = auction
            .currentBid
            .amount
            .mul(auction.settings.creatorRoyaltyRate)
            .div(100);
            _asyncTransfer(nftCreator, creatorRoyaltyFee);

            // send remaining funds to the seller in escrow
            _asyncTransfer(
                auction.payee,
                auction.currentBid.amount.sub(creatorRoyaltyFee).sub(commissionFee)
            );
        }

        // send the NFT to the winning bidder
        IERC721(auction.nftAddress).safeTransferFrom(
            address(this), // from
            auction.currentBidder, // to
            auction.tokenId
        );

        _delete(_auctionId);

        emit AuctionEnded(
            _auctionId,
            auction.payee,
            auction.currentBidder,
            auction.currentBid.amount,
            auction.currentBid.buyerPremiumAmount,
            commissionFee,
            creatorRoyaltyFee,
            auction.currentBid.amount.sub(creatorRoyaltyFee).sub(commissionFee) // seller payment
        );
    }

    /**
     * @dev external function to cancel an auction & return the NFT to the creator of the auction
     * @param _auctionId uint256 auction id
     */
    function cancelAuction(uint256 _auctionId)
        external
        nonReentrant
        auctionExists(_auctionId)
        senderIsAuctionCreatorOrAdmin(_auctionId)
    {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            // only admin may cancel an auction with bids
            require(
                auctions[_auctionId].currentBidder == address(0),
                'cancelAuction: auction with bids may not be canceled'
            );
        }

        // return the token back to the original owner
        IERC721(auctions[_auctionId].nftAddress).safeTransferFrom(
            address(this),
            auctions[_auctionId].payee,
            auctions[_auctionId].tokenId
        );

        uint256 refundAmount = 0;
        if (auctions[_auctionId].currentBidder != address(0)) {
            // If there's a bidder, return funds to them
            refundAmount = auctions[_auctionId].currentBid.amount.add(
                auctions[_auctionId].currentBid.buyerPremiumAmount
            );
            _tryTransferThenEscrow(auctions[_auctionId].currentBidder, refundAmount);
        }

        _delete(_auctionId);
        emit AuctionCanceled(_auctionId, _msgSender(), refundAmount);
    }

    /**
     * @dev external function for pausing / unpausing an auction
     * @param _auctionId uint256 auction id
     * @param _paused true to pause the auction, false to unpause the auction
     */
    function setAuctionPause(uint256 _auctionId, bool _paused)
        external
        auctionExists(_auctionId)
        senderIsAuctionCreatorOrAdmin(_auctionId)
    {
        if (_paused == auctions[_auctionId].paused) {
            // no-op, auction is already in this state
            return;
        }
        if (_paused) {
            auctions[_auctionId].pausedTime = uint64(block.timestamp);
        } else if (
            !_paused && auctions[_auctionId].pausedTime > 0 && auctions[_auctionId].startTime > 0
        ) {
            // if the auction has started, increment duration by difference between current time and paused time
            auctions[_auctionId].settings.duration += uint32(
                block.timestamp.sub(auctions[_auctionId].pausedTime)
            );
            auctions[_auctionId].pausedTime = 0;
        }
        auctions[_auctionId].paused = _paused;
        emit AuctionPaused(
            _auctionId,
            auctions[_auctionId].payee,
            _msgSender(),
            _paused,
            auctions[_auctionId].settings.duration
        );
    }

    /**
     * @notice Handle the receipt of an NFT
     * @dev Per erc721 spec this interface must be implemented to receive NFTs via
     *      the safeTransferFrom function. See: https://eips.ethereum.org/EIPS/eip-721 for more.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external override returns (bytes4) {
        return IERC721Receiver(address(this)).onERC721Received.selector;
    }

    /**
     * @dev utility function for calculating an auctions end time
     * @param _auctionId uint256
     */
    function _endTime(uint256 _auctionId) private view returns (uint256) {
        return auctions[_auctionId].startTime + auctions[_auctionId].settings.duration;
    }

    /**
     * @dev Delete auctionId for current auction for token+id & delete auction struct
     * @param _auctionId uint256
     */
    function _delete(uint256 _auctionId) private {
        address nftAddress = auctions[_auctionId].nftAddress;
        uint256 tokenId = auctions[_auctionId].tokenId;
        // delete auctionId for current address+id token combo
        // only one auction at a time per token allowed
        delete auctionIds[nftAddress][tokenId];
        // Delete auction struct
        delete auctions[_auctionId];
    }

    /**
     * @dev Sending ether is not guaranteed complete, and the method used here will
     * escrow the value if it fails. For example, a contract can block transfer, or might use
     * an excessive amount of gas, thereby griefing a bidder.
     * We limit the gas used in transfers, and handle failure with escrowing.
     * @param _to address to transfer ETH to
     * @param _amount uint256 WEI amount to transfer
     */
    function _tryTransferThenEscrow(address _to, uint256 _amount) private {
        // increase the gas limit a reasonable amount above the default, and try
        // to send ether to the recipient.
        (bool success, ) = _to.call{ value: _amount, gas: 30000 }('');
        if (!success) {
            _asyncTransfer(_to, _amount);
        }
    }
}