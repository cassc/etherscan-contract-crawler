// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import './Params.sol';


contract RENTS is RENTSPARAMS {

    function setParams(uint _fee, address _discounts, address _methods) external onlyOwner {
        (bool success, ) = _methods.delegatecall(msg.data);
        require(success);
    }

    function get(uint rentId) external view returns(Rent memory) {
        return rents[rentId];
    }

    function operationDiscountCosts(
        address buyer, 
        uint rentId
    ) public view returns(
        uint discount,
        uint operationFee,
        uint operationFeeDiscount,
        uint bmarketFee,
        uint totalToPay
    ) {
        discount = IDiscounts(discounts).calculateDiscount(buyer);
        operationFee = rents[rentId].fee / fee;
        operationFeeDiscount = discount == 1 ? 0 : operationFee / discount;
        bmarketFee = operationFee - operationFeeDiscount;
        totalToPay = rents[rentId].fee - operationFeeDiscount;
    }

    function create(
        address[] calldata _nftAddresses, 
        uint[] calldata _nftIds, 
        uint[] calldata _nftAmounts, 
        uint32[] calldata _nftTypes, 
        uint _valability, 
        uint _price, 
        uint _fee, 
        address _currency
    ) external {
        (bool success, ) = methods.delegatecall(msg.data);
        require(success);
    }

    function cancel(uint rentId) external nonReentrant {
        (bool success, ) = methods.delegatecall(msg.data);
        require(success);
    }

    function rent(uint rentId) external payable nonReentrant {
        (bool success, ) = methods.delegatecall(msg.data);
        require(success);
    }

    function finish(uint rentId) external nonReentrant {
        (bool success, ) = methods.delegatecall(msg.data);
        require(success);
    }

    function terminate(uint rentId) external nonReentrant {
        (bool success, ) = methods.delegatecall(msg.data);
        require(success);
    }

}