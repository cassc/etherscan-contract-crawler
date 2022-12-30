// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./factory/Factory.sol";

import "./security/ReEntrancyGuard.sol";

import "./helpers/TransactionFee.sol";
import "./helpers/Oracle.sol";
import "./helpers/Withdraw.sol";

contract Marketplace is
    Factory,
    ReEntrancyGuard,
    TransactionFee,
    Oracle,
    Withdraw
{
    using SafeMath for uint256;

    struct Listing {
        uint256 listing_id;
        address owner;
        bool is_active;
        uint256 token_id;
        uint256 price;
    }

    // este maping almacena todos los nft  en el smart contract
    mapping(address => mapping(uint256 => Listing)) private listings;

    /// @dev buy a nft from the marketplace
    function buyNative(
        uint256 collectionID,
        uint256 listing_id
    ) public payable noReentrant {
        require(msg.value > 0, "Buy Native: Send  buy some tokens");

        /// @dev valid if the token is active
        require(_isActive, "Buy Native: Token is not active");

        /// @dev get data of the listing from the marketplace nft
        Collection storage collection = ListCollections[collectionID];

        /// @dev  valid if the collection is active
        require(
            listings[collection.sc_address][listing_id].is_active,
            "Buy Native:: Listing is not active"
        );

        /// @dev get the price from the nft
        uint256 priceNft = listings[collection.sc_address][listing_id].price;

        /// @dev get data oracle in usd
        uint256 latestPrice = getLatestPrice(
            _addressOracle,
            _addressDecimalOracle
        );

        // @dev tranformar el token enviado a 18 decimales
        uint256 amountTo18 = msg.value;

        // @dev calculate the amount of token to buy
        uint256 valueInUsd = latestPrice.mul(amountTo18);

        /// @dev price listing
        require(valueInUsd >= priceNft, "Buy Native:: Price is too low");

        /// @dev remove the nft from the marketplace
        listings[collection.sc_address][listing_id].is_active = false;

        uint256 fee1 = calculateFee(msg.value, _fbpa1);
        require(
            payable(a1).send(fee1),
            "Buy Native: Error sending money to a1"
        );

        uint256 fee2 = calculateFee(msg.value, _fbpa2);
        require(
            payable(a1).send(fee2),
            "Buy Native: Error sending money to a2"
        );

        /// @dev transfer the token to the seller
        uint256 fullSellet = getFullSeller();
        uint256 seller = calculateFee(msg.value, fullSellet);
        require(
            payable(a1).send(seller),
            "Buy Native: Error sending money to seller"
        );

        /// @dev transfer the token to the buyer
        IERC721(collection.sc_address).transferFrom(
            address(this),
            _msgSender(),
            listings[collection.sc_address][listing_id].token_id
        );
    }

    /// @dev add a new listing to the marketplace
    function addListing(
        uint256 collectionID,
        uint256 token_id,
        uint256 price
    ) public noReentrant {
        /// @dev check if the price is valid
        require(price > 0, "Add Listing: The price must be greater than 0");

        /// @dev get the collection address
        Collection storage collection = ListCollections[collectionID];

        require(collection.active, "Add Listing: The collection is not active");

        /// @dev get count of listings of contract
        uint256 listing_count = countCollection[collection.sc_address];

        /// @dev is approve to add listing
        require(
            ERC721(collection.sc_address).isApprovedForAll(
                _msgSender(),
                address(this)
            ),
            "Add Listing: You don't have permission to add a listing"
        );

        /// @dev is owner of the nft
        require(
            _msgSender() == IERC721(collection.sc_address).ownerOf(token_id),
            "Add Listing: Sender must be owner"
        );

        /// @dev add the listing
        listings[collection.sc_address][listing_count] = Listing(
            listing_count,
            _msgSender(),
            true,
            token_id,
            price
        );

        /// listing_count = listing_count.add(1);
        countCollection[collection.sc_address] = listing_count.add(1);

        /// @dev tranfer the token to the contract
        IERC721(collection.sc_address).transferFrom(
            _msgSender(),
            address(this),
            token_id
        );
    }

    /// @dev remove a listing from the marketplace
    function removeListing(
        uint256 collectionID,
        uint256 listing_id
    ) external noReentrant {
        /// @dev get the collection address
        Collection storage collection = ListCollections[collectionID];

        require(
            listings[collection.sc_address][listing_id].owner == _msgSender(),
            "Remove Listing: Sender must be owner"
        );

        require(
            listings[collection.sc_address][listing_id].is_active,
            "Remove Listing: Listing is not active"
        );

        /// @dev remove the listing
        listings[collection.sc_address][listing_id].is_active = false;
        IERC721(collection.sc_address).transferFrom(
            address(this),
            _msgSender(),
            listings[collection.sc_address][listing_id].token_id
        );
    }

    /// @dev get the listing of the marketplace for contract
    function getListActive(
        uint256 collectionID
    ) external view returns (Listing[] memory) {
        Collection storage collection = ListCollections[collectionID];

        uint256 listing_count = countCollection[collection.sc_address];

        unchecked {
            Listing[] memory p = new Listing[](listing_count);

            for (uint256 i = 0; i < listing_count; i++) {
                Listing storage s = listings[collection.sc_address][i];

                // @dev if the listing is active
                if (listings[collection.sc_address][i].is_active) {
                    p[i] = s;
                }
            }

            return p;
        }
    }

    /// @dev get the listing of the marketplace for contract
    function getListActivePaginated(
        uint256 _collectionID,
        uint256 _from,
        uint256 _to
    ) external view returns (Listing[] memory) {
        Collection storage collection = ListCollections[_collectionID];

        uint256 listing_count = countCollection[collection.sc_address];

        uint256 to = (_to > listing_count) ? listing_count : _to;

        unchecked {
            Listing[] memory p = new Listing[](to);

            for (uint256 i = _from; i < _to; i++) {
                Listing storage s = listings[collection.sc_address][i];
                // @dev if the listing is active
                if (listings[collection.sc_address][i].is_active) {
                    p[i] = s;
                }
            }
            return p;
        }
    }

    /// @dev - emergency stop - remove all listings from the marketplace
    function emergencyStop(address sc_address) public noReentrant {
        /// @dev get all listings
        for (uint256 i = 0; i < countCollection[sc_address]; i++) {
            listings[_msgSender()][i].is_active = false;
        }
    }

    /// @dev emergency tracfer - remove all listings from the marketplace
    function emergencyTransfer(
        uint256 collectionID,
        uint256 listing_id,
        address new_owner
    ) public onlyAdmin noReentrant {
        /// @dev get the collection address
        Collection storage collection = ListCollections[collectionID];

        /// @dev remove the listing
        listings[collection.sc_address][listing_id].is_active = false;

        IERC721(collection.sc_address).transferFrom(
            address(this),
            new_owner,
            listings[collection.sc_address][listing_id].token_id
        );
    }

    /// @dev get the listing of the marketplace for contract
    function getActiveListings(
        uint256 collectionID,
        uint256 index
    ) external view returns (uint256) {
        /// @dev get the collection address
        Collection storage collection = ListCollections[collectionID];

        // @dev get the listing of the contract
        uint256 listing_count = countCollection[collection.sc_address];
        unchecked {
            uint256 j = 0;
            for (uint256 i = 0; i < listing_count; i++) {
                if (listings[collection.sc_address][i].is_active) {
                    if (index == j) {
                        return i;
                    }
                    j += 1;
                }
            }
            return 0;
        }
    }

    /// @dev get the listing of the marketplace for contract
    function getListingsByOwner(
        uint256 collectionID,
        address owner,
        uint256 index
    ) external view returns (uint256) {
        /// @dev get the collection address
        Collection storage collection = ListCollections[collectionID];

        // @dev get the listing of the contract
        uint256 listing_count = countCollection[collection.sc_address];
        unchecked {
            uint256 j = 0;
            for (uint256 i = 0; i < listing_count; i++) {
                if (
                    listings[collection.sc_address][i].is_active &&
                    listings[collection.sc_address][i].owner == owner
                ) {
                    if (index == j) {
                        return i;
                    }
                    j += 1;
                }
            }
            return 0;
        }
    }

    // @dev get the listing of the marketplace for contract
    function getListingsByOwnerCount(
        uint256 collectionID,
        address owner
    ) external view returns (uint256) {
        /// @dev get the collection address
        Collection storage collection = ListCollections[collectionID];

        // @dev get the listing of the contract
        uint256 listing_count = countCollection[collection.sc_address];

        unchecked {
            uint256 result = 0;
            for (uint256 i = 0; i < listing_count; i++) {
                if (
                    listings[collection.sc_address][i].is_active &&
                    listings[collection.sc_address][i].owner == owner
                ) {
                    result += 1;
                }
            }
            return result;
        }
    }

    /// @dev get count of listings of contract
    function getListingsCount(
        uint256 collectionID
    ) external view returns (uint256) {
        /// @dev get the collection address
        Collection storage collection = ListCollections[collectionID];

        return countCollection[collection.sc_address];
    }

    /// @dev get data listing nft
    function getListing(
        uint256 collectionID,
        uint256 listing_id
    ) external view returns (Listing memory listing) {
        /// @dev get the collection address
        Collection storage collection = ListCollections[collectionID];

        return listings[collection.sc_address][listing_id];
    }

    // @dev get the listing of the marketplace for contract
    function getActiveListingsCount(
        uint256 collectionID
    ) public view returns (uint256) {
        /// @dev get the collection address
        Collection storage collection = ListCollections[collectionID];

        // @dev get the listing of the contract
        uint256 listing_count = countCollection[collection.sc_address];

        unchecked {
            uint256 result = 0;
            for (uint256 i = 0; i < listing_count; i++) {
                if (listings[collection.sc_address][i].is_active) {
                    result += 1;
                }
            }
            return result;
        }
    }
}