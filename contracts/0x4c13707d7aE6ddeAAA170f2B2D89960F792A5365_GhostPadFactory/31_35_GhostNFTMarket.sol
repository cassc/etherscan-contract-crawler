// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import './interfaces/IERC721Ownable.sol';
import '../node_modules/@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../node_modules/@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import './interfaces/ICollectionWhitelistChecker.sol';
import '../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './libraries/AdminWhitelistable.sol';
import './libraries/PayReward.sol';

contract GhostNFTMarket is ERC721Holder, AdminWhitelistable, ReentrancyGuard, PayReward {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    using SafeERC20 for IERC20;

    enum CollectionStatus {
        Pending,
        Open,
        Close
    }

    uint256 public constant TOTAL_MAX_FEE = 10000; // 100% of a sale

    address public treasury;
    uint256 public minAskPrice; // in wei
    uint256 public maxAskPrice; // in wei

    uint256 public _treasuryFee = 250;

    EnumerableSet.AddressSet private _collectionAddressSet;
    address[] private _supportedCollections;

    mapping(address => mapping(uint256 => Ask)) private _askDetails; // Ask details (price + seller address) for a given collection and a tokenId
    mapping(address => EnumerableSet.UintSet) private _askTokenIds; // Set of tokenIds for a collection
    mapping(address => Collection) private _collections; // Details about the collections
    mapping(address => mapping(address => EnumerableSet.UintSet)) private _tokenIdsOfSellerForCollection;

    mapping(address => mapping(uint256 => address)) private _tokenCreators; // Details about token creators

    struct Ask {
        address seller; // address of the seller
        uint256 price; // price of the token
        address msgSender; // address of the msgSender
    }

    struct Collection {
        CollectionStatus status; // status of the collection
        address creatorAddress; // address of the creator
        address whitelistChecker; // whitelist checker (if not set --> 0x00)
        uint256 creatorFee; // creator fee (100 = 1%, 500 = 5%, 5 = 0.05%)
        uint256 refererFee; // referer fee (100 = 1%, 500 = 5%, 5 = 0.05%)
    }

    event AskNew(
        address indexed collection,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 askPrice,
        address msgSender
    );
    event AskCancel(address indexed collection, address indexed seller, uint256 indexed tokenId);
    event AskUpdate(
        address indexed collection,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 askPrice,
        address msgSender
    );

    // Collection is closed for trading and new listings
    event CollectionClose(address indexed collection);

    // New collection is added
    event CollectionNew(
        address indexed collection,
        address indexed creator,
        address indexed whitelistChecker,
        uint256 creatorFee,
        uint256 refererFee
    );

    // Existing collection is updated
    event CollectionUpdate(
        address indexed collection,
        address indexed creator,
        address indexed whitelistChecker,
        uint256 creatorFee,
        uint256 refererFee
    );

    event UpdateTreasury(address indexed treasury);
    event UpdateMinAndMaxAskPrices(uint256 minimumAskPrice, uint256 maximumAskPrice);

    // Recover NFT tokens sent by accident
    event NonFungibleTokenRecovery(address indexed token, uint256 indexed tokenId);

    // Recover ERC20 tokens sent by accident
    event TokenRecovery(address indexed token, uint256 amount);

    // Ask order is matched by a trade
    event Trade(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 askPrice,
        uint256 netPrice
    );

    /**
     * @notice Constructor
     * @param _whitelist : address of the ghost admin whitelist
     * @param _treasury: address of the treasury
     * @param _weth: WETH address
     * @param _minAskPrice: minimum ask price
     * @param _maxAskPrice: maximum ask price
     */
    constructor(address _whitelist, address _treasury, address _weth, uint256 _minAskPrice, uint256 _maxAskPrice) {
        _updateAdminWhitelist(_whitelist);
        _updateTreasury(_treasury);
        _updateWETH(_weth);
        _updateMinMaxAsk(_minAskPrice, _maxAskPrice);
    }

    /**
     * @notice Buy token with ETH by matching the price of an existing ask order
     * @param _collection: contract address of the NFT
     * @param _tokenId: tokenId of the NFT purchased
     * @param _referer: referer of buyer
     * @param _to: nft sending target
     */
    function buyTokenUsingETH(
        address _collection,
        uint256 _tokenId,
        address _referer,
        address _to
    ) external payable nonReentrant {
        _WETHDeposit();
        _buyToken(_collection, _tokenId, msg.value, _referer, _to);
    }

    /**
     * @notice Buy token with WETH by matching the price of an existing ask order
     * @param _collection: contract address of the NFT
     * @param _tokenId: tokenId of the NFT purchased
     * @param _price: price (must be equal to the askPrice set by the seller)
     * @param _referer: referer of buyer
     * @param _to: nft sending target
     */
    function buyTokenUsingWETH(
        address _collection,
        uint256 _tokenId,
        uint256 _price,
        address _referer,
        address _to
    ) external nonReentrant {
        _WETHTransferFrom(msg.sender, address(this), _price);
        _buyToken(_collection, _tokenId, _price, _referer, _to);
    }

    function _checkTokenListed(address _collection, uint256 _tokenId, address _seller) internal view {
        require(
            _tokenIdsOfSellerForCollection[_seller][_collection].contains(_tokenId),
            'GhostNFTMarket : Token not listed'
        );
    }

    /**
     * @notice Cancel existing ask order
     * @param _collection: contract address of the NFT
     * @param _tokenId: tokenId of the NFT
     */
    function cancelAskOrder(address _collection, uint256 _tokenId) external nonReentrant {
        // Verify the sender has listed it
        _checkTokenListed(_collection, _tokenId, msg.sender);
        // Adjust the information
        _tokenIdsOfSellerForCollection[msg.sender][_collection].remove(_tokenId);
        delete _askDetails[_collection][_tokenId];
        _askTokenIds[_collection].remove(_tokenId);

        // Transfer the NFT back to the user
        IERC721Ownable(_collection).transferFrom(address(this), address(msg.sender), _tokenId);

        // Emit event
        emit AskCancel(_collection, msg.sender, _tokenId);
    }

    function _checkPriceRange(uint256 _ask) internal view {
        require(_ask >= minAskPrice && _ask <= maxAskPrice, 'GhostNFTMarket : Price not within range');
    }

    function _checkCollectionOpen(address _collection) internal view {
        require(_collections[_collection].status == CollectionStatus.Open, 'GhostNFTMarket : Not for listing');
    }

    /**
     * @notice Create ask order
     * @param _collection: contract address of the NFT
     * @param _tokenId: tokenId of the NFT
     * @param _askPrice: price for listing (in wei)
     * @param _seller: address of seller
     */
    function createAskOrder(
        address _collection,
        uint256 _tokenId,
        uint256 _askPrice,
        address _seller
    ) external nonReentrant {
        _checkPriceRange(_askPrice); // Verify price is not too low/high
        _checkCollectionOpen(_collection); // Verify collection is accepted

        // Verify token has restriction
        require(_isClearCollectionWhitelist(_collection, _tokenId), 'GhostNFTMarket : tokenId not eligible');

        // Transfer NFT to this contract
        IERC721Ownable(_collection).safeTransferFrom(address(msg.sender), address(this), _tokenId);

        // Adjust the information
        _tokenIdsOfSellerForCollection[_seller][_collection].add(_tokenId);
        _askDetails[_collection][_tokenId] = Ask({msgSender: msg.sender, price: _askPrice, seller: _seller});

        // Add tokenId to the askTokenIds set
        _askTokenIds[_collection].add(_tokenId);

        // Emit event
        emit AskNew(_collection, _seller, _tokenId, _askPrice, msg.sender);
    }

    /**
     * @notice Modify existing ask order
     * @param _collection: contract address of the NFT
     * @param _tokenId: tokenId of the NFT
     * @param _newPrice: new price for listing (in wei)
     * @param _seller: address of seller
     */
    function modifyAskOrder(
        address _collection,
        uint256 _tokenId,
        uint256 _newPrice,
        address _seller
    ) external nonReentrant {
        // Verify new price is not too low/high
        _checkPriceRange(_newPrice);

        // Verify collection is accepted
        _checkCollectionOpen(_collection);

        // Verify the sender has listed it
        _checkTokenListed(_collection, _tokenId, _seller);

        // Adjust the information
        _askDetails[_collection][_tokenId].price = _newPrice;

        // Emit event
        emit AskUpdate(_collection, _seller, _tokenId, _newPrice, msg.sender);
    }

    function _checkCreatorFee(uint256 _creatorFee, address _creator) internal pure {
        require(
            _creatorFee == 0 || (_creatorFee != 0 && _creator != address(0)),
            'GhostNFTMarket: Creator parameters incorrect'
        );
    }

    function _checkFee(uint256 _a, uint256 _b, uint256 _c) internal pure {
        require(_a + _b + _c <= TOTAL_MAX_FEE, 'GhostNFTMarket: Sum of fee must inferior to TOTAL_MAX_FEE');
    }

    /**
     * @notice Add a new collection
     * @param _collection: collection address
     * @param _creator: creator address (must be 0x00 if none)
     * @param _whitelistChecker: whitelist checker (for additional restrictions, must be 0x00 if none)
     * @param _creatorFee: creator fee (100 = 1%, 500 = 5%, 5 = 0.05%, 0 if creator is 0x00)
     * @param _refererFee: referer fee (100 = 1%, 500 = 5%, 5 = 0.05%, 0 if creator is 0x00)
     * @dev Callable by admin
     */
    function addCollection(
        address _collection,
        address _creator,
        address _whitelistChecker,
        uint256 _creatorFee,
        uint256 _refererFee
    ) external {
        _addCollection(_collection, _creator, _whitelistChecker, _creatorFee, _refererFee);
    }

    function _addCollection(
        address _collection,
        address _creator,
        address _whitelistChecker,
        uint256 _creatorFee,
        uint256 _refererFee
    ) internal {
        require(!_collectionAddressSet.contains(_collection), 'GhostNFTMarket: Collection already listed');
        require(IERC721Ownable(_collection).supportsInterface(0x80ac58cd), 'GhostNFTMarket: Not ERC721');
        require(
            IERC721Ownable(_collection).owner() == msg.sender || isInWhitelist(msg.sender),
            'GhostNFTMarket: Not collection owner'
        );

        _checkCreatorFee(_creatorFee, _creator);
        _checkFee(_treasuryFee, _creatorFee, _refererFee);

        _collectionAddressSet.add(_collection);
        _supportedCollections.push(_collection);

        _collections[_collection] = Collection({
            status: CollectionStatus.Open,
            creatorAddress: _creator,
            whitelistChecker: _whitelistChecker,
            creatorFee: _creatorFee,
            refererFee: _refererFee
        });

        emit CollectionNew(_collection, _creator, _whitelistChecker, _creatorFee, _refererFee);
    }

    /**
     * @notice Get all collections with supported this nft market
     */
    function getCollections() external view returns (address[] memory) {
        return _supportedCollections;
    }

    /**
     * @notice Allows the admin to close collection for trading and new listing
     * @param _collection: collection address
     * @dev Callable by admin
     */
    function closeCollectionForTradingAndListing(address _collection) external onlyAdminWhitelist {
        require(_collectionAddressSet.contains(_collection), 'GhostNFTMarket: Collection not listed');

        _collections[_collection].status = CollectionStatus.Close;
        _collectionAddressSet.remove(_collection);

        emit CollectionClose(_collection);
    }

    /**
     * @notice Modify collection characteristics
     * @param _collection: collection address
     * @param _creator: creator address (must be 0x00 if none)
     * @param _whitelistChecker: whitelist checker (for additional restrictions, must be 0x00 if none)
     * @param _creatorFee: creator fee (100 = 1%, 500 = 5%, 5 = 0.05%, 0 if creator is 0x00)
     * @param _refererFee: referer fee (100 = 1%, 500 = 5%, 5 = 0.05%, 0 if creator is 0x00)
     * @dev Callable by admin
     */
    function modifyCollection(
        address _collection,
        address _creator,
        address _whitelistChecker,
        uint256 _creatorFee,
        uint256 _refererFee
    ) external {
        require(_collectionAddressSet.contains(_collection), 'GhostNFTMarket : Collection not listed');
        require(
            IERC721Ownable(_collection).owner() == msg.sender || isInWhitelist(msg.sender),
            'GhostNFTMarket: Not collection owner'
        );
        _checkCreatorFee(_creatorFee, _creator);
        _checkFee(_treasuryFee, _creatorFee, _refererFee);
        _collections[_collection] = Collection({
            status: CollectionStatus.Open,
            creatorAddress: _creator,
            whitelistChecker: _whitelistChecker,
            creatorFee: _creatorFee,
            refererFee: _refererFee
        });

        emit CollectionUpdate(_collection, _creator, _whitelistChecker, _creatorFee, _refererFee);
    }

    /**
     * @notice Allows the admin to update minimum and maximum prices for a token (in wei)
     * @param _min: minimum ask price
     * @param _max: maximum ask price
     * @dev Callable by admin
     */
    function _updateMinMaxAsk(uint256 _min, uint256 _max) internal {
        require(_min > 0, 'GhostNFTMarket : _minAskPrice > 0');
        require(_min < _max, 'GhostNFTMarket : _minAskPrice < _maxAskPrice');
        minAskPrice = _min;
        maxAskPrice = _max;
        emit UpdateMinAndMaxAskPrices(_min, _max);
    }

    function updateMinMaxAsk(uint256 _min, uint256 _max) external onlyAdminWhitelist {
        return _updateMinMaxAsk(_min, _max);
    }

    /**
     * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverFungibleTokens(address _token) external onlyOwner {
        require(_token != WETH, 'GhostNFTMarket : Cannot recover WETH');
        uint256 amountToRecover = IERC20(_token).balanceOf(address(this));
        require(amountToRecover != 0, 'GhostNFTMarket : No token to recover');
        IERC20(_token).safeTransfer(address(msg.sender), amountToRecover);
        emit TokenRecovery(_token, amountToRecover);
    }

    /**
     * @notice Allows the owner to recover NFTs sent to the contract by mistake
     * @param _token: NFT token address
     * @param _tokenId: tokenId
     * @dev Callable by owner
     */
    function recoverNonFungibleToken(address _token, uint256 _tokenId) external onlyOwner nonReentrant {
        require(!_askTokenIds[_token].contains(_tokenId), 'GhostNFTMarket : NFT not recoverable');
        IERC721Ownable(_token).safeTransferFrom(address(this), address(msg.sender), _tokenId);
        emit NonFungibleTokenRecovery(_token, _tokenId);
    }

    /**
     * @notice Set treasury address
     * @param _newTreasury: address of the treasury
     */
    function _updateTreasury(address _newTreasury) internal {
        require(_newTreasury != address(0), 'GhostNFTMarket: Treasury address cannot be zero');
        treasury = _newTreasury;
        emit UpdateTreasury(_newTreasury);
    }

    function updateTreasury(address _newTreasury) external onlyAdminWhitelist {
        return _updateTreasury(_newTreasury);
    }

    /**
     * @notice Check asks for an array of tokenIds in a collection
     * @param collection: address of the collection
     * @param tokenIds: array of tokenId
     */
    function viewAsksByCollectionAndTokenIds(
        address collection,
        uint256[] calldata tokenIds
    ) external view returns (bool[] memory statuses, Ask[] memory askInfo) {
        uint256 length = tokenIds.length;

        statuses = new bool[](length);
        askInfo = new Ask[](length);

        for (uint256 i = 0; i < length; i++) {
            if (_askTokenIds[collection].contains(tokenIds[i])) {
                statuses[i] = true;
            } else {
                statuses[i] = false;
            }

            askInfo[i] = _askDetails[collection][tokenIds[i]];
        }

        return (statuses, askInfo);
    }

    /**
     * @notice View ask orders for a given collection across all sellers
     * @param collection: address of the collection
     * @param cursor: cursor
     * @param size: size of the response
     */
    function viewAsksByCollection(
        address collection,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory tokenIds, Ask[] memory askInfo, uint256) {
        uint256 length = size;

        if (length > _askTokenIds[collection].length() - cursor) {
            length = _askTokenIds[collection].length() - cursor;
        }

        tokenIds = new uint256[](length);
        askInfo = new Ask[](length);

        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = _askTokenIds[collection].at(cursor + i);
            askInfo[i] = _askDetails[collection][tokenIds[i]];
        }

        return (tokenIds, askInfo, cursor + length);
    }

    /**
     * @notice View ask orders for a given collection and a seller
     * @param collection: address of the collection
     * @param seller: address of the seller
     * @param cursor: cursor
     * @param size: size of the response
     */
    function viewAsksByCollectionAndSeller(
        address collection,
        address seller,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory tokenIds, Ask[] memory askInfo, uint256) {
        uint256 length = size;

        if (length > _tokenIdsOfSellerForCollection[seller][collection].length() - cursor) {
            length = _tokenIdsOfSellerForCollection[seller][collection].length() - cursor;
        }

        tokenIds = new uint256[](length);
        askInfo = new Ask[](length);

        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = _tokenIdsOfSellerForCollection[seller][collection].at(cursor + i);
            askInfo[i] = _askDetails[collection][tokenIds[i]];
        }

        return (tokenIds, askInfo, cursor + length);
    }

    /*
     * @notice View addresses and details for all the collections available for trading
     * @param cursor: cursor
     * @param size: size of the response
     */
    function viewCollections(
        uint256 cursor,
        uint256 size
    ) external view returns (address[] memory collectionAddresses, Collection[] memory collectionDetails, uint256) {
        uint256 length = size;

        if (length > _collectionAddressSet.length() - cursor) {
            length = _collectionAddressSet.length() - cursor;
        }

        collectionAddresses = new address[](length);
        collectionDetails = new Collection[](length);

        for (uint256 i = 0; i < length; i++) {
            collectionAddresses[i] = _collectionAddressSet.at(cursor + i);
            collectionDetails[i] = _collections[collectionAddresses[i]];
        }

        return (collectionAddresses, collectionDetails, cursor + length);
    }

    /**
     * @notice Calculate price and associated fees for a collection
     * @param collection: address of the collection
     * @param price: listed price
     */
    function calculatePriceAndFeesForCollection(
        address collection,
        uint256 price
    ) external view returns (uint256 netPrice, uint256 treasureFee, uint256 creatorFee, uint256 refererFee) {
        if (_collections[collection].status != CollectionStatus.Open) {
            return (0, 0, 0, 0);
        }

        return (_calculatePriceAndFeesForCollection(collection, price));
    }

    /**
     * @notice Checks if an array of tokenIds can be listed
     * @param _collection: address of the collection
     * @param _tokenIds: array of tokenIds
     * @dev if collection is not for trading, it returns array of bool with false
     */
    function canTokensBeListed(
        address _collection,
        uint256[] calldata _tokenIds
    ) external view returns (bool[] memory listingStatuses) {
        listingStatuses = new bool[](_tokenIds.length);

        if (_collections[_collection].status != CollectionStatus.Open) {
            return listingStatuses;
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            listingStatuses[i] = _isClearCollectionWhitelist(_collection, _tokenIds[i]);
        }

        return listingStatuses;
    }

    /**
     * @notice Buy token by matching the price of an existing ask order
     * @param _collection: contract address of the NFT
     * @param _tokenId: tokenId of the NFT purchased
     * @param _price: price (must match the askPrice from the seller)
     */
    function _buyToken(
        address _collection,
        uint256 _tokenId,
        uint256 _price,
        address _refererAddress,
        address _to
    ) internal {
        _checkCollectionOpen(_collection);
        require(_askTokenIds[_collection].contains(_tokenId), 'Buy: Not for sale');

        Ask memory askOrder = _askDetails[_collection][_tokenId];
        // Front-running protection
        require(_price == askOrder.price, 'Buy: Incorrect price');
        require(msg.sender != askOrder.seller, 'Buy: Buyer cannot be seller');

        // Calculate the net price (collected by seller), trading fee (collected by treasury), creator fee (collected by creator)
        (
            uint256 netPrice,
            uint256 treasureFee,
            uint256 creatorFee,
            uint256 refererFee
        ) = _calculatePriceAndFeesForCollection(_collection, _price);

        // Update storage information
        _tokenIdsOfSellerForCollection[askOrder.seller][_collection].remove(_tokenId);
        delete _askDetails[_collection][_tokenId];
        _askTokenIds[_collection].remove(_tokenId);

        _payReward(askOrder.seller, netPrice);
        _payReward(treasury, treasureFee);
        _payReward(_collections[_collection].creatorAddress, creatorFee);
        _payReward(_refererAddress, refererFee);

        // Transfer NFT to buyer
        IERC721Ownable(_collection).safeTransferFrom(address(this), _to, _tokenId);

        // Emit event
        emit Trade(_collection, _tokenId, askOrder.seller, _to, _price, netPrice);
    }

    /**
     * @notice Calculate price and associated fees for a collection
     * @param _collection: address of the collection
     * @param _askPrice: listed price
     */
    function _calculatePriceAndFeesForCollection(
        address _collection,
        uint256 _askPrice
    ) internal view returns (uint256 netPrice, uint256 treasureFee, uint256 creatorFee, uint256 refererFee) {
        treasureFee = (_askPrice * _treasuryFee) / 10000;
        creatorFee = (_askPrice * _collections[_collection].creatorFee) / 10000;
        refererFee = (_askPrice * _collections[_collection].refererFee) / 10000;

        netPrice = _askPrice - treasureFee - creatorFee - refererFee;

        return (netPrice, treasureFee, creatorFee, refererFee);
    }

    /**
     * @notice Checks if a token can be listed
     * @param _collection: address of the collection
     * @param _tokenId: tokenId
     */
    function _isClearCollectionWhitelist(address _collection, uint256 _tokenId) internal view returns (bool) {
        address whitelistCheckerAddress = _collections[_collection].whitelistChecker;
        return
            (whitelistCheckerAddress == address(0)) ||
            ICollectionWhitelistChecker(whitelistCheckerAddress).canList(_tokenId);
    }

    function emitTradeFromPadFactory(
        address _collection,
        uint256[] calldata _tokenIds,
        uint256 _price,
        address _seller,
        address _referer,
        address _to
    ) external onlyAdminWhitelist {
        _checkPriceRange(_price); // Verify price is not too low/high
        _checkCollectionOpen(_collection); // Verify collection is accepted

        uint256 _length = _tokenIds.length;

        // Calculate the net price (collected by seller), trading fee (collected by treasury), creator fee (collected by creator)
        (
            uint256 netPrice,
            uint256 treasureFee,
            uint256 creatorFee,
            uint256 refererFee
        ) = _calculatePriceAndFeesForCollection(_collection, _price);

        // Verify token has restriction
        for (uint256 index = 0; index < _length; index++) {
            require(
                _isClearCollectionWhitelist(_collection, _tokenIds[index]),
                'GhostNFTMarket : tokenId not eligible'
            );
            // event emit
            emit AskNew(_collection, _seller, _tokenIds[index], _price, msg.sender);
            emit Trade(_collection, _tokenIds[index], _seller, _to, _price, netPrice);
        }

        // Update storage information
        _payReward(_seller, netPrice * _length);
        _payReward(treasury, treasureFee * _length);
        _payReward(_collections[_collection].creatorAddress, creatorFee * _length);
        _payReward(_referer, refererFee * _length);
    }
}