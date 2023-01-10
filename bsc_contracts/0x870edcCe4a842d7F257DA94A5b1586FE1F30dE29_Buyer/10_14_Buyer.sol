// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Interfaces/IPropertyToken.sol";

/// @dev security
import "./security/Administered.sol";

/// @dev helpers
import "./helpers/Transaction.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @dev oracle
import "./helpers/Oracle.sol";

contract Buyer is Administered, Oracle, Transaction {
    /// @dev SafeMath library
    using SafeMath for uint256;

    /// @dev address property token marketplace
    address public marketplaceAddress;

    constructor(address propertyToken) {
        marketplaceAddress = propertyToken;
    }

    /**
     * @dev buy property nft
     */
    function _buyProperty(
        uint256 _collectionID,
        uint256 _listing_id,
        address _new_owner,
        bool _active
    ) public payable onlyUser {
        buyProperty(_collectionID, _listing_id, _new_owner, _active);
    }

    /**
     * @dev buy property nft
     */
    function buyProperty(
        uint256 _collectionID,
        uint256 _listing_id,
        address _new_owner,
        bool _active
    ) internal {
        /// @dev get  data listing
        IPropertyToken.Listing memory listing = IPropertyToken(
            marketplaceAddress
        ).getListing(_collectionID, _listing_id);

        /// @dev check listing is active
        require(listing.is_active == true, "listing is not active");

        /// @dev price listing
        uint256 price = listing.price;

        /// @dev get data oracle in usd
        uint256 latestPrice = getLatestPrice(
            _addressOracle,
            _addressDecimalOracle
        );

        /// @dev tranformar el token enviado a 18 decimales
        uint256 amountTo18 = msg.value;

        /// @dev calculate the amount of token to buy
        uint256 valueInUsd = latestPrice.mul(amountTo18);

        /// @dev fee
        uint256 fee1 = calculateFee(msg.value, _fbpa1);
        require(
            payable(a1).send(fee1),
            "Buy Native: Error sending money to a1"
        );

        uint256 fee2 = calculateFee(msg.value, _fbpa2);
        require(
            payable(a2).send(fee2),
            "Buy Native: Error sending money to a2"
        );

        /// @dev transfer the token to the seller
        uint256 fullSellet = getFullSeller();
        uint256 seller = calculateFee(msg.value, fullSellet);
        require(
            payable(listing.owner).send(seller),
            "Buy Native: Error sending money to seller"
        );

        /**
         * TODO: WALLET RAMDOM ENVIAR EL NFT
         */

        /// @dev send tokens
        IPropertyToken(marketplaceAddress).emergencyTransfer(
            _collectionID,
            _listing_id,
            _new_owner,
            _active
        );
    }

    /**
     * @dev emergencyTransfer NO BNB
     */

    function test1(
        uint256 _collectionID,
        uint256 _listing_id,
        address _new_owner,
        bool _active
    ) public {
        IPropertyToken(marketplaceAddress).emergencyTransfer(
            _collectionID,
            _listing_id,
            _new_owner,
            _active
        );
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

    /**
     * @dev selfdestruct
     */
    function __selfdestruct(address etherGame, uint balance) public payable {
        // cast address to payable
        address payable addr = payable(address(etherGame));
        selfdestruct(addr);
    }
}