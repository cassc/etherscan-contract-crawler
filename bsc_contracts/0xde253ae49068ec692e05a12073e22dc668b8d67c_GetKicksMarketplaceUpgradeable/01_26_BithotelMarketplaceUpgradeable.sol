// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../token/ERC721/IGetKicksCollection.sol";
import "./ERC721MarketplaceUpgradeable.sol";

contract GetKicksMarketplaceUpgradeable is
    Initializable,
    AccessControlUpgradeable,
    ERC721HolderUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ERC721MarketplaceUpgradeable for ERC721MarketplaceUpgradeable.Category;
    using ERC721MarketplaceUpgradeable for ERC721MarketplaceUpgradeable.Status;
    using ERC721MarketplaceUpgradeable for ERC721MarketplaceUpgradeable.ERC721Listing;
    using ERC721MarketplaceUpgradeable for ERC721MarketplaceUpgradeable.ListingListItem;
    using ERC721MarketplaceUpgradeable for ERC721MarketplaceUpgradeable.AppStorage;

    CountersUpgradeable.Counter private _sNextERC721ListingId;
    ERC721MarketplaceUpgradeable.AppStorage private _storage;

    uint256 private constant _MAX = ~uint256(0);
    uint16 internal constant _DIV = 10000;

    address private _sTimelockController;
    bool public initializerRan;
    bool private _isListingFeeEnabled;
    uint256 private _sListingFeeInWei;
    uint256 private _sListingTax;
    IERC20Upgradeable private _token;
    address private _tokenAddress;
    IERC20Upgradeable private _kick;
    address private _kickAddress;
    address private _wallet;
    address private _burnAddress;
    address private _thisAddress;

    address[] private _includedErc721TokenAddresses;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant TIMELOCK_CONTROLLER_ROLE = keccak256("TIMELOCK_CONTROLLER_ROLE");
    bytes32 public constant INCLUDED_COLLECTIONS = keccak256("INCLUDED_COLLECTIONS");

    address[] private _includedCollections;

    mapping(address => uint256) private _includedCollectionIndex;

    event TimelockChanged(address newAddress);
    event TokenChanged(address newToken);
    event KickChanged(address newKick);
    event KickBurned(address from, address to, uint256 amount);
    event IncludedErc721TokenAddressesAdded(address[] addresses, ERC721MarketplaceUpgradeable.Category[] category);
    event IncludedErc721TokenAddressesRemoved(address[] addresses);

    event ERC721ListingAdd(
        uint256 indexed listingId,
        address indexed seller,
        address erc721TokenAddress,
        uint256 erc721TokenId,
        ERC721MarketplaceUpgradeable.Category indexed category,
        uint256 priceInWei,
        uint256 timeAdded,
        ERC721MarketplaceUpgradeable.Status status
    );

    event ERC721ExecutedListing(
        uint256 indexed listingId,
        address indexed seller,
        address buyer,
        address erc721TokenAddress,
        uint256 erc721TokenId,
        ERC721MarketplaceUpgradeable.Category category,
        uint256 priceInWei,
        uint256 timeExecuted,
        ERC721MarketplaceUpgradeable.Status status
    );
    event ERC721ListingCancelled(
        uint256 indexed listingId,
        ERC721MarketplaceUpgradeable.Category category,
        uint256 timeCancelled,
        ERC721MarketplaceUpgradeable.Status status
    );
    event ERC721ListingRemoved(
        uint256 indexed listingId,
        ERC721MarketplaceUpgradeable.Category category,
        uint256 timeRemoved,
        ERC721MarketplaceUpgradeable.Status status
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {
        // solhint-disable-previous-line no-empty-blocks
    }

    function initialize(
        address mKick,
        address mToken,
        address mOwner,
        address mWallet,
        address mTimelockController,
        uint256 mListingTax
    ) public initializer {
        __AccessControl_init();
        __ERC721Holder_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __GetKicksMarketplace_init_unchained(mKick, mToken, mOwner, mWallet, mTimelockController, mListingTax);
    }

    function __GetKicksMarketplace_init_unchained(
        address mKick,
        address mToken,
        address mOwner,
        address mWallet,
        address mTimelockController,
        uint256 mListingTax
    ) internal onlyInitializing {
        require(mKick != address(0), "GetKicksMarketplace: kick token is the zero address");
        require(mToken != address(0), "GetKicksMarketplace: token is the zero address");
        require(mOwner != address(0), "GetKicksMarketplace: owner is the zero address");
        require(mWallet != address(0), "GetKicksMarketplace: wallet is the zero address");
        require(mTimelockController != address(0), "GetKicksMarketplace: timelock controller is the zero address");

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, mOwner);
        _grantRole(TIMELOCK_CONTROLLER_ROLE, mTimelockController);
        _grantRole(UPGRADER_ROLE, _msgSender());

        _kickAddress = mKick;
        _kick = IERC20Upgradeable(mKick);
        _tokenAddress = mToken;
        _token = IERC20Upgradeable(mToken);
        _wallet = mWallet;
        _sTimelockController = mTimelockController;
        _burnAddress = address(0x000000000000000000000000000000000000dEaD);
        _thisAddress = address(this);
        _isListingFeeEnabled = false;
        _sListingFeeInWei = 0; // 0 KICK for each listing
        _sListingTax = mListingTax;
        initializerRan = true;
    }

    function version() external pure virtual returns (string memory) {
        return "1.0";
    }

    function getChainId() external view virtual returns (uint256) {
        return block.chainid;
    }

    function getERC721Listing(uint256 mListingId)
        external
        view
        virtual
        returns (ERC721MarketplaceUpgradeable.ERC721Listing memory)
    {
        return _storage.erc721Listings[mListingId];
    }

    function bulkAddIncludedCollections(
        address[] memory erc721TokenAddresses,
        ERC721MarketplaceUpgradeable.Category[] memory categories
    ) external virtual nonReentrant onlyRole(TIMELOCK_CONTROLLER_ROLE) {
        require(erc721TokenAddresses.length > 0, "GetKicksMarketplace: empty addresses");
        require(
            categories.length == erc721TokenAddresses.length,
            "GetKicksMarketplace: categories array length mismatched"
        );
        for (uint256 i = 0; i < erc721TokenAddresses.length; i++) {
            address included = erc721TokenAddresses[i];
            _addIncludedCollection(included, categories[i]);
        }
        emit IncludedErc721TokenAddressesAdded(erc721TokenAddresses, categories);
    }

    function bulkRemoveIncludedCollections(address[] memory erc721TokenAddresses)
        external
        virtual
        nonReentrant
        onlyRole(TIMELOCK_CONTROLLER_ROLE)
    {
        require(erc721TokenAddresses.length > 0, "GetKicksMarketplace: empty addresses");
        for (uint256 i = 0; i < erc721TokenAddresses.length; i++) {
            address excluded = erc721TokenAddresses[i];
            _removeIncludedCollection(excluded);
        }
        emit IncludedErc721TokenAddressesRemoved(erc721TokenAddresses);
    }

    function setListingFeeEnabled(bool value) external nonReentrant onlyRole(TIMELOCK_CONTROLLER_ROLE) {
        require(_isListingFeeEnabled != value, "GetKicksMarketplace: listingFeeEnabled already set");
        _isListingFeeEnabled = value;
    }

    function changeListingFeeInWei(uint256 newListingFeeInWei)
        external
        nonReentrant
        onlyRole(TIMELOCK_CONTROLLER_ROLE)
    {
        require(newListingFeeInWei != _sListingFeeInWei, "GetKicksMarketplace: _sListingFeeInWei already set");
        _sListingFeeInWei = newListingFeeInWei;
    }

    function changeKick(address mKick) external nonReentrant onlyRole(TIMELOCK_CONTROLLER_ROLE) {
        require(mKick != address(0), "GetKicksMarketplace: kick is the zero address");
        _kickAddress = mKick;
        _kick = IERC20Upgradeable(mKick);
        emit KickChanged(mKick);
    }

    function changeToken(address mToken) external nonReentrant onlyRole(TIMELOCK_CONTROLLER_ROLE) {
        require(mToken != address(0), "GetKicksMarketplace: token is the zero address");
        _token = IERC20Upgradeable(mToken);
        _tokenAddress = mToken;
        emit TokenChanged(mToken);
    }

    // Collections external functions
    function setCollectionController(address erc721TokenAddress, address newController)
        external
        virtual
        nonReentrant
        onlyRole(TIMELOCK_CONTROLLER_ROLE)
    {
        require(erc721TokenAddress != address(0), "GetKicksMarketplace: ERC721 is the zero address");

        require(newController != address(0), "GetKicksMarketplace: controller is the zero address");

        IGetKicksCollection collection = IGetKicksCollection(erc721TokenAddress);

        require(
            collection.controller() == _thisAddress,
            "GetKicksMarketplace: marketplace doesn't control GetKicksCollection"
        );
        collection.setController(newController);
    }

    function addERC721Listing(
        address erc721TokenAddress,
        uint256 erc721TokenId,
        uint256 priceInWei
    ) external virtual whenNotPaused nonReentrant {
        address owner = _msgSender();
        _beforeAddERC721Listing(erc721TokenAddress, erc721TokenId, priceInWei, owner);
        _sNextERC721ListingId.increment();
        uint256 listingId = _sNextERC721ListingId.current();

        uint256 oldListingId = _storage.erc721TokenToListingId[erc721TokenAddress][erc721TokenId][owner];
        if (oldListingId != 0) {
            _storage.cancelERC721Listing(oldListingId, owner);
        }
        _storage.erc721TokenToListingId[erc721TokenAddress][erc721TokenId][owner] = listingId;
        ERC721MarketplaceUpgradeable.Category category = getERC721Category(erc721TokenAddress, erc721TokenId);
        if (category == ERC721MarketplaceUpgradeable.Category.Room) {
            IGetKicksCollection collection = IGetKicksCollection(erc721TokenAddress);

            bool exist = collection.exists(erc721TokenId);
            require(exist, "GetKicksMarketplace: adding ERC721 listing for nonexistent tokenId");
            address currentController = collection.controller();
            if (currentController == _thisAddress) {
                bool isLocked = collection.locked(erc721TokenId);
                if (!isLocked) {
                    _lockTokenId(erc721TokenAddress, erc721TokenId);
                }
            } else {
                _receiveERC721(erc721TokenAddress, owner, _thisAddress, erc721TokenId);
            }
        } else {
            _receiveERC721(erc721TokenAddress, owner, _thisAddress, erc721TokenId);
        }
        _storage.erc721Listings[listingId] = ERC721MarketplaceUpgradeable.ERC721Listing({
            listingId: listingId,
            seller: owner,
            erc721TokenAddress: erc721TokenAddress,
            erc721TokenId: erc721TokenId,
            category: category,
            priceInWei: priceInWei,
            timeAdded: block.timestamp,
            timeCancelled: 0,
            timePurchased: 0,
            status: ERC721MarketplaceUpgradeable.Status.None
        });
        _storage.changeListingStatus(listingId, ERC721MarketplaceUpgradeable.Status.Added);
        _storage.addERC721ListingItem(owner, uint256(category), "listed", listingId);
        if (isListingFeeEnabled() && listingFeeInWei() > 0) {
            _receiveTokens(kick(), owner, burnAddress(), listingFeeInWei());
            emit KickBurned(address(0), burnAddress(), listingFeeInWei());
        }
        emit ERC721ListingAdd(
            listingId,
            owner,
            erc721TokenAddress,
            erc721TokenId,
            category,
            priceInWei,
            block.timestamp,
            ERC721MarketplaceUpgradeable.Status.Added
        );
        _afterAddERC721Listing(erc721TokenAddress, erc721TokenId, priceInWei);
    }

    function cancelERC721Listing(uint256 mListingId) external virtual whenNotPaused nonReentrant {
        address owner = _msgSender();
        _beforeCancelERC721Listing(mListingId, owner);
        _cancelERC721Listing(mListingId, owner);
        _storage.cancelERC721Listing(mListingId, owner);
        _afterCancelERC721Listing(mListingId);
    }

    function executeERC721Listing(uint256 mListingId) external whenNotPaused nonReentrant {
        ERC721MarketplaceUpgradeable.ERC721Listing storage listing = _storage.erc721Listings[mListingId];
        address buyer = _msgSender();
        address seller = listing.seller;
        _beforeExecuteERC721Listing(mListingId, buyer, seller);
        listing.timePurchased = block.timestamp;
        uint256 tax = (listing.priceInWei * listingTax()) / _DIV;
        uint256 amountAfterTax = listing.priceInWei - tax;
        _receiveTokens(token(), buyer, _thisAddress, listing.priceInWei);
        _sendTokens(token(), wallet(), tax); // tax amount goes to wallet
        _sendTokens(token(), seller, amountAfterTax);

        ERC721MarketplaceUpgradeable.Category category = getERC721Category(
            listing.erc721TokenAddress,
            listing.erc721TokenId
        );
        if (category == ERC721MarketplaceUpgradeable.Category.Room) {
            IGetKicksCollection collection = IGetKicksCollection(listing.erc721TokenAddress);

            bool exist = collection.exists(listing.erc721TokenId);
            bool locked = collection.locked(listing.erc721TokenId);
            if (exist && locked) {
                _releaseLockedTokenId(listing.erc721TokenAddress, listing.erc721TokenId);
                _sendERC721(listing.erc721TokenAddress, seller, buyer, listing.erc721TokenId);
            }
        } else {
            _sendERC721(listing.erc721TokenAddress, _thisAddress, buyer, listing.erc721TokenId);
        }
        _storage.changeListingStatus(mListingId, ERC721MarketplaceUpgradeable.Status.Executed);

        emit ERC721ExecutedListing(
            mListingId,
            seller,
            buyer,
            listing.erc721TokenAddress,
            listing.erc721TokenId,
            listing.category,
            listing.priceInWei,
            block.timestamp,
            ERC721MarketplaceUpgradeable.Status.Executed
        );
        _afterExecuteERC721Listing(mListingId);
    }

    function cancelERC721Listings(uint256[] memory mListingIds)
        external
        nonReentrant
        onlyRole(TIMELOCK_CONTROLLER_ROLE)
    {
        for (uint256 i; i < mListingIds.length; i++) {
            uint256 listingId = mListingIds[i];
            ERC721MarketplaceUpgradeable.ERC721Listing storage listing = _storage.erc721Listings[listingId];
            address owner = listing.seller;
            _cancelERC721Listing(listingId, owner);
            _storage.cancelERC721Listing(listingId, owner);
        }
    }

    function getAllIncludedCollections() public view virtual returns (address[] memory) {
        return _includedCollections;
    }

    function totalIncludedCollections() public view virtual returns (uint256) {
        return _includedCollections.length;
    }

    function getIncludedCollectionIndex(address erc721TokenAddress) public view virtual returns (uint256) {
        return _includedCollectionIndex[erc721TokenAddress];
    }

    function isListingFeeEnabled() public view returns (bool) {
        return _isListingFeeEnabled;
    }

    function listingFeeInWei() public view returns (uint256) {
        return _sListingFeeInWei;
    }

    function listingTax() public view returns (uint256) {
        return _sListingTax;
    }

    function getNextERC721ListingId() public view virtual returns (uint256) {
        return _sNextERC721ListingId.current();
    }

    function listingIds() public view virtual returns (uint256[] memory) {
        return _storage.getAllListingIds();
    }

    function totalListingIds() public view virtual returns (uint256) {
        return _storage.totalListingIds();
    }

    //return the index of listingId
    function listingIdIndex(uint256 mListingId) public view virtual returns (uint256) {
        return _storage.getListingIdIndex(mListingId);
    }

    function getERC721ListingListItem(uint256 mListingId)
        public
        view
        virtual
        returns (ERC721MarketplaceUpgradeable.ListingListItem memory)
    {
        return _storage.getERC721ListingListItem(mListingId);
    }

    function getErc721ListingHead(uint256 mCategory, string memory mSort) public view virtual returns (uint256) {
        return _storage.getErc721ListingHead(mCategory, mSort);
    }

    function getErc721Categories(address erc721TokenAddress)
        public
        view
        virtual
        returns (ERC721MarketplaceUpgradeable.Category)
    {
        return _storage.getErc721Categories(erc721TokenAddress);
    }

    function getErc721OwnerListingHead(
        address mOwner,
        uint256 mCategory,
        string memory mSort
    ) public view virtual returns (uint256) {
        return _storage.getErc721OwnerListingHead(mOwner, mCategory, mSort);
    }

    function getErc721TokenToListingId(
        address erc721TokenAddress,
        uint256 erc721TokenId,
        address mOwner
    ) public view virtual returns (uint256) {
        return _storage.getErc721TokenToListingId(erc721TokenAddress, erc721TokenId, mOwner);
    }

    function getERC721Category(address erc721TokenAddress, uint256 erc721TokenId)
        public
        view
        returns (ERC721MarketplaceUpgradeable.Category)
    {
        // TODO require
        return _storage.getErc721Categories(erc721TokenAddress);
    }

    function timelockController() public view virtual returns (address) {
        return _sTimelockController;
    }

    function token() public view returns (address) {
        return _tokenAddress;
    }

    function kick() public view returns (address) {
        return _kickAddress;
    }

    function wallet() public view returns (address) {
        return _wallet;
    }

    function burnAddress() public view virtual returns (address) {
        return _burnAddress;
    }

    function pause() public virtual {
        _beforePause();
        _pause();
    }

    function unpause() public virtual {
        _beforeUnpause();
        _unpause();
    }

    function _cancelERC721Listing(uint256 mListingId, address mOwner) internal virtual {
        ERC721MarketplaceUpgradeable.ERC721Listing storage listing = _storage.erc721Listings[mListingId];
        ERC721MarketplaceUpgradeable.Category category = getERC721Category(
            listing.erc721TokenAddress,
            listing.erc721TokenId
        );
        if (category == ERC721MarketplaceUpgradeable.Category.Room) {
            IGetKicksCollection collection = IGetKicksCollection(listing.erc721TokenAddress);

            bool exist = collection.exists(listing.erc721TokenId);
            bool isLocked = collection.locked(listing.erc721TokenId);
            if (exist && isLocked) {
                _releaseLockedTokenId(listing.erc721TokenAddress, listing.erc721TokenId);
            }
        } else {
            _sendERC721(listing.erc721TokenAddress, _thisAddress, mOwner, listing.erc721TokenId);
        }
    }

    function _addIncludedCollection(address erc721TokenAddress, ERC721MarketplaceUpgradeable.Category mCategory)
        internal
        virtual
    {
        uint256 index = totalIncludedCollections() + 1; // mapping index starts with 1
        _includedCollections.push(erc721TokenAddress);
        _includedCollectionIndex[erc721TokenAddress] = index;
        _grantRole(INCLUDED_COLLECTIONS, erc721TokenAddress);
        addCollectionCategory(erc721TokenAddress, mCategory);
    }

    function _removeIncludedCollection(address erc721TokenAddress) internal virtual {
        uint256 index = getIncludedCollectionIndex(erc721TokenAddress);
        require(index != 0, "Marketplace: non included collection");
        uint256 arrayIndex = index - 1;
        require(arrayIndex >= 0, "Marketplace: out-of-bounds");
        if (arrayIndex != totalIncludedCollections() - 1) {
            _includedCollections[arrayIndex] = _includedCollections[totalIncludedCollections() - 1];
            _includedCollectionIndex[_includedCollections[arrayIndex]] = index;
        }
        _includedCollections.pop();
        delete _includedCollectionIndex[erc721TokenAddress];
        _revokeRole(INCLUDED_COLLECTIONS, erc721TokenAddress);
    }

    function addCollectionCategory(address erc721TokenAddress, ERC721MarketplaceUpgradeable.Category mCategory)
        internal
        virtual
    {
        _storage.erc721Categories[erc721TokenAddress] = mCategory;
    }

    /**
     * @dev Hook that is called before addERC721Listing.
     */
    function _beforeAddERC721Listing(
        address erc721TokenAddress,
        uint256 erc721TokenId,
        uint256 priceInWei,
        address mOwner
    ) internal virtual {
        require(erc721TokenAddress != address(0), "GetKicksMarketplace: address is the zero address");
        require(
            hasRole(INCLUDED_COLLECTIONS, erc721TokenAddress),
            "GetKicksMarketplace, can't add given ERC721 addres"
        );
        require(priceInWei != 0, "GetKicksMarketplace: priceInWei is the zero value");
        IERC721Upgradeable erc721Token = IERC721Upgradeable(erc721TokenAddress);
        require(erc721Token.ownerOf(erc721TokenId) == mOwner, "GetKicksMarketplace: not owner");
        require(
            erc721Token.isApprovedForAll(mOwner, _thisAddress) ||
                erc721Token.getApproved(erc721TokenId) == _thisAddress,
            "GetKicksMarketplace: not approved for transfer"
        );
        if (isListingFeeEnabled()) {
            require(_kick.balanceOf(mOwner) >= listingFeeInWei(), "GetKicksMarketplace: need KICK balance");

            require(_kick.allowance(mOwner, _thisAddress) >= listingFeeInWei(), "GetKicksMarketplace: approve KICK!");
        }
    }

    /**
     * @dev Hook that is called after addERC721Listing.
     */
    function _afterAddERC721Listing(
        address erc721TokenAddress,
        uint256 erc721TokenId,
        uint256 priceInWei
    ) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _beforeExecuteERC721Listing(
        uint256 mListingId,
        address buyer,
        address seller
    ) internal virtual {
        ERC721MarketplaceUpgradeable.ERC721Listing storage listing = _storage.erc721Listings[mListingId];

        require(listing.timePurchased == 0, "GetKicksMarketplace: listing already sold");

        require(
            listing.status == ERC721MarketplaceUpgradeable.Status.Added,
            "GetKicksMarketplace: listing not added yet"
        );
        uint256 priceInWei = listing.priceInWei;

        require(seller != buyer, "GetKicksMarketplace: buyer can't be seller");

        require(
            IERC20Upgradeable(token()).balanceOf(buyer) >= priceInWei,
            "GetKicksMarketplace: not enough token balance"
        );

        require(
            _token.allowance(buyer, _thisAddress) >= priceInWei,
            "GetKicksMarketplace: token not approved for transfer"
        );
    }

    /**
     * @dev Hook that is called after executeERC721Listing.
     */
    function _afterExecuteERC721Listing(uint256 mListingId) internal virtual {}

    function _beforeCancelERC721Listing(uint256 mListingId, address mOwner) internal virtual {
        require(mListingId > 0, "GetKicksMarketplace: listingId is the zero value");
        ERC721MarketplaceUpgradeable.ListingListItem storage listingItem = _storage.erc721ListingListItem[mListingId];
        require(listingItem.listingId > 0, "GetKicksMarketplace: listingItem listingId is the zero value");
        ERC721MarketplaceUpgradeable.ERC721Listing storage listing = _storage.erc721Listings[mListingId];
        require(
            listing.status != ERC721MarketplaceUpgradeable.Status.Cancelled,
            "GetKicksMarketplace: listing already cancelled"
        );
        require(
            listing.status != ERC721MarketplaceUpgradeable.Status.Executed,
            "GetKicksMarketplace: listing already executed"
        );
        require(
            listing.status != ERC721MarketplaceUpgradeable.Status.Removed,
            "GetKicksMarketplace: listing already removed"
        );
        require(listing.timePurchased == 0, "GetKicksMarketplace: listing already purchased");
        address checkOwner = IERC721Upgradeable(listing.erc721TokenAddress).ownerOf(listing.erc721TokenId);
        require(checkOwner == mOwner, "GetKicksMarketplace, not owner");
        require(listing.seller == mOwner, "GetKicksMarketplace: msg.sender is not seller");
    }

    /**
     * @dev Hook that is called after cancelERC721Listing.
     */
    function _afterCancelERC721Listing(uint256 mListingId) internal virtual {}

    function _lockTokenId(address erc721TokenAddress, uint256 tokenId) internal {
        require(erc721TokenAddress != address(0), "GetKicksMarketplace: ERC721 is the zero address");

        require(tokenId != 0, "GetKicksMarketplace: tokenId is zero");

        IGetKicksCollection collection = IGetKicksCollection(erc721TokenAddress);

        require(collection.exists(tokenId), "GetKicksMarketplace: change for nonexistent token");

        //require(collection.locked() == false, "GetKicksMarketplace: tokenId already locked");

        require(collection.controller() == _thisAddress, "GetKicksMarketplace: doesn't control GetKicksCollection");

        collection.lockTokenId(tokenId);
    }

    function _releaseLockedTokenId(address erc721TokenAddress, uint256 tokenId) internal {
        require(erc721TokenAddress != address(0), "GetKicksMarketplace: ERC721 is the zero address");

        require(tokenId != 0, "GetKicksMarketplace: tokenId is zero");

        IGetKicksCollection collection = IGetKicksCollection(erc721TokenAddress);

        require(collection.exists(tokenId), "GetKicksMarketplace: change for nonexistent token");

        //require(collection.locked() == true, "GetKicksMarketplace: tokenId not locked");

        require(collection.controller() == _thisAddress, "GetKicksMarketplace: doesn't control GetKicksCollection");

        collection.releaseLockedTokenId(tokenId);
    }

    function _receiveTokens(
        address mToken,
        address beneficiary,
        address to,
        uint256 tokenAmount
    ) internal virtual {
        IERC20Upgradeable(mToken).safeTransferFrom(beneficiary, to, tokenAmount);
    }

    function _sendTokens(
        address mToken,
        address to,
        uint256 tokenAmount
    ) internal virtual {
        IERC20Upgradeable(mToken).safeTransfer(to, tokenAmount);
    }

    function _receiveERC721(
        address erc721TokenAddress,
        address beneficiary,
        address to,
        uint256 tokenId
    ) internal virtual {
        IERC721Upgradeable erc721Token = IERC721Upgradeable(erc721TokenAddress);
        require(
            erc721Token.isApprovedForAll(beneficiary, to) || erc721Token.getApproved(tokenId) == to,
            "GetKicksMarketplace: not approved"
        );
        erc721Token.safeTransferFrom(beneficiary, to, tokenId);
    }

    function _sendERC721(
        address erc721TokenAddress,
        address seller,
        address to,
        uint256 tokenId
    ) internal virtual {
        IERC721Upgradeable erc721Token = IERC721Upgradeable(erc721TokenAddress);
        erc721Token.safeTransferFrom(seller, to, tokenId);
    }

    function _beforePause()
        internal
        virtual
        onlyRole(TIMELOCK_CONTROLLER_ROLE)
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function _beforeUnpause()
        internal
        virtual
        onlyRole(TIMELOCK_CONTROLLER_ROLE)
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(UPGRADER_ROLE) {
        // solhint-disable-next-line no-empty-blocks
    }

    uint256[50] private __gap;
}