pragma solidity ^0.5.16;

import "./MtrollerInterface.sol";
import "./MTokenInterfaces.sol";
import "./MTokenStorage.sol";
import "./ErrorReporter.sol";
import "./compound/Exponential.sol";
import "./open-zeppelin/token/ERC721/IERC721.sol";

contract TokenAuction is Exponential, TokenErrorReporter {

    event NewAuctionOffer(uint240 tokenID, address offeror, uint256 totalOfferAmount);
    event AuctionOfferCancelled(uint240 tokenID, address offeror, uint256 cancelledOfferAmount);
    event HighestOfferAccepted(uint240 tokenID, address offeror, uint256 acceptedOfferAmount, uint256 auctioneerTokens, uint256 oldOwnerTokens);
    event AuctionRefund(address beneficiary, uint256 amount);

    struct Bidding {
        mapping (address => uint256) offers;
        mapping (address => uint256) offerIndex;
        uint256 nextOffer;
        mapping (uint256 => mapping (uint256 => address)) maxOfferor;
    }

    bool internal _notEntered; // re-entrancy check flag
    
    MEtherUserInterface public paymentToken;
    MtrollerUserInterface public mtroller;

    mapping (uint240 => Bidding) public biddings;

    // ETH account for each participant
    mapping (address => uint256) public refunds;

    constructor(MtrollerUserInterface _mtroller, MEtherUserInterface _mEtherPaymentToken) public
    {
        mtroller = _mtroller;
        paymentToken = _mEtherPaymentToken;
        _notEntered = true; // Start true prevents changing from zero to non-zero (smaller gas cost)
    }

    /**
        @notice Increase a currently pending offer for _mToken. Should only be called by the _mToken 
        contract, not the user directly. If _mToken is the anchorToken then it is a collection offer.
        If _directSale == true the underlying NFT will be sold directly to _bidder instead of adding
        a new bid. In this case it is required to approve this contract to transfer the _mToken before 
        calling this function. 
    */
    function addOfferETH(
        uint240 _mToken,
        address _bidder,
        address payable _oldOwner,
        bool _directSale
    )
        external
        nonReentrant
        payable
        returns (uint256)
    {
        require (msg.value > 0, "No payment sent");
        ( , , address _tokenAddress) = mtroller.parseToken(_mToken);
        require(msg.sender == _tokenAddress, "Only token contract");

        uint256 _oldOffer = biddings[_mToken].offers[_bidder];
        uint256 _newOffer = _oldOffer + msg.value;

        /* Check if auction is allowed by mtroller. For collection offers only check if mToken is listed. 
           For specific offers allow instant sale if _directSale == true */
        uint240 _anchorToken = mtroller.getAnchorToken(_tokenAddress);
        if (_mToken == _anchorToken) {
            mtroller.collateralFactorMantissa(_mToken); // reverts if _mToken is not listed
        }
        else {
            /* more extensive checks. Reverts if mToken currently does not exist (e.g. has been redeemed) */
            require(mtroller.auctionAllowed(_mToken, _bidder) == uint(Error.NO_ERROR), "Auction not allowed");
            /* if _directSale == true, we do not enter the bid but sell directly */
            if (_directSale) {
                if (_oldOffer > 0) {
                    require(cancelOfferInternal(_mToken, _bidder) == _oldOffer, "Could not cancel offer");
                }
                ( , uint256 oldOwnerTokens) = processPaymentInternal(_oldOwner, _newOffer, _oldOwner, 0);
                redeemFromAndTransfer(_mToken, _tokenAddress, _bidder);
                emit HighestOfferAccepted(_mToken, _bidder, _newOffer, 0, oldOwnerTokens);
                return _newOffer; // return sale price for verification purposes
            }
        }

        /* the new offer is entered normally */
        if (_oldOffer == 0) {
            uint256 _nextIndex = biddings[_mToken].nextOffer;
            biddings[_mToken].offerIndex[_bidder] = _nextIndex;
            biddings[_mToken].nextOffer = _nextIndex + 1;
        }
        _updateOffer(_mToken, biddings[_mToken].offerIndex[_bidder], _bidder, _newOffer);
        emit NewAuctionOffer(_mToken, _bidder, _newOffer);
        return 0;
    }

    /**
        @notice Cancel any existing offer of the sender for _mToken and prepare refund.
    */
    function cancelOffer(
        uint240 _mToken
    )
        public
        nonReentrant
    {
        // // for later version: if sender is the highest bidder try to start grace period 
        // // and do not allow to cancel bid during grace period (+ 2 times preferred liquidator delay)
        // if (msg.sender == getMaxOfferor(_mToken)) {
        //     ( , , address _mTokenAddress) = mtroller.parseToken(_mToken);
        //     MERC721Interface(_mTokenAddress).startGracePeriod(_mToken);
        // }
        uint256 _oldOffer = cancelOfferInternal(_mToken, msg.sender);
        refunds[msg.sender] += _oldOffer;
        emit AuctionOfferCancelled(_mToken, msg.sender, _oldOffer);
    }
    
    /**
        @notice Accepts the highest currently active offer for _mToken, taking into account both specific
        offers for that _mToken and any active offers for the whole collection. If _favoriteBidder is
        nonzero, then the _mToken is sold to that address instead of the highest bidder.
        Required: approve this contract to transfer the _mToken before calling this function. 
        Should only be called by the _mToken contract, not the user directly. 
    */
    function acceptHighestOffer(
        uint240 _mToken,
        address payable _oldOwner,
        address payable _auctioneer,
        uint256 _auctioneerFeeMantissa,
        uint256 _minimumPrice,
        address _favoriteBidder
    )
        external
        nonReentrant
        returns (address _maxOfferor, uint256 _maxOffer, uint256 auctioneerTokens, uint256 oldOwnerTokens)
    {
        require(mtroller.auctionAllowed(_mToken, _auctioneer) == uint(Error.NO_ERROR), "Auction not allowed");
        ( , , address _tokenAddress) = mtroller.parseToken(_mToken);
        require(msg.sender == _tokenAddress, "Only token contract");

        if (_favoriteBidder == address(0)) {
            /* if no favorite bidder, check for and handle highest offer (collection or specific) */
            uint256 _maxAllOffers = getMaxOffer(_mToken);
            require(_maxAllOffers > 0, "No valid offer found");
            uint240 _anchorToken = mtroller.getAnchorToken(_tokenAddress);
            if (_maxAllOffers > getMaxOffer(_anchorToken)) {
                _maxOfferor = getMaxOfferor(_mToken); // this should never revert here
                _maxOffer = cancelOfferInternal(_mToken, _maxOfferor);
            }
            else {
                _maxOfferor = getMaxOfferor(_anchorToken); // this should never revert here
                _maxOffer = cancelOfferInternal(_anchorToken, _maxOfferor);
            }
        }
        else {
            /* otherwise sell to the favorite bidder */
            _maxOfferor = _favoriteBidder;
            uint240 _anchorToken = mtroller.getAnchorToken(_tokenAddress);
            if (getOffer(_anchorToken, _maxOfferor) > getOffer(_mToken, _maxOfferor))
            {
                _maxOffer = cancelOfferInternal(_anchorToken, _maxOfferor); // reverts if favorite bidder has no active offer
            }
            else {
                _maxOffer = cancelOfferInternal(_mToken, _maxOfferor); // reverts if favorite bidder has no active offer
            }
        }
        require(_maxOffer >= _minimumPrice, "Best offer too low");

        /* process payment, reverts on error */
        (auctioneerTokens, oldOwnerTokens) = processPaymentInternal(_oldOwner, _maxOffer, _auctioneer, _auctioneerFeeMantissa);

        /* redeem _mToken and transfer underlying to _maxOfferor (reverts on error) */
        redeemFromAndTransfer(_mToken, _tokenAddress, _maxOfferor);

        emit HighestOfferAccepted(_mToken, _maxOfferor, _maxOffer, auctioneerTokens, oldOwnerTokens);
        
        return (_maxOfferor, _maxOffer, auctioneerTokens, oldOwnerTokens);
    }

    function redeemFromAndTransfer(uint240 _mToken, address _tokenAddress, address _beneficiary) internal {
        MERC721Interface _mTokenContract = MERC721Interface(_tokenAddress);
        MTokenV1Storage _mTokenStorage = MTokenV1Storage(_tokenAddress);
        uint256 _underlyingID = _mTokenStorage.underlyingIDs(_mToken);
        _mTokenContract.safeTransferFrom(_mTokenContract.ownerOf(_mToken), address(this), _mToken);
        require(_mTokenContract.redeem(_mToken) == uint(Error.NO_ERROR), "Redeem failed");
        IERC721(_mTokenStorage.underlyingContract()).safeTransferFrom(address(this), _beneficiary, _underlyingID);
        require(IERC721(_mTokenStorage.underlyingContract()).ownerOf(_underlyingID) == _beneficiary, "Transfer failed");
    }

    function payOut(address payable beneficiary, uint256 amount) internal returns (uint256 mintedMTokens) {
        // try to accrue mEther interest first; if it fails, pay out full amount in mEther
        uint240 mToken = MTokenV1Storage(address(paymentToken)).thisFungibleMToken();
        uint err = paymentToken.accrueInterest(mToken);
        if (err != uint(Error.NO_ERROR)) {
            mintedMTokens = paymentToken.mintTo.value(amount)(beneficiary);
            return mintedMTokens;
        }

        // if beneficiary has outstanding borrows, repay as much as possible (revert on error)
        uint256 borrowBalance = paymentToken.borrowBalanceStored(beneficiary, mToken);
        if (borrowBalance > amount) {
            borrowBalance = amount;
        }
        if (borrowBalance > 0) {
            require(paymentToken.repayBorrowBehalf.value(borrowBalance)(beneficiary) == borrowBalance, "Borrow repayment failed");
        }

        // payout any surplus: in cash (ETH) if beneficiary has no shortfall; otherwise in mEther
        if (amount > borrowBalance) {
            uint256 shortfall;
            (err, , shortfall) = MtrollerInterface(MTokenV1Storage(address(paymentToken)).mtroller()).getAccountLiquidity(beneficiary);
            if (err == uint(Error.NO_ERROR) && shortfall == 0) {
                (bool success, ) = beneficiary.call.value(amount - borrowBalance)("");
                require(success, "ETH Transfer failed");
                mintedMTokens = 0;
            }
            else {
                mintedMTokens = paymentToken.mintTo.value(amount - borrowBalance)(beneficiary);
            }
        }
    }

    function processPaymentInternal(
        address payable _oldOwner,
        uint256 _price,
        address payable _broker,
        uint256 _brokerFeeMantissa
    )
        internal
        returns (uint256 brokerTokens, uint256 oldOwnerTokens) 
    {
        require(_oldOwner != address(0), "Invalid owner address");
        require(_price > 0, "Invalid price");
        
        /* calculate fees for protocol and add it to protocol's reserves (in underlying cash) */
        uint256 _amountLeft = _price;
        Exp memory _feeShare = Exp({mantissa: paymentToken.getProtocolAuctionFeeMantissa()});
        (MathError _mathErr, uint256 _fee) = mulScalarTruncate(_feeShare, _price);
        require(_mathErr == MathError.NO_ERROR, "Invalid protocol fee");
        if (_fee > 0) {
            (_mathErr, _amountLeft) = subUInt(_price, _fee);
            require(_mathErr == MathError.NO_ERROR, "Invalid protocol fee");
            paymentToken._addReserves.value(_fee)();
        }

        /* calculate and pay broker's fee (if any) by minting corresponding paymentToken amount */
        _feeShare = Exp({mantissa: _brokerFeeMantissa});
        (_mathErr, _fee) = mulScalarTruncate(_feeShare, _price);
        require(_mathErr == MathError.NO_ERROR, "Invalid broker fee");
        if (_fee > 0) {
            require(_broker != address(0), "Invalid broker address");
            (_mathErr, _amountLeft) = subUInt(_amountLeft, _fee);
            require(_mathErr == MathError.NO_ERROR, "Invalid broker fee");
            brokerTokens = payOut(_broker, _fee);
        }

        /* 
         * Pay anything left to the old owner by minting a corresponding paymentToken amount. In case 
         * of liquidation these paymentTokens can be liquidated in a next step. 
         * NEVER pay underlying cash to the old owner here!!
         */
        if (_amountLeft > 0) {
            oldOwnerTokens = payOut(_oldOwner, _amountLeft);
        }
    }
    
    function cancelOfferInternal(
        uint240 _mToken,
        address _offeror
    )
        internal
        returns (uint256 _oldOffer)
    {
        _oldOffer = biddings[_mToken].offers[_offeror];
        require (_oldOffer > 0, "No active offer found");
        uint256 _thisIndex = biddings[_mToken].offerIndex[_offeror];
        uint256 _nextIndex = biddings[_mToken].nextOffer;
        assert (_nextIndex > 0);
        _nextIndex--;
        if (_thisIndex != _nextIndex) {
            address _swappedOfferor = biddings[_mToken].maxOfferor[0][_nextIndex];
            biddings[_mToken].offerIndex[_swappedOfferor] = _thisIndex;
            uint256 _newOffer = biddings[_mToken].offers[_swappedOfferor];
            _updateOffer(_mToken, _thisIndex, _swappedOfferor, _newOffer);
        }
        _updateOffer(_mToken, _nextIndex, address(0), 0);
        delete biddings[_mToken].offers[_offeror];
        delete biddings[_mToken].offerIndex[_offeror];
        biddings[_mToken].nextOffer = _nextIndex;
        return _oldOffer;
    }
    
    /**
        @notice Withdraws any funds the contract has collected for the msg.sender from refunds
                and proceeds of sales or auctions.
    */
    function withdrawAuctionRefund() 
        public
        nonReentrant 
    {
        require(refunds[msg.sender] > 0, "No outstanding refunds found");
        uint256 _refundAmount = refunds[msg.sender];
        refunds[msg.sender] = 0;
        msg.sender.transfer(_refundAmount);
        emit AuctionRefund(msg.sender, _refundAmount);
    }

    /**
        @notice Convenience function to cancel and withdraw in one call
    */
    function cancelOfferAndWithdrawRefund(
        uint240 _mToken
    )
        external
    {
        cancelOffer(_mToken);
        withdrawAuctionRefund();
    }

    uint256 constant private clusterSize = (2**4);

    function _updateOffer(
        uint240 _mToken,
        uint256 _offerIndex,
        address _newOfferor,
        uint256 _newOffer
    )
        internal
    {
        assert (biddings[_mToken].nextOffer > 0);
        assert (biddings[_mToken].offers[address(0)] == 0);
        uint256 _n = 0;
        address _origOfferor = _newOfferor;
        uint256 _origOffer = biddings[_mToken].offers[_newOfferor];
        if (_newOffer != _origOffer) {
            biddings[_mToken].offers[_newOfferor] = _newOffer;
        }
        
        for (uint256 tmp = biddings[_mToken].nextOffer * clusterSize; tmp > 0; tmp = tmp / clusterSize) {

            uint256 _oldOffer;
            address _oldOfferor = biddings[_mToken].maxOfferor[_n][_offerIndex];
            if (_oldOfferor != _newOfferor) {
                biddings[_mToken].maxOfferor[_n][_offerIndex] = _newOfferor;
            }

            _offerIndex = _offerIndex / clusterSize;
            address _maxOfferor = biddings[_mToken].maxOfferor[_n + 1][_offerIndex];
            if (tmp < clusterSize) {
                if (_maxOfferor != address(0)) {
                    biddings[_mToken].maxOfferor[_n + 1][_offerIndex] = address(0);
                }
                return;
            }
            
            if (_maxOfferor != address(0)) {
                if (_oldOfferor == _origOfferor) {
                    _oldOffer = _origOffer;
                }
                else {
                    _oldOffer = biddings[_mToken].offers[_oldOfferor];
                }
                
                if ((_oldOfferor != _maxOfferor) && (_newOffer <= _oldOffer)) {
                    return;
                }
                if ((_oldOfferor == _maxOfferor) && (_newOffer > _oldOffer)) {
                    _n++;
                    continue;
                }
            }
            uint256 _i = _offerIndex * clusterSize;
            _newOfferor = biddings[_mToken].maxOfferor[_n][_i];
            _newOffer = biddings[_mToken].offers[_newOfferor];
            _i++;
            while ((_i % clusterSize) != 0) {
                address _tmpOfferor = biddings[_mToken].maxOfferor[_n][_i];
                if (biddings[_mToken].offers[_tmpOfferor] > _newOffer) {
                    _newOfferor = _tmpOfferor;
                    _newOffer = biddings[_mToken].offers[_tmpOfferor];
                }
                _i++;
            } 
            _n++;
        }
    }

    /**
        @notice Returns the maximum offer currently active for the given _mToken. If the current maximum
        offer for the collection (= offer for the anchorToken) is higher, then this collection offer value 
        is returned.
    */
    function getMaxOffer(
        uint240 _mToken
    )
        public
        view
        returns (uint256)
    {
        uint256 _maxCollectionOffer = 0;
        ( , , address _tokenAddress) = mtroller.parseToken(_mToken);
        uint240 _anchorToken = mtroller.getAnchorToken(_tokenAddress);
        if (_mToken != _anchorToken && biddings[_anchorToken].nextOffer != 0) {
            _maxCollectionOffer = biddings[_anchorToken].offers[getMaxOfferor(_anchorToken)];
        }
        if (biddings[_mToken].nextOffer == 0) {
            return _maxCollectionOffer;
        }
        uint256 _maxSpecificOffer = biddings[_mToken].offers[getMaxOfferor(_mToken)];
        return (_maxCollectionOffer > _maxSpecificOffer ? _maxCollectionOffer : _maxSpecificOffer);
    }

    /**
        @notice Returns the current highest bidder for the given _mToken. Active offers for the collection
        are NOT implicitly searched (they can be queried explicitly by setting mToken = anchorToken).
        Reverts if no active offer found for the given mToken.
    */
    function getMaxOfferor(
        uint240 _mToken
    )
        public
        view
        returns (address)
    {
        uint256 _n = 0;
        for (uint256 tmp = biddings[_mToken].nextOffer * clusterSize; tmp > 0; tmp = tmp / clusterSize) {
            _n++;
        }
        require (_n > 0, "No valid offer found");
        _n--;
        return biddings[_mToken].maxOfferor[_n][0];
    }

    function getMaxOfferor(
        uint240 _mToken, 
        uint256 _level, 
        uint256 _offset
    )
        public
        view
        returns (address[10] memory _offerors)
    {
        for (uint256 _i = 0; _i < 10; _i++) {
            _offerors[_i] = biddings[_mToken].maxOfferor[_level][_offset + _i];
        }
        return _offerors;
    }

    function getOffer(
        uint240 _mToken,
        address _account
    )
        public
        view
        returns (uint256)
    {
        return biddings[_mToken].offers[_account];
    }

    function getOfferIndex(
        uint240 _mToken
    )
        public
        view
        returns (uint256)
    {
        require (biddings[_mToken].offers[msg.sender] > 0, "No active offer");
        return biddings[_mToken].offerIndex[msg.sender];
    }

    function getCurrentOfferCount(
        uint240 _mToken
    )
        external
        view
        returns (uint256)
    {
        return(biddings[_mToken].nextOffer);
    }

    function getOfferAtIndex(
        uint240 _mToken,
        uint256 _offerIndex
    )
        external
        view
        returns (address offeror, uint256 offer)
    {
        require(biddings[_mToken].nextOffer > 0, "No valid offer");
        require(_offerIndex < biddings[_mToken].nextOffer, "Offer index out of range");
        offeror = biddings[_mToken].maxOfferor[0][_offerIndex];
        offer = biddings[_mToken].offers[offeror];
    }

    /**
     * @notice Handle the receipt of an NFT, see Open Zeppelin's IERC721Receiver.
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public view returns (bytes4) {
        /* unused parameters */
        from;
        tokenId;
        data;

        /* Reject any token where operator was not this contract or an MERC721 contract */
        if (operator == address(this)) {
            return this.onERC721Received.selector;
        }
        else if (MERC721Interface(operator).getTokenType() == MTokenIdentifier.MTokenType.ERC721_MTOKEN) {
            return this.onERC721Received.selector;
        }
        else {
            revert("Cannot accept token");
        }
    }

    /**
        @notice MTroller admin may collect any ERC-721 token that have been transferred to this contract 
                inadvertently (otherwise they would be locked forever).
        @dev Reverts upon any failure.        
        @param _tokenContract The contract address of the "lost" token.
        @param _tokenID The ID of the "lost" token.
    */
    function _sweepERC721(address _tokenContract, uint256 _tokenID) external nonReentrant {
        require(msg.sender == mtroller.getAdmin(), "Only mtroller admin can do that");
        IERC721(_tokenContract).safeTransferFrom(address(this), msg.sender, _tokenID);
    }

    /**
     * @dev Block reentrancy (directly or indirectly)
     */
    modifier nonReentrant() {
        require(_notEntered, "Reentrance not allowed");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }


// ************************************************************
//  Test functions only below this point, remove in production!

    // function addOfferETH_Test(
    //     uint240 _mToken,
    //     address _sender,
    //     uint256 _amount
    // )
    //     public
    //     nonReentrant
    // {
    //     require (_amount > 0, "No payment sent");
    //     uint256 _oldOffer = biddings[_mToken].offers[_sender];
    //     uint256 _newOffer = _oldOffer + _amount;
    //     if (_oldOffer == 0) {
    //         uint256 _nextIndex = biddings[_mToken].nextOffer;
    //         biddings[_mToken].offerIndex[_sender] = _nextIndex;
    //         biddings[_mToken].nextOffer = _nextIndex + 1;
    //     }
    //     _updateOffer(_mToken, biddings[_mToken].offerIndex[_sender], _sender, _newOffer);
    //     emit NewAuctionOffer(_mToken, _sender, _newOffer);
    // }

    // function cancelOfferETH_Test(
    //     uint240 _mToken,
    //     address _sender
    // )
    //     public
    //     nonReentrant
    // {
    //     uint256 _oldOffer = biddings[_mToken].offers[_sender];
    //     require (_oldOffer > 0, "No active offer found");
    //     uint256 _thisIndex = biddings[_mToken].offerIndex[_sender];
    //     uint256 _nextIndex = biddings[_mToken].nextOffer;
    //     assert (_nextIndex > 0);
    //     _nextIndex--;
    //     if (_thisIndex != _nextIndex) {
    //         address _swappedOfferor = biddings[_mToken].maxOfferor[0][_nextIndex];
    //         biddings[_mToken].offerIndex[_swappedOfferor] = _thisIndex;
    //         uint256 _newOffer = biddings[_mToken].offers[_swappedOfferor];
    //         _updateOffer(_mToken, _thisIndex, _swappedOfferor, _newOffer);
    //     }
    //     _updateOffer(_mToken, _nextIndex, address(0), 0);
    //     delete biddings[_mToken].offers[_sender];
    //     delete biddings[_mToken].offerIndex[_sender];
    //     biddings[_mToken].nextOffer = _nextIndex;
    //     refunds[_sender] += _oldOffer;
    //     emit AuctionOfferCancelled(_mToken, _sender, _oldOffer);
    // }

    // function testBidding(
    //     uint256 _start,
    //     uint256 _cnt
    // )
    //     public
    // {
    //     for (uint256 _i = _start; _i < (_start + _cnt); _i++) {
    //         addOfferETH_Test(1, address(uint160(_i)), _i);
    //     }
    // }

}