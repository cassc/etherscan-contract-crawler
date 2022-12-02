// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./NftMarketInterfaces.sol";
import "../includes/access/Ownable.sol";
import "../includes/libraries/Percentages.sol";
import "../includes/utils/ReentrancyGuard.sol";
import "../includes/token/BEP20/IBEP20.sol";

contract OblivionMintingService1155 is Ownable, ReentrancyGuard {
    using Percentages for uint256;

    struct MintListing {
        address owner;
        address nft;     
        uint256 tokenId;
        address paymentToken;
        uint256 price;
        uint256 sales;
        uint256 maxSales;
        uint256 endDate;
        uint256 maxQuantity;
        uint256 discount;
        bool whitelisted;
        bool ended;
        address[] treasuryAddresses;
        uint256[] treasuryAllocations;
    }

    address payable treasury;
    uint256 public tax;

    MintListing[] public listings;
    mapping(address => uint256) public discounts;
    mapping(address => address) public nftModerators;
    mapping(address => bool) public paymentTokens;
    mapping(uint256 => mapping(address => bool)) whitelists;
    mapping(address => bool) nftListed;
    mapping(address => uint256) nftListingId;
    mapping(address => uint256[]) userListings;

    event SetNftModerator(address nft, address moderator);
    event SetListingWhitelist(uint256 id, address wallet, bool whitelisted);
    event SetListingWhitelists(uint256 id, uint256 count, bool whitelisted);
    event CreateListing(uint256 id, address nft, address paymentToken, uint256 price, uint256 maxSales, uint256 maxQuantity, bool whitelisted);
    event UpdateListing(uint256 id, address paymentToken, uint256 price, uint256 maxSales, uint256 maxQuantity, bool whitelisted);
    event MultiNftPurchases(uint256 id, address buyer, uint256 quantity);

    constructor (address _treasury, uint256 _tax) {
        treasury = payable(_treasury);
        tax = _tax;
    }

    function totalListings() public view returns (uint256) { return listings.length; }
    function isWhitelisted(uint256 _id, address _wallet) public view returns (bool) { return whitelists[_id][_wallet]; }
    function getUserListings(address _user) public view returns (uint256[] memory) { return userListings[_user]; }
    
    function getTreasuryInfo(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        MintListing memory listing = listings[_id];
        return (listing.treasuryAddresses, listing.treasuryAllocations);
    }
    
    function setTreasury(address _treasury) public onlyOwner() {
        treasury = payable(_treasury);
    }

    function setTax(uint256 _tax) public onlyOwner() {
        tax = _tax;
    }

    function setDiscount(address _user, uint256 _discount) public onlyOwner() {
        discounts[_user] = _discount;
    }

    function setListingDiscount(uint256 _id, uint256 _discount) public onlyOwner() {
        require(_id < totalListings(), 'Invalid listing ID');
        listings[_id].discount = _discount;
    }

    function setAllowedPaymentToken(address _token, bool _allowed) public onlyOwner() {
        paymentTokens[_token] = _allowed;
    }

    function recoverNftOwnership(uint256 _id) public {
        MintListing memory listing = listings[_id];
        require(listing.owner == msg.sender, 'Must be listing owner');
        require(listing.ended, 'Listing is still open');
        INft1155 nft = INft1155(listing.nft);
        nft.transferOwnership(msg.sender);
    }

    function setNftModerator(address _nft, address _moderator) public {
        require(msg.sender == INft1155(_nft).owner() || msg.sender == owner(), 'must be owner');
        nftModerators[_nft] = _moderator;
        emit SetNftModerator(_nft, _moderator);
    }

    function endSale(uint256 _id) public {
        require(_id < listings.length, 'invalid listing');
        MintListing storage listing = listings[_id];
        require(msg.sender == listing.owner, 'must be owner');
        require(!listing.ended, 'already ended');
        listing.ended = true;
        nftListed[listing.nft] = false;
    }

    function createListing(address _nft, uint256 _tokenId, address _paymentToken, uint256 _price, uint256 _maxSales, uint256 _endDate, uint256 _maxQuantity, bool _whitelisted, address[] memory _treasuryAddresses, uint256[] memory _treasuryAllocations) public returns (uint256) {
        require(msg.sender == INft1155(_nft).owner() || msg.sender == nftModerators[_nft], 'must be owner');
        require(_validateAllocations(_treasuryAddresses, _treasuryAllocations), 'invalid allocations');
        require(_paymentToken == address(0) || paymentTokens[_paymentToken], 'invalid payment token');
        require(!nftListed[_nft], 'NFT already listed');

        listings.push(MintListing({
            owner: msg.sender,
            nft: _nft,
            tokenId: _tokenId,
            price: _price,
            paymentToken: _paymentToken,
            sales: 0,
            maxSales: _maxSales,
            endDate: _endDate,
            maxQuantity: _maxQuantity,
            whitelisted: _whitelisted,
            discount: 0,
            ended: false,
            treasuryAddresses: _treasuryAddresses,
            treasuryAllocations: _treasuryAllocations
        }));

        uint256 id = listings.length - 1;

        nftListed[_nft] = true;
        nftListingId[_nft] = id;

        userListings[msg.sender].push(id);

        emit CreateListing(id, _nft, _paymentToken, _price, _maxSales, _maxQuantity, _whitelisted);
        return id;
    }

    function updateListing(uint256 _id, address _paymentToken, uint256 _price, uint256 _maxSales, uint256 _endDate, uint256 _maxQuantity, bool _whitelisted, address[] memory _treasuryAddresses, uint256[] memory _treasuryAllocations) public {
        require(_id < listings.length, 'invalid listing');
        MintListing storage listing = listings[_id];
        require(msg.sender == listing.owner, 'must be owner');
        require(_validateAllocations(_treasuryAddresses, _treasuryAllocations), 'invalid allocations');
        require(_paymentToken == address(0) || paymentTokens[_paymentToken], 'invalid payment token');
        listing.price = _price;
        listing.paymentToken = _paymentToken;
        listing.maxSales = _maxSales;
        listing.treasuryAddresses = _treasuryAddresses;
        listing.treasuryAllocations = _treasuryAllocations;
        listing.endDate = _endDate;
        listing.whitelisted = _whitelisted;
        listing.maxQuantity = _maxQuantity;
        emit UpdateListing(_id, _paymentToken, _price, _maxSales, _maxQuantity, _whitelisted);
    }

    function setWhitelistAddress(uint256 _id, address _wallet, bool _whitelisted) public {
        require(_id < listings.length, 'invalid listing');
        require(msg.sender == listings[_id].owner, 'must be owner');
        whitelists[_id][_wallet] = _whitelisted;
        emit SetListingWhitelist(_id, _wallet, _whitelisted);
    }

    function setWhitelistAddresses(uint256 _id, address[] memory _wallets, bool _whitelisted) public {
        require(_id < listings.length, 'invalid listing');
        require(msg.sender == listings[_id].owner, 'must be owner');
        for (uint256 i = 0; i < _wallets.length; i++) whitelists[_id][_wallets[i]] = _whitelisted;
        emit SetListingWhitelists(_id, _wallets.length, _whitelisted);
    }

    function mintMultiBnb(uint256 _id, uint256 _quantity) public payable nonReentrant() {
        require(_id < listings.length, 'invalid listing');
        _checkListing(_id, true, _quantity);
        MintListing storage listing = listings[_id];
        uint256 total = listing.price * _quantity;

        require(msg.value == total, 'incorrect BNB sent');
        require(listing.maxQuantity == 0 || _quantity <= listing.maxQuantity, 'maximum quantity per sale exceeded');

        uint256 taxes = _getTaxes(_id, total);
        uint256 remaining = total - taxes;
        uint256[] memory allocations = _getAllocations(remaining, listing.treasuryAllocations);

        if (taxes > 0) _safeTransfer(treasury, taxes);
        for (uint256 i = 0; i < listing.treasuryAddresses.length; i++)
            _safeTransfer(listing.treasuryAddresses[i], allocations[i]);

        listing.sales += _quantity;
        INft1155(listing.nft).mint(msg.sender, listing.tokenId, _quantity, "");

        emit MultiNftPurchases(_id, msg.sender, _quantity);
    }

    function mintMultiBep20(uint256 _id, uint256 _quantity) public nonReentrant() {
        require(_id < listings.length, 'invalid listing');
        _checkListing(_id, false, _quantity);
        MintListing storage listing = listings[_id];
        uint256 total = listing.price * _quantity;

        require(listing.maxQuantity == 0 || _quantity <= listing.maxQuantity, 'maximum quantity per sale exceeded');
        uint256 taxes = _getTaxes(_id, total);
        uint256 remaining = total - taxes;
        uint256[] memory allocations = _getAllocations(remaining, listing.treasuryAllocations);

        IBEP20 token = IBEP20(listing.paymentToken);

        if (taxes > 0) token.transferFrom(msg.sender, treasury, taxes);
        for (uint256 i = 0; i < listing.treasuryAddresses.length; i++)
            token.transferFrom(msg.sender, listing.treasuryAddresses[i], allocations[i]);

        listing.sales += _quantity;

        INft1155(listing.nft).mint(msg.sender, listing.tokenId, _quantity, "");

        emit MultiNftPurchases(_id, msg.sender, _quantity);
    }

    function _getTaxes(uint256 _id, uint256 _amount) private view returns (uint256) {
        MintListing memory listing = listings[_id];
        uint256 taxes = _amount.calcPortionFromBasisPoints(tax);
        
        if (discounts[listing.owner] == 0 && listing.discount == 0) return taxes;

        uint256 discount;

        if (listing.discount > 0) discount = listing.discount;
        else discount = discounts[listing.owner];
        
        if (discount >= 10000) taxes = 0;
        else {
            uint256 savings = taxes.calcPortionFromBasisPoints(discount);
            taxes -= savings;
        }

        return taxes;
    }

    function _getAllocations(uint256 _amount, uint256[] memory _allocations) private pure returns (uint256[] memory) {
        uint256 leftOver = _amount;
        uint256[] memory allocations = new uint256[](_allocations.length);

        if (_allocations.length == 1) allocations[0] = _amount;
        else {
            for (uint256 i = 0; i < _allocations.length; i++) {
                if (i == _allocations.length - 1) allocations[i] = leftOver;
                else {
                    allocations[i] = _amount.calcPortionFromBasisPoints(_allocations[i]);                    
                    leftOver -= allocations[i];                    
                }
            }
        }
        return allocations;
    }

    function _checkListing(uint256 _id, bool _isBnb, uint256 _quantity) private view {
        MintListing memory listing = listings[_id];
        require(listing.maxSales == 0 || listing.sales + _quantity <= listing.maxSales, 'maximum sales reached');
        require(_isBnb && listing.paymentToken == address(0) || !_isBnb && listing.paymentToken != address(0), 'incorrect payment type');
        require(!listing.ended && (listing.endDate == 0 || block.timestamp < listing.endDate), 'sale has ended');
        require(!listing.whitelisted || whitelists[_id][msg.sender], 'must be whitelisted');
    }

    function _validateAllocations(address[] memory _addresses, uint256[] memory _allocations) private pure returns (bool) {
        if (_addresses.length != _allocations.length) return false;
        if (_allocations.length == 0) return false;
        uint256 totalAllocations;
        for (uint256 i = 0; i < _allocations.length; i++) totalAllocations += _allocations[i];
        return totalAllocations == 10000;
    }

    function _safeTransfer(address _recipient, uint _amount) private {
        (bool _success,) = _recipient.call{value : _amount}("");
        require(_success, "transfer failed");
    }
}