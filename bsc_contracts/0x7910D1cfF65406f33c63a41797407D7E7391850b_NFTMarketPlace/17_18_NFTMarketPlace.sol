// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./NFTType.sol";

contract NFTMarketPlace is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    NFTType,
    ERC1155Receiver,
    ERC1155Holder
{
    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        uint256 amount;
        address offeror;
        address owner;
        uint256 price;
        address currency;
        bool isAuction;
        bool isPublisher;
        uint256 minimumOffer;
        uint256 duration;
        address bidder;
        uint256 lockedBid;
        address invitedBidder;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    Counters.Counter private _itemsRemoved;

    address public feeAddress;
    event FeeAddressUpdated(address oldAddress, address newAddress);
    uint32 public defaultFee;
    event DefaultFeeUpdated(uint32 oldFee, uint32 newFee);
    mapping(uint256 => MarketItem) private idToMarketItem;
    mapping(uint256 => uint256) private tokenIdToItemId;
    //Counters.Counter private _privateItems;
    // mapping(uint256 => MarketItem) private idToPrivateMarketItem;
    // mapping(uint256 => uint256) private tokenIdToPrivateItemId;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address offeror,
        address owner,
        uint256 price,
        address currency,
        bool isAuction,
        bool isPublisher,
        uint256 minimumOffer,
        uint256 duration
    );

    event MarketItemRemoved(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId
    );

    event MarketItemSold(address owner, address buyer, uint256 tokenId);

    /// @notice A token is offered for sale by owner; or such an offer is revoked
    /// @param  tokenId       which token
    /// @param  offeror       the token owner that is selling
    /// @param  minimumOffer  the amount (in Wei) that is the minimum to accept; or zero to indicate no offer
    /// @param  invitedBidder the exclusive invited buyer for this offer; or the zero address if not exclusive
    event OfferUpdated(
        uint256 indexed tokenId,
        address offeror,
        uint256 minimumOffer,
        address invitedBidder
    );

    /// @notice A new highest bid is committed for a token; or such a bid is revoked
    /// @param  tokenId   which token
    /// @param  bidder    the party that committed Ether to bid
    /// @param  lockedBid the amount (in Wei) that the bidder has committed
    event BidUpdated(
        uint256 indexed tokenId,
        address bidder,
        uint256 lockedBid
    );

    /// @notice A token is traded on the marketplace (this implies any offer for the token is revoked)
    /// @param  tokenId which token
    /// @param  value   the sale price
    /// @param  offeror the party that previously owned the token
    /// @param  bidder  the party that now owns the token
    event Traded(
        uint256 indexed tokenId,
        uint256 value,
        address indexed offeror,
        address indexed bidder
    );

    event RoyaltyTransferred(address from, address to, uint256 amount);

    function initialize(address _feeAddress, uint32 _defaultFee)
        public
        virtual
        initializer
    {
        __Ownable_init();
        __Pausable_init();

        feeAddress = _feeAddress;
        defaultFee = _defaultFee;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Receiver, NFTType)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setFeeAddress(address _feeAddress) public onlyOwner {
        feeAddress = _feeAddress;
    }

    function setDefaultFee(uint32 _defaultFee) public onlyOwner {
        defaultFee = _defaultFee;
    }

    function getMarketItem(uint256 itemId)
        public
        view
        onlyMarketItem(itemId)
        returns (MarketItem memory)
    {
        return idToMarketItem[itemId];
    }

    function createPrivateMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        address currency,
        address invitedBidder
    ) external whenNotPaused onlyNftOwner(nftContract, tokenId) {
        require(price > 0, "Price must be at least 1 wei");
        require(
            invitedBidder != address(0),
            "Invited bidder cannot be address 0"
        );

        _itemIds.increment();
        uint256 itemId = _itemIds.current();
        tokenIdToItemId[tokenId] = itemId; // TODO: Regarder si on en a vraiment besoin
        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            amount,
            msg.sender,
            address(0),
            price,
            currency,
            false,
            false,
            price,
            0,
            address(0),
            0,
            invitedBidder
        );

        _transfertNft(msg.sender, address(this), nftContract, tokenId, amount);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            currency,
            false,
            false,
            price,
            0
        );
    }

    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        address currency,
        bool isAuction,
        bool isPublisher,
        uint256 minimumOffer,
        uint256 duration
    ) external whenNotPaused onlyNftOwner(nftContract, tokenId) {
        require(price > 0, "Price must be at least 1 wei");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();
        tokenIdToItemId[tokenId] = itemId; // TODO: Regarder si on en a vraiment besoin
        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            amount,
            msg.sender,
            address(0),
            price,
            currency,
            isAuction,
            isPublisher,
            minimumOffer,
            duration,
            address(0),
            0,
            address(0)
        );

        // transfer the NFT to marketplace
        _transfertNft(msg.sender, address(this), nftContract, tokenId, amount);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            currency,
            isAuction,
            isPublisher,
            minimumOffer,
            duration
        );

        if (isAuction) {
            require(
                minimumOffer > 0,
                "createMarketItem: minimum offer must be at least 1 wei"
            );
            emit OfferUpdated(tokenId, msg.sender, minimumOffer, address(0));
        }
    }

    function removeMarketItem(uint256 itemId)
        public
        whenNotPaused
        onlyMarketItem(itemId)
    {
        require(
            idToMarketItem[itemId].offeror == msg.sender,
            "removeMarketItem : you are not the offeror of the NFT"
        );
        require(
            idToMarketItem[itemId].lockedBid <= 0 &&
                idToMarketItem[itemId].bidder == address(0),
            "An auction on this NFT is running and has active bid. Cancel the auction before removing this item from the market"
        );
        idToMarketItem[itemId].owner = msg.sender;
        idToMarketItem[itemId].offeror = address(0);

        // transfer the NFT back to sender
        _transfertNft(
            address(this),
            msg.sender,
            idToMarketItem[itemId].nftContract,
            idToMarketItem[itemId].tokenId,
            idToMarketItem[itemId].amount
        );

        emit MarketItemRemoved(
            itemId,
            idToMarketItem[itemId].nftContract,
            idToMarketItem[itemId].tokenId
        );
    }

    // function createPrivateMarketSale(uint256 tokenId)
    //     public
    //     whenNotPaused
    //     onlyPrivateMarketItem(tokenId)
    // {
    //     uint256 itemId = tokenIdToPrivateItemId[tokenId];
    //     uint256 price = idToPrivateMarketItem[itemId].price;
    //     address offeror = idToPrivateMarketItem[itemId].offeror;
    //     address currency = idToPrivateMarketItem[itemId].currency;
    //     address nftContract = idToPrivateMarketItem[itemId].nftContract;
    //     address buyer = msg.sender;

    //     // compute fee amount
    //     uint256 fee = (price * defaultFee) / 10000;
    //     //compute owner sale amount
    //     uint256 amount = price - fee;

    //     // Transfer the owner amount
    //     IERC20(currency).transferFrom(buyer, offeror, amount);
    //     // Transfer the fee amount
    //     IERC20(currency).transferFrom(buyer, feeAddress, fee);

    //     // transfer the NFT to the buyer
    //     if (isERC721(nftContract)) {
    //         IERC721(nftContract).transferFrom(address(this), buyer, tokenId);
    //     } else {
    //         bytes memory empty;
    //         IERC1155(nftContract).safeTransferFrom(
    //             address(this),
    //             buyer,
    //             tokenId,
    //             idToPrivateMarketItem[itemId].amount,
    //             empty
    //         );
    //     }

    //     idToPrivateMarketItem[itemId].owner = buyer;
    //     idToPrivateMarketItem[itemId].offeror = address(0);
    //     idToPrivateMarketItem[itemId].amount = 0;
    //     idToPrivateMarketItem[itemId].minimumOffer = 0;
    //     idToPrivateMarketItem[itemId].invitedBidder = address(0);

    //     emit MarketItemSold(offeror, buyer, tokenId);
    // }

    function _sendRoyalties(uint256 tokenId, uint256 quantity) private {
        uint256 itemId = tokenIdToItemId[tokenId];
        uint256 price = idToMarketItem[itemId].price;
        //uint256 amount = idToMarketItem[itemId].amount;
        address offeror = idToMarketItem[itemId].offeror;
        address currency = idToMarketItem[itemId].currency;
        address nftContract = idToMarketItem[itemId].nftContract;
        address buyer = msg.sender;

        address receiver = address(0);
        uint256 royaltyAmount = 0;

        if (
            IERC165(nftContract).supportsInterface(type(IERC2981).interfaceId)
        ) {
            (address _receiver, uint256 _royaltyAmount) = IERC2981(nftContract)
                .royaltyInfo(tokenId, price * quantity);

            if (offeror != _receiver) {
                receiver = _receiver;
                royaltyAmount = _royaltyAmount;
            }
        }

        // compute fee amount
        uint256 fee = (price * quantity * defaultFee) / 10000;
        //compute owner sale amount
        uint256 salePrice = price * quantity - fee - royaltyAmount;

        // Transfer the owner amount
        IERC20(currency).transferFrom(buyer, offeror, salePrice);
        // Transfer the fee amount
        IERC20(currency).transferFrom(buyer, feeAddress, fee);
        if (receiver != address(0)) {
            // Transfer the royalty amount
            IERC20(currency).transferFrom(buyer, receiver, royaltyAmount);
            emit RoyaltyTransferred(buyer, receiver, royaltyAmount);
        }
    }

    function createMarketSale(uint256 itemId, uint256 quantity)
        public
        whenNotPaused
        onlyMarketItem(itemId)
    {
        require(msg.sender != address(0), "zero adresse cannot buy NFT");
        require(
            idToMarketItem[itemId].amount >= quantity,
            "createMarketSale: not enough token availables"
        );
        require(
            idToMarketItem[itemId].invitedBidder == address(0) ||
                idToMarketItem[itemId].invitedBidder == msg.sender,
            "createMarketSale: this item is reserved"
        );
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        address offeror = idToMarketItem[itemId].offeror;

        _sendRoyalties(tokenId, quantity);

        // transfer the NFT to the buyer
        _transfertNft(
            address(this),
            msg.sender,
            idToMarketItem[itemId].nftContract,
            tokenId,
            quantity
        );

        idToMarketItem[itemId].amount =
            idToMarketItem[itemId].amount -
            quantity;

        if (idToMarketItem[itemId].amount < 1) {
            idToMarketItem[itemId].owner = msg.sender;
            idToMarketItem[itemId].offeror = address(0);
            idToMarketItem[itemId].minimumOffer = 0;
            idToMarketItem[itemId].invitedBidder = address(0);
        }

        _itemsSold.increment();

        emit MarketItemSold(offeror, msg.sender, tokenId);
    }

    function _transfertNft(
        address _from,
        address _to,
        address _nftContract,
        uint256 _tokenId,
        uint256 _amount
    ) private {
        require(_to != address(0), "cannot transfer to address(0)");
        if (isERC721(_nftContract)) {
            require(_amount == 1, "ERC721: Invalid quantity");
            IERC721(_nftContract).transferFrom(_from, _to, _tokenId);
        } else {
            bytes memory empty;
            IERC1155(_nftContract).safeTransferFrom(
                _from,
                _to,
                _tokenId,
                _amount,
                empty
            );
        }
    }

    function closeAuction(uint256 itemId)
        public
        whenNotPaused
        onlyMarketItem(itemId)
    {
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        require(
            block.timestamp > idToMarketItem[itemId].duration,
            "closeAuction: Auction period is running"
        );
        require(
            msg.sender == idToMarketItem[itemId].offeror,
            "closeAuction: Only offeror can cancel and auction for a token he owns"
        );
        
        uint256 highestBid = idToMarketItem[itemId].lockedBid;
        address offeror = idToMarketItem[itemId].offeror;
        address bidder = idToMarketItem[itemId].bidder;

        if (bidder != address(0)) {
            _doTrade(itemId, highestBid, offeror, bidder);
            _itemsSold.increment();
            emit MarketItemSold(offeror, bidder, tokenId);
        } else {
            _transfertNft(
                address(this),
                msg.sender,
                idToMarketItem[itemId].nftContract,
                idToMarketItem[itemId].tokenId,
                idToMarketItem[itemId].amount
            );
        }
        _setBid(itemId, address(0), 0);
    }

    /// @dev Collect fee for owner & offeror and transfer underlying asset. The Traded event emits before the
    ///      ERC721.Transfer event so that somebody observing the events and seeing the latter will recognize the
    ///      context of the former. The bid is NOT cleaned up generally in this function because a circumstance exists
    ///      where an existing bid persists after a trade. See "context 3" above.
    function _doTrade(
        uint256 itemId,
        uint256 value,
        address offeror,
        address bidder
    ) private {
        address receiver = address(0);
        uint256 royaltyAmount = 0;

        if (
            IERC165(idToMarketItem[itemId].nftContract).supportsInterface(
                type(IERC2981).interfaceId
            )
        ) {
            (address _receiver, uint256 _royaltyAmount) = IERC2981(
                idToMarketItem[itemId].nftContract
            ).royaltyInfo(idToMarketItem[itemId].tokenId, value);

            if (offeror != _receiver) {
                receiver = _receiver;
                royaltyAmount = _royaltyAmount;
            }
        }
        // Divvy up proceeds
        uint256 feeAmount = (value * defaultFee) / 10000; // reverts on overflow
        uint256 bidderAmount = value - feeAmount - royaltyAmount;
        IERC20(idToMarketItem[itemId].currency).transfer(feeAddress, feeAmount);
        IERC20(idToMarketItem[itemId].currency).transfer(offeror, bidderAmount);
        if (receiver != address(0)) {
            // Transfer the royalty amount
            IERC20(idToMarketItem[itemId].currency).transfer(
                receiver,
                royaltyAmount
            );
            emit RoyaltyTransferred(bidder, receiver, royaltyAmount);
        }

        // transfer the NFT to the bidder
        _transfertNft(
            address(this),
            address(0),
            idToMarketItem[itemId].nftContract,
            idToMarketItem[itemId].tokenId,
            idToMarketItem[itemId].amount
        );

        emit Traded(idToMarketItem[itemId].tokenId, value, offeror, bidder);

        idToMarketItem[itemId].offeror = address(0);
        idToMarketItem[itemId].minimumOffer = 0;
        idToMarketItem[itemId].invitedBidder = address(0);
        idToMarketItem[itemId].owner = bidder;
        idToMarketItem[itemId].amount = 0;

        // transfer the NFT to the bidder
        _transfertNft(
            address(this),
            bidder,
            idToMarketItem[itemId].nftContract,
            idToMarketItem[itemId].tokenId,
            idToMarketItem[itemId].amount
        );
    }

    function fetchMyPrivateMarketItems()
        public
        view
        returns (MarketItem[] memory)
    {
        uint256 itemCount = _itemIds.current();
        uint256 currentIndex = 0;

        uint256 count = 0;
        for (uint256 i = 0; i < itemCount; i++) {
            if (
                idToMarketItem[i + 1].owner == address(0) &&
                idToMarketItem[i + 1].invitedBidder == msg.sender
            ) {
                count += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](count);
        for (uint256 i = 0; i < itemCount; i++) {
            if (
                idToMarketItem[i + 1].owner == address(0) &&
                idToMarketItem[i + 1].invitedBidder == msg.sender
            ) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 currentIndex = 0;

        uint256 count = 0;
        for (uint256 i = 0; i < itemCount; i++) {
            if (
                idToMarketItem[i + 1].owner == address(0) &&
                idToMarketItem[i + 1].invitedBidder == address(0)
            ) {
                count += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](count);
        for (uint256 i = 0; i < itemCount; i++) {
            if (
                idToMarketItem[i + 1].owner == address(0) &&
                idToMarketItem[i + 1].invitedBidder == address(0)
            ) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    // function fetchAll() public view returns (MarketItem[] memory) {
    //     uint256 itemCount = _itemIds.current();
    //     uint256 currentIndex = 0;

    //     uint256 count = 0;
    //     for (uint256 i = 0; i < itemCount; i++) {
    //         //if (idToMarketItem[i + 1].owner == address(0)) {
    //         count += 1;
    //         // }
    //     }

    //     MarketItem[] memory items = new MarketItem[](count);
    //     for (uint256 i = 0; i < itemCount; i++) {
    //         //if (idToMarketItem[i + 1].owner == address(0)) {
    //         uint256 currentId = idToMarketItem[i + 1].itemId;
    //         MarketItem storage currentItem = idToMarketItem[currentId];
    //         items[currentIndex] = currentItem;
    //         currentIndex += 1;
    //         //}
    //     }

    //     return items;
    // }

    function fetchMyListedNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].offeror == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].offeror == msg.sender) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                idToMarketItem[i + 1].owner == msg.sender &&
                idToMarketItem[i + 1].invitedBidder == address(0)
            ) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function cancelAuction(uint256 itemId)
        public
        whenNotPaused
        onlyMarketItem(itemId)
    {
        require(
            block.timestamp <= idToMarketItem[itemId].duration,
            "cancelAuction: Auction period is over for this NFT"
        );
        require(
            msg.sender == idToMarketItem[itemId].offeror,
            "cancelAuction: Only offeror can cancel and auction for a token he owns"
        );

        address bidder = idToMarketItem[itemId].bidder;
        uint256 lockedBid = idToMarketItem[itemId].lockedBid;
        address currency = idToMarketItem[itemId].currency;

        if (bidder != address(0)) {
            // Refund the current bidder
            IERC20(currency).transfer(bidder, lockedBid);
        }
        _setOffer(itemId, address(0), 0, address(0));
    }

    /// @notice An bidder may revoke their bid
    /// @param  itemId which itemId
    function revokeBid(uint256 itemId)
        external
        whenNotPaused
        onlyMarketItem(itemId)
    {
        require(
            block.timestamp <= idToMarketItem[itemId].duration,
            "revoke Bid: Auction period is over for this NFT"
        );
        require(
            msg.sender == idToMarketItem[itemId].bidder,
            "revoke Bid: Only the bidder may revoke their bid"
        );
        address currency = idToMarketItem[itemId].currency;
        address existingBidder = idToMarketItem[itemId].bidder;
        uint256 existingLockedBid = idToMarketItem[itemId].lockedBid;
        IERC20(currency).transfer(existingBidder, existingLockedBid);
        _setBid(itemId, address(0), 0);
    }

    /// @notice Anyone may commit more than the existing bid for a token.
    /// @param  itemId which item
    function bid(uint256 itemId, uint256 amount)
        external
        whenNotPaused
        onlyMarketItem(itemId)
    {
        uint256 existingLockedBid = idToMarketItem[itemId].lockedBid;
        uint256 minimumOffer = idToMarketItem[itemId].minimumOffer;
        require(
            idToMarketItem[itemId].isAuction,
            "bid: this NFT is not auctionable"
        );

        require(
            block.timestamp <= idToMarketItem[itemId].duration,
            "bid: Auction period is over for this NFT"
        );

        require(amount >= minimumOffer, "Bid too low");
        require(amount > existingLockedBid, "Bid lower than the highest bid");

        address existingBidder = idToMarketItem[itemId].bidder;
        address currency = idToMarketItem[itemId].currency;

        IERC20(currency).transferFrom(msg.sender, address(this), amount);
        if (existingBidder != address(0)) {
            IERC20(currency).transfer(existingBidder, existingLockedBid);
        }
        _setBid(itemId, msg.sender, amount);
    }

    /// @notice Anyone may add more value to their existing bid
    /// @param  itemId which itemId
    function bidIncrease(uint256 itemId, uint256 amount)
        external
        whenNotPaused
        onlyMarketItem(itemId)
    {
        require(
            block.timestamp <= idToMarketItem[itemId].duration,
            "bid Increase: Auction period is over for this NFT"
        );
        require(amount > 0, "bidIncrease: Must send value to increase bid");
        require(
            msg.sender == idToMarketItem[itemId].bidder,
            "bidIncrease: You are not current bidder"
        );

        uint256 newBidAmount = idToMarketItem[itemId].lockedBid + amount;
        address currency = idToMarketItem[itemId].currency;

        IERC20(currency).transferFrom(msg.sender, address(this), amount);
        idToMarketItem[itemId].lockedBid = newBidAmount;
        _setBid(itemId, msg.sender, newBidAmount);
    }

    /// @notice The owner can set the fee portion
    /// @param  newFeePortion the transaction fee (in basis points) as a portion of the sale price
    function setFeePortion(uint32 newFeePortion) external onlyOwner {
        require(newFeePortion >= 0, "Exceeded maximum fee portion of 10%");
        defaultFee = newFeePortion;
    }

    /// @dev Set and emit new offer
    function _setOffer(
        uint256 itemId,
        address offeror,
        uint256 minimumOffer,
        address invitedBidder
    ) private {
        idToMarketItem[itemId].offeror = offeror;
        idToMarketItem[itemId].minimumOffer = minimumOffer;
        idToMarketItem[itemId].invitedBidder = invitedBidder;
        emit OfferUpdated(
            idToMarketItem[itemId].tokenId,
            offeror,
            minimumOffer,
            invitedBidder
        );
    }

    /// @dev Set and emit new bid
    function _setBid(
        uint256 itemId,
        address bidder,
        uint256 lockedBid
    ) private {
        idToMarketItem[itemId].bidder = bidder;
        idToMarketItem[itemId].lockedBid = lockedBid;
        emit BidUpdated(idToMarketItem[itemId].tokenId, bidder, lockedBid);
    }

    function _marketItemCount() public view returns (uint256) {
        return _itemIds.current();
    }

    modifier onlyMarketItem(uint256 itemId) {
        require(
            idToMarketItem[itemId].tokenId > 0,
            "TokenId not found in the market"
        );
        _;
    }

    function _onlyNftOwner(address nftContract, uint256 tokenId) private view {
        if (isERC721(nftContract)) {
            require(
                msg.sender == IERC721(nftContract).ownerOf(tokenId),
                "Only the token owner can offer"
            );
        } else if (isERC1155(nftContract)) {
            require(
                IERC1155(nftContract).balanceOf(msg.sender, tokenId) > 0,
                "Only the token owner can offer"
            );
        } else require(false, "NFTContract type not supported");
    }

    modifier onlyNftOwner(address nftContract, uint256 tokenId) {
        _onlyNftOwner(nftContract, tokenId);
        _;
    }
}