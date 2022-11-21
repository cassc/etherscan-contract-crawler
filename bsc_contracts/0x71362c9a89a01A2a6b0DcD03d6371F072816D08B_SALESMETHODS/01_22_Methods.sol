// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import './Params.sol';


contract SALESMETHODS is SALESPARAMS {

    function setParams(uint _fee, address _discounts, address _methods) external onlyOwner {
        require(_fee > 0);
        fee = _fee;
        discounts = _discounts;
        methods = _methods;
    }

    function get(uint saleId) external view returns(Sale memory) {
        return sales[saleId];
    }

    function operationDiscountCosts(
        address buyer, 
        uint saleId
    ) public view returns(
        uint discount,
        uint operationFee,
        uint operationFeeDiscount,
        uint bmarketFee,
        uint totalToPay
    ) {
        discount = IDiscounts(discounts).calculateDiscount(buyer);
        operationFee = sales[saleId].price / fee;
        operationFeeDiscount = discount == 1 ? 0 : operationFee / discount;
        bmarketFee = operationFee - operationFeeDiscount;
        totalToPay = sales[saleId].price - operationFeeDiscount;
    }

    function sell(
        address[] calldata _nftAddresses, 
        uint[] calldata _nftIds, 
        uint[] calldata _nftAmounts, 
        uint32[] calldata _nftTypes, 
        uint _price, 
        address _currency
    ) external {
        require(_price > 0);
        require(_nftAddresses.length > 0);

        checkItemsApproval(msg.sender,_nftAddresses,_nftIds,_nftTypes);  

        sales[id].nftAddresses = _nftAddresses;
        sales[id].nftIds = _nftIds;
        sales[id].nftAmounts = _nftAmounts;
        sales[id].nftTypes = _nftTypes;
        sales[id].price = _price;
        sales[id].currency = _currency;
        sales[id].seller = msg.sender;
        sales[id].status = Status.LISTED;

        emit NewSale(id,sales[id]);
        ++id;
    }

    function cancel(uint saleId) external {
        require(msg.sender == sales[saleId].seller);
        require(sales[saleId].status == Status.LISTED);

        sales[saleId].status = Status.CANCELLED;

        emit Cancellation(saleId,sales[saleId]);
    }

    function buy(uint saleId) external payable {
        require(saleId < id);
        require(sales[saleId].status == Status.LISTED);

        (, , uint operationFeeDiscount, uint bmarketFee, ) = operationDiscountCosts(msg.sender,saleId);

        if ( sales[saleId].currency != address(0) ) {
            require(IERC20(sales[saleId].currency).transferFrom(msg.sender,address(this),sales[saleId].price - operationFeeDiscount));
            require(IERC20(sales[saleId].currency).transferFrom(msg.sender,sales[saleId].seller,sales[saleId].price - bmarketFee));
            require(IERC20(sales[saleId].currency).transferFrom(msg.sender,owner(),bmarketFee));
        } else {
            require(msg.value >= sales[saleId].price - operationFeeDiscount);
            require(payable(sales[saleId].seller).send(sales[saleId].price - bmarketFee));
            require(payable(owner()).send(bmarketFee));
        }

        transferTokens(
            sales[saleId].seller,
            address(this),
            sales[saleId].nftAddresses,
            sales[saleId].nftIds,
            sales[saleId].nftAmounts,
            sales[saleId].nftTypes
        );

        transferTokens(
            address(this),
            msg.sender,
            sales[saleId].nftAddresses,
            sales[saleId].nftIds,
            sales[saleId].nftAmounts,
            sales[saleId].nftTypes
        );

        sales[saleId].status = Status.PURCHASED;
        sales[saleId].buyer = msg.sender;
        
        emit Purchase(saleId,sales[saleId]);
    }

}