// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTM.sol";

abstract contract NFTMTokenMarketFee is NFTM {

    uint256 internal _marketFeeCoin; //change datgatype to uint8?

    function buyNFTWithLox(
        address tokenAddr,
        uint256 tokenId
    ) public payable nonReentrant onlySellingToken(tokenAddr,tokenId) onlyValidToken(tokenAddr, tokenId){

        uint256 marketFeeWEI = _centToWEI(_marketFeeCENT);

        SaleItem memory item = _nftSaleItems[tokenAddr][tokenId];
        _marketCoin.useCoinFrom(msg.sender, _marketFeeCoin);
        
        _executeSaleItem(tokenAddr, tokenId, item.price - marketFeeWEI, item.seller, item.creator, item.creatorFee, 0);

    }
        /*
        itemprice < market fee
        */
    function checkNFTPriceWithLox(
        address tokenAddr,
        uint256 tokenId
    ) public view onlySellingToken(tokenAddr, tokenId) onlyValidToken(tokenAddr, tokenId) returns(uint256){

        uint256 marketFeeWEI = _centToWEI(_marketFeeCENT);
        SaleItem memory item = _nftSaleItems[tokenAddr][tokenId];
        return item.price - marketFeeWEI;

    }

    function setMarketFeeCoin(uint256 marketFeeCoin) external onlyOwner {
        _marketFeeCoin = marketFeeCoin;
    }

    function getMarketFeeCoin() public view returns (uint256) {
        return _marketFeeCoin;
    }
}