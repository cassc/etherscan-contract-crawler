// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./EverlensAccessControl.sol";
import "./EverlensERC721.sol";
import "../interface/IBEP20.sol";

contract EverlensMarketPlace is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    EverlensAccessControl,
    IERC721ReceiverUpgradeable
{
    using Counters for Counters.Counter;
    Counters.Counter private _orderIds;

    //EIP-2981 InterfaceId
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    struct AuctionOrder {
        uint256 tokenId;
        //AuctionType: 1 = FixedPriceAuction,2 = UnlimitedAuction
        uint256 auctionType;
        address seller;
        uint256 price;
        uint256 endTime;
    }

    struct BidDetails {
        //Bid amount includes fees
        uint256 bidAmount;
        address bidderAddr;
    }

    struct RoyaltyDetails {
        uint256 royaltyPercentage;
        address creator;
    }

    //orderId -> AuctionOrder
    mapping(uint256 => AuctionOrder) public auctionOrders;

    //orderId -> BidDetails
    mapping(uint256 => BidDetails) public tokenBids;

    address public feeAddress;
    ///@dev FeesPercent has two decimal points
    uint256 public feePercent;

    //10 Elen Token for listing on marketplace
    uint256 public marketplaceListingFees;

    EverlensERC721 tokenContract;
    IBEP20 elenTokenContract;

    event LogOrderCreated(
        uint256 orderId,
        uint256 tokenId,
        uint256 auctionType,
        address seller,
        uint256 price
    );
    event LogOrderFinalised(
        uint256 orderId,
        uint256 tokenId,
        uint256 auctionType,
        address buyer
    );

    event LogNewBidCreated(
        uint256 orderId,
        uint256 tokenId,
        uint256 newPrice,
        address newBidder
    );
    event LogAuctionCancelled(uint256 orderId, uint256 auctionType);
    event LogFeeAddressUpdated(address newAddress, address senderAddress);
    event RoyaltiesPaid(uint256 tokenId, uint256 value);
    event LogMarketplaceListingFeeUpdated(
        uint256 newFees,
        address senderAddress
    );

    modifier OnlySeller(uint256 _orderId) {
        require(
            auctionOrders[_orderId].seller == _msgSender(),
            "Sender is not the seller of NFT"
        );
        _;
    }

    modifier isValidOrderId(uint256 orderId) {
        require(orderId != 0, "OrderId cannot be zero");
        require(
            orderId <= _orderIds.current(),
            "OrderId should be less than current order Id"
        );
        _;
    }

    function initialize(
        address _tokenAddress,
        address _elenTokenAddress,
        address _feeAddress,
        address[] memory _whitelistAddresses,
        uint256 _feePercent,
        uint256 _marketplaceListingFees
    ) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __EverlensAccessControl_init(_whitelistAddresses);

        feeAddress = _feeAddress;
        feePercent = _feePercent;
        marketplaceListingFees = _marketplaceListingFees;
        tokenContract = EverlensERC721(_tokenAddress);
        elenTokenContract = IBEP20(_elenTokenAddress);
    }

    /// @notice Transfers royalties to the rightsowner if applicable
    /// @param tokenId - the NFT assed queried for royalties
    /// @param grossSaleValue - the price at which the asset will be sold
    /// @return netSaleAmount - the value that will go to the seller after
    ///         deducting royalties
    function _deduceRoyalties(uint256 tokenId, uint256 grossSaleValue)
        internal
        returns (uint256 netSaleAmount)
    {
        // Get amount of royalties to pays and recipient
        (address royaltiesReceiver, uint256 royaltiesAmount) = tokenContract
            .royaltyInfo(tokenId, grossSaleValue);
        // Deduce royalties from sale value
        uint256 netSaleValue = grossSaleValue - royaltiesAmount;
        // Transfer royalties to rightholder if not zero
        if (royaltiesAmount > 0) {
            elenTokenContract.transferFrom(
                _msgSender(),
                royaltiesReceiver,
                royaltiesAmount
            );
        }
        // Broadcast royalties payment
        emit RoyaltiesPaid(tokenId, royaltiesAmount);
        return netSaleValue;
    }

    /// @notice Checks if NFT contract implements the ERC-2981 interface
    /// @param _contract - the address of the NFT contract to query
    /// @return true if ERC-2981 interface is supported, false otherwise
    function _checkRoyalties(address _contract) internal view returns (bool) {
        bool success = IERC2981(_contract).supportsInterface(
            _INTERFACE_ID_ERC2981
        );
        return success;
    }

    function createFixedPriceAuction(uint256 tokenId, uint256 price)
        external
        nonReentrant
        whenNotPaused
    {
        require(tokenContract.exists(tokenId), "TokenId does not exist");
        tokenContract.safeTransferFrom(_msgSender(), address(this), tokenId);

        _orderIds.increment();

        //Fees for listing on Marketplace
        elenTokenContract.transferFrom(
            _msgSender(),
            feeAddress,
            marketplaceListingFees
        );

        auctionOrders[_orderIds.current()] = AuctionOrder({
            tokenId: tokenId,
            auctionType: 1,
            seller: _msgSender(),
            price: price,
            endTime: 0
        });

        emit LogOrderCreated(
            _orderIds.current(),
            tokenId,
            1,
            _msgSender(),
            price
        );
    }

    function finaliseFixedPriceAuction(uint256 orderId, uint256 bidAmount)
        external
        nonReentrant
        whenNotPaused
        isValidOrderId(orderId)
    {
        AuctionOrder memory currAuctionOrder = auctionOrders[orderId];
        require(
            currAuctionOrder.auctionType == 1,
            "Auction should be fixedAuction type"
        );
        uint256 currFees = ((currAuctionOrder.price) * (feePercent)) / (10000);
        require(
            bidAmount >= currFees + currAuctionOrder.price,
            "Value transferred not enugh for buying"
        );
        delete auctionOrders[orderId];

        uint256 netSalePrice = _deduceRoyalties(
            currAuctionOrder.tokenId,
            currAuctionOrder.price
        );

        //Transfer Fees to the feeAddress
        elenTokenContract.transferFrom(_msgSender(), feeAddress, currFees);

        //Transfer amount to seller after deducting loyalties
        elenTokenContract.transferFrom(
            _msgSender(),
            currAuctionOrder.seller,
            netSalePrice
        );
        tokenContract.safeTransferFrom(
            address(this),
            _msgSender(),
            currAuctionOrder.tokenId
        );
        emit LogOrderFinalised(
            orderId,
            currAuctionOrder.tokenId,
            1,
            _msgSender()
        );
    }

    function createUnlimitedAuction(
        uint256 tokenId,
        uint256 minAuctionPrice,
        uint256 endTime
    ) external nonReentrant whenNotPaused {
        require(tokenContract.exists(tokenId), "TokenId does not exist");
        require(
            endTime > block.timestamp,
            "Auction End time should be greater than current time"
        );

        tokenContract.safeTransferFrom(_msgSender(), address(this), tokenId);

        _orderIds.increment();

        auctionOrders[_orderIds.current()] = AuctionOrder({
            tokenId: tokenId,
            auctionType: 2,
            seller: _msgSender(),
            price: minAuctionPrice,
            endTime: endTime
        });

        //Fees for listing on Marketplace
        elenTokenContract.transferFrom(
            _msgSender(),
            feeAddress,
            marketplaceListingFees
        );

        emit LogOrderCreated(
            _orderIds.current(),
            tokenId,
            2,
            _msgSender(),
            minAuctionPrice
        );
    }

    function bidOnUnlimitedAuction(uint256 orderId, uint256 bidPrice)
        external
        nonReentrant
        whenNotPaused
        isValidOrderId(orderId)
    {
        AuctionOrder memory currAuctionOrder = auctionOrders[orderId];
        BidDetails memory currBidDetails = tokenBids[orderId];
        require(
            currAuctionOrder.auctionType == 2,
            "Auction should be Unlimited type"
        );
        require(
            currAuctionOrder.endTime >= block.timestamp,
            "Auction has ended"
        );
        require(
            currAuctionOrder.price <= bidPrice,
            "Current Bid price is less than min bid price"
        );

        if (
            currBidDetails.bidderAddr != address(0) &&
            currBidDetails.bidAmount > 0
        ) {
            //Return to the last highest bidder
            elenTokenContract.transfer(
                currBidDetails.bidderAddr,
                currBidDetails.bidAmount
            );
        }
        //Transfer new bid Price to the token
        elenTokenContract.transferFrom(_msgSender(), address(this), bidPrice);

        //Update Minimum Bid value to the latest bid.
        currAuctionOrder.price = bidPrice;
        //Update current Bid Details
        tokenBids[orderId] = BidDetails({
            bidAmount: bidPrice,
            bidderAddr: _msgSender()
        });

        emit LogNewBidCreated({
            orderId: orderId,
            tokenId: currAuctionOrder.tokenId,
            newPrice: bidPrice,
            newBidder: _msgSender()
        });
    }

    function finaliseUnlimitedAuction(uint256 orderId)
        external
        nonReentrant
        whenNotPaused
        isValidOrderId(orderId)
        OnlySeller(orderId)
    {
        AuctionOrder memory currAuctionOrder = auctionOrders[orderId];
        BidDetails memory currBidDetails = tokenBids[orderId];

        require(
            currAuctionOrder.auctionType == 2,
            "Auction should be Unlimited type"
        );
        require(
            currAuctionOrder.endTime <= block.timestamp,
            "Cannot end Auction before end time"
        );
        delete auctionOrders[orderId];
        delete tokenBids[orderId];

        uint256 feeAmt = (currBidDetails.bidAmount * feePercent) /
            (10000 + feePercent);
        uint256 netBidAmount = currBidDetails.bidAmount - feeAmt;

        uint256 netSalePrice = _deduceRoyalties(
            currAuctionOrder.tokenId,
            netBidAmount
        );

        //Transfer Fees to the feeAddress
        elenTokenContract.transfer(feeAddress, feeAmt);

        //Transfer amount to seller after deducting loyalties
        elenTokenContract.transfer(currAuctionOrder.seller, netSalePrice);

        //Transfer NFT to the bidder
        tokenContract.safeTransferFrom(
            address(this),
            currBidDetails.bidderAddr,
            currAuctionOrder.tokenId
        );

        emit LogOrderFinalised(
            orderId,
            currAuctionOrder.tokenId,
            2,
            currBidDetails.bidderAddr
        );
    }

    function _cancelAuction(uint256 orderId) internal nonReentrant {
        AuctionOrder memory currAuctionOrder = auctionOrders[orderId];
        require(
            currAuctionOrder.seller != address(0) &&
                currAuctionOrder.tokenId != 0,
            "Auction does not exist"
        );
        //Transfer NFT to the user
        tokenContract.safeTransferFrom(
            address(this),
            currAuctionOrder.seller,
            currAuctionOrder.tokenId
        );
        //FixedPrice Auction cancel
        if (currAuctionOrder.auctionType == 1) {
            delete auctionOrders[orderId];
        }
        //Unlimited Auction cancel
        else {
            BidDetails memory currBidDetails = tokenBids[orderId];
            delete auctionOrders[orderId];
            delete tokenBids[orderId];

            if (currBidDetails.bidderAddr != address(0)) {
                //Transfer amount to bidder if Auction is cancelled
                elenTokenContract.transfer(
                    currBidDetails.bidderAddr,
                    currBidDetails.bidAmount
                );
            }
        }
        emit LogAuctionCancelled(orderId, currAuctionOrder.auctionType);
    }

    function cancelAuction(uint256 orderId)
        public
        nonReentrant
        whenNotPaused
        OnlySeller(orderId)
    {
        _cancelAuction(orderId);
    }

    function cancelAllAuctions() external OnlyAdmin {
        for (uint256 i = 0; i <= _orderIds.current(); i++) {
            if (auctionOrders[i].seller != address(0)) {
                _cancelAuction(i);
            }
        }
    }

    function updateFeeAddress(address _newFeeAddress) public OnlyAdmin {
        feeAddress = _newFeeAddress;
        emit LogFeeAddressUpdated(feeAddress, _msgSender());
    }

    function updateMarketplaceListingFees(uint256 _marketplaceListingFees)
        public
        OnlyAdmin
    {
        marketplaceListingFees = _marketplaceListingFees;
        emit LogMarketplaceListingFeeUpdated(
            _marketplaceListingFees,
            _msgSender()
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}