// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract marketplace is ReentrancyGuard, ERC1155Holder, Initializable, UUPSUpgradeable

{



    address private owner;


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    

    address payable public immutable feeAccount = payable(0x2265EcB63c1a949Bf71e754b4d7448389badCA2A);
    uint immutable feesPercent = 2;
    uint private auctionItem;
    uint private itemCount;

    //structure for listing data
    struct Item{
        uint itemId;
        IERC1155 nft;
        uint tokenId;
        uint qunatity;
        uint price;
        address payable Seller;
        
        address payable royalityReceipent;
        uint256 royalityPercentage;
        uint timestamp;
        bool sold;
        bool archieved;
    }




    

    //structure for the Bids data
    struct Bids {
        uint bidPrice;
        address payable Bidder;
    }



    event TransferSingle(address indexed from, address indexed to, uint id, uint value);
    event SaleEvent(address indexed _seller, uint indexed saleId);
    // event AuctionEvent(address indexed _seller, uint indexed auctionId);




    
    mapping(uint=>Item) public items;

    mapping(uint=>Bids) public bids;  


    function initialize() initializer public {
        __UUPSUpgradeable_init();
        owner = address(0x2265EcB63c1a949Bf71e754b4d7448389badCA2A);


    }

    function ListForSale(IERC1155 _nft, uint _tokenId, uint _price, uint _amount, bytes calldata _bytes, address _royaltyReceipent, uint256 _royalityPercentage) external nonReentrant returns(uint){
        require(_price>0, "Price must be greater then zero");
        itemCount ++;

        bool approved = _nft.isApprovedForAll(msg.sender, address(this));
        if(!approved){
            revert("please approve the marketplace contract to interact");
        }
        _nft.safeTransferFrom(msg.sender,address(this), _tokenId, _amount, _bytes);
        items[itemCount]= Item(itemCount,_nft,_tokenId,_amount, _price,payable(msg.sender), payable(_royaltyReceipent), _royalityPercentage, block.timestamp, false, false);

        bids[itemCount] = Bids(0, payable(msg.sender));



            
        emit SaleEvent(msg.sender, itemCount);

        return itemCount;
        
    }

    function PurchaseItem(uint _itemId) external payable nonReentrant{
        Bids storage bid = bids[_itemId];
        uint _totalPrice = getTotalPrice(_itemId);
        Item storage item = items[_itemId];
        require(_itemId>0 && _itemId<=itemCount,"item doesnot exist");
        require(msg.value >=_totalPrice, "Not enough amount to cover ur value");
        require(!item.sold,"item already sold");
        // require(item.end_date > block.timestamp, "Sale Over");
        require(!item.archieved,"item revoke");

        uint royalityVal = (uint(item.royalityPercentage) * _totalPrice/10000);
        item.royalityReceipent.transfer(royalityVal);
        item.Seller.transfer(_totalPrice - royalityVal);
        feeAccount.transfer(item.price - _totalPrice - royalityVal);
        item.sold = true;
        item.nft.safeTransferFrom(address(this),msg.sender, item.tokenId, item.qunatity,"");
        if(bid.bidPrice > 0){
            bid.Bidder.transfer(bid.bidPrice);
        }
        emit TransferSingle(address(this), msg.sender, item.tokenId, item.qunatity);
    }

    function SaleBidding(uint _itemId) external payable nonReentrant
    {
        Bids storage bid = bids[_itemId];
        Item storage item = items[_itemId];
        uint _totalPrice = getTotalPrice(_itemId);

        // require(item.end_date > block.timestamp, "Sale Over");
        require(msg.value>bid.bidPrice,"Bidding value must be greater than the last bid");
        require(_itemId>0 && _itemId<=itemCount,"item doesnot exist");
        require(!item.sold,"item already sold");
        require(!item.archieved,"item revoke");

        
        if(msg.value == item.price){
            require(msg.value >=_totalPrice,"Not enough Value");
            uint royalityVal = (uint(item.royalityPercentage) * _totalPrice/10000);
            item.royalityReceipent.transfer(royalityVal);
            item.Seller.transfer(_totalPrice - royalityVal);
            feeAccount.transfer(item.price - _totalPrice - royalityVal);
            item.Seller.transfer(_totalPrice);
            feeAccount.transfer(item.price-_totalPrice);
            item.sold = true;
            item.nft.safeTransferFrom(address(this),msg.sender,
            item.tokenId, item.qunatity,"");
            emit TransferSingle(address(this), msg.sender, item.tokenId, item.qunatity);
        }
        bid.Bidder.transfer(bid.bidPrice);
        bid.bidPrice  = msg.value;
        bid.Bidder =payable(msg.sender);
    }


    function SaleAcceptBid(uint _itemId) external payable nonReentrant{
        Bids storage bid = bids[_itemId];
        Item storage item = items[_itemId];
        uint _totalPrice = getTotalPrice(_itemId);
        require(item.Seller == msg.sender, "exception throw" );
        require(_itemId>0 && _itemId<=itemCount,"item doesnot exist");
        require(!item.sold,"item already sold");
        require(!item.archieved,"item revoke");

        require(bid.bidPrice != 0, "No bids has been made");
        // require(item.end_date > block.timestamp, "Sale Over");

        uint royalityVal = (uint(item.royalityPercentage) * (bid.bidPrice*(100 - feesPercent)/100)/10000);
        item.royalityReceipent.transfer(royalityVal);




        item.Seller.transfer((bid.bidPrice*(100 - feesPercent)/100) - royalityVal);
        feeAccount.transfer(bid.bidPrice - (bid.bidPrice*(100 - feesPercent)/100) - royalityVal);
        item.sold = true;
        item.nft.safeTransferFrom(address(this),bid.Bidder,
        item.tokenId, item.qunatity,"");
        emit TransferSingle(address(this), bid.Bidder, item.tokenId, item.qunatity);
    }

    function RevertSale(uint _itemId) external payable nonReentrant {
        Item storage item = items[_itemId];
        Bids storage bid = bids[_itemId];
        require(item.Seller == msg.sender, "exception throw" );
        require(!item.archieved, "item is already reverted");
        item.archieved = true;
        if(bid.bidPrice> 0){
            bid.Bidder.transfer(bid.bidPrice);
        }
        item.nft.safeTransferFrom(address(this),msg.sender,
            item.tokenId, item.qunatity,"");
        emit TransferSingle(address(this), msg.sender, item.tokenId, item.qunatity);
    }




    function getTotalPrice(uint _itemId) private returns(uint){
    return (items[_itemId].price*(100 - feesPercent)/100);
    }

    function GetSalesCount() public view returns(uint){
        return itemCount;
    }



    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}