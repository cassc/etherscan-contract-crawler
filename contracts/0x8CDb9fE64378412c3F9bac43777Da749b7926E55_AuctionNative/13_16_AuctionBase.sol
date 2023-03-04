// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./IAuctionBase.sol";
import "../../buyNow/base/BuyNowBase.sol";
import "./IEIP712VerifierAuction.sol";

/**
 * @title Base Escrow Contract for Payments, that adds an Auction mode
 *  to the inherited BuyNowBase, which implements the BuyNow mode.
 * @author Freeverse.io, www.freeverse.io
 * @notice Full contract documentation in IAuctionBase
 */

abstract contract AuctionBase is IAuctionBase, BuyNowBase {
    // max amount of time allowed between the arrival of the first bid
    // of an auction, and the planned auction endsAt, in absence of late bids.
    uint256 public constant _MAX_AUCTION_DURATION = 15 days;

    // max total amount of time that an auction's endsAt can be
    // increased as a result of accumulated late-arriving bids.
    uint256 public constant _MAX_EXTENDABLE_BY = 2 days;

    // the default config parameters used by Auctions
    AuctionConfig internal _defaultAuctionConfig;

    // mapping between universeId and their specific auction config parameters
    mapping(uint256 => AuctionConfig) private _universeAuctionConfig;

    // mapping between universeId and whether a specific auction config exists
    // for that universe
    mapping(uint256 => bool) public _universeAuctionConfigExists;

    // mapping between existing paymentsIds for auctions,
    // and the stored data about these Auctions
    mapping(bytes32 => ExistingAuction) private _auctions;

    constructor(
        uint256 minIncreasePercentage,
        uint256 time2Extend,
        uint256 extendableBy
    ) {
       setDefaultAuctionConfig(
            minIncreasePercentage,
            time2Extend,
            extendableBy
        );
    }

    /// @inheritdoc IAuctionBase
    function setDefaultAuctionConfig(
        uint256 minIncreasePercentage,
        uint256 time2Extend,
        uint256 extendableBy
    ) public onlyOwner {
        AuctionConfig memory oldConfig = _defaultAuctionConfig;
        _defaultAuctionConfig = _createAuctionConfig(
            minIncreasePercentage,
            time2Extend,
            extendableBy
        );
        emit DefaultAuctionConfig(
            minIncreasePercentage, time2Extend, extendableBy,
            oldConfig.minIncreasePercentage, oldConfig.timeToExtend, oldConfig.extendableBy
        );
    }

    /// @inheritdoc IAuctionBase
    function setUniverseAuctionConfig(
        uint256 universeId,
        uint256 minIncreasePercentage,
        uint256 time2Extend,
        uint256 extendableBy
    ) external onlyOwner {
        AuctionConfig memory oldConfig =  _universeAuctionConfig[universeId];
        _universeAuctionConfig[universeId] = _createAuctionConfig(
            minIncreasePercentage,
            time2Extend,
            extendableBy
        );
        _universeAuctionConfigExists[universeId] = true;
        emit UniverseAuctionConfig(
            universeId,
            minIncreasePercentage, time2Extend, extendableBy,
            oldConfig.minIncreasePercentage, oldConfig.timeToExtend, oldConfig.extendableBy
        );
    }

    /// @inheritdoc IAuctionBase
    function removeUniverseAuctionConfig(uint256 universeId)
        external
        onlyOwner
    {
        delete _universeAuctionConfig[universeId];
        _universeAuctionConfigExists[universeId] = false;
        emit RemovedUniverseAuctionConfig(universeId);
    }

    // PRIVATE & INTERNAL FUNCTIONS

    /**
     * @dev Checks bid input parameters,
     *  transfers required funds from external contract (in case of ERC20 Payments),
     *  reuses buyer's local balance (if any),
     *  stores the payment and auction data in contract's storage,
     *  and refunds previous highest bidder (if any).
     *  - If payment is in NOT_STARTED => it moves to AUCTIONING
     *  - If payment is in AUCTIONING => it remains in AUCTIONING
     * @param operator The address of the operator of this payment.
     * @param bidInput The BidInput struct
     */
    function _processBid(
        address operator,
        BidInput calldata bidInput,
        bytes calldata sellerSignature
    ) internal {
        State state = assertBidInputsOK(bidInput);
        assertSeparateRoles(operator, bidInput.bidder, bidInput.seller);
        (uint256 newFundsNeeded, uint256 localFunds, bool isSameBidder) = splitAuctionFundingSources(bidInput);
        _updateBuyerBalanceOnPaymentReceived(bidInput.bidder, newFundsNeeded, localFunds);

        if (state == State.NotStarted) {
            // If 1st bid for auction => new auction is to be created:
            // 1. Only verify the permission to list the asset on the first bid to arrive
            require(
                IEIP712VerifierAuction(_eip712).verifySellerSignature(
                    sellerSignature,
                    bidInput
                ),
                "AuctionBase::_processBid: incorrect seller signature"
            );
            // 2.- store the part of the data common to Auctions and BuyNows;
            //     maxBidder and maxBid are stored in this struct, and updated on successive bids
            uint256 extendableUntil = bidInput.endsAt + universeExtendableBy(bidInput.universeId);
            uint256 expirationTime = extendableUntil + _paymentWindow;
            _payments[bidInput.paymentId] = Payment(
                State.Auctioning,
                bidInput.bidder,
                bidInput.seller,
                bidInput.universeId,
                universeFeesCollector(bidInput.universeId),
                expirationTime,
                bidInput.feeBPS,
                bidInput.bidAmount
            );
            // 2.- store the part of the data only relevant to Auctions;
            //     only 'endsAt' may change in this struct (and only on arrival of late bids)
            _auctions[bidInput.paymentId] = ExistingAuction(
                bidInput.endsAt,
                universeMinIncreasePercentage(bidInput.universeId),
                universeTimeToExtend(bidInput.universeId),
                extendableUntil
            );
        } else {
            // If an auction already existed:
            if (!isSameBidder) {
                // if new bidder is different from previous max bidder:
                // - and refund previous max bidder
                _refundPreviousBidder(bidInput);

                // - update max bidder
                _payments[bidInput.paymentId].buyer = bidInput.bidder;

            }

            // 2.- update the previous highest bid
            _payments[bidInput.paymentId].amount = bidInput.bidAmount;
        }

        // extend auction ending time if classified as late bid:
        uint256 endsAt = _extendAuctionOnLateBid(bidInput);

        emit Bid(bidInput.paymentId, bidInput.bidder, bidInput.seller, bidInput.bidAmount, endsAt);
    }

    /**
     * @dev Interface to a method that, on arrival of a bid that outbids a previous one,
     *  refunds previous bidder, with refund options depedending on implementation
     *  (refund to local balance, transfer to external contract, etc.)
     * @param bidInput The struct containing all bid data
     */
    function _refundPreviousBidder(BidInput memory bidInput) internal virtual;

    /**
     * @notice Increments the ending time of an auction on arrival of a 'late bid' during the
     *  time window [currentEndsAt - timeToExtend, currentEndsAt], by an amount equal to timeToExtend,
     *  never exceeding the extendableUntil value stored during the creation of that auction.
     * @param bidInput The struct containing all bid data
     * @return endsAt On late bid: the incremented ending time of the auction;
     *  on non-late bid: the previous unmodified ending time.
     */
    function _extendAuctionOnLateBid(BidInput memory bidInput)
        private
        returns (uint256 endsAt)
    {
        endsAt = _auctions[bidInput.paymentId].endsAt;

        // return current endsAt if not within the last minutes:
        uint256 time2Extend = _auctions[bidInput.paymentId].timeToExtend;
        if ((block.timestamp + time2Extend) <= endsAt) return endsAt;

        // increment endsAt, but never beyond extension limit
        endsAt += time2Extend;
        uint256 extendableUntil = _auctions[bidInput.paymentId].extendableUntil;
        if (endsAt > extendableUntil) endsAt = extendableUntil;

        // store incremented value:
        _auctions[bidInput.paymentId].endsAt = endsAt;
    }

    /**
     * @notice Checks that minIncreasePercentage is non-zero, and returns an AuctionConfig struct
     * @param minIncreasePercentage The minimum amount that a new bid needs to increase
     *  above the previous highest bid, expressed as a percentage in Basis Points (BPS).
     *  e.g.: minIncreasePercentage = 500 requires new bids to be 5% larger.
     * @param time2Extend If a bid arrives during the time window [endsAt - timeToExtend, endsAt],
     *  then endsAt is increased by timeToExtend.
     * @param extendableBy The maximum value that endsAt can be increased in an auction
     *  as a result of accumulated late-arriving bids.
     * @return the AuctionConfig struct
     */
    function _createAuctionConfig(
        uint256 minIncreasePercentage,
        uint256 time2Extend,
        uint256 extendableBy
    ) private pure returns (AuctionConfig memory) {
        require(
            minIncreasePercentage > 0,
            "AuctionBase::_createAuctionConfig: minIncreasePercentage must be non-zero"
        );
        require(
            extendableBy <= _MAX_EXTENDABLE_BY,
            "AuctionBase::_createAuctionConfig: extendableBy exceeds maximum allowed"
        );
        return AuctionConfig(minIncreasePercentage, time2Extend, extendableBy);
    }

    // VIEW FUNCTIONS

    /// @inheritdoc IAuctionBase
    function assertBidInputsOK(BidInput calldata bidInput)
        public
        view
        returns (State state)
    {
        uint256 currentTime = block.timestamp;

        // requirements independent of current auction state:
        require(
            currentTime <= bidInput.deadline,
            "AuctionBase::assertBidInputsOK: payment deadline expired"
        );
        if (_isSellerRegistrationRequired) {
            require(
                _isRegisteredSeller[bidInput.seller],
                "AuctionBase::assertBidInputsOK: seller not registered"
            );
        }

        // requirements that depend on current auction state:
        state = paymentState(bidInput.paymentId);
        if (state == State.NotStarted) {
            // if auction does not exist yet, assert values are within obvious limits 
            require(
                bidInput.endsAt >= currentTime,
                "AuctionBase::assertBidInputsOK: endsAt cannot be in the past"
            );
            require(
                bidInput.endsAt < currentTime + _MAX_AUCTION_DURATION,
                "AuctionBase::assertBidInputsOK: endsAt exceeds maximum allowed"
            );
            require(
                bidInput.feeBPS <= _maxFeeBPS,
                "AuctionBase::assertBidInputsOK: fee cannot be larger than maxFeeBPS"
            );
            require(
                bidInput.bidAmount > 0,
                "AuctionBase::assertBidInputsOK: bid amount cannot be 0"
            );
        } else if (state == State.Auctioning) {
            // if auction exists already:
            require(
                bidInput.bidAmount >= minNewBidAmount(bidInput.paymentId),
                "AuctionBase::assertBidInputsOK: bid needs to be larger than previous bid by a certain percentage"
            );
        } else {
            revert("AuctionBase::assertBidInputsOK: bids are only accepted if state is either NOT_STARTED or AUCTIONING");
        }
    }

    /// @inheritdoc IAuctionBase
    function splitAuctionFundingSources(BidInput calldata bidInput)
        public
        view
        returns (
            uint256 externalFunds,
            uint256 localFunds,
            bool isSameBidder
        )
    {
        isSameBidder = (bidInput.bidder == _payments[bidInput.paymentId].buyer);

        // If new bidder coincides with previous max bidder, only the provision of funds
        // corresponding to the difference between the two bidAmounts is required
        uint256 amount = isSameBidder
            ? bidInput.bidAmount - _payments[bidInput.paymentId].amount
            : bidInput.bidAmount;
        (externalFunds, localFunds) = splitFundingSources(
            bidInput.bidder,
            amount
        );
    }

    /// @inheritdoc IAuctionBase
    function minNewBidAmount(bytes32 paymentId) public view returns (uint256) {
        uint256 previousBidAmount = _payments[paymentId].amount;
        uint256 minNewAmount = (previousBidAmount *
            (10000 + _auctions[paymentId].minIncreasePercentage)) / 10000;
        // If previousBidAmount and minIncreasePercentage are small,
        // it is possible to the int division results in minNewAmount = previousBidAmount.
        // In that case, return + 1 to avoid accepting bids that do not increment previous amount.
        return minNewAmount > previousBidAmount ? minNewAmount : previousBidAmount + 1;
    }

    /// @inheritdoc IAuctionBase
    function paymentState(bytes32 paymentId)
        public
        view
        virtual
        override(IAuctionBase, BuyNowBase)
        returns (State)
    {
        State state = _payments[paymentId].state;
        if (state != State.Auctioning) return state;
        return
            (block.timestamp > _auctions[paymentId].endsAt)
                ? State.AssetTransferring
                : State.Auctioning;
    }

    /// @inheritdoc IAuctionBase
    function universeMinIncreasePercentage(uint256 universeId)
        public
        view
        returns (uint256)
    {
        return
            _universeAuctionConfigExists[universeId]
                ? _universeAuctionConfig[universeId].minIncreasePercentage
                : _defaultAuctionConfig.minIncreasePercentage;
    }

    /// @inheritdoc IAuctionBase
    function universeTimeToExtend(uint256 universeId) public view returns (uint256) {
        return
            _universeAuctionConfigExists[universeId]
                ? _universeAuctionConfig[universeId].timeToExtend
                : _defaultAuctionConfig.timeToExtend;
    }

    /// @inheritdoc IAuctionBase
    function universeExtendableBy(uint256 universeId) public view returns (uint256) {
        return
            _universeAuctionConfigExists[universeId]
                ? _universeAuctionConfig[universeId].extendableBy
                : _defaultAuctionConfig.extendableBy;
    }

    /// @inheritdoc IAuctionBase
    function defaultAuctionConfig() public view returns (AuctionConfig memory) {
        return _defaultAuctionConfig;
    }

    /// @inheritdoc IAuctionBase
    function universeAuctionConfig(uint256 universeId)
        public
        view
        returns (AuctionConfig memory)
    {
        return _universeAuctionConfig[universeId];
    }

    /// @inheritdoc IAuctionBase
    function existingAuction(bytes32 paymentId)
        public
        view
        returns (ExistingAuction memory)
    {
        return _auctions[paymentId];
    }
}