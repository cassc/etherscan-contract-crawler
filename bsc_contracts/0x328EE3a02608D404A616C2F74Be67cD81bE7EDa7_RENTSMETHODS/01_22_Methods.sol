// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import './Params.sol';


contract RENTSMETHODS is RENTSPARAMS {

    function setParams(uint _fee, address _discounts, address _methods) external onlyOwner {
        require(_fee > 0);
        fee = _fee;
        discounts = _discounts;
        methods = _methods;
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
        require(_fee * 2 < _price && _valability > 0 && _fee > 0);
        require(_nftAddresses.length > 0);

        checkItemsApproval(msg.sender,_nftAddresses,_nftIds,_nftTypes);  

        rents[id].owner = msg.sender;
        rents[id].valability = _valability;
        rents[id].price = _price;
        rents[id].fee = _fee;
        rents[id].currency = _currency;
        rents[id].nftAddresses = _nftAddresses;
        rents[id].nftIds = _nftIds;
        rents[id].nftAmounts = _nftAmounts;
        rents[id].nftTypes = _nftTypes;
        rents[id].returningTime = 1 days;
        rents[id].status = Status.LISTED;

        emit NewRent(id, rents[id]);
        ++id;
    }

    function cancel(uint rentId) external {
        require(msg.sender == rents[rentId].owner);
        require(rents[rentId].status == Status.LISTED);

        rents[rentId].status = Status.CANCELLED;
        
        emit RentCancelled(rentId,rents[rentId]);
    }

    function rent(uint rentId) external payable {
        require(rents[rentId].expiration == 0 || ( rents[rentId].expiration > 0 && rents[rentId].expiration + rents[rentId].returningTime < block.timestamp ));
        require(rents[rentId].status == Status.LISTED);

        if ( rents[rentId].currency != address(0) ) {
            require(IERC20(rents[rentId].currency).transferFrom(msg.sender, address(this), rents[rentId].price));
        } else {
            require(msg.value >= rents[rentId].price);
        }

        transferTokens(
            rents[rentId].owner,
            address(this),
            rents[rentId].nftAddresses,
            rents[rentId].nftIds,
            rents[rentId].nftAmounts,
            rents[rentId].nftTypes
        );

        transferTokens(
            address(this),
            msg.sender,
            rents[rentId].nftAddresses,
            rents[rentId].nftIds,
            rents[rentId].nftAmounts,
            rents[rentId].nftTypes
        );

        rents[rentId].expiration = block.timestamp + rents[rentId].valability;
        rents[rentId].client = msg.sender;
        rents[rentId].status = Status.RENTED;
        
        emit RentOngoing(rentId,rents[rentId]);
    }

    function finish(uint rentId) external {
        require(msg.sender == rents[rentId].client && rents[rentId].status == Status.RENTED);
        require(block.timestamp < rents[rentId].expiration + rents[rentId].returningTime);

        (, , , uint bmarketFee, ) = operationDiscountCosts(msg.sender,rentId);

        if ( rents[rentId].currency != address(0) ) {
            require(IERC20(rents[rentId].currency).transfer(rents[rentId].client, rents[rentId].price - rents[rentId].fee - bmarketFee));
            require(IERC20(rents[rentId].currency).transfer(rents[rentId].owner, rents[rentId].fee));
            require(IERC20(rents[rentId].currency).transfer(owner(), bmarketFee));
        } else {
            require(payable(rents[rentId].client).send(rents[rentId].price - rents[rentId].fee - bmarketFee));
            require(payable(rents[rentId].owner).send(rents[rentId].fee));
            require(payable(owner()).send(bmarketFee));
        }

        transferTokens(
            rents[rentId].client,
            address(this),
            rents[rentId].nftAddresses,
            rents[rentId].nftIds,
            rents[rentId].nftAmounts,
            rents[rentId].nftTypes
        );

        transferTokens(
            address(this),
            rents[rentId].owner,
            rents[rentId].nftAddresses,
            rents[rentId].nftIds,
            rents[rentId].nftAmounts,
            rents[rentId].nftTypes
        );

        rents[rentId].client = address(0);
        rents[rentId].status = Status.LISTED;
        rents[rentId].expiration = 0;
      
        emit RentDone(rentId,rents[rentId]);
    }

    function terminate(uint rentId) external {
        require(msg.sender == rents[rentId].owner && rents[rentId].expiration + rents[rentId].returningTime <= block.timestamp);

        (, , , uint bmarketFee, ) = operationDiscountCosts(msg.sender,rentId);

        if ( rents[rentId].currency != address(0) ) {
            require(IERC20(rents[rentId].currency).transfer(rents[rentId].owner, rents[rentId].price - bmarketFee));
            require(IERC20(rents[rentId].currency).transfer(owner(), bmarketFee));
        } else {
            require(payable(rents[rentId].owner).send(rents[rentId].price - bmarketFee));
            require(payable(owner()).send(bmarketFee));
        }

        rents[rentId].status = Status.TERMINATED;
        
        emit RentDone(rentId,rents[rentId]);
    }

}