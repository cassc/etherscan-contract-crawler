/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./utils/Counters.sol";
import "./utils/RoyaltyEngineV1.sol";
import "./access/Ownable.sol";

/**
 *
 * @title NinfaEnglishAuction                                *
 *                                                           *
 * @notice On-chain english auction                          *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 *
 */

contract NinfaEnglishAuction is Ownable, RoyaltyEngineV1 {
    using Counters for Counters.Counter;

    Counters.Counter private _auctionId;
    /// @notice Ninfa's external registry, mapping Ninfa's ERC721 sovereign
    /// collection's tokenIds to a boolean value
    /// indicating if the token has been sold on any of Ninfa's contracts, such
    /// as this marketplace or an auction
    /// contract.
    address private immutable _PRIMARY_MARKET_REGISTRY;
    /**
     * @notice auctions ids mapped to NFT auction data.
     * @dev This is deleted when an auction is finalized or canceled.
     * @dev Visibility needs to be public so that it can be called by a frontend
     * as the auction creation event only
     * emits auction id.
     */
    mapping(uint256 => _Auction) private _auctions;
    /// @notice whitelist of address codehashes of Ninfa's sovreign ERC721
    /// collections, in order to determine if it is a
    /// primary market sale
    bytes32 private _ERC721SovreignV1CodeHash;
    /**
     * @notice _feeRecipient multisig for receiving trading fees
     */
    address payable private _feeRecipient;
    /// @notice factory contract for deploying self-sovereign collections.
    address private _factory;
    address private _whitelist;
    /**
     * @notice How long an auction lasts for once the first bid has been
     * received.
     */
    uint256 private constant _DURATION = 1 days;
    /**
     * @notice The window for auction extensions, any bid placed in the final 15
     * minutes of an auction will reset the
     * time remaining to 15 minutes.
     */
    uint256 private constant _EXTENSION_DURATION = 15 minutes;
    /**
     * @notice the last highest bid is divided by this number in order to obtain
     * the minimum bid increment. E.g.
     * _MIN_BID_RAISE = 10 is 10% increment, 20 is 5%, 2 is 50%. I.e. 100 /
     * _MIN_BID_RAISE. OpenSea uses a fixed 5%
     * increment while SuperRare between 5-10%
     */
    uint256 private constant _MIN_BID_RAISE = 20;
    /// @notice Ninfa Marketplace fee percentage on primary sales, expressed in
    /// basis points
    uint256 private _primaryMarketFee;
    /// @notice Ninfa Marketplace fee percentage on all secondary sales,
    /// expressed in basis points
    uint256 private _secondaryMarketFee;

    /**
     * @notice Stores the auction configuration for a specific NFT.
     * @param operator since the order creator may be a gallery, i.e. the
     * commission receiver itself, they would not be
     * able to cancel or update the order as there would be no way to know if
     * the order creator was the seller or the
     * commissionReceiver,
     * @dev therefore an additional parameter is needed to store the address of
     * `msg.sender`
     * @param end the time at which this auction will not accept any new bids.
     * This is `0` until the first bid is
     * placed.
     * @param bidder highest bidder, needs to be payable in order to receive
     * refund in case of being outbid
     * @param price reserve price, highest bid, and all bids in between
     * @param erc1155Amount 0 for erc721, 1> for erc1155
     */
    struct _Auction {
        address operator;
        address seller;
        address collection;
        address bidder;
        uint256 tokenId;
        uint256 bidPrice;
        uint256 end;
        uint256[] commissionBps;
        address[] commissionReceivers;
    }

    /**
     * @notice Emitted when an NFT is listed for auction.
     * @param auctionId The id of the auction that was created.
     * @dev the only parameter needed is auctionId, the emitted event must
     * trigger the backend to retrieve all auction
     * data from a getter function and store it in DB.
     */
    event AuctionCreated(uint256 auctionId);

    /**
     * @notice Emitted when an auction is cancelled.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was cancelled.
     */
    event AuctionCanceled(uint256 auctionId);

    /**
     * @notice Emitted when the auction's reserve price is updated.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was updated.
     */
    event AuctionUpdated(uint256 auctionId);

    /**
     * @notice Emitted when an auction that has already ended is finalized,
     * indicating that the NFT has been transferred and revenue from the sale
     * distributed.
     */
    event AuctionFinalized(uint256 auctionId);

    /**
     * @notice Emitted when a bid is placed.
     * @param auctionId The id of the auction this bid was for.
     */
    event Bid(uint256 auctionId);

    /**
     * @notice ERC721 and ERC1155 collections must be whitelisted.
     * @dev if the collection has not been whitelisted, check if it is one of
     * Ninfa's factory clones (Ninfa's
     * self-sovereign collections)
     * @dev by checking the whitelist first with nested `if`s avoids having to
     * make an external call unnecessarily
     */
    modifier isWhitelisted(address _collection) {
        bytes memory authorized;
            (, authorized) = _factory.staticcall(
                abi.encodeWithSelector(0xf6a3d24e, _collection)
            );
        if (abi.decode(authorized, (bool)) == false) {
            (, authorized) = _whitelist.staticcall(
                abi.encodeWithSelector(0x3af32abf, _collection)
            );
            if (abi.decode(authorized, (bool)) == false) revert Unauthorized();
        }
        _;
    }

    /**
     * @notice Creates an auction for the given NFT. The NFT is held in escrow
     * until the auction is finalized or
     * canceled.
     * @param _id The id of the NFT.
     * @param _reservePrice The initial reserve price for the auction.
     * @dev reserve price may also be 0, clearly a mistake but not strictly
     * required, only done in order to save gas by
     * removing the need for a condition such as `if (_price == 0) revert
     * InvalidAmount(_price)`
     * @param _commissionReceivers address of sale commissions receiver
     * @dev if `msg.sender` is also the `_commissionReceiver`, e.g. if
     * `msg.sender` is a gallery, they must put their
     * own address as the `_commissionReceiver`, and set the `_seller` parameter
     * with the artist's/collector's address.
     * @dev if there is no commission receiver, it must be set to address(0)
     * @dev it is not required for `_commissionReceiver` and `_seller` addresses
     * to be different (in order to save gas),
     * although it would likely be a mistake, it cannot be exploited as the
     * total amount paid out will never exceed the
     * price set for the order. I.e. in the worst case the same address will
     * receive both principal sale profit and
     * commissions.
     */
    function _createAuction(
        address _operator, //  either the previous owner or operator, i.e.
            // whichever address called safeTransferFrom on
            // the ERC1155 contract
        address _from, // previous owner, i.e. seller
        uint256 _id,
        uint256 _reservePrice,
        uint256[] memory _commissionBps,
        address[] memory _commissionReceivers
    )
        private
    {
        _auctionId.increment(); // start counter at 1

        uint256 auctionId_ = _auctionId.current();

        _auctions[auctionId_] = _Auction(
            _operator,
            _from, // auction beneficiary, needs to be payable in order to
                // receive funds from the auction sale
            msg.sender,
            address(0), // bidder is only known once a bid has been placed. //
                // highest bidder, needs to be payable in
                // order to receive refund in case of being outbid
            _id,
            _reservePrice,
            0,
            _commissionBps,
            _commissionReceivers
        );

        emit AuctionCreated(auctionId_);
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this
     * contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the
     * recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with
     * `IERC721.onERC721Received.selector`.
     * @param _operator The address which called `safeTransferFrom` function
     * @param _from The address which previously owned the token
     * @param _tokenId The NFT identifier which is being transferred
     * @param _data Additional data with no specified format
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        returns (bytes4)
    {
        (uint256 reservePrice, uint256[] memory commissionBps, address[] memory commissionReceivers) =
            abi.decode(_data, (uint256, uint256[], address[]));

        _createAuction(_operator, _from, _tokenId, reservePrice, commissionBps, commissionReceivers);

        return 0x150b7a02;
    }

    function _transferNFT(address _collection, address _from, address _to, uint256 _tokenId) private {
        (bool success,) = _collection.call(
            abi.encodeWithSelector(
                0x42842e0e, // bytes4(keccak256('safeTransferFrom(address,address,uint256)'))
                    // == 0x42842e0e
                _from,
                _to,
                _tokenId
            )
        );

        require(success);
    }

    function firstBid(uint256 auctionId_) external payable {
        _Auction storage _auction = _auctions[auctionId_];

        // hardcoded 0x0 address in order to avoid reading from storage.
        // there is no need to check whether the auction exists already, because
        // even if someone managed to set end,
        // price and bidder for a (yet) non-existing auction, they would be
        // reser when an auction with the same id gets
        // created
        // the important thing is that no one can reset these variables for
        // auctions that have already started, and
        // can't happen because _auction.bidder would be set after the first bid
        // is placed by calling this function.
        if (
            _auction.bidder != 0x0000000000000000000000000000000000000000 // if
                // auction has started
                || msg.value < _auction.bidPrice
        ) revert Unauthorized();

        // if the auction exists and this is the firsat bid, start the auction
        // timer.
        // On the first bid, set the end to now + duration. `_DURATION` is a
        // constant set to 24hrs therefore the below
        // addition can't overflow.
        unchecked {
            _auction.end = block.timestamp + _DURATION;
            _auction.bidPrice = msg.value; // new highest bid
            _auction.bidder = msg.sender; // new highest bidder
        }

        emit Bid(auctionId_);
    }

    /**
     * @notice Place a bid in an auction.
     * A bidder may place a bid which is at least the amount defined by
     * `getMinBidAmount`.
     * If this is the first bid on the auction, the countdown will begin.
     * If there is already an outstanding bid, the previous bidder will be
     * refunded at this time
     * and if the bid is placed in the final moments of the auction, the
     * countdown may be extended.
     * @dev bids MUST be at least 5% higher than previous bid.
     * @param auctionId_ The id of the auction to bid on.
     * @dev auctionId_ MUST exist, auction MUST have begun and MUST not have
     * ended.
     */
    function bid(uint256 auctionId_) external payable {
        _Auction storage _auction = _auctions[auctionId_];
        // if auction hasn't started or doesn't exist, i.e. no one has called
        // firstBid() yet, _auction.end will still be
        // 0,
        // therefore the following require statement implicitly checks that
        // auction has started and explicitly that it
        // has not ended

        if (
            block.timestamp > _auction.end || _auction.end == 0 // required
                // otherwise calling this function would start
                // a 15 minutes auction rather than 24h
                || msg.value - _auction.bidPrice < _auction.bidPrice / _MIN_BID_RAISE
        ) revert Unauthorized();

        // if there is less than 15 minutes left, increment end time by 15 more.
        // _EXTENSION_DURATION is always set to 15
        // minutes so the below can't overflow.
        // already checking in previous if statement that if `block.timestamp >
        // _auction.end` the tx reverts, meaning
        // that `block.timestamp` must be less than `_auction.end`, i.e. auction
        // hasn't expired,
        // if you combine that with `block.timestamp + _EXTENSION_DURATION >
        // _auction.end` that means that
        // `block.timestamp` must be between `_auction.end` and `_auction.end -
        // 15 minutes`, i.e. it's the last 15
        // minutes of the auction.
        if (block.timestamp + _EXTENSION_DURATION > _auction.end) {
            unchecked {
                _auction.end += _EXTENSION_DURATION;
            }
        }

        // refund the previous bidder
        _sendValue(_auction.bidder, _auction.bidPrice);

        // does not follow check-effects-interactions pattern so that storing
        // previous bidder and amount in memory is
        // not required, however there is no reentrancy exploit in this case;
        // calling back into `bid()` requires that `msg.value` is 5% higher than
        // previous bid, meaning that the extra 5%
        // would not be refunded because storage has not been updated yet
        // besides the bid() function, there is no other function that can be
        // called back into which represents a
        // security risk, namely `createAuction()` and `firstBid()`, i.e.
        // _auction.bidPrice and _auction.bidder are not
        // read by any other function that may be reentered
        _auction.bidPrice = msg.value; // new highest bid
        _auction.bidder = msg.sender; // new highest bidder

        emit Bid(auctionId_);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, the
     * `reservePrice` may be edited by the
     * seller.
     * @param auctionId_ The id of the auction to change.
     * @param _newReservePrice The new reserve price for this auction, may be
     * higher or lower than the previoius price.
     * @dev `_newReservePrice` may be equal to old price
     * (`_auctions[auctionId_].price`); although this doesn't make much
     * sense it isn't a security requirement, hence `require(_auction.bidPrice
     * != _price)` it has been omitted in order
     * to save the user some gas
     * @dev `_newReservePrice` may also be 0, clearly a mistake but not a
     * security requirement,  hence `require(_price >
     * 0)` has been omitted in order to save the user some gas
     */
    function updateReservePrice(uint256 auctionId_, uint256 _newReservePrice) external {
        _Auction storage _auction = _auctions[auctionId_];
        // code duplication because modifiers can't pass variables to functions,
        // meanining that storage pointer cannot
        // be instantiated in modifier
        require(_auction.operator == msg.sender && _auction.end == 0);

        // Update the current reserve price.
        _auction.bidPrice = _newReservePrice;

        emit AuctionUpdated(auctionId_);
    }

    function setCommissions(
        uint256 auctionId_, 
        uint256[] memory _commissionBps, 
        address[] memory _commissionReceivers) external {
        require(msg.sender == _auctions[auctionId_].operator);
        _auctions[auctionId_].commissionBps = _commissionBps;
        _auctions[auctionId_].commissionReceivers = _commissionReceivers;
        emit AuctionUpdated(auctionId_);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, it
     * may be canceled by the seller.
     * @dev The NFT is transferred back to the owner unless there is still a buy
     * price set.
     * @param auctionId_ The id of the auction to cancel.
     */
    function cancelAuction(uint256 auctionId_) external {
        _Auction memory _auction = _auctions[auctionId_];

        require(_auction.operator == msg.sender && _auction.end == 0);

        // Delete the _auction.
        delete _auctions[auctionId_];

        _transferNFT(_auction.collection, address(this), msg.sender, _auction.tokenId);

        emit AuctionCanceled(auctionId_);
    }

    function finalize(uint256 auctionId_) external {
        _Auction memory auction = _auctions[auctionId_];
        address payable[] memory royaltyRecipients; // declare
            // `royaltyRecipients`, its value will be calculated based
            // on whether it is a primary or secondary sale
        uint256[] memory royaltyAmounts; // declare `royaltyAmounts`, its value
            // will be calculated based on whether it
            // is a primary or secondary sale
        // sellerAmount is a security check as well as a variable assignment,
        // because it would revert if there was an
        // underflow
        // sellerAmount may be 0 if royalties are set too high for an external
        // collection. If `royaltyAmount ==
        // (auction.bidPrice - marketplaceAmount)` then `sellerAmount == 0`. if
        // royalties amount exceeds price - fees
        // amount the transaction will revert.
        uint256 sellerAmount = auction.bidPrice;
        uint256 marketplaceAmount;

        // there must be at least one bid higher than the reserve price in order
        // to execute the trade, no bids mean no
        // end time
        if (block.timestamp < auction.end || auction.end == 0) {
            revert Unauthorized();
        }

        // Remove the auction.
        delete _auctions[auctionId_];

        bool checkSecondaryMarket = true;

        if (auction.collection.codehash == _ERC721SovreignV1CodeHash) {
            // it's a v1 721 token, check market registry
            (, bytes memory secondaryMarket) = _PRIMARY_MARKET_REGISTRY.call(
                abi.encodeWithSelector(
                    0x7abab711,
                    auction.collection,
                    auction.tokenId
                ) // bytes4(keccak256("secondaryMarketInfo(address,uint256)")) == 0x7abab711
            );

            checkSecondaryMarket = abi.decode(secondaryMarket, (bool));
        }

        /*----------------------------------------------------------*|
        |*  # PAY ROYALTIES                                         *|
        |*----------------------------------------------------------*/
        // > "Marketplaces that support this standard MUST pay royalties no
        // matter where the sale occurred or in what
        // currency" - https://eips.ethereum.org/EIPS/eip-2981.

        /*----------------------------------------------------------*|
        |*  # IF ROYALTIES SUPPORTED                                *|
        |*----------------------------------------------------------*/
        // The collection implements some royalty standard, otherwise the length
        // of the arrays returned would be 0.
        if (checkSecondaryMarket) {
            (royaltyRecipients, royaltyAmounts) = getRoyalty(auction.collection, auction.tokenId, sellerAmount);
        }
        
        uint256 royaltyRecipientsLength = royaltyRecipients.length; // assign to

        if (royaltyRecipientsLength > 0) {
            if (_secondaryMarketFee > 0) {
                /*----------------------------------------------------------*|
                |*  # PAY MARKETPLACE FEE                                   *|
                |*----------------------------------------------------------*/
                marketplaceAmount = (auction.bidPrice * _secondaryMarketFee) / 10_000;
                // subtracting primary or secondary fee amount from seller
                // amount, this is a security check (will revert
                // on underflow) as well as a variable assignment.
                sellerAmount -= marketplaceAmount; // subtract before external
                    // call
                _sendValue(_feeRecipient, marketplaceAmount);
            }

            do {
                royaltyRecipientsLength--;
                // subtracting royalty amount from seller amount, this is a
                // security check (will revert on
                // underflow) as well as a variable assignment.
                if(royaltyAmounts[royaltyRecipientsLength] > 0){
                    sellerAmount -= royaltyAmounts[royaltyRecipientsLength]; // subtract
                        // before external call
                    _sendValue(royaltyRecipients[royaltyRecipientsLength], royaltyAmounts[royaltyRecipientsLength]);
                }
            } while (royaltyRecipientsLength > 0);
        } else {
            //case primary
            marketplaceAmount = (auction.bidPrice * _primaryMarketFee) / 10_000;
            sellerAmount -= marketplaceAmount; // subtract before external
            // call
            _sendValue(_feeRecipient, marketplaceAmount);
        }

        /**
         *
         * Pay seller commissions *
         *
         */

        uint256 commissionReceiversLength = auction.commissionReceivers.length;

        if (commissionReceiversLength > 0) {
            do {
                commissionReceiversLength--;
                if(auction.commissionBps[commissionReceiversLength] > 0){
                    uint256 commissionAmount = (auction.commissionBps[commissionReceiversLength] * auction.bidPrice) / 10_000; // calculate
    
                    sellerAmount -= commissionAmount; // subtract before external

                    _sendValue(auction.commissionReceivers[commissionReceiversLength], commissionAmount);
                }
            } while (commissionReceiversLength > 0);
        }

        /**
         *
         * Pay seller *
         *
         */

        _sendValue(auction.seller, sellerAmount);

        // transfer nft to auction winner
        _transferNFT(auction.collection, address(this), auction.bidder, auction.tokenId);

        emit AuctionFinalized(auctionId_);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `_amount` wei to
     * `_receiver`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] raises the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {_sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn
     * more].
     *
     * IMPORTANT: because control is transferred to `_receiver`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions
     * pattern].
     */
    function _sendValue(address _receiver, uint256 _amount) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = payable(_receiver).call{ value: _amount }("");
        require(success);
    }

    /**
     * @dev setter function only callable by contract admin used to change the
     * address to which fees are paid
     * @param _newFeeAccount is the address owned by NINFA that will collect
     * sales fees
     */
    function setFeeRecipient(address payable _newFeeAccount) external onlyOwner {
        _feeRecipient = _newFeeAccount;
    }

    function setWhitelist(address whitelist_) external onlyOwner {
        _whitelist = whitelist_;
    }

    /**
     * @notice sets primary sale fees for NINFA_ERC721_V2 communal collection.
     */
    function setMarketFees(uint256 primaryMarketFee_, uint256 secondaryMarketFee_) external onlyOwner {
        _primaryMarketFee = primaryMarketFee_;
        _secondaryMarketFee = secondaryMarketFee_;
    }

    function auctions(uint256 auctionId_) external view returns (_Auction memory) {
        return _auctions[auctionId_];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
        // Interface ID for IERC165
        interfaceId == 0x01ffc9a7
        // Interface ID for IERC721Receiver. A wallet/broker/auction application
        // MUST implement the wallet interface if
        // it will accept safe transfers.
        || interfaceId == 0x150b7a02;
    }

    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`
     * @dev after deployment admin needs to manually whitelist collections.
     * @param _royaltyRegistry see https://royaltyregistry.xyz/lookup for public
     * addresses
     */
    constructor(
        address _royaltyRegistry,
        address _primarySalesRegistry,
        address factory_,
        address whitelist_,
        bytes32 ERC721SovreignV1CodeHash
    )
        RoyaltyEngineV1(_royaltyRegistry)
    {
        _PRIMARY_MARKET_REGISTRY = _primarySalesRegistry;
        _factory = factory_;
        _whitelist = whitelist_;
        _ERC721SovreignV1CodeHash = ERC721SovreignV1CodeHash;
    }
}