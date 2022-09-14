/**
 *Submitted for verification at Etherscan.io on 2022-09-13
*/

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// CryptoCatsHelper v0.9.1
//
// https://github.com/bokkypoobah/TokenToolz
//
// Deployed to Mainnet 0xa029435F2DbD8721E2Ad33a5B1b8476F17c7F47f
//
// SPDX-License-Identifier: MIT
//
// Enjoy. And hello, from the past.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2022. The MIT Licence.
// ----------------------------------------------------------------------------

// CryptoCatsMarkets @ 0x088C6Ad962812b5Aa905BA6F3c5c145f9D4C079f
interface CryptoCatsMarkets {
    struct Offer {
        bool isForSale;
        uint catIndex;
        address seller;
        uint minPrice;
        address sellOnlyTo;
    }

    function catIndexToAddress(uint256 catId) external view returns (address owner);
    function attributeType(uint256 attributeIndex) external view returns (string memory attributeName);
    function catAttributes(uint256 catId, uint256 attributeIndex) external view returns (string memory attributes);
    function catsForSale(uint256 catId) external view returns (Offer memory offer);
}


contract CryptoCatsHelper {
    function getCatData(CryptoCatsMarkets cryptoCatsMarket, uint[] memory catIds) public view returns (
        address[] memory owners,
        string[] memory attributeNames,
        string[6][] memory attributes,
        CryptoCatsMarkets.Offer[] memory offers
    ) {
        uint length = catIds.length;
        attributeNames = new string[](6);
        owners = new address[](length);
        attributes = new string[6][](length);
        offers = new CryptoCatsMarkets.Offer[](length);
        for (uint i = 0; i < 6; i++) {
            attributeNames[i] = cryptoCatsMarket.attributeType(i);
        }
        for (uint i = 0; i < length;) {
            owners[i] = cryptoCatsMarket.catIndexToAddress(i);
            for (uint j = 0; j < 6; j++) {
                attributes[i][j] = cryptoCatsMarket.catAttributes(i, j);
            }
            offers[i] = cryptoCatsMarket.catsForSale(i);
            unchecked {
                i++;
            }
        }
    }
}