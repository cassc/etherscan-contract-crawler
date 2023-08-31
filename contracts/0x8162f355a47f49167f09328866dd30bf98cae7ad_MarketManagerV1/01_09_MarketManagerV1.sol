// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ERC721/IIOGINALITY.sol";
import "./utils/Manageable.sol";

contract MarketManagerV1 is Ownable, Manageable, ReentrancyGuard {

    mapping (uint256 => Listing) private listings;

    IIOGINALITY private nftToken;

    string private _name;

    bool private isActive = true;

    uint32 private defaultBidIncreasePercentage;
    uint32 private marketplaceFee;

    uint256 private marketplaceIncome = 0;

    mapping (address => uint256) private debts;

    enum ListingType {
        None,
        FixedPrice,
        Auction
        // ReversAuction
    }

    /* 
        Royalties struct is used to store royalties for NFT token
        There is some method to define royalties for secindary sales
        1. Royalties can be set by seller when he creates fixed price listing
        2. Royalties can be set by seller when he creates auction listing

        Royalties can be set only once for each sale
    */
    struct Royalties {
        address[] recipients;
        uint32[] amounts;
        uint32 total;
    }

    struct RoyaltiesInput {
        address[] recipients;
        uint32[] amounts;
    }

    /*
        contract supports only native blockchain currency
    */
    struct Listing {
        ListingType listingType;
        uint256 tokenId;
        address sellerManager;
        address seller;
        uint128 price; // for ListingType.Auction the same as buyNowPrice
        uint64 end; // time of listing ending
        address whitelistBuyer; // seller can create listing only for specific buyer address
        uint128 startPrice; // start price for Auction and ReverseAuction
        uint128 reservePrice; // minimum price for Auction must finish successful
        uint128 highestBid;
        address highestBidder;
        uint32 bidStep; // for ListingType.Auction value to increase for ListingType.ReverseAuction value to decrease
        Royalties royalties;
    }

    /**
     * EVENTS START
     */

    event FixedPriceListingCreated(
        uint256 tokenId,
        address seller,
        uint128 price,
        uint64 end,
        address whitelistBuyer
    );

    event AuctionListingCreated(
        uint256 tokenId,
        address seller,
        uint128 startPrice,
        uint128 reservePrice,
        uint128 buyNowPrice,
        uint64 end,
        address whitelistBuyer
    );

    event BidMade(
        uint256 tokenId,
        address bidder,
        uint128 amount,
        uint256 timestamp
    );

    event ListingCancelled(
        uint256 tokenId,
        uint256 timestamp
    );

    event ListingFinished(
        uint256 tokenId,
        uint256 timestamp
    );

    event ListingSold(
        uint256 tokenId,
        uint128 price,
        address buyer,
        ListingType type_,
        uint256 timestamp
    );

    event MarketplaceFeeChanged(
        uint32 marketplaceFee,
        uint256 timestamp
    );

    event ContractStarted(uint256 timestamp);
    event ContractStoppped(uint256 timestamp);

    event MarketplaceFeeReceived(
        uint256 tokenId,
        uint128 amount,
        uint256 timestamp
    );

    event SetRoyalty(
        uint256 tokenId,
        address seller,
        uint128 amount
    );

    event RoyaltiesPaid(
        uint256 tokenId,
        address reciever,
        uint128 amount
    );

    event SellerPaid(
        uint256 tokenId,
        address seller,
        uint128 amount,
        uint256 timestamp
    );

    /**
     * EVENTS END
     */

    /**
     * MODIFIERS START
     */

    modifier contractIsActive() {
        require(isActive, 'Contract is stopped now');
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(nftToken.ownerOf(tokenId) != address(0), 'Token is not exists');
        _;
    }

    modifier canManageToken(uint256 tokenId) {
        if(! _canManagerToken(tokenId)) {
            nftToken.approve(address(this), tokenId);
        }

        // require(_canManagerToken(tokenId), 'Contract can not manage NFT token');
        _;
    }

    modifier listingExists(uint256 tokenId) {
        require(listings[tokenId].tokenId > 0, 'Listing does not exist');
        _;
    }

    modifier listingIsOngoing(uint256 tokenId) {
        require(listings[tokenId].tokenId > 0, 'Listing is not exists');
        require(listings[tokenId].end > block.timestamp, 'Token selling time is over');
        _;
    }

    modifier tokenIsNotSelling(uint256 tokenId) {
        require(listings[tokenId].tokenId < 1, 'There is already the listing is selling the same token');
        _;
    }

    modifier isAuction(uint256 tokenId) {
        require(listings[tokenId].listingType == ListingType.Auction, 'Listing is not the auction type');
        _;
    }

    modifier isFixedPrice(uint256 tokenId) {
        require(listings[tokenId].listingType == ListingType.FixedPrice, 'Listing is not the fixed price type');
        _;
    }

    modifier isPaymentAcceptable(uint256 tokenId) {
        require(msg.sender != address(0), 'sender must not be an empty address');
        require(msg.sender != listings[tokenId].seller, 'sender must not be a seller');
        require(msg.value == listings[tokenId].price, 'sent money is insufficient');

        _;
    }

    modifier isBidAcceptable(uint256 tokenId) {
        require(msg.sender != address(0), 'sender must not be an empty address');
        require(msg.sender != listings[tokenId].seller, 'sender must not be a seller');

        if(listings[tokenId].whitelistBuyer != address(0)) {
            require(listings[tokenId].whitelistBuyer == msg.sender, 'Auction accepts bid only from whitelist buyer');
        }

        /* check it's a bid(not a buy now)  */
        if(! (listings[tokenId].price > 0 && listings[tokenId].price == msg.value))
        {
            if(listings[tokenId].highestBid > 0) {
                require(msg.value > listings[tokenId].highestBid, 'The bet must be greater than the last bet');

                uint128 requiredNextBid = listings[tokenId].highestBid + ((listings[tokenId].highestBid * _getBidIncreaseIndex(tokenId)) / 10000);
                require(msg.value >= requiredNextBid, 'Bid insufficient');
                
            }
            else if(listings[tokenId].startPrice > 0) {
                require(msg.value >= listings[tokenId].startPrice, 'Bid insufficient');
            }
            else {
                require(msg.value >= 0, 'Bid insufficient');
            }
        }

        _;
    }

    modifier onlyOwnerOrManagerOrSeller(uint256 tokenId) {
        require(owner() == msg.sender || manager() == msg.sender || listings[tokenId].sellerManager == msg.sender || listings[tokenId].seller == msg.sender, 'Method can call only owner/manager/seller');
        _;
    }

    modifier doesTotalFeesCorrect(uint256 tokenId) {
        (uint32 royalties) = nftToken.getRoyaltiesAmount(tokenId);
        require(royalties + marketplaceFee <= 10000, 'Total fees should not exceed 100%');
        _;
    }

    modifier isRoyaltiesInputCorrect(RoyaltiesInput memory royaltiesInput) {
        require(royaltiesInput.recipients.length == royaltiesInput.amounts.length, 'roylties recipients and amounts number should be equal');
        _;
    }

    /**
     * MODIFIERS END
     */

    /**
     * address _nftTokenContract is the address of ERC721 token contract
     */
    constructor(string memory name_, address _nftToken, uint32 _marketplaceFee, uint32 _defaultBidIncreasePercentage, address manager_) {

        require(_marketplaceFee <= (50 * 100), 'marketplace fee should not exceed 50%');

        _name = name_;
        nftToken = IIOGINALITY(_nftToken);
        marketplaceFee = _marketplaceFee;
        defaultBidIncreasePercentage = _defaultBidIncreasePercentage;

        _transferMangership(manager_);
    }

    function _canManagerToken(uint256 _tokenId)
        private view returns(bool)
    {
        return nftToken.getApproved(_tokenId) == address(this);
    }

    function _getBidIncreaseIndex(uint256 _tokenId)
        private view returns (uint32)
    {
        if(listings[_tokenId].bidStep > 0) {
            return listings[_tokenId].bidStep;
        }

        return defaultBidIncreasePercentage;
    }

    /* check does auction has winner */
    function _hasAuctionWinner(uint256 _tokenId)
        private view returns(bool)
    {
        /* if we have someone who has palced a bet */
        if(listings[_tokenId].highestBidder != address(0) && listings[_tokenId].highestBid > 0) {
            if(listings[_tokenId].reservePrice > 0) {
                if(listings[_tokenId].reservePrice <= listings[_tokenId].highestBid) {
                    return true;
                }
            }
            else {
                return true;
            }
        }

        return false;
    }

    function _getPortionOfAmount(uint128 _amount, uint32 _percentage)
        internal
        pure
        returns (uint128)
    {
        return (_amount * (_percentage)) / 10000;
    }

    function _checkTotalFeesAndGetSecondaryRoyalties(uint256 tokenId, RoyaltiesInput memory royaties)
        internal
        view
        returns (Royalties memory)
    {
        uint32 total;
        for (uint256 i = 0; i < royaties.amounts.length; i++) {
            total += royaties.amounts[i];
        }

        require(total <= 10000, 'Secondary royalties should not exceed 100%');

        (uint32 tokenRoyalties) = nftToken.getRoyaltiesAmount(tokenId);
        require((tokenRoyalties + marketplaceFee + total) <= 10000, 'Total fees should not exceed 100%');

        return Royalties(royaties.recipients, royaties.amounts, total);
    }

    /**
     * Fixed price sale
     */
    function makeFixedPriceListing(uint256 _tokenId, uint128 _price, uint64 _end)
        nonReentrant()
        contractIsActive()
        tokenIsNotSelling(_tokenId)
        tokenExists(_tokenId)
        canManageToken(_tokenId)
        doesTotalFeesCorrect(_tokenId)
        external
    {
        // we can create new sale only when no has another listing with the same tokenId
        _createFixedPriceSale(_tokenId, _price, _end, address(0));

        emit FixedPriceListingCreated(_tokenId, msg.sender, _price, _end, address(0));
    }

    /**
     * Fixed price sale with secondary sale royalties
     */
    function makeFixedPriceListing(uint256 _tokenId, uint128 _price, uint64 _end, RoyaltiesInput memory royaltiesInput)
        nonReentrant()
        contractIsActive()
        tokenIsNotSelling(_tokenId)
        tokenExists(_tokenId)
        canManageToken(_tokenId)
        isRoyaltiesInputCorrect(royaltiesInput)
        external
    {
        Royalties memory royalties = _checkTotalFeesAndGetSecondaryRoyalties(_tokenId, royaltiesInput);
        // we can create new sale only when no has another listing with the same tokenId
        _createFixedPriceSale(_tokenId, _price, _end, address(0));
        listings[_tokenId].royalties = royalties;

        emit FixedPriceListingCreated(_tokenId, msg.sender, _price, _end, address(0));
    }

    /**
     * British auction sale
     */
    function makeBritishAuctionListing(uint256 _tokenId, uint32 _bidStep, uint128 _startPrice, uint128 _reservePrice, uint128 _buyNowPrice, uint64 _end)
        nonReentrant()
        contractIsActive()
        tokenIsNotSelling(_tokenId)
        tokenExists(_tokenId)
        canManageToken(_tokenId)
        doesTotalFeesCorrect(_tokenId)
        external
    {
        _createAuctionSale(_tokenId, _bidStep, _startPrice, _reservePrice, _buyNowPrice, _end, address(0));

        emit AuctionListingCreated(_tokenId, msg.sender, _startPrice, _reservePrice, _buyNowPrice, _end, address(0));
    }

    /**
     * British auction sale with secondary sale royalties
     */
    // function makeBritishAuctionListing(uint256 _tokenId, uint32 aa, uint128 _startPrice, uint128 _reservePrice, uint128 _buyNowPrice, uint64 _end, address[] memory _royaltyRecipients, uint32[] memory _royaltyAmounts)
    function makeBritishAuctionListing(uint256 _tokenId, uint32 _bidStep, uint128 _startPrice, uint128 _reservePrice, uint128 _buyNowPrice, uint64 _end, RoyaltiesInput memory royaltiesInput)
        nonReentrant()
        contractIsActive()
        tokenIsNotSelling(_tokenId)
        tokenExists(_tokenId)
        canManageToken(_tokenId)
        isRoyaltiesInputCorrect(royaltiesInput)
        external
    {
        Royalties memory royalties = _checkTotalFeesAndGetSecondaryRoyalties(_tokenId, royaltiesInput);
        // we can create new sale only when no has another listing with the same tokenId
        _createAuctionSale(_tokenId, _bidStep, _startPrice, _reservePrice, _buyNowPrice, _end, address(0));

        listings[_tokenId].royalties = royalties;

        emit AuctionListingCreated(_tokenId, msg.sender, _startPrice, _reservePrice, _buyNowPrice, _end, address(0));
    }

    function buy(uint256 _tokenId)
        payable external
        nonReentrant()
        contractIsActive()
        listingIsOngoing(_tokenId)
        isPaymentAcceptable(_tokenId)
    {
        uint128 _value = uint128(msg.value);
        _release(_tokenId, msg.sender, _value);

        emit ListingSold(_tokenId, _value, msg.sender, listings[_tokenId].listingType, block.timestamp);
    }

    /**
     * Accept bid of auction only from recepient
     */
    function bid(uint256 _tokenId)
        payable external
        nonReentrant()
        contractIsActive()
        listingIsOngoing(_tokenId)
        isAuction(_tokenId)
        isBidAcceptable(_tokenId)
    {
        _revertHighestBid(_tokenId);

        /* handle buy now price */
        if(listings[_tokenId].price > 0 && listings[_tokenId].price == msg.value) {
            _release(_tokenId, msg.sender, uint128(msg.value));
        }
        else {
            listings[_tokenId].highestBid = uint128(msg.value);
            listings[_tokenId].highestBidder = msg.sender;

            emit BidMade(_tokenId, listings[_tokenId].highestBidder, listings[_tokenId].highestBid, block.timestamp);
        }
    }

    function getPrice(uint256 _tokenId)
        external view
        listingIsOngoing(_tokenId)
        returns (uint128)
    {
        return listings[_tokenId].price;
    }

    function isTokenListed(uint256 _tokenId)
        external view
        returns (bool)
    {
        return listings[_tokenId].tokenId > 0;
    }

    function getBidPrice(uint256 _tokenId)
        external view
        listingIsOngoing(_tokenId)
        isAuction(_tokenId)
        returns (uint128)
    {
        if(listings[_tokenId].highestBid > 0) {
            uint128 minNextBid = listings[_tokenId].highestBid + ((listings[_tokenId].highestBid * _getBidIncreaseIndex(_tokenId)) / 10000);
            return minNextBid;
        }
        else if(listings[_tokenId].startPrice > 0) {
            return listings[_tokenId].startPrice;
        }
        else {
            return uint128(2 gwei);
        }
    }

    function getEndTime(uint256 _tokenId)
        external view
        listingIsOngoing(_tokenId)
        returns (uint64)
    {
        return listings[_tokenId].end;
    }

    function getSecondaryRoyalties(uint256 _tokenId)
        external view
        listingIsOngoing(_tokenId)
        returns (address[] memory, uint32[] memory)
    {
        return (listings[_tokenId].royalties.recipients, listings[_tokenId].royalties.amounts);
    }

    function cancel(uint256 _tokenId)
        external
        nonReentrant()
        contractIsActive()
        listingIsOngoing(_tokenId)
        onlyOwnerOrManagerOrSeller(_tokenId)
    {
        if(listings[_tokenId].listingType == ListingType.Auction) {
            _revertHighestBid(_tokenId);
        }

        _resetListing(_tokenId);

        emit ListingCancelled(_tokenId, block.timestamp);
    }

    function finish(uint256 _tokenId)
        external
        nonReentrant()
        contractIsActive()
        listingExists(_tokenId)
        onlyOwnerOrManagerOrSeller(_tokenId)
    {
        if(listings[_tokenId].listingType == ListingType.Auction && _hasAuctionWinner(_tokenId)) {
            _release(_tokenId, listings[_tokenId].highestBidder, listings[_tokenId].highestBid);

            emit ListingSold(_tokenId, listings[_tokenId].highestBid, listings[_tokenId].highestBidder, ListingType.Auction, uint64(block.timestamp));
        }
        else {
            _resetListing(_tokenId);

            emit ListingFinished(_tokenId, block.timestamp);
        }
    }

    function getMarketplaceFee()
        external view
        returns (uint128)
    {
        return marketplaceFee;
    }

    function setMarketplaceFee(uint32 _marketplaceFee)
        external
        contractIsActive()
        onlyOwner
    {
        require(_marketplaceFee < (51 * 100), 'Max value for marketplace fee 50 pecent');

        if(marketplaceFee != _marketplaceFee) {
            marketplaceFee = _marketplaceFee;

            emit MarketplaceFeeChanged(marketplaceFee, block.timestamp);
        }
    }

    function getIncome()
        external view
        onlyOwner
        returns (uint256)
    {
        return marketplaceIncome;
    }

    function withdrawIncome(address to, uint256 _amount)
        external
        onlyOwner
    {
        if(_amount > 0) {
            require(_amount <= marketplaceIncome, 'Not enough income');
        }
        else {
            _amount = marketplaceIncome;
        }

        require(_amount <= address(this).balance, 'The contract balance is not enaugh');

        (bool sent, ) = payable(to).call{value: _amount}("");

        require(sent, "Failed to send Ether");
    }

    function withdraw()
        nonReentrant()
        external
    {
        if(debts[msg.sender] > 0) {
            uint256 _amount = debts[msg.sender];
            debts[msg.sender] = 0;

            require(_amount <= address(this).balance, 'The contract balance is not enaugh');

            (bool sent, ) = payable(msg.sender).call{value: _amount}("");

            require(sent, "Failed to send Ether");
        }
    }

    function _createFixedPriceSale(uint256 _tokenId, uint128 _price, uint64 _end, address _whitelistBuyer)
        tokenIsNotSelling(_tokenId) private
    {
        listings[_tokenId].listingType = ListingType.FixedPrice;
        listings[_tokenId].tokenId = _tokenId;
        listings[_tokenId].sellerManager = msg.sender;
        listings[_tokenId].seller = nftToken.ownerOf(_tokenId);
        listings[_tokenId].price = _price;
        listings[_tokenId].end = _end;
        listings[_tokenId].whitelistBuyer = _whitelistBuyer;
    }

    function _createAuctionSale(uint256 _tokenId, uint32 _bidStep, uint128 _startPrice, uint128 _reservePrice, uint128 _buyNowPrice, uint64 _end, address _whitelistBuyer)
        tokenIsNotSelling(_tokenId) private
    {
        require(_reservePrice == 0 || _reservePrice >= _startPrice, 'reserve price must equal zero or greater than start price');
        require(_buyNowPrice == 0 || _buyNowPrice >= _startPrice && _buyNowPrice >= _reservePrice, 'buy now price must equal zero or greater or equal than start and reserve prices');

        listings[_tokenId].listingType = ListingType.Auction;
        listings[_tokenId].tokenId = _tokenId;
        listings[_tokenId].sellerManager = msg.sender;
        listings[_tokenId].seller = nftToken.ownerOf(_tokenId);
        listings[_tokenId].price = _buyNowPrice;
        listings[_tokenId].end = _end;
        listings[_tokenId].whitelistBuyer = _whitelistBuyer;
        listings[_tokenId].startPrice = _startPrice;
        listings[_tokenId].reservePrice = _reservePrice;
        listings[_tokenId].bidStep = _bidStep;
    }

    function _resetListing(uint256 _tokenId)
        private
    {
        listings[_tokenId].listingType = ListingType.None;
        listings[_tokenId].tokenId = 0;
        listings[_tokenId].sellerManager = address(0);
        listings[_tokenId].seller = address(0);
        listings[_tokenId].price = 0;
        listings[_tokenId].end = 0;
        listings[_tokenId].whitelistBuyer = address(0);
        listings[_tokenId].startPrice = 0;
        listings[_tokenId].reservePrice = 0;
        listings[_tokenId].highestBid = 0;
        listings[_tokenId].highestBidder = address(0);
        listings[_tokenId].bidStep = 0;
    }

    function _revertHighestBid(uint256 _tokenId)
        private
    {
        if(listings[_tokenId].highestBid > 0 && listings[_tokenId].highestBidder != address(0))
        {
            (bool sent, ) = payable(listings[_tokenId].highestBidder).call{value: listings[_tokenId].highestBid}("");

            if(! sent) {
                debts[listings[_tokenId].highestBidder] += listings[_tokenId].highestBid;
            }
        }
    }

    function _release(uint256 _tokenId, address buyer, uint128 amount)
        private
    {
        require(nftToken.getApproved(_tokenId) == address(this), 'Current contract can not manage NFT token');

        if(amount > 0) {
            uint128 marketplaceFeeAmount = _getPortionOfAmount(amount, marketplaceFee);
            uint128 royaltiesTotal = 0;

            (address[] memory royaltyRecipients, uint32[] memory royaltyAmounts) = nftToken.getRoyalties(_tokenId);

            for(uint i = 0; i < royaltyRecipients.length; i++) {
                uint128 royaltyAmount = _getPortionOfAmount(amount, royaltyAmounts[i]);

                (bool sentRoyalty, ) = payable(royaltyRecipients[i]).call{value: royaltyAmount}("");

                if(sentRoyalty) {
                    emit RoyaltiesPaid(_tokenId, royaltyRecipients[i], royaltyAmount);
                }
                else {
                    debts[royaltyRecipients[i]] += royaltyAmount;
                }

                royaltiesTotal+= royaltyAmount;
            }

            if(listings[_tokenId].royalties.total > 0) {
                for(uint i = 0; i < listings[_tokenId].royalties.recipients.length; i++) {
                    uint128 royaltyAmount = _getPortionOfAmount(amount, listings[_tokenId].royalties.amounts[i]);

                    (bool sentRoyalty2, ) = payable(listings[_tokenId].royalties.recipients[i]).call{value: royaltyAmount}("");

                    if(sentRoyalty2) {
                        emit RoyaltiesPaid(_tokenId, listings[_tokenId].royalties.recipients[i], royaltyAmount);
                    }
                    else {
                        debts[listings[_tokenId].royalties.recipients[i]] += royaltyAmount;
                    }

                    royaltiesTotal+= royaltyAmount;
                }
            }

            uint128 sellerAmount = amount - marketplaceFeeAmount - royaltiesTotal;

            (bool sent, ) = payable(listings[_tokenId].seller).call{value: sellerAmount}("");

            require(sent, 'Failed to send money');
            emit SellerPaid(_tokenId, listings[_tokenId].seller, sellerAmount, block.timestamp);

            marketplaceIncome+= marketplaceFeeAmount;
            emit MarketplaceFeeReceived(_tokenId, marketplaceFeeAmount, block.timestamp);
        }

        nftToken.transferFrom(nftToken.ownerOf(_tokenId), buyer, _tokenId);

        _resetListing(_tokenId);
    }

    function stop() external 
        onlyOwner
    {
        if(isActive) {
            isActive = false;

            emit ContractStoppped(block.timestamp);
        }
    }

    function start() external 
        onlyOwner
    {
        if(! isActive) {
            isActive = true;

            emit ContractStarted(block.timestamp);
        }
    }

    function name() external view virtual returns (string memory) {
        return _name;
    }
}