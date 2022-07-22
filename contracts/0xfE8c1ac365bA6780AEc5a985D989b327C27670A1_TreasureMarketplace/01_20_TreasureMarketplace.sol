// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/// @title  Treasure NFT marketplace
/// @notice This contract allows you to buy and sell NFTs from token contracts that are approved by the contract owner.
///         Please note that this contract is upgradeable. In the event of a compromised ProxyAdmin contract owner,
///         collectable tokens and payments may be at risk. To prevent this, the ProxyAdmin is owned by a multi-sig
///         governed by the TreasureDAO council.
/// @dev    This contract does not store any tokens at any time, it's only collects details "the sale" and approvals
///         from both parties and preforms non-custodial transaction by transfering NFT from owner to buying and payment
///         token from buying to NFT owner.
contract TreasureMarketplace is AccessControlEnumerableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct ListingOrBid {
        /// @dev number of tokens for sale or requested (1 if ERC-721 token is active for sale) (for bids, quantity for ERC-721 can be greater than 1)
        uint64 quantity;
        /// @dev price per token sold, i.e. extended sale price equals this times quantity purchased. For bids, price offered per item.
        uint128 pricePerItem;
        /// @dev timestamp after which the listing/bid is invalid
        uint64 expirationTime;
        /// @dev the payment token for this listing/bid.
        address paymentTokenAddress;
    }

    struct CollectionOwnerFee {
        /// @dev the fee, out of 10,000, that this collection owner will be given for each sale
        uint32 fee;
        /// @dev the recipient of the collection specific fee
        address recipient;
    }

    enum TokenApprovalStatus {NOT_APPROVED, ERC_721_APPROVED, ERC_1155_APPROVED}

    /// @notice TREASURE_MARKETPLACE_ADMIN_ROLE role hash
    bytes32 public constant TREASURE_MARKETPLACE_ADMIN_ROLE = keccak256("TREASURE_MARKETPLACE_ADMIN_ROLE");

    /// @notice ERC165 interface signatures
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /// @notice the denominator for portion calculation, i.e. how many basis points are in 100%
    uint256 public constant BASIS_POINTS = 10000;

    /// @notice the maximum fee which the owner may set (in units of basis points)
    uint256 public constant MAX_FEE = 1500;

    /// @notice the maximum fee which the collection owner may set
    uint256 public constant MAX_COLLECTION_FEE = 2000;

    /// @notice the minimum price for which any item can be sold
    uint256 public constant MIN_PRICE = 1e9;

    /// @notice the default token that is used for marketplace sales and fee payments. Can be overridden by collectionToTokenAddress.
    IERC20Upgradeable public paymentToken;

    /// @notice fee portion (in basis points) for each sale, (e.g. a value of 100 is 100/10000 = 1%). This is the fee if no collection owner fee is set.
    uint256 public fee;

    /// @notice address that receives fees
    address public feeReceipient;

    /// @notice mapping for listings, maps: nftAddress => tokenId => offeror
    mapping(address => mapping(uint256 => mapping(address => ListingOrBid))) public listings;

    /// @notice NFTs which the owner has approved to be sold on the marketplace, maps: nftAddress => status
    mapping(address => TokenApprovalStatus) public tokenApprovals;

    /// @notice fee portion (in basis points) for each sale. This is used if a separate fee has been set for the collection owner.
    uint256 public feeWithCollectionOwner;

    /// @notice Maps the collection address to the fees which the collection owner collects. Some collections may not have a seperate fee, such as those owned by the Treasure DAO.
    mapping(address => CollectionOwnerFee) public collectionToCollectionOwnerFee;

    /// @notice Maps the collection address to the payment token that will be used for purchasing. If the address is the zero address, it will use the default paymentToken.
    mapping(address => address) public collectionToPaymentToken;

    /// @notice The address for weth.
    IERC20Upgradeable public weth;

    /// @notice mapping for token bids (721/1155): nftAddress => tokneId => offeror
    mapping(address => mapping(uint256 => mapping(address => ListingOrBid))) public tokenBids;

    /// @notice mapping for collection level bids (721 only): nftAddress => offeror
    mapping(address => mapping(address => ListingOrBid)) public collectionBids;

    /// @notice Indicates if bid related functions are active.
    bool public areBidsActive;

    /// @notice The fee portion was updated
    /// @param  fee new fee amount (in units of basis points)
    event UpdateFee(uint256 fee);

    /// @notice The fee portion was updated for collections that have a collection owner.
    /// @param  fee new fee amount (in units of basis points)
    event UpdateFeeWithCollectionOwner(uint256 fee);

    /// @notice A collection's fees have changed
    /// @param  _collection  The collection
    /// @param  _recipient   The recipient of the fees. If the address is 0, the collection fees for this collection have been removed.
    /// @param  _fee         The fee amount (in units of basis points)
    event UpdateCollectionOwnerFee(address _collection, address _recipient, uint256 _fee);

    /// @notice The fee recipient was updated
    /// @param  feeRecipient the new recipient to get fees
    event UpdateFeeRecipient(address feeRecipient);

    /// @notice The approval status for a token was updated
    /// @param  nft    which token contract was updated
    /// @param  status the new status
    /// @param  paymentToken the token that will be used for payments for this collection
    event TokenApprovalStatusUpdated(address nft, TokenApprovalStatus status, address paymentToken);

    event TokenBidCreatedOrUpdated(
        address bidder,
        address nftAddress,
        uint256 tokenId,
        uint64 quantity,
        uint128 pricePerItem,
        uint64 expirationTime,
        address paymentToken
    );

    event CollectionBidCreatedOrUpdated(
        address bidder,
        address nftAddress,
        uint64 quantity,
        uint128 pricePerItem,
        uint64 expirationTime,
        address paymentToken
    );

    event TokenBidCancelled(
        address bidder,
        address nftAddress,
        uint256 tokenId
    );

    event CollectionBidCancelled(
        address bidder,
        address nftAddress
    );

    event BidAccepted(
        address seller,
        address bidder,
        address nftAddress,
        uint256 tokenId,
        uint64 quantity,
        uint128 pricePerItem,
        address paymentToken,
        BidType bidType
    );

    /// @notice An item was listed for sale
    /// @param  seller         the offeror of the item
    /// @param  nftAddress     which token contract holds the offered token
    /// @param  tokenId        the identifier for the offered token
    /// @param  quantity       how many of this token identifier are offered (or 1 for a ERC-721 token)
    /// @param  pricePerItem   the price (in units of the paymentToken) for each token offered
    /// @param  expirationTime UNIX timestamp after when this listing expires
    /// @param  paymentToken   the token used to list this item
    event ItemListed(
        address seller,
        address nftAddress,
        uint256 tokenId,
        uint64 quantity,
        uint128 pricePerItem,
        uint64 expirationTime,
        address paymentToken
    );

    /// @notice An item listing was updated
    /// @param  seller         the offeror of the item
    /// @param  nftAddress     which token contract holds the offered token
    /// @param  tokenId        the identifier for the offered token
    /// @param  quantity       how many of this token identifier are offered (or 1 for a ERC-721 token)
    /// @param  pricePerItem   the price (in units of the paymentToken) for each token offered
    /// @param  expirationTime UNIX timestamp after when this listing expires
    /// @param  paymentToken   the token used to list this item
    event ItemUpdated(
        address seller,
        address nftAddress,
        uint256 tokenId,
        uint64 quantity,
        uint128 pricePerItem,
        uint64 expirationTime,
        address paymentToken
    );

    /// @notice An item is no longer listed for sale
    /// @param  seller     former offeror of the item
    /// @param  nftAddress which token contract holds the formerly offered token
    /// @param  tokenId    the identifier for the formerly offered token
    event ItemCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);

    /// @notice A listed item was sold
    /// @param  seller       the offeror of the item
    /// @param  buyer        the buyer of the item
    /// @param  nftAddress   which token contract holds the sold token
    /// @param  tokenId      the identifier for the sold token
    /// @param  quantity     how many of this token identifier where sold (or 1 for a ERC-721 token)
    /// @param  pricePerItem the price (in units of the paymentToken) for each token sold
    /// @param  paymentToken the payment token that was used to pay for this item
    event ItemSold(
        address seller,
        address buyer,
        address nftAddress,
        uint256 tokenId,
        uint64 quantity,
        uint128 pricePerItem,
        address paymentToken
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice Perform initial contract setup
    /// @dev    The initializer modifier ensures this is only called once, the owner should confirm this was properly
    ///         performed before publishing this contract address.
    /// @param  _initialFee          fee to be paid on each sale, in basis points
    /// @param  _initialFeeRecipient wallet to collets fees
    /// @param  _initialPaymentToken address of the token that is used for settlement
    function initialize(
        uint256 _initialFee,
        address _initialFeeRecipient,
        IERC20Upgradeable _initialPaymentToken
    )
        external
        initializer
    {
        require(address(_initialPaymentToken) != address(0), "TreasureMarketplace: cannot set address(0)");

        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();

        _setRoleAdmin(TREASURE_MARKETPLACE_ADMIN_ROLE, TREASURE_MARKETPLACE_ADMIN_ROLE);
        _grantRole(TREASURE_MARKETPLACE_ADMIN_ROLE, msg.sender);

        setFee(_initialFee, _initialFee);
        setFeeRecipient(_initialFeeRecipient);
        paymentToken = _initialPaymentToken;
    }

    /// @notice Creates an item listing. You must authorize this marketplace with your item's token contract to list.
    /// @param  _nftAddress     which token contract holds the offered token
    /// @param  _tokenId        the identifier for the offered token
    /// @param  _quantity       how many of this token identifier are offered (or 1 for a ERC-721 token)
    /// @param  _pricePerItem   the price (in units of the paymentToken) for each token offered
    /// @param  _expirationTime UNIX timestamp after when this listing expires
    function createListing(
        address _nftAddress,
        uint256 _tokenId,
        uint64 _quantity,
        uint128 _pricePerItem,
        uint64 _expirationTime,
        address _paymentToken
    )
        external
        nonReentrant
        whenNotPaused
    {
        require(listings[_nftAddress][_tokenId][_msgSender()].quantity == 0, "TreasureMarketplace: already listed");
        _createListingWithoutEvent(_nftAddress, _tokenId, _quantity, _pricePerItem, _expirationTime, _paymentToken);
        emit ItemListed(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _quantity,
            _pricePerItem,
            _expirationTime,
            _paymentToken
        );
    }

    /// @notice Updates an item listing
    /// @param  _nftAddress        which token contract holds the offered token
    /// @param  _tokenId           the identifier for the offered token
    /// @param  _newQuantity       how many of this token identifier are offered (or 1 for a ERC-721 token)
    /// @param  _newPricePerItem   the price (in units of the paymentToken) for each token offered
    /// @param  _newExpirationTime UNIX timestamp after when this listing expires
    function updateListing(
        address _nftAddress,
        uint256 _tokenId,
        uint64 _newQuantity,
        uint128 _newPricePerItem,
        uint64 _newExpirationTime,
        address _paymentToken
    )
        external
        nonReentrant
        whenNotPaused
    {
        require(listings[_nftAddress][_tokenId][_msgSender()].quantity > 0, "TreasureMarketplace: not listed item");
        _createListingWithoutEvent(_nftAddress, _tokenId, _newQuantity, _newPricePerItem, _newExpirationTime, _paymentToken);
        emit ItemUpdated(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _newQuantity,
            _newPricePerItem,
            _newExpirationTime,
            _paymentToken
        );
    }

    function createOrUpdateListing(
        address _nftAddress,
        uint256 _tokenId,
        uint64 _quantity,
        uint128 _pricePerItem,
        uint64 _expirationTime,
        address _paymentToken)
    external
    nonReentrant
    whenNotPaused
    {
        bool _existingListing = listings[_nftAddress][_tokenId][_msgSender()].quantity > 0;
        _createListingWithoutEvent(_nftAddress, _tokenId, _quantity, _pricePerItem, _expirationTime, _paymentToken);
        // Keep the events the same as they were before.
        if(_existingListing) {
            emit ItemUpdated(
                _msgSender(),
                _nftAddress,
                _tokenId,
                _quantity,
                _pricePerItem,
                _expirationTime,
                _paymentToken
            );
        } else {
            emit ItemListed(
                _msgSender(),
                _nftAddress,
                _tokenId,
                _quantity,
                _pricePerItem,
                _expirationTime,
                _paymentToken
            );
        }
    }

    /// @notice Performs the listing and does not emit the event
    /// @param  _nftAddress     which token contract holds the offered token
    /// @param  _tokenId        the identifier for the offered token
    /// @param  _quantity       how many of this token identifier are offered (or 1 for a ERC-721 token)
    /// @param  _pricePerItem   the price (in units of the paymentToken) for each token offered
    /// @param  _expirationTime UNIX timestamp after when this listing expires
    function _createListingWithoutEvent(
        address _nftAddress,
        uint256 _tokenId,
        uint64 _quantity,
        uint128 _pricePerItem,
        uint64 _expirationTime,
        address _paymentToken
    )
        internal
    {
        require(_expirationTime > block.timestamp, "TreasureMarketplace: invalid expiration time");
        require(_pricePerItem >= MIN_PRICE, "TreasureMarketplace: below min price");

        if (tokenApprovals[_nftAddress] == TokenApprovalStatus.ERC_721_APPROVED) {
            IERC721Upgradeable nft = IERC721Upgradeable(_nftAddress);
            require(nft.ownerOf(_tokenId) == _msgSender(), "TreasureMarketplace: not owning item");
            require(nft.isApprovedForAll(_msgSender(), address(this)), "TreasureMarketplace: item not approved");
            require(_quantity == 1, "TreasureMarketplace: cannot list multiple ERC721");
        } else if (tokenApprovals[_nftAddress] == TokenApprovalStatus.ERC_1155_APPROVED) {
            IERC1155Upgradeable nft = IERC1155Upgradeable(_nftAddress);
            require(nft.balanceOf(_msgSender(), _tokenId) >= _quantity, "TreasureMarketplace: must hold enough nfts");
            require(nft.isApprovedForAll(_msgSender(), address(this)), "TreasureMarketplace: item not approved");
            require(_quantity > 0, "TreasureMarketplace: nothing to list");
        } else {
            revert("TreasureMarketplace: token is not approved for trading");
        }

        address _paymentTokenForCollection = getPaymentTokenForCollection(_nftAddress);
        require(_paymentTokenForCollection == _paymentToken, "TreasureMarketplace: Wrong payment token");

        listings[_nftAddress][_tokenId][_msgSender()] = ListingOrBid(
            _quantity,
            _pricePerItem,
            _expirationTime,
            _paymentToken
        );
    }

    /// @notice Remove an item listing
    /// @param  _nftAddress which token contract holds the offered token
    /// @param  _tokenId    the identifier for the offered token
    function cancelListing(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
    {
        delete (listings[_nftAddress][_tokenId][_msgSender()]);
        emit ItemCanceled(_msgSender(), _nftAddress, _tokenId);
    }

    function cancelManyBids(CancelBidParams[] calldata _cancelBidParams) external nonReentrant {
        for(uint256 i = 0; i < _cancelBidParams.length; i++) {
            CancelBidParams calldata _cancelBidParam = _cancelBidParams[i];
            if(_cancelBidParam.bidType == BidType.COLLECTION) {
                collectionBids[_cancelBidParam.nftAddress][_msgSender()].quantity = 0;

                emit CollectionBidCancelled(_msgSender(), _cancelBidParam.nftAddress);
            } else {
                tokenBids[_cancelBidParam.nftAddress][_cancelBidParam.tokenId][_msgSender()].quantity = 0;

                emit TokenBidCancelled(_msgSender(), _cancelBidParam.nftAddress, _cancelBidParam.tokenId);
            }
        }
    }

    /// @notice Creates a bid for a particular token.
    function createOrUpdateTokenBid(
        address _nftAddress,
        uint256 _tokenId,
        uint64 _quantity,
        uint128 _pricePerItem,
        uint64 _expirationTime,
        address _paymentToken)
    external
    nonReentrant
    whenNotPaused
    whenBiddingActive
    {
        if(tokenApprovals[_nftAddress] == TokenApprovalStatus.ERC_721_APPROVED) {
            require(_quantity == 1, "TreasureMarketplace: token bid quantity 1 for ERC721");
        } else if (tokenApprovals[_nftAddress] == TokenApprovalStatus.ERC_1155_APPROVED) {
            require(_quantity > 0, "TreasureMarketplace: bad quantity");
        } else {
            revert("TreasureMarketplace: token is not approved for trading");
        }

        _createBidWithoutEvent(_nftAddress, _quantity, _pricePerItem, _expirationTime, _paymentToken, tokenBids[_nftAddress][_tokenId][_msgSender()]);

        emit TokenBidCreatedOrUpdated(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _quantity,
            _pricePerItem,
            _expirationTime,
            _paymentToken
        );
    }

    function createOrUpdateCollectionBid(
        address _nftAddress,
        uint64 _quantity,
        uint128 _pricePerItem,
        uint64 _expirationTime,
        address _paymentToken)
    external
    nonReentrant
    whenNotPaused
    whenBiddingActive
    {
        if(tokenApprovals[_nftAddress] == TokenApprovalStatus.ERC_721_APPROVED) {
            require(_quantity > 0, "TreasureMarketplace: Bad quantity");
        } else if (tokenApprovals[_nftAddress] == TokenApprovalStatus.ERC_1155_APPROVED) {
            revert("TreasureMarketplace: No collection bids on 1155s");
        } else {
            revert("TreasureMarketplace: token is not approved for trading");
        }

        _createBidWithoutEvent(_nftAddress, _quantity, _pricePerItem, _expirationTime, _paymentToken, collectionBids[_nftAddress][_msgSender()]);

        emit CollectionBidCreatedOrUpdated(
            _msgSender(),
            _nftAddress,
            _quantity,
            _pricePerItem,
            _expirationTime,
            _paymentToken
        );
    }

    function _createBidWithoutEvent(
        address _nftAddress,
        uint64 _quantity,
        uint128 _pricePerItem,
        uint64 _expirationTime,
        address _paymentToken,
        ListingOrBid storage _bid)
    private
    {
        require(_expirationTime > block.timestamp, "TreasureMarketplace: invalid expiration time");
        require(_pricePerItem >= MIN_PRICE, "TreasureMarketplace: below min price");

        address _paymentTokenForCollection = getPaymentTokenForCollection(_nftAddress);
        require(_paymentTokenForCollection == _paymentToken, "TreasureMarketplace: Bad payment token");

        IERC20Upgradeable _token = IERC20Upgradeable(_paymentToken);

        uint256 _totalAmountNeeded = _pricePerItem * _quantity;

        require(_token.allowance(_msgSender(), address(this)) >= _totalAmountNeeded && _token.balanceOf(_msgSender()) >= _totalAmountNeeded,
            "TreasureMarketplace: Not enough tokens owned or allowed for bid");

        _bid.quantity = _quantity;
        _bid.pricePerItem = _pricePerItem;
        _bid.expirationTime = _expirationTime;
        _bid.paymentTokenAddress = _paymentToken;
    }

    function acceptCollectionBid(
        AcceptBidParams calldata _acceptBidParams)
    external
    nonReentrant
    whenNotPaused
    whenBiddingActive
    {
        _acceptBid(_acceptBidParams, BidType.COLLECTION);
    }

    function acceptTokenBid(
        AcceptBidParams calldata _acceptBidParams)
    external
    nonReentrant
    whenNotPaused
    whenBiddingActive
    {
        _acceptBid(_acceptBidParams, BidType.TOKEN);
    }

    function _acceptBid(AcceptBidParams calldata _acceptBidParams, BidType _bidType) private {
        // Validate buy order
        require(_msgSender() != _acceptBidParams.bidder, "TreasureMarketplace: Cannot supply own bid");
        require(_acceptBidParams.quantity > 0, "TreasureMarketplace: Nothing to supply to bidder");

        // Validate bid
        ListingOrBid storage _bid = _bidType == BidType.COLLECTION
            ? collectionBids[_acceptBidParams.nftAddress][_acceptBidParams.bidder]
            : tokenBids[_acceptBidParams.nftAddress][_acceptBidParams.tokenId][_acceptBidParams.bidder];

        require(_bid.quantity > 0, "TreasureMarketplace: bid does not exist");
        require(_bid.expirationTime >= block.timestamp, "TreasureMarketplace: bid expired");
        require(_bid.pricePerItem > 0, "TreasureMarketplace: bid price invalid");
        require(_bid.quantity >= _acceptBidParams.quantity, "TreasureMarketplace: not enough quantity");
        require(_bid.pricePerItem == _acceptBidParams.pricePerItem, "TreasureMarketplace: price does not match");

        // Ensure the accepter, the bidder, and the collection all agree on the token to be used for the purchase.
        // If the token used for buying/selling has changed since the bid was created, this effectively blocks
        // all the old bids with the old payment tokens from being bought.
        address _paymentTokenForCollection = getPaymentTokenForCollection(_acceptBidParams.nftAddress);

        require(_bid.paymentTokenAddress == _acceptBidParams.paymentToken && _acceptBidParams.paymentToken == _paymentTokenForCollection, "TreasureMarketplace: Wrong payment token");

        // Transfer NFT to buyer, also validates owner owns it, and token is approved for trading
        if(tokenApprovals[_acceptBidParams.nftAddress] == TokenApprovalStatus.ERC_721_APPROVED) {
            require(_acceptBidParams.quantity == 1, "TreasureMarketplace: Cannot supply multiple ERC721s");

            IERC721Upgradeable(_acceptBidParams.nftAddress).safeTransferFrom(_msgSender(), _acceptBidParams.bidder, _acceptBidParams.tokenId);
        } else if (tokenApprovals[_acceptBidParams.nftAddress] == TokenApprovalStatus.ERC_1155_APPROVED) {

            IERC1155Upgradeable(_acceptBidParams.nftAddress).safeTransferFrom(_msgSender(), _acceptBidParams.bidder, _acceptBidParams.tokenId, _acceptBidParams.quantity, bytes(""));
        } else {
            revert("TreasureMarketplace: token is not approved for trading");
        }

        _payFees(_bid, _acceptBidParams.quantity, _acceptBidParams.nftAddress, _acceptBidParams.bidder, _msgSender(), _acceptBidParams.paymentToken, false);

        // Announce accepting bid
        emit BidAccepted(
            _msgSender(),
            _acceptBidParams.bidder,
            _acceptBidParams.nftAddress,
            _acceptBidParams.tokenId,
            _acceptBidParams.quantity,
            _acceptBidParams.pricePerItem,
            _acceptBidParams.paymentToken,
            _bidType
        );

        // Deplete or cancel listing
        _bid.quantity -= _acceptBidParams.quantity;
    }

    /// @notice Buy multiple listed items. You must authorize this marketplace with your payment token to completed the buy or purchase with eth if it is a weth collection.
    function buyItems(
        BuyItemParams[] calldata _buyItemParams)
    external
    payable
    nonReentrant
    whenNotPaused
    {
        uint256 _ethAmountRequired;
        for(uint256 i = 0; i < _buyItemParams.length; i++) {
            _ethAmountRequired += _buyItem(_buyItemParams[i]);
        }

        require(msg.value == _ethAmountRequired, "TreasureMarketplace: Bad ETH value");
    }

    // Returns the amount of eth a user must have sent.
    function _buyItem(BuyItemParams calldata _buyItemParams) private returns(uint256) {
        // Validate buy order
        require(_msgSender() != _buyItemParams.owner, "TreasureMarketplace: Cannot buy your own item");
        require(_buyItemParams.quantity > 0, "TreasureMarketplace: Nothing to buy");

        // Validate listing
        ListingOrBid memory listedItem = listings[_buyItemParams.nftAddress][_buyItemParams.tokenId][_buyItemParams.owner];
        require(listedItem.quantity > 0, "TreasureMarketplace: not listed item");
        require(listedItem.expirationTime >= block.timestamp, "TreasureMarketplace: listing expired");
        require(listedItem.pricePerItem > 0, "TreasureMarketplace: listing price invalid");
        require(listedItem.quantity >= _buyItemParams.quantity, "TreasureMarketplace: not enough quantity");
        require(listedItem.pricePerItem <= _buyItemParams.maxPricePerItem, "TreasureMarketplace: price increased");

        // Ensure the buyer, the seller, and the collection all agree on the token to be used for the purchase.
        // If the token used for buying/selling has changed since the listing was created, this effectively blocks
        // all the old listings with the old payment tokens from being bought.
        address _paymentTokenForCollection = getPaymentTokenForCollection(_buyItemParams.nftAddress);
        address _paymentTokenForListing = _getPaymentTokenForListing(listedItem);

        require(_paymentTokenForListing == _buyItemParams.paymentToken && _buyItemParams.paymentToken == _paymentTokenForCollection, "TreasureMarketplace: Wrong payment token");

        if(_buyItemParams.usingEth) {
            require(_paymentTokenForListing == address(weth), "TreasureMarketplace: ETH only used with weth collection");
        }

        // Transfer NFT to buyer, also validates owner owns it, and token is approved for trading
        if (tokenApprovals[_buyItemParams.nftAddress] == TokenApprovalStatus.ERC_721_APPROVED) {
            require(_buyItemParams.quantity == 1, "TreasureMarketplace: Cannot buy multiple ERC721");
            IERC721Upgradeable(_buyItemParams.nftAddress).safeTransferFrom(_buyItemParams.owner, _msgSender(), _buyItemParams.tokenId);
        } else if (tokenApprovals[_buyItemParams.nftAddress] == TokenApprovalStatus.ERC_1155_APPROVED) {
            IERC1155Upgradeable(_buyItemParams.nftAddress).safeTransferFrom(_buyItemParams.owner, _msgSender(), _buyItemParams.tokenId, _buyItemParams.quantity, bytes(""));
        } else {
            revert("TreasureMarketplace: token is not approved for trading");
        }

        _payFees(listedItem, _buyItemParams.quantity, _buyItemParams.nftAddress, _msgSender(), _buyItemParams.owner, _buyItemParams.paymentToken, _buyItemParams.usingEth);

        // Announce sale
        emit ItemSold(
            _buyItemParams.owner,
            _msgSender(),
            _buyItemParams.nftAddress,
            _buyItemParams.tokenId,
            _buyItemParams.quantity,
            listedItem.pricePerItem, // this is deleted below in "Deplete or cancel listing"
            _buyItemParams.paymentToken
        );

        // Deplete or cancel listing
        if (listedItem.quantity == _buyItemParams.quantity) {
            delete listings[_buyItemParams.nftAddress][_buyItemParams.tokenId][_buyItemParams.owner];
        } else {
            listings[_buyItemParams.nftAddress][_buyItemParams.tokenId][_buyItemParams.owner].quantity -= _buyItemParams.quantity;
        }

        if(_buyItemParams.usingEth) {
            return _buyItemParams.quantity * listedItem.pricePerItem;
        } else {
            return 0;
        }
    }

    /// @dev pays the fees to the marketplace fee recipient, the collection recipient if one exists, and to the seller of the item.
    /// @param _listOrBid the item that is being purchased/accepted
    /// @param _quantity the quantity of the item being purchased/accepted
    /// @param _collectionAddress the collection to which this item belongs
    function _payFees(ListingOrBid memory _listOrBid, uint256 _quantity, address _collectionAddress, address _from, address _to, address _paymentTokenAddress, bool _usingEth) private {
        IERC20Upgradeable _paymentToken = IERC20Upgradeable(_paymentTokenAddress);

        // Handle purchase price payment
        uint256 _totalPrice = _listOrBid.pricePerItem * _quantity;

        address _collectionFeeRecipient = collectionToCollectionOwnerFee[_collectionAddress].recipient;

        uint256 _protocolFee;
        uint256 _collectionFee;

        if(_collectionFeeRecipient != address(0)) {
            _protocolFee = feeWithCollectionOwner;
            _collectionFee = collectionToCollectionOwnerFee[_collectionAddress].fee;
        } else {
            _protocolFee = fee;
            _collectionFee = 0;
        }

        uint256 _protocolFeeAmount = _totalPrice * _protocolFee / BASIS_POINTS;
        uint256 _collectionFeeAmount = _totalPrice * _collectionFee / BASIS_POINTS;

        _transferAmount(_from, feeReceipient, _protocolFeeAmount, _paymentToken, _usingEth);
        _transferAmount(_from, _collectionFeeRecipient, _collectionFeeAmount, _paymentToken, _usingEth);

        // Transfer rest to seller
        _transferAmount(_from, _to, _totalPrice - _protocolFeeAmount - _collectionFeeAmount, _paymentToken, _usingEth);
    }

    function _transferAmount(address _from, address _to, uint256 _amount, IERC20Upgradeable _paymentToken, bool _usingEth) private {
        if(_amount == 0) {
            return;
        }

        if(_usingEth) {
            (bool _success,) = payable(_to).call{value: _amount}("");
            require(_success, "TreasureMarketplace: Sending eth was not successful");
        } else {
            _paymentToken.safeTransferFrom(_from, _to, _amount);
        }
    }

    function getPaymentTokenForCollection(address _collection) public view returns(address) {
        address _collectionPaymentToken = collectionToPaymentToken[_collection];

        // For backwards compatability. If a collection payment wasn't set at the collection level, it was using the payment token.
        return _collectionPaymentToken == address(0) ? address(paymentToken) : _collectionPaymentToken;
    }

    function _getPaymentTokenForListing(ListingOrBid memory listedItem) private view returns(address) {
        // For backwards compatability. If a listing has no payment token address, it was using the original, default payment token.
        return listedItem.paymentTokenAddress == address(0) ? address(paymentToken) : listedItem.paymentTokenAddress;
    }

    // Owner administration ////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Updates the fee amount which is collected during sales, for both collections with and without owner specific fees.
    /// @dev    This is callable only by the owner. Both fees may not exceed MAX_FEE
    /// @param  _newFee the updated fee amount is basis points
    function setFee(uint256 _newFee, uint256 _newFeeWithCollectionOwner) public onlyRole(TREASURE_MARKETPLACE_ADMIN_ROLE) {
        require(_newFee <= MAX_FEE && _newFeeWithCollectionOwner <= MAX_FEE, "TreasureMarketplace: max fee");

        fee = _newFee;
        feeWithCollectionOwner = _newFeeWithCollectionOwner;

        emit UpdateFee(_newFee);
        emit UpdateFeeWithCollectionOwner(_newFeeWithCollectionOwner);
    }

    /// @notice Updates the fee amount which is collected during sales fro a specific collection
    /// @dev    This is callable only by the owner
    /// @param  _collectionAddress The collection in question. This must be whitelisted.
    /// @param _collectionOwnerFee The fee and recipient for the collection. If the 0 address is passed as the recipient, collection specific fees will not be collected.
    function setCollectionOwnerFee(address _collectionAddress, CollectionOwnerFee calldata _collectionOwnerFee) external onlyRole(TREASURE_MARKETPLACE_ADMIN_ROLE) {
        require(tokenApprovals[_collectionAddress] == TokenApprovalStatus.ERC_1155_APPROVED
            || tokenApprovals[_collectionAddress] == TokenApprovalStatus.ERC_721_APPROVED, "TreasureMarketplace: Collection is not approved");
        require(_collectionOwnerFee.fee <= MAX_COLLECTION_FEE, "TreasureMarketplace: Collection fee too high");

        // The collection recipient can be the 0 address, meaning we will treat this as a collection with no collection owner fee.
        collectionToCollectionOwnerFee[_collectionAddress] = _collectionOwnerFee;

        emit UpdateCollectionOwnerFee(_collectionAddress, _collectionOwnerFee.recipient, _collectionOwnerFee.fee);
    }

    /// @notice Updates the fee recipient which receives fees during sales
    /// @dev    This is callable only by the owner.
    /// @param  _newFeeRecipient the wallet to receive fees
    function setFeeRecipient(address _newFeeRecipient) public onlyRole(TREASURE_MARKETPLACE_ADMIN_ROLE) {
        require(_newFeeRecipient != address(0), "TreasureMarketplace: cannot set 0x0 address");
        feeReceipient = _newFeeRecipient;
        emit UpdateFeeRecipient(_newFeeRecipient);
    }

    /// @notice Sets a token as an approved kind of NFT or as ineligible for trading
    /// @dev    This is callable only by the owner.
    /// @param  _nft    address of the NFT to be approved
    /// @param  _status the kind of NFT approved, or NOT_APPROVED to remove approval
    function setTokenApprovalStatus(address _nft, TokenApprovalStatus _status, address _paymentToken) external onlyRole(TREASURE_MARKETPLACE_ADMIN_ROLE) {
        if (_status == TokenApprovalStatus.ERC_721_APPROVED) {
            require(IERC165Upgradeable(_nft).supportsInterface(INTERFACE_ID_ERC721), "TreasureMarketplace: not an ERC721 contract");
        } else if (_status == TokenApprovalStatus.ERC_1155_APPROVED) {
            require(IERC165Upgradeable(_nft).supportsInterface(INTERFACE_ID_ERC1155), "TreasureMarketplace: not an ERC1155 contract");
        }

        require(_paymentToken != address(0) && (_paymentToken == address(weth) || _paymentToken == address(paymentToken)), "TreasureMarketplace: Payment token not supported");

        tokenApprovals[_nft] = _status;

        collectionToPaymentToken[_nft] = _paymentToken;
        emit TokenApprovalStatusUpdated(_nft, _status, _paymentToken);
    }

    function setWeth(address _wethAddress) external onlyRole(TREASURE_MARKETPLACE_ADMIN_ROLE) {
        require(address(weth) == address(0), "WETH address already set");

        weth = IERC20Upgradeable(_wethAddress);
    }

    function toggleAreBidsActive() external onlyRole(TREASURE_MARKETPLACE_ADMIN_ROLE) {
        areBidsActive = !areBidsActive;
    }

    /// @notice Pauses the marketplace, creatisgn and executing listings is paused
    /// @dev    This is callable only by the owner. Canceling listings is not paused.
    function pause() external onlyRole(TREASURE_MARKETPLACE_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses the marketplace, all functionality is restored
    /// @dev    This is callable only by the owner.
    function unpause() external onlyRole(TREASURE_MARKETPLACE_ADMIN_ROLE) {
        _unpause();
    }

    modifier whenBiddingActive() {
        require(areBidsActive, "TreasureMarketplace: Bidding is not active");

        _;
    }
}

struct BuyItemParams {
    /// which token contract holds the offered token
    address nftAddress;
    /// the identifier for the token to be bought
    uint256 tokenId;
    /// current owner of the item(s) to be bought
    address owner;
    /// how many of this token identifier to be bought (or 1 for a ERC-721 token)
    uint64 quantity;
    /// the maximum price (in units of the paymentToken) for each token offered
    uint128 maxPricePerItem;
    /// the payment token to be used
    address paymentToken;
    /// indicates if the user is purchasing this item with eth.
    bool usingEth;
}

struct AcceptBidParams {
    // Which token contract holds the given tokens
    address nftAddress;
    // The token id being given
    uint256 tokenId;
    // The user who created the bid initially
    address bidder;
    // The quantity of items being supplied to the bidder
    uint64 quantity;
    // The price per item that the bidder is offering
    uint128 pricePerItem;
    /// the payment token to be used
    address paymentToken;
}

struct CancelBidParams {
    BidType bidType;
    address nftAddress;
    uint256 tokenId;
}

enum BidType {
    TOKEN,
    COLLECTION
}