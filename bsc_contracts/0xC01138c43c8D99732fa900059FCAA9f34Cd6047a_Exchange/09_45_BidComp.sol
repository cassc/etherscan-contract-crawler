// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract BidComp{
    function _bid(address bidder, address currency, uint256 price) internal {
        if (currency == address(0)){
            require(msg.value == price, "Exchange: Match price and value failed");
        }else{            
            IERC20Upgradeable erc20 =  IERC20Upgradeable(currency);
            require(erc20.transferFrom(bidder, address(this), price), "BidComp: Bid with ERC20 token failed");
        }
    }

    function _returnBid(address lastBidder, address currency, uint256 price) internal {
        if (currency == address(0)){
            payable(lastBidder).transfer(price);
        }else{
            IERC20Upgradeable erc20 =  IERC20Upgradeable(currency);
            require(erc20.transfer(lastBidder, price), "BidComp: returnBid failed");
        }
    }
}