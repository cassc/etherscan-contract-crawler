//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/IAccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/PullPayment.sol';

import '../interfaces/IOwnable.sol';
import './IFirstDibsMarketSettingsV2.sol';
import '../royaltyEngine/IRoyaltyEngineV1.sol';
import './BidUtils.sol';
import './FirstDibsERC2771Context.sol';
import './IERC721TokenCreatorV2.sol';

contract FirstDibsAuctionV2 is
    PullPayment,
    AccessControl,
    ReentrancyGuard,
    IERC721Receiver,
    FirstDibsERC2771Context
{
    using BidUtils for uint256;

    bytes32 public constant BIDDER_ROLE = keccak256('BIDDER_ROLE');
    /**
     * ========================
     * #Public state variables
     * ========================
     */
    bool public bidderRoleRequired; // if true, bids require bidder having BIDDER_ROLE role
    bool public globalPaused; // flag for pausing all auctions
    IFirstDibsMarketSettingsV2 public iFirstDibsMarketSettings;
    IERC721TokenCreatorV2 public iERC721TokenCreatorRegistry;
    address public manifoldRoyaltyEngineAddress; // address of the manifold royalty engine https://royaltyregistry.xyz
    address public auctionV1Address; // address of the V1 auction contract, used as the source of bidder role truth

    // Mapping auction id => Auction
    mapping(uint256 => Auction) public auctions;
    // Map token address => tokenId => auctionId
    mapping(address => mapping(uint256 => uint256)) public auctionIds;

    /*
     * ========================
     * #Private state variables
     * ========================
     */
    uint256 private auctionIdsCounter;

    /**
     * ========================
     * #Structs
     * ========================
     */
    struct AuctionSettings {
        uint32 buyerPremium; // RBS; added on top of current bid
        uint32 duration; // defaults to globalDuration
        uint32 minimumBidIncrement; // defaults to globalMinimumBidIncrement
        uint32 commissionRate; // percent; defaults to globalMarketCommission
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
        address tokenOwner; // address of the owner of the token
        address payable fundsRecipient; // address of auction proceeds recipient
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
    function onlyAdmin() internal view {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'caller is not an admin');
    }

    function notPaused(uint256 auctionId) internal view {
        require(!globalPaused && !auctions[auctionId].paused, 'auction paused');
    }

    function auctionExists(uint256 auctionId) internal view {
        require(auctions[auctionId].fundsRecipient != address(0), "auction doesn't exist");
    }

    function hasBid(uint256 auctionId) internal view {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            // only admin may change state of auction with bids
            require(
                auctions[auctionId].currentBidder == address(0),
                'only admin can update state of auction with bids'
            );
        }
    }

    function senderIsAuctionCreatorOrAdmin(uint256 auctionId) internal view {
        require(
            _msgSender() == auctions[auctionId].auctionCreator ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            'must be auction creator or admin'
        );
    }

    function checkZeroAddress(address addr) internal pure {
        require(addr != address(0), '0 address not allowed');
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
        address fundsRecipient,
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

    event TransferFailed(address to, uint256 amount);

    /**
     * ========================
     * constructor
     * ========================
     */
    constructor(
        address _marketSettings,
        address _creatorRegistry,
        address _trustedForwarder,
        address _manifoldRoyaltyEngineAddress,
        address _auctionV1Address
    ) FirstDibsERC2771Context(_trustedForwarder) {
        require(
            _marketSettings != address(0) &&
                _creatorRegistry != address(0) &&
                _manifoldRoyaltyEngineAddress != address(0) &&
                _auctionV1Address != address(0),
            '0 address for contract ref'
        );
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); // deployer of the contract gets admin permissions
        iFirstDibsMarketSettings = IFirstDibsMarketSettingsV2(_marketSettings);
        iERC721TokenCreatorRegistry = IERC721TokenCreatorV2(_creatorRegistry);
        manifoldRoyaltyEngineAddress = _manifoldRoyaltyEngineAddress;
        auctionV1Address = _auctionV1Address;
        bidderRoleRequired = true;
        auctionIdsCounter = 0;
    }

    /**
     * @dev setter for manifold royalty engine address
     * @param _manifoldRoyaltyEngineAddress new manifold royalty engine address
     */
    function setManifoldRoyaltyEngineAddress(address _manifoldRoyaltyEngineAddress) external {
        onlyAdmin();
        checkZeroAddress(_manifoldRoyaltyEngineAddress);
        manifoldRoyaltyEngineAddress = _manifoldRoyaltyEngineAddress;
    }

    /**
     * @dev setter for market settings address
     * @param _iFirstDibsMarketSettings address of the FirstDibsMarketSettings contract to set for the auction
     */
    function setIFirstDibsMarketSettings(address _iFirstDibsMarketSettings) external {
        onlyAdmin();
        checkZeroAddress(_iFirstDibsMarketSettings);
        iFirstDibsMarketSettings = IFirstDibsMarketSettingsV2(_iFirstDibsMarketSettings);
    }

    /**
     * @dev setter for creator registry address
     * @param _iERC721TokenCreatorRegistry address of the IERC721TokenCreator contract to set for the auction
     */
    function setIERC721TokenCreatorRegistry(address _iERC721TokenCreatorRegistry) external {
        onlyAdmin();
        checkZeroAddress(_iERC721TokenCreatorRegistry);
        iERC721TokenCreatorRegistry = IERC721TokenCreatorV2(_iERC721TokenCreatorRegistry);
    }

    /**
     * @dev setter for setting bidder role being required to bid
     * @param _bidderRole bool If true, bidder must have bidder role to bid
     */
    function setBidderRoleRequired(bool _bidderRole) external {
        onlyAdmin();
        bidderRoleRequired = _bidderRole;
    }

    /**
     * @dev setter for global pause state
     * @param _paused true to pause all auctions, false to unpause all auctions
     */
    function setGlobalPaused(bool _paused) external {
        onlyAdmin();
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
     * @param _startTimeArg (optional) unix timestamp; allow bidding to start at this time
     * @param _auctionDurationArg (optional) auction duration in seconds
     * @param _fundsRecipient address to send auction proceeds to
     */
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _reservePrice,
        bool _pausedArg,
        uint64 _startTimeArg,
        uint32 _auctionDurationArg,
        address _fundsRecipient
    ) external {
        adminCreateAuction(
            _nftAddress,
            _tokenId,
            _reservePrice,
            _pausedArg,
            _startTimeArg,
            _auctionDurationArg,
            _fundsRecipient,
            10001 // adminCreateAuction function ignores values > 10000
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
     * @param _startTimeArg (optional) unix timestamp; allow bidding to start at this time
     * @param _auctionDurationArg (optional) auction duration in seconds
     * @param _fundsRecipient address to send auction proceeds to
     * @param _commissionRateArg (optional) admin-only; pass in a custom marketplace commission rate
     */
    function adminCreateAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _reservePrice,
        bool _pausedArg,
        uint64 _startTimeArg,
        uint32 _auctionDurationArg,
        address _fundsRecipient,
        uint16 _commissionRateArg
    ) public {
        notPaused(0);
        // May not create auctions unless you are the token owner or
        // an admin of this contract
        address tokenOwner = IERC721(_nftAddress).ownerOf(_tokenId);
        require(
            _msgSender() == tokenOwner ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
                IERC721(_nftAddress).getApproved(_tokenId) == _msgSender() ||
                IERC721(_nftAddress).isApprovedForAll(tokenOwner, _msgSender()),
            'must be token owner, admin, or approved'
        );

        require(_fundsRecipient != address(0), 'must pass funds recipient');

        require(auctionIds[_nftAddress][_tokenId] == 0, 'auction already exists');

        require(_reservePrice > 0, 'Reserve must be > 0');

        Auction memory auction = Auction({
            currentBid: Bid({ amount: 0, buyerPremiumAmount: 0 }),
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            tokenOwner: tokenOwner,
            fundsRecipient: payable(_fundsRecipient), // pass in the fundsRecipient
            auctionCreator: _msgSender(),
            reservePrice: _reservePrice, // minimum bid threshold for auction to begin
            startTime: 0,
            currentBidder: payable(address(0)), // there is no bidder at auction creation
            paused: _pausedArg, // is individual auction paused
            pausedTime: 0, // when the auction was paused
            settings: AuctionSettings({ // Defaults to global market settings; admins may override
                buyerPremium: iFirstDibsMarketSettings.globalBuyerPremium(),
                duration: iFirstDibsMarketSettings.globalAuctionDuration(),
                minimumBidIncrement: iFirstDibsMarketSettings.globalMinimumBidIncrement(),
                commissionRate: iFirstDibsMarketSettings.globalMarketCommission()
            })
        });
        if (_auctionDurationArg > 0) {
            require(
                _auctionDurationArg >= iFirstDibsMarketSettings.globalTimeBuffer(),
                'duration must be >= time buffer'
            );
            auction.settings.duration = _auctionDurationArg;
        }

        if (_startTimeArg > 0) {
            require(block.timestamp < _startTimeArg, 'start time must be in the future');
            auction.startTime = _startTimeArg;
            // since `bid` is gated by `notPaused` modifier
            // and a start time in the future means that a bid
            // must be allowed after that time, we can't have
            // the auction paused if there is a start time > 0
            auction.paused = false;
        }

        if (hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            if (_commissionRateArg <= 10000) {
                auction.settings.commissionRate = _commissionRateArg;
            }
        }

        auctionIdsCounter++;
        auctions[auctionIdsCounter] = auction;
        auctionIds[_nftAddress][_tokenId] = auctionIdsCounter;

        // transfer the NFT to the auction contract to hold in escrow for the duration of the auction
        IERC721(_nftAddress).safeTransferFrom(tokenOwner, address(this), _tokenId);

        emit AuctionCreated(
            auctionIdsCounter,
            _nftAddress,
            _tokenId,
            tokenOwner,
            _fundsRecipient,
            _reservePrice,
            auction.paused,
            _msgSender(),
            auction.settings.duration
        );
    }

    /**
     * @dev external function that can be called by any address which submits a bid to an auction
     * @param _auctionId uint256 id of the auction
     * @param _amount uint256 bid in WEI
     */
    function bid(uint256 _auctionId, uint256 _amount) external payable nonReentrant {
        auctionExists(_auctionId);
        notPaused(_auctionId);

        if (bidderRoleRequired == true) {
            require(
                IAccessControl(auctionV1Address).hasRole(BIDDER_ROLE, _msgSender()),
                'bidder role required'
            );
        }
        require(msg.value > 0 && _amount == msg.value, 'invalid bid value');
        // Auctions with a start time can't accept bids until now is greater than start time
        require(block.timestamp >= auctions[_auctionId].startTime, 'auction not started');
        // Auctions with an end time less than now may accept a bid
        require(
            auctions[_auctionId].startTime == 0 || block.timestamp < _endTime(_auctionId),
            'auction expired'
        );
        require(
            auctions[_auctionId].currentBidder != _msgSender() &&
                auctions[_auctionId].fundsRecipient != _msgSender() &&
                auctions[_auctionId].tokenOwner != _msgSender(),
            'invalid bidder'
        );

        // Validate the amount sent and get sent bid and sent premium
        (uint256 _sentBid, uint256 _sentPremium) = _amount.validateAndGetBid(
            auctions[_auctionId].settings.buyerPremium,
            auctions[_auctionId].reservePrice,
            auctions[_auctionId].currentBid.amount,
            auctions[_auctionId].settings.minimumBidIncrement,
            auctions[_auctionId].currentBidder
        );

        // bid amount is OK, if not first bid, then transfer funds
        // back to previous bidder & update current bidder to the current sender
        if (auctions[_auctionId].startTime == 0) {
            auctions[_auctionId].startTime = uint64(block.timestamp);
        } else if (auctions[_auctionId].currentBidder != address(0)) {
            _tryTransferThenEscrow(
                auctions[_auctionId].currentBidder, // prior
                auctions[_auctionId].currentBid.amount +
                    auctions[_auctionId].currentBid.buyerPremiumAmount // refund amount
            );
        }
        auctions[_auctionId].currentBid.amount = _sentBid;
        auctions[_auctionId].currentBid.buyerPremiumAmount = _sentPremium;
        auctions[_auctionId].currentBidder = payable(_msgSender());

        // extend countdown for bids within the time buffer of the auction
        if (
            // if auction ends less than globalTimeBuffer from now
            _endTime(_auctionId) < block.timestamp + iFirstDibsMarketSettings.globalTimeBuffer()
        ) {
            // increment the duration by the difference between the new end time and the old end time
            auctions[_auctionId].settings.duration += uint32(
                block.timestamp + iFirstDibsMarketSettings.globalTimeBuffer() - _endTime(_auctionId)
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
    function endAuction(uint256 _auctionId) external nonReentrant {
        auctionExists(_auctionId);
        notPaused(_auctionId);
        require(auctions[_auctionId].currentBidder != address(0), 'no bidders; use cancelAuction');

        require(
            auctions[_auctionId].startTime > 0 && //  auction has started
                block.timestamp >= _endTime(_auctionId), // past the endtime of the auction,
            'auction is not complete'
        );

        Auction memory auction = auctions[_auctionId];
        _delete(_auctionId);

        // send commission fee & buyer premium to commission address
        uint256 commissionFee = (auction.currentBid.amount * auction.settings.commissionRate) /
            10000;
        // don't attempt to transfer fees if there are none
        if (commissionFee + auction.currentBid.buyerPremiumAmount > 0) {
            _tryTransferThenEscrow(
                iFirstDibsMarketSettings.commissionAddress(),
                commissionFee + auction.currentBid.buyerPremiumAmount
            );
        }

        // Find token creator to determine if this is a primary sale
        // 1.  Get token creator from 1stDibs token registry;
        //     applies to 1stDibs tokens only
        address nftCreator = iERC721TokenCreatorRegistry.tokenCreator(
            auction.nftAddress,
            auction.tokenId
        );

        // 2. If token creator has not been registered through 1stDibs, check contract owner.
        //    We're assuming that creator is the owner, which isn't foolproof. Our primary use-case
        //    for non-1D tokens are Manifold ERC721 contracts and it's a reasonable assumption that
        //    creator equals contract owner. There are edge cases where this assumption will fail
        if (nftCreator == address(0)) {
            try IOwnable(auction.nftAddress).owner() returns (address owner) {
                nftCreator = owner;
            } catch {}
        }

        uint256 royaltyAmount = 0;
        if (nftCreator != auction.tokenOwner && nftCreator != address(0)) {
            // creator is not seller, so payout royalties
            // get royalty information from manifold royalty engine
            // https://royaltyregistry.xyz/
            (
                address payable[] memory royaltyRecipients,
                uint256[] memory amounts
            ) = IRoyaltyEngineV1(manifoldRoyaltyEngineAddress).getRoyalty(
                    auction.nftAddress,
                    auction.tokenId,
                    auction.currentBid.amount
                );
            uint256 arrLength = royaltyRecipients.length;
            for (uint256 i = 0; i < arrLength; ) {
                if (amounts[i] != 0 && royaltyRecipients[i] != address(0)) {
                    royaltyAmount += amounts[i];
                    _sendFunds(royaltyRecipients[i], amounts[i]);
                }
                unchecked {
                    ++i;
                }
            }
        }
        uint256 sellerFee = auction.currentBid.amount - royaltyAmount - commissionFee;
        _sendFunds(auction.fundsRecipient, sellerFee);

        // send the NFT to the winning bidder
        IERC721(auction.nftAddress).safeTransferFrom(
            address(this), // from
            auction.currentBidder, // to
            auction.tokenId
        );
        emit AuctionEnded(
            _auctionId,
            auction.tokenOwner,
            auction.currentBidder,
            auction.currentBid.amount,
            auction.currentBid.buyerPremiumAmount,
            commissionFee,
            royaltyAmount,
            sellerFee
        );
    }

    /**
     * @dev external function to cancel an auction & return the NFT to the creator of the auction
     * @param _auctionId uint256 auction id
     */
    function cancelAuction(uint256 _auctionId) external nonReentrant {
        senderIsAuctionCreatorOrAdmin(_auctionId);
        auctionExists(_auctionId);
        hasBid(_auctionId);

        Auction memory auction = auctions[_auctionId];
        _delete(_auctionId);

        // return the token back to the original owner
        IERC721(auction.nftAddress).safeTransferFrom(
            address(this),
            auction.tokenOwner,
            auction.tokenId
        );

        uint256 refundAmount = 0;
        if (auction.currentBidder != address(0)) {
            // If there's a bidder, return funds to them
            refundAmount = auction.currentBid.amount + auction.currentBid.buyerPremiumAmount;
            _tryTransferThenEscrow(auction.currentBidder, refundAmount);
        }

        emit AuctionCanceled(_auctionId, _msgSender(), refundAmount);
    }

    /**
     * @dev external function for pausing / unpausing an auction
     * @param _auctionId uint256 auction id
     * @param _paused true to pause the auction, false to unpause the auction
     */
    function setAuctionPause(uint256 _auctionId, bool _paused) external {
        senderIsAuctionCreatorOrAdmin(_auctionId);
        auctionExists(_auctionId);
        hasBid(_auctionId);

        if (_paused == auctions[_auctionId].paused) {
            revert('auction paused state not updated');
        }
        if (_paused) {
            auctions[_auctionId].pausedTime = uint64(block.timestamp);
        } else if (
            !_paused && auctions[_auctionId].pausedTime > 0 && auctions[_auctionId].startTime > 0
        ) {
            if (auctions[_auctionId].currentBidder != address(0)) {
                // if the auction has started, increment duration by difference between current time and paused time
                // differentiate here between an auction that has started with a bid (increment time) vs an auction that has a start time in the future (do not increment time)
                auctions[_auctionId].settings.duration += uint32(
                    block.timestamp - auctions[_auctionId].pausedTime
                );
            }
            auctions[_auctionId].pausedTime = 0;
        }
        auctions[_auctionId].paused = _paused;
        emit AuctionPaused(
            _auctionId,
            auctions[_auctionId].tokenOwner,
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
    ) external view override returns (bytes4) {
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
        // delete auctionId for current address+id token combo
        // only one auction at a time per token allowed
        delete auctionIds[auctions[_auctionId].nftAddress][auctions[_auctionId].tokenId];
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
            emit TransferFailed(_to, _amount);
            _asyncTransfer(_to, _amount);
        }
    }

    /**
     * @dev check if funds recipient is a contract. If it is, transfer ETH directly. If not, store in escrow on this contract.
     */
    function _sendFunds(address _to, uint256 _amount) private {
        // check if address is contract
        // see reference implementation at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L41
        if (_to.code.length > 0) {
            _tryTransferThenEscrow(_to, _amount);
        } else {
            _asyncTransfer(_to, _amount);
        }
    }

    function _msgSender()
        internal
        view
        override(Context, FirstDibsERC2771Context)
        returns (address sender)
    {
        return super._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, FirstDibsERC2771Context)
        returns (bytes calldata)
    {
        return super._msgData();
    }
}