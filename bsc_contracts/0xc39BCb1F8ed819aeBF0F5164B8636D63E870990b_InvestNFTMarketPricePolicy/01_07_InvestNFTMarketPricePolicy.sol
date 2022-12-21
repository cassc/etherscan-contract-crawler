// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/Assets.sol";
import "../RecoverableFunds.sol";


contract InvestNFTMarketPricePolicy is Ownable, RecoverableFunds {

    uint public price;

    function getPrice(uint count, Assets.Key assetKey) public view returns (uint) {
        return price;
    }

    function getTokensForSpecifiedAmount(uint amount, Assets.Key assetKey) public view returns (uint) {
        return amount / price;
    }

    function setPrice(uint newPrice) public onlyOwner {
        price = newPrice;
    }

    function retrieveTokens(address recipient, address tokenAddress) external onlyOwner {
        _retrieveTokens(recipient, tokenAddress);
    }

    function retrieveETH(address payable recipient) external onlyOwner {
        _retrieveETH(recipient);
    }

}