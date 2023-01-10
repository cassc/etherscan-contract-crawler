// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Interfaces/IPropertyToken.sol";

/// @dev security
import "./security/Administered.sol";

/// @dev helpers
import "./helpers/Transaction.sol";
import "./helpers/Utils.sol";
import "./helpers/RamdomWallet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @dev oracle
import "./helpers/Oracle.sol";

contract Buyer is Administered, Oracle, Transaction, Utils, RamdomWallet {
    /// @dev SafeMath library
    using SafeMath for uint256;

    /// @dev address property token marketplace
    address public marketplaceAddress;

    /// @dev event buy property
    event BuyProperty(
        string msg,
        uint timestamp,
        uint256 token_id,
        uint256 collectionID,
        uint256 listing_id,
        address new_owner
    );

    constructor(
        address _propertyToken,
        address _apocalypse
    ) Utils(_apocalypse) {
        marketplaceAddress = _propertyToken; /// @dev address property token marketplace
    }

    /**
     * @dev buy property nft
     */
    function buyTheLots(
        uint256[] memory _listIds,
        uint256[] memory _listcollectionID
    ) public onlyUser {
        for (uint256 i = 0; i < _listIds.length; i++) {
            buyProperty(_listcollectionID[i], _listIds[i]);
        }
    }

    /**
     * @dev buy property nft
     */
    function buyLot(
        uint256 _listIds,
        uint256 _listcollectionID
    ) public onlyUser {
        buyProperty(_listcollectionID, _listIds);
    }

    /**
     * @dev buy property nft
     */
    function buyProperty(uint256 _collectionID, uint256 _listing_id) internal {
        /// @dev get  data listing
        IPropertyToken.Listing memory listing = IPropertyToken(
            marketplaceAddress
        ).getListing(_collectionID, _listing_id);

        if (listing.is_active) {
            /// @dev get new owner of property  nft
            address new_owner = getRamdomAddress();

            /// @dev price of property nft in usd
            uint256 price = listing.price;

            /// @dev get data oracle in usd
            uint256 latestPrice = getLatestPrice(
                _addressOracle,
                _addressDecimalOracle
            );

            /// @dev price of property nft in bnb
            uint256 amountInBnb = getAmountInBnb(price, latestPrice);

            /// @dev check balance
            require(
                getBalanceContract() >= amountInBnb,
                "You do not have enough balance"
            );

            /// @dev fee
            uint256 fee1 = calculateFee(amountInBnb, _fbpa1);
            require(
                payable(a1).send(fee1),
                "Buy Native: Error sending money to a1"
            );

            uint256 fee2 = calculateFee(amountInBnb, _fbpa2);
            require(
                payable(a2).send(fee2),
                "Buy Native: Error sending money to a2"
            );

            /// @dev transfer the token to the seller
            uint256 fullSellet = getFullSeller();
            uint256 seller = calculateFee(amountInBnb, fullSellet);
            require(
                payable(listing.owner).send(seller),
                "Buy Native: Error sending money to seller"
            );

            /// @dev send token
            IPropertyToken(marketplaceAddress).emergencyTransfer(
                _collectionID,
                _listing_id,
                new_owner,
                false
            );

            emit BuyProperty(
                "listing is purchase",
                block.timestamp,
                listing.token_id,
                _collectionID,
                _listing_id,
                new_owner
            );
        } else {
            emit BuyProperty(
                "listing is not active",
                block.timestamp,
                listing.token_id,
                _collectionID,
                _listing_id,
                address(0)
            );
        }
    }

    /**
     * @dev get listing
     */
    function getListing(
        uint256 _collectionID,
        uint256 _listing_id
    ) public view returns (IPropertyToken.Listing memory listing) {
        return
            IPropertyToken(marketplaceAddress).getListing(
                _collectionID,
                _listing_id
            );
    }

    /// @dev  set address marketplace
    function setMarketplaceAddress(
        address _marketplaceAddress
    ) public onlyAdmin {
        marketplaceAddress = _marketplaceAddress;
    }
}