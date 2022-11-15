// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import "./ERC721SaleBase.sol";

contract ERC721Sale is ERC721SaleBase {
    using ArrayLibrary for address[];
    using ArrayLibrary for uint256[];

    function createSale(
        address contractAddr,
        uint256 tokenId,
        uint8 payment,
        uint256 startPrice,
        uint256 endPrice,
        uint256 duration
    ) external virtual isProperContract(contractAddr) {
        require(startPrice >= endPrice, "Invalid Price");
        IERC721(contractAddr).transferFrom(msg.sender, address(this), tokenId);
        uint256 timestamp = block.timestamp;
        tokenIdToSales[contractAddr][tokenId] = Sale(
            msg.sender,
            payment,
            startPrice,
            endPrice,
            timestamp,
            duration,
            new address[](0),
            new uint256[](0)
        );
        saleTokenIds[contractAddr].push(tokenId);
        saleTokenIdsBySeller[msg.sender][contractAddr].push(tokenId);
        emit SaleCreated(
            contractAddr,
            tokenId,
            payment,
            startPrice,
            endPrice,
            timestamp,
            duration
        );
    }

    function buy(address contractAddr, uint256 tokenId)
        external
        payable
        virtual
        isProperContract(contractAddr)
        nonReentrant
    {
        Sale memory sale = tokenIdToSales[contractAddr][tokenId];
        require(sale.startPrice > 0, "Not On Sale");
        require(sale.seller != msg.sender, "Is Seller");
        uint256 price = getCurrentPrice(contractAddr, tokenId);
        PaymentLibrary.escrowFund(tokenAddrs[sale.payment], price);
        PaymentLibrary.payFund(
            tokenAddrs[sale.payment],
            price,
            sale.seller,
            royaltyAddr,
            royaltyPercent,
            contractAddr,
            tokenId
        );
        _removeSale(contractAddr, tokenId);
        IERC721(contractAddr).transferFrom(address(this), msg.sender, tokenId);
        emit SaleSuccessful(
            contractAddr,
            tokenId,
            sale.payment,
            price,
            msg.sender
        );
    }

    function cancelSale(address contractAddr, uint256 tokenId)
        external
        isProperContract(contractAddr)
    {
        Sale memory sale = tokenIdToSales[contractAddr][tokenId];
        require(sale.startPrice > 0, "Not On Sale");
        require(sale.seller == msg.sender, "Not Seller");
        IERC721(contractAddr).transferFrom(address(this), sale.seller, tokenId);
        _removeSale(contractAddr, tokenId);
        emit SaleCancelled(contractAddr, tokenId);
    }

    function makeOffer(
        address contractAddr,
        uint256 tokenId,
        uint256 price
    ) external payable isProperContract(contractAddr) {
        Sale memory sale = tokenIdToSales[contractAddr][tokenId];
        require(sale.startPrice > 0, "Not On Sale");
        require(sale.seller != msg.sender, "Is Seller");
        require(
            price < getCurrentPrice(contractAddr, tokenId),
            "Invalid Offer Price"
        );
        PaymentLibrary.escrowFund(tokenAddrs[sale.payment], price);
        tokenIdToSales[contractAddr][tokenId].offerers.push(msg.sender);
        tokenIdToSales[contractAddr][tokenId].offerPrices.push(price);
        emit OfferCreated(contractAddr, tokenId, price, msg.sender);
    }

    function cancelOffer(address contractAddr, uint256 tokenId)
        external
        isProperContract(contractAddr)
    {
        Sale storage sale = tokenIdToSales[contractAddr][tokenId];
        require(sale.startPrice > 0, "Not On Sale");
        require(sale.seller != msg.sender, "Is Seller");
        uint256 i;
        for (
            ;
            i < sale.offerers.length && sale.offerers[i] != msg.sender;
            ++i
        ) {}
        require(i < sale.offerers.length, "No Offer");
        uint256 price = sale.offerPrices[i];
        PaymentLibrary.transferFund(
            tokenAddrs[sale.payment],
            price,
            msg.sender
        );
        tokenIdToSales[contractAddr][tokenId].offerers.removeAt(i);
        tokenIdToSales[contractAddr][tokenId].offerPrices.removeAt(i);
        emit OfferCancelled(contractAddr, tokenId, price, msg.sender);
    }

    function acceptOffer(address contractAddr, uint256 tokenId)
        external
        isProperContract(contractAddr)
    {
        Sale memory sale = tokenIdToSales[contractAddr][tokenId];
        require(sale.startPrice > 0, "Not On Sale");
        require(sale.seller == msg.sender, "Not Seller");
        uint256 maxOffererId;
        require(sale.offerers.length > 0, "No Offer");
        for (uint256 i = 1; i < sale.offerers.length; ++i) {
            if (sale.offerPrices[i] > sale.offerPrices[maxOffererId]) {
                maxOffererId = i;
            }
        }
        uint256 price = sale.offerPrices[maxOffererId];
        address offerer = sale.offerers[maxOffererId];
        PaymentLibrary.payFund(
            tokenAddrs[sale.payment],
            price,
            msg.sender,
            royaltyAddr,
            royaltyPercent,
            contractAddr,
            tokenId
        );
        IERC721(contractAddr).transferFrom(address(this), offerer, tokenId);
        tokenIdToSales[contractAddr][tokenId].offerers.removeAt(maxOffererId);
        tokenIdToSales[contractAddr][tokenId].offerPrices.removeAt(
            maxOffererId
        );
        _removeSale(contractAddr, tokenId);
        emit OfferAccepted(contractAddr, tokenId, sale.payment, price, offerer);
    }
}