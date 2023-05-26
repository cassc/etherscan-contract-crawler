// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./MintPass.sol";
import "./QQL.sol";

struct ListingData {
    address lister;
    uint96 price;
}

/// @title A market for QQL seeds
/// @author Dandelion Wist & William Chargin
/// @notice This contract is used to list QQL seeds for sale, to be used by a QQL mint pass holder to mint the corresponding seed.
contract SeedMarket is Ownable {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using Address for address payable;

    QQL immutable qql_;
    MintPass immutable pass_;
    uint256 blessingFee_;

    mapping(bytes32 => bool) blessed_;
    mapping(bytes32 => ListingData) listings_;

    event BlessingFeeUpdate(uint256 oldFee, uint256 newFee);
    event Blessing(bytes32 indexed seed, address indexed cleric);
    event Trade(
        bytes32 indexed seed,
        address indexed seller,
        address indexed buyer,
        uint256 price
    );
    event Listing(bytes32 indexed seed, address indexed lister, uint256 price);
    event Delisting(bytes32 indexed seed);

    /// Emitted when the contract owner withdraws accumulated fees
    event Withdrawal(address indexed recipient, uint256 amount);

    constructor(
        QQL _qql,
        MintPass _pass,
        uint256 _blessingFee
    ) {
        qql_ = _qql;
        pass_ = _pass;
        blessingFee_ = _blessingFee;
        emit BlessingFeeUpdate(0, _blessingFee);
    }

    /// Change the blessing fee. May only be called by the owner.
    function setBlessingFee(uint256 _blessingFee) external onlyOwner {
        emit BlessingFeeUpdate(blessingFee_, _blessingFee);
        blessingFee_ = _blessingFee;
    }

    function isSeedOperatorOrParametricArtist(address operator, bytes32 seed)
        internal
        view
        returns (bool)
    {
        if (operator == address(bytes20(seed))) return true;
        return qql_.isApprovedOrOwnerForSeed(operator, seed);
    }

    /// Returns the "blessing fee", which must be paid to "bless" a seed before it is listed
    /// on the market. The fee is intended as a spam-prevention mechanism, and to pay the
    /// server costs of generating and storing canonical renders of blessed seeds.
    /// If interacting via etherscan: remember, this value is in wei, so 0.01E
    /// would be 10000000000000000
    function blessingFee() external view returns (uint256) {
        return blessingFee_;
    }

    /// Bless a seed, at which point the seed is canonically tracked as part of the seed
    /// marketplace and is available for listing. Blessing a seed does not also list it.
    /// You can only bless a seed if you either own it, or were the parametric artist for it.
    function bless(bytes32 seed) public payable {
        if (!isSeedOperatorOrParametricArtist(msg.sender, seed))
            revert("SeedMarket: unauthorized");
        if (msg.value != blessingFee_) revert("SeedMarket: wrong fee");
        if (blessed_[seed]) revert("SeedMarket: already blessed");
        emit Blessing(seed, msg.sender);
        blessed_[seed] = true;
    }

    /// Bless a seed and simultaneously list it on the Seed Marketplace.
    /// See docs on `bless` and `list`.
    function blessAndList(bytes32 seed, uint256 price) external payable {
        bless(seed);
        list(seed, price);
    }

    /// Check whether a seed has been blessed
    function isBlessed(bytes32 seed) external view returns (bool) {
        return blessed_[seed];
    }

    /// List a seed on the marketplace, specifying a price.
    /// Someone who wants to use the seed can trustlessly mint it using their own
    /// QQL mint pass, provided that they transfer you the requested `price`.
    /// If using this function on etherscan: remember that price is wei, so
    /// 1 ether would be 1000000000000000000
    function list(bytes32 seed, uint256 price) public {
        if (!qql_.isApprovedOrOwnerForSeed(msg.sender, seed))
            revert("SeedMarket: unauthorized");
        if (!blessed_[seed]) revert("SeedMarket: must bless to list");
        qql_.transferSeed(qql_.ownerOfSeed(seed), address(this), seed);
        uint96 price96 = uint96(price);
        if (price96 != price) revert("SeedMarket: price too high");
        listings_[seed] = ListingData({lister: msg.sender, price: price96});
        emit Listing(seed, msg.sender, price);
    }

    /// Retrieve the listing for a given seed (if it exists). Returns it as being
    /// listed by the zero address if unlisted.
    function getListing(bytes32 seed)
        external
        view
        returns (address lister, uint256 price)
    {
        ListingData memory lst = listings_[seed];
        return (lst.lister, uint256(lst.price));
    }

    /// Change the price for a listed seed.
    function reprice(bytes32 seed, uint256 price) external {
        ListingData memory lst = listings_[seed];
        if (lst.lister != msg.sender) revert("SeedMarket: unauthorized");
        lst.price = uint96(price);
        if (lst.price != price) revert("SeedMarket: price too high");
        listings_[seed] = lst;
        emit Listing(seed, msg.sender, price);
    }

    /// Remove the listing for a listed seed, making it no longer available for sale on the
    /// market. May only be called by the address that listed that seed. The seed will remain
    /// blessed
    function delist(bytes32 seed) external {
        if (listings_[seed].lister != msg.sender)
            revert("SeedMarket: unauthorized");
        delete listings_[seed];
        qql_.transferSeed(address(this), msg.sender, seed);
        emit Delisting(seed);
    }

    /// Fill a listing, purchasing a seed from the marketplace and using it to mint a QQL.
    /// This is called by the seed purchaser. They must pay the requested amount by the seed
    /// lister, and must have access to a mint pass.
    function fillListing(bytes32 seed, uint256 mintPassId) external payable {
        ListingData memory lst = listings_[seed];
        address payable lister = payable(lst.lister);
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
            lister.sendValue(price);
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

    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        emit Withdrawal(recipient, balance);
        recipient.sendValue(balance);
    }
}