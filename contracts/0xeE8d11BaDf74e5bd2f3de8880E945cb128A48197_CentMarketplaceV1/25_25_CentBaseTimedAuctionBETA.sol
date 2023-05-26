///SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./CentBaseStorageBETA.sol";
import "./CentBaseMarketPlaceBETA.sol";

contract CentBaseTimedAuctionBETA is CentBaseStorageBETA {
    uint256 internal _currentAuctionId;
    uint256 internal _currentAuctionsSold;

    receive() external payable {
        revert ErrorMessage("Not payable receive");
    }

    /// @notice Creates a new Auction from a given market item.
    /// @param itemId The Id of the MarketItem to list for auction.
    /// @param biddingTime The timespan in seconds to collect bids for this auction.
    /// @param minimumBid The minimum bid amount for this auction.
    /// @dev Restricted to only owner account.
    /// @dev Restricted by modifiers { isAuthorized, isNotActive }.
    function createMarketAuction(
        bytes32 itemId,
        uint256 biddingTime,
        uint256 minimumBid
    )
        external
        isAuthorized(itemId)
        isNotActive(itemId)
    {
        if (itemId == 0x0 || biddingTime == 0 || minimumBid == 0) {
            revert NoZeroValues();
        }

        bytes32 _auctionId = bytes32(_currentAuctionId += 1);
        bytes32 _itemId = itemId;
        uint256 _auctionEndTime = block.timestamp + biddingTime;
        uint256 _minBid = minimumBid;

        MarketAuction storage _a = auctionsMapping[_auctionId];
        _a.auctionId = _auctionId;
        _a.itemId = _itemId;
        _a.auctionEndTime= _auctionEndTime;
        _a.highestBid = _minBid;
        _a.highestBidder;
        _a.ended = false;

        itemsMapping[_itemId].status = Status(2);
        itemsMapping[_itemId].active = true;

        emit MarketAuctionCreated(
            _auctionId,
            _itemId,
            itemsMapping[_itemId].tokenOwner
        );
    }

    /// @notice Executes a new bid on a auctionId.
    /// @param two Requires a bool false.
    /// @param auctionId The auctionId to bid on.
    /// @dev Restricted by modifiers { costs, isLiveAuction, minBid }.
    function bid(bool two, bytes32 auctionId)
        public
        payable
        costs(two, auctionId)
        isLiveAuction(auctionId)
        minBid(auctionId)
    {
        MarketAuction storage _a = auctionsMapping[auctionId];
        uint256 _bid = msg.value;
        address payable _bidder = payable(_msgSender());

        if (_msgSender() == _a.highestBidder) revert ErrorMessage("Already highest bidder!");
        if (two != false) revert ErrorMessage("Requires uint value: 2");

        if (_a.highestBidder != address(0)) {
            pendingReturns[_a.highestBidder] += _a.highestBid;
            _sendPaymentToEscrow(payable(_a.highestBidder), _a.highestBid);
        }

        _a.highestBid = _bid;
        _a.highestBidder = _bidder;

        emit HighestBidIncrease(_a.auctionId, _a.highestBidder, _a.highestBid);
    }

    /// @notice For users who lost an auction.This will allow them to withdraw their pending returns from the escrow. 
    /// @dev This method will withdraw all the users funds from the escrow contract.
    /// @return success if transaction is completed succewssfully.
    function withdrawPendingReturns() external returns (bool success) {
        if (pendingReturns[_msgSender()] == 0)
            revert ErrorMessage("No pending Returns!");

        uint256 _amount = pendingReturns[_msgSender()];

        if (_amount > 0) {
            pendingReturns[_msgSender()] = 0;

            withdrawSellerRevenue(payable(_msgSender()));
            emit WithdrawPendingReturns(_msgSender(), _amount);
        }
        return true;
    }



    /// @notice Method used to fetch all current live timed auctions on the marketplace.
    /// @return MarketAuction Returns an bytes32 array of all the current active auctions.
    function fetchMarketAuctions()
        external
        view
        returns (MarketAuction[] memory)
    {
        uint256 auctionCount = _currentAuctionId;
        uint256 unsoldAuctionCount = _currentAuctionId - _currentAuctionsSold;
        uint256 currentIndex = 0;

        MarketAuction[] memory _auctions = new MarketAuction[](
            unsoldAuctionCount
        );
        for (uint256 i = 0; i < auctionCount; i++) {
            bytes32 currentId = bytes32(i + 1);
            MarketAuction memory currentAuction = auctionsMapping[currentId];
            _auctions[currentIndex] = currentAuction;
            currentIndex += 1;
        }
        return _auctions;
    }

    /// @notice Public method to finalise an auction.
    /// @param auctionId The auctionId to claim.
    /// @dev The winner of an auction is able to end the auction they won, by claiming the auction,
    ///      the winner will receive their nft and the payment is transfered to the escrow contract. 
    /// @return bool Returns true is auction has a highest bidder, returns false if the auction had no bids. 
    function claimAuction(bytes32 auctionId) public isLiveAuction(auctionId) returns (bool) {
        MarketAuction storage _a = auctionsMapping[auctionId];
        MarketItem storage _item = itemsMapping[_a.itemId];

        if (block.timestamp < _a.auctionEndTime) revert ErrorMessage("To soon!");
        if (_a.ended) revert NotActive(_a.auctionId);

        _a.ended = true;
        _item.status = Status(0);
        _item.active = false;
        
        if (_a.highestBidder == address(0)) {
            _removeAuction(_a.auctionId);
            emit NoBuyer(_a.auctionId, _item.itemId);
            
            return false;
        }
        
        _currentAuctionsSold += 1;

        ( , uint _toSellerAmount, uint _totalFeeAmount) = _calculateFees(_a.highestBid);

        (bool success) = IERC165(_item.nftContract).supportsInterface(_INTERFACE_ID_ERC2981);
        
        if (!success) {
            if (!payable(serviceWallet).send(_totalFeeAmount)) {
                revert FailedTransaction("Fees");
            }

            _sendPaymentToEscrow(_item.tokenOwner, _toSellerAmount);       
            _sendAsset(_item.itemId, _a.highestBidder);

            emit TransferServiceFee(serviceWallet, _totalFeeAmount);
        
        } else {
            _transferRoyaltiesAndServiceFee(_item, _totalFeeAmount, _toSellerAmount);

            _sendAsset(_item.itemId, _a.highestBidder);
        }

        emit AuctionClaimed(_a.auctionId, _a.itemId, _a.highestBidder, _a.highestBid);
        
        _removeAuction(_a.auctionId);
        
        return true;
    }

    /// @notice Method to get an marketAuction.
    /// @param auctionId The bytes32 auctionId to query.
    /// @return marketAuction Returns the MarketAuction.
    function getMarketAuction(bytes32 auctionId)
        external
        view
        onlyRole(ADMIN_ROLE)
        returns (MarketAuction memory marketAuction)
    {
        MarketAuction memory a = auctionsMapping[auctionId];
        return a;
    }

   
    /// @notice Private method to remove a auction from the auctionsMapping.
    /// @param auctionId The auctionId to remove.
    function _removeAuction(bytes32 auctionId) private {
        MarketAuction memory _a = auctionsMapping[auctionId];
        if (_a.ended) {

            emit AuctionRemoved(
                _a.auctionId,
                _a.itemId,
                _a.highestBidder,
                _a.highestBid,
                block.timestamp
            );

            delete (auctionsMapping[auctionId]);
        }
    }
}