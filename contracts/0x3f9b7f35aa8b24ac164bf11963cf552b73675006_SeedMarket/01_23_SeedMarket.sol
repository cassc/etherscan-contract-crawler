// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import "./MintPass.sol";
import "./QQL.sol";

struct ListingData {
    address lister;
    uint96 price;
}

contract SeedMarket is Ownable {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    QQL immutable qql_;
    MintPass immutable pass_;
    uint256 blessingFee_;

    mapping(bytes32 => bool) blessed_;
    mapping(bytes32 => ListingData) listings_;

    event BlessingFeeUpdate(uint256 oldFee, uint256 newFee);
    event Blessing(bytes32 indexed seed, address cleric);
    event Trade(
        bytes32 indexed seed,
        address indexed seller,
        address indexed buyer,
        uint256 price
    );
    event Listing(bytes32 indexed seed, address indexed lister, uint256 price);
    event Delisting(bytes32 indexed seed);

    constructor(
        QQL _qql,
        MintPass _pass,
        uint256 blessingFee
    ) {
        qql_ = _qql;
        pass_ = _pass;
        blessingFee_ = blessingFee;
        emit BlessingFeeUpdate(0, blessingFee);
    }

    function setBlessingFee(uint256 blessingFee) external onlyOwner {
        emit BlessingFeeUpdate(blessingFee_, blessingFee);
        blessingFee_ = blessingFee;
    }

    function isSeedOperatorOrParametricArtist(address operator, bytes32 seed)
        internal
        view
        returns (bool)
    {
        if (operator == address(bytes20(seed))) return true;
        return qql_.isApprovedOrOwnerForSeed(operator, seed);
    }

    function bless(bytes32 seed) public payable {
        if (!isSeedOperatorOrParametricArtist(msg.sender, seed))
            revert("SeedMarket: unauthorized");
        if (msg.value != blessingFee_) revert("SeedMarket: wrong fee");
        if (blessed_[seed]) revert("SeedMarket: already blessed");
        emit Blessing(seed, msg.sender);
        blessed_[seed] = true;
    }

    function blessAndList(bytes32 seed, uint256 price) external payable {
        bless(seed);
        list(seed, price);
    }

    function isBlessed(bytes32 seed) external view returns (bool) {
        return blessed_[seed];
    }

    function list(bytes32 seed, uint256 price) public payable {
        if (!qql_.isApprovedOrOwnerForSeed(msg.sender, seed))
            revert("SeedMarket: unauthorized");
        if (!blessed_[seed]) revert("SeedMarket: must bless to list");
        qql_.transferSeed(qql_.ownerOfSeed(seed), address(this), seed);
        uint96 price96 = uint96(price);
        if (price96 != price) revert("SeedMarket: price too high");
        listings_[seed] = ListingData({lister: msg.sender, price: price96});
        emit Listing(seed, msg.sender, price);
    }

    function getListing(bytes32 seed)
        external
        view
        returns (address lister, uint256 price)
    {
        ListingData memory lst = listings_[seed];
        return (lst.lister, uint256(lst.price));
    }

    function reprice(bytes32 seed, uint256 price) external {
        ListingData memory lst = listings_[seed];
        if (lst.lister != msg.sender) revert("SeedMarket: unauthorized");
        lst.price = uint96(price);
        if (lst.price != price) revert("SeedMarket: price too high");
        listings_[seed] = lst;
        emit Listing(seed, msg.sender, price);
    }

    function delist(bytes32 seed) external {
        if (listings_[seed].lister != msg.sender)
            revert("SeedMarket: unauthorized");
        delete listings_[seed];
        qql_.transferSeed(address(this), msg.sender, seed);
        emit Delisting(seed);
    }

    function fillListing(bytes32 seed, uint256 mintPassId) external payable {
        ListingData memory lst = listings_[seed];
        address lister = lst.lister;
        uint256 price = uint256(lst.price);
        if (lister == address(0)) revert("SeedMarket: unlisted seed");
        if (msg.value != price) revert("SeedMarket: incorrect payment");
        if (!pass_.isApprovedOrOwner(msg.sender, mintPassId))
            revert("SeedMarket: not owner or approved for pass");
        delete listings_[seed];
        qql_.transferSeed(address(this), msg.sender, seed);
        emit Trade(seed, lister, msg.sender, price);
        // Careful: invokes ERC721 received hook for buyer
        qql_.mintTo(mintPassId, seed, msg.sender);
        if (price > 0) {
            // Careful: invokes fallback function on seller
            payable(lister).transfer(price);
        }
    }

    /// Sends a seed that's been accidentally transferred directly to this
    /// contract back to the original artist.
    function rescue(bytes32 seed) external {
        if (listings_[seed].lister != address(0))
            revert("SeedMarket: seed is listed");
        address artist = address(bytes20(seed));
        qql_.transferSeed(address(this), artist, seed);
    }
}