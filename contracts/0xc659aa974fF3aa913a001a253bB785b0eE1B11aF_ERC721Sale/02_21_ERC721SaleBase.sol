// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./MarketplaceBase.sol";

abstract contract ERC721SaleBase is MarketplaceBase {
    using ArrayLibrary for uint256[];

    struct Sale {
        address seller;
        uint8 payment;
        uint256 startPrice;
        uint256 endPrice;
        uint256 startedAt;
        uint256 duration;
        address[] offerers;
        uint256[] offerPrices;
    }

    mapping(address => uint256[]) internal saleTokenIds;
    mapping(address => mapping(address => uint256[]))
        internal saleTokenIdsBySeller;

    mapping(address => mapping(uint256 => Sale)) internal tokenIdToSales;

    event SaleCreated(
        address contractAddr,
        uint256 tokenId,
        uint8 payment,
        uint256 startPrice,
        uint256 endPrice,
        uint256 time,
        uint256 duration
    );
    event SaleSuccessful(
        address contractAddr,
        uint256 tokenId,
        uint8 payment,
        uint256 price,
        address buyer
    );
    event SaleCancelled(address contractAddr, uint256 tokenId);
    event OfferCreated(
        address contractAddr,
        uint256 tokenId,
        uint256 price,
        address offerer
    );
    event OfferCancelled(
        address contractAddr,
        uint256 tokenId,
        uint256 price,
        address offerer
    );
    event OfferAccepted(
        address contractAddr,
        uint256 tokenId,
        uint8 payment,
        uint256 price,
        address offerer
    );

    function _removeSale(address contractAddr, uint256 tokenId) internal {
        saleTokenIds[contractAddr].remove(tokenId);
        Sale memory sale = tokenIdToSales[contractAddr][tokenId];
        saleTokenIdsBySeller[sale.seller][contractAddr].remove(tokenId);
        uint256 length = sale.offerers.length;
        for (uint256 i; i < length; ++i) {
            claimable[sale.offerers[i]][sale.payment] += sale.offerPrices[i];
        }
        delete tokenIdToSales[contractAddr][tokenId];
    }

    function getSale(address contractAddr, uint256 tokenId)
        external
        view
        isProperContract(contractAddr)
        returns (Sale memory sale, uint256 currentPrice)
    {
        sale = tokenIdToSales[contractAddr][tokenId];
        require(sale.startPrice > 0, "Not On Sale");
        currentPrice = getCurrentPrice(contractAddr, tokenId);
    }

    function getSales(address contractAddr)
        external
        view
        isProperContract(contractAddr)
        returns (Sale[] memory sales, uint256[] memory currentPrices)
    {
        uint256 length = saleTokenIds[contractAddr].length;
        sales = new Sale[](length);
        currentPrices = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            uint256 tokenId = saleTokenIds[contractAddr][i];
            sales[i] = tokenIdToSales[contractAddr][tokenId];
            currentPrices[i] = getCurrentPrice(contractAddr, tokenId);
        }
    }

    function getSalesBySeller(address contractAddr, address seller)
        external
        view
        isProperContract(contractAddr)
        returns (Sale[] memory sales, uint256[] memory currentPrices)
    {
        uint256 length = saleTokenIdsBySeller[seller][contractAddr].length;
        sales = new Sale[](length);
        currentPrices = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            uint256 tokenId = saleTokenIdsBySeller[seller][contractAddr][i];
            sales[i] = tokenIdToSales[contractAddr][tokenId];
            currentPrices[i] = getCurrentPrice(contractAddr, tokenId);
        }
    }

    function getCurrentPrice(address contractAddr, uint256 tokenId)
        public
        view
        isProperContract(contractAddr)
        returns (uint256)
    {
        Sale memory sale = tokenIdToSales[contractAddr][tokenId];
        require(sale.startPrice > 0, "Not On Sale");
        uint256 timestamp = block.timestamp;
        if (timestamp >= sale.startedAt + sale.duration) {
            return sale.endPrice;
        }
        return
            sale.startPrice -
            ((sale.startPrice - sale.endPrice) * (timestamp - sale.startedAt)) /
            sale.duration;
    }

    function getSaleTokens(address contractAddr)
        public
        view
        isProperContract(contractAddr)
        returns (uint256[] memory)
    {
        return saleTokenIds[contractAddr];
    }

    function getSaleTokensBySeller(address contractAddr, address seller)
        public
        view
        isProperContract(contractAddr)
        returns (uint256[] memory)
    {
        return saleTokenIdsBySeller[seller][contractAddr];
    }
}