// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import './Params.sol';


contract AUCTIONS is AUCTIONSPARAMS {

    function setParams(uint _fee, address _discounts, address _methods) external onlyOwner {
        (bool success, ) = _methods.delegatecall(msg.data);
        require(success);
    }
    
    function get(uint auctionId) external view returns(Auction memory) {
        return auctions[auctionId];
    }

    function operationDiscountCosts(
        address buyer, 
        uint auctionId
    ) public view returns(
        uint discount,
        uint operationFee,
        uint operationFeeDiscount,
        uint bmarketFee,
        uint totalToPay
    ) {
        discount = IDiscounts(discounts).calculateDiscount(buyer);
        operationFee = auctions[auctionId].price / fee;
        operationFeeDiscount = discount == 1 ? 0 : operationFee / discount;
        bmarketFee = operationFee - operationFeeDiscount;
        totalToPay = auctions[auctionId].price - operationFeeDiscount;
    }

    function create(
        address[] calldata _nftAddresses, 
        uint[] calldata _nftIds, 
        uint[] calldata _nftAmounts, 
        uint32[] calldata _nftTypes, 
        uint _price, 
        uint _tax, 
        address _currency
    ) external {
        (bool success, ) = methods.delegatecall(msg.data);
        require(success);      
    }
    
    function cancel(uint auctionId) external nonReentrant {
        (bool success, ) = methods.delegatecall(msg.data);
        require(success);
    }
    
    function bid(uint auctionId) external payable nonReentrant {
        (bool success, ) = methods.delegatecall(msg.data);
        require(success);
    }

    function finish(uint auctionId) external nonReentrant {
        (bool success, ) = methods.delegatecall(msg.data);
        require(success);
    }

}