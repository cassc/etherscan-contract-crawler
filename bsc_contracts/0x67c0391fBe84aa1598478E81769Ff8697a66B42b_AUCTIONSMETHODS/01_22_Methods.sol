// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import './Params.sol';


contract AUCTIONSMETHODS is AUCTIONSPARAMS {
    
    function setParams(
        uint _fee, 
        address _discounts, 
        address _methods
    ) 
        external 
        onlyOwner 
    {
        require(_fee > 0);
        fee = _fee;
        discounts = _discounts;
        methods = _methods;
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
        require(_price > 0 && _tax > 0 && _tax * 2 < _price);
        require(_nftAddresses.length > 0);
        
        checkItemsApproval(msg.sender,_nftAddresses,_nftIds,_nftTypes);  

        auctions[id].owner = msg.sender;
        auctions[id].currency = _currency;
        auctions[id].nftAddresses = _nftAddresses;
        auctions[id].nftIds = _nftIds;
        auctions[id].nftAmounts = _nftAmounts;
        auctions[id].nftTypes = _nftTypes;
        auctions[id].price = _price;
        auctions[id].tax = _tax;
        auctions[id].status = Status.LISTED;
        
        emit NewAuction(id,auctions[id]);

        ++id;        
    }
    
    function cancel(uint auctionId) external {
        require(msg.sender == auctions[auctionId].owner);
        require(auctions[auctionId].status == Status.LISTED || auctions[auctionId].status == Status.ONGOING);
        
        if ( auctions[auctionId].winner != address(0) ) {

            if ( auctions[auctionId].currency != address(0) ) {
                require(IERC20(auctions[auctionId].currency).transfer(auctions[auctionId].winner, auctions[auctionId].currentBid));
            } else {
                require(payable(auctions[auctionId].winner).send(auctions[auctionId].currentBid));
            }
            
        }
        
        auctions[auctionId].status = Status.CANCELLED;
        emit Cancellation(auctionId,auctions[auctionId]);
    }
    
    function bid(uint auctionId) external payable {
        require(auctions[auctionId].status == Status.LISTED || auctions[auctionId].status == Status.ONGOING);
        
        if ( auctions[auctionId].currency != address(0) ) {

            if ( auctions[auctionId].winner != address(0) ) {
                require(IERC20(auctions[auctionId].currency).transfer(auctions[auctionId].winner, auctions[auctionId].currentBid));
            }

            require(IERC20(auctions[auctionId].currency).transferFrom(
                msg.sender,
                address(this), 
                auctions[auctionId].price
            ));

            auctions[auctionId].currentBid = auctions[auctionId].price;
            auctions[auctionId].price = auctions[auctionId].price + auctions[auctionId].tax;
            auctions[auctionId].winner = msg.sender;

        } else {

            if ( auctions[auctionId].winner != address(0) ) {
                require(payable(auctions[auctionId].winner).send(auctions[auctionId].currentBid));
            }

            require(msg.value >= auctions[auctionId].price);

            auctions[auctionId].currentBid = auctions[auctionId].price;
            auctions[auctionId].price = auctions[auctionId].price + auctions[auctionId].tax;
            auctions[auctionId].winner = msg.sender;

        }

        auctions[auctionId].status = Status.ONGOING;
        emit Bid(auctionId,auctions[auctionId]);
    }

    function finish(uint auctionId) external {
        require(auctions[auctionId].status == Status.ONGOING);
        require(auctions[auctionId].owner == msg.sender);

        (, , , uint bmarketFee, ) = operationDiscountCosts(msg.sender,auctionId);

        if ( auctions[auctionId].currency != address(0) ) {
            require(IERC20(auctions[auctionId].currency).transfer(auctions[auctionId].owner, auctions[auctionId].currentBid - bmarketFee));
            require(IERC20(auctions[auctionId].currency).transfer(owner(),bmarketFee));
        } else {
            require(payable(auctions[auctionId].owner).send(auctions[auctionId].currentBid - bmarketFee));
            require(payable(owner()).send(bmarketFee));
        }
        
        transferTokens(
            auctions[auctionId].owner,
            address(this),
            auctions[auctionId].nftAddresses,
            auctions[auctionId].nftIds,
            auctions[auctionId].nftAmounts,
            auctions[auctionId].nftTypes
        );

        transferTokens(
            address(this),
            auctions[auctionId].winner,
            auctions[auctionId].nftAddresses,
            auctions[auctionId].nftIds,
            auctions[auctionId].nftAmounts,
            auctions[auctionId].nftTypes
        );

        auctions[auctionId].status = Status.FINISHED;
        
        emit Finished(auctionId,auctions[auctionId]);
    }

}