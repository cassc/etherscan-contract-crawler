//SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Real world asset receipt token
abstract contract RealWorldAssetReceipt is ERC20, ReentrancyGuard {

    using SafeERC20 for IERC20;

    IERC20 public immutable usdt;
    IERC20 public immutable receipt;
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint public totalAmountListed;
    uint public totalListings;
    uint public totalDelisted;
    bool internal _inbound;

    struct User {
        uint amountListed;
        uint[] listingIds;
        uint[] purchasedIds;
    }

    struct Listing {
        uint listingId;
        address seller;
        address buyer;
        uint listedAt;
        uint purchasedAt;
        uint delistedAt;
        uint amount;
        uint cost;
    }

    mapping(address => User) public _users;
    mapping(uint => Listing) public _listings;

    event Listed(address indexed seller, uint indexed listingId, uint amount, uint cost);
    event Delisted(address indexed seller, uint indexed listingId);
    event PriceChanged(uint indexed oldListingId, uint indexed newListingId, uint newCost);
    event Purchased(address indexed buyer, uint indexed listingId);

    /// @param _listingId Listing ID
    modifier onlyActiveListing(uint _listingId) {
        require(_listingId < totalListings, "RealWorldAssetReceipt: Listing does not exist");
        require(_listings[_listingId].purchasedAt == 0, "RealWorldAssetReceipt: Listing has already been purchased");
        require(_listings[_listingId].delistedAt == 0, "RealWorldAssetReceipt: Listing has already been delisted");
        _;
    }

    modifier onlyActivePool() {
        require(_isPoolActive(), "RealWorldAssetReceipt: OTC has closed");
        _;
    }

    /// @param _name Receipt token name
    /// @param _symbol Receipt token symbol
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        usdt = IERC20(USDT);
        receipt = IERC20(address(this));
    }

    /// @inheritdoc ERC20
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /// @notice List a RWA receipt tokens
    /// @param _amount Amount of RWA receipt tokens to list
    /// @param _cost Cost of _amount in USDT
    function list(uint _amount, uint _cost) external nonReentrant onlyActivePool {
        require(_amount <= balanceOf(_msgSender()), "RealWorldAssetReceipt: Insufficient balance");
        require(_amount <= allowance(_msgSender(), address(this)), "RealWorldAssetReceipt: Insufficient allowance");
        uint listingId = _list(_amount, _cost);
        totalAmountListed += _amount;
        _inbound = true;
        receipt.safeTransferFrom(_msgSender(), address(this), _amount);
        _inbound = false;
        emit Listed(_msgSender(), listingId, _amount, _cost);
    }

    /// @notice Delist your listing. If the pool has ended you don't need to delist because the pool with automatically handle it for you
    /// @param _listingId Listing ID
    function delist(uint _listingId) external nonReentrant onlyActiveListing(_listingId) onlyActivePool {
        uint amount = _delist(_listingId);
        totalAmountListed -= amount;
        receipt.safeTransfer(_msgSender(), amount);
        emit Delisted(_msgSender(), _listingId);
    }

    /// @notice Change price of a listing (delists then relists)
    /// @param _listingId Listing ID
    /// @param _newCost New cost of the listing in USDT
    function changePrice(uint _listingId, uint _newCost) external nonReentrant onlyActiveListing(_listingId) onlyActivePool {
        require(0 < _newCost, "RealWorldAssetReceipt: _cost must be greater than 0");
        /// @dev Delists then relists otherwise when purchasing a user could be frontrun if they approved max
        uint amount = _delist(_listingId);
        uint newListingId = _list(amount, _newCost);
        emit PriceChanged(_listingId, newListingId, _newCost);
    }

    /// @notice Purchase a listing
    /// @param _listingId Listing ID
    function purchase(uint _listingId) external nonReentrant onlyActiveListing(_listingId) onlyActivePool {
        Listing storage listing = _listings[_listingId];
        require(listing.seller != _msgSender(), "RealWorldAssetReceipt: You cannot purchase your own listing");
        require(listing.cost <= usdt.balanceOf(_msgSender()), "RealWorldAssetReceipt: Insufficient USDT balance");
        require(listing.cost <= usdt.allowance(_msgSender(), address(this)), "RealWorldAssetReceipt: Insufficient USDT allowance");
        listing.purchasedAt = block.timestamp;
        listing.buyer = _msgSender();
        _users[_msgSender()].purchasedIds.push(_listingId);
        _users[listing.seller].amountListed -= listing.amount;
        totalAmountListed -= listing.amount;
        usdt.safeTransferFrom(_msgSender(), listing.seller, listing.cost);
        receipt.safeTransfer(_msgSender(), listing.amount);
        emit Purchased(_msgSender(), _listingId);
    }

    /// @notice Get the amount listed by a user
    /// @param _user User address
    /// @return Amount listed by _user
    function getUserAmountListed(address _user) external view returns (uint) {
        require(_user != address(0), "RealWorldAssetReceipt: _user cannot equal the zero address");
        return _getUserAmountListed(_user);
    }

    /// @notice Get the total number of listings by a user
    /// @param _user User address
    /// @return Total listings by _user
    function getUserTotalListings(address _user) public view returns (uint) {
        require(_user != address(0), "RealWorldAssetReceipt: _user cannot equal the zero address");
        return _users[_user].listingIds.length;
    }

    /// @notice Get the total purchases by a user
    /// @param _user User address
    /// @return Total purchases by _user
    function getUserTotalPurchases(address _user) public view returns (uint) {
        require(_user != address(0), "RealWorldAssetReceipt: _user cannot equal the zero address");
        return _users[_user].purchasedIds.length;
    }

    /// @notice Get listings
    /// @param _startIndex Start index
    /// @param _endIndex End index
    /// @return listings Listings
    function getListings(uint _startIndex, uint _endIndex) external view returns (Listing[] memory listings) {
        _validateIndexes(_startIndex, _endIndex, totalListings);
        listings = new Listing[](_endIndex - _startIndex + 1);
        uint listIndex;
        for (uint index = _startIndex; index <= _endIndex; index++) {
            listings[listIndex] = _listings[index];
            listIndex++;
        }
        return listings;
    }

    /// @notice Get user listings
    /// @param _user User address
    /// @param _startIndex Start index
    /// @param _endIndex End index
    /// @return listings Listings
    function getUserListings(address _user, uint _startIndex, uint _endIndex) external view returns (Listing[] memory listings) {
        uint total = getUserTotalListings(_user);
        _validateIndexes(_startIndex, _endIndex, total);
        listings = new Listing[](_endIndex - _startIndex + 1);
        uint listIndex;
        for (uint index = _startIndex; index <= _endIndex; index++) {
            listings[listIndex] = _listings[_users[_user].listingIds[index]];
            listIndex++;
        }
        return listings;
    }

    /// @notice Get user purchases
    /// @param _user User address
    /// @param _startIndex Start index
    /// @param _endIndex End index
    /// @return listings Listings
    function getUserPurchases(address _user, uint _startIndex, uint _endIndex) external view returns (Listing[] memory listings) {
        uint total = getUserTotalPurchases(_user);
        _validateIndexes(_startIndex, _endIndex, total);
        listings = new Listing[](_endIndex - _startIndex + 1);
        uint listIndex;
        for (uint index = _startIndex; index <= _endIndex; index++) {
            listings[listIndex] = _listings[_users[_user].purchasedIds[index]];
            listIndex++;
        }
        return listings;
    }

    /// @param _startIndex Start index
    /// @param _endIndex End index
    /// @param _total Total
    function _validateIndexes(uint _startIndex, uint _endIndex, uint _total) private pure {
        require(_startIndex <= _endIndex, "RealWorldAssetReceipt: Start index must be less than or equal to end index");
        require(_startIndex < _total, "RealWorldAssetReceipt: Invalid start index");
        require(_endIndex < _total, "RealWorldAssetReceipt: Invalid end index");
    }

    /// @param _user User address
    /// @return uint Amount listed by _user
    function _getUserAmountListed(address _user) internal view returns (uint) {
        return _users[_user].amountListed;
    }

    /// @dev Used when withdrawing
    /// @param _user User address
    function _clearUserAmountListed(address _user) internal {
        _users[_user].amountListed = 0;
    }

    /// @return bool Is pool active
    function _isPoolActive() internal view virtual returns (bool);

    /// @param _amount Amount of RWA receipt tokens to list
    /// @param _cost Cost of _amount in USDT
    /// @return uint Listing ID
    function _list(uint _amount, uint _cost) private returns (uint) {
        require(0 < _amount, "RealWorldAssetReceipt: _amount must be greater than 0");
        require(0 < _cost, "RealWorldAssetReceipt: _cost must be greater than 0");
        User storage user = _users[_msgSender()];
        uint listingId = totalListings;
        _listings[listingId] = Listing(listingId, _msgSender(), address(0), block.timestamp, 0, 0, _amount, _cost);
        user.amountListed += _amount;
        user.listingIds.push(listingId);
        totalListings++;
        return listingId;
    }

    /// @param _listingId Listing ID
    /// @return uint Amount of RWA receipt tokens associated with _listingId
    function _delist(uint _listingId) private returns (uint) {
        Listing storage listing = _listings[_listingId];
        require(listing.seller == _msgSender(), "RealWorldAssetReceipt: Only the seller can delist their listing");
        listing.delistedAt = block.timestamp;
        User storage user = _users[_msgSender()];
        user.amountListed -= listing.amount;
        totalDelisted++;
        return listing.amount;
    }
}