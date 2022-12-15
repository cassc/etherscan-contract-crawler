// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Utils.sol";

contract Kenomi is Ownable, Utils {
    uint256 public nonce = 0;
    // 7 days
    uint256 public itemsRemoveTime = 604800;

    function setItemRemoveTime(uint256 time) external onlyOwnerOrAdmin {
        itemsRemoveTime = time;
    }

    event WhiteListItemAdded(WhiteListItem item);
    event WhiteListItemUpdated(uint256 itemIndex, WhiteListItem item);
    event WhiteListItemBuyed(WhiteListItem item, address owner);
    event WhiteListItemDeleted(uint256 itemIndex, WhiteListItem item);

    event AuctionItemAdded(AuctionItem item);
    event AuctionItemUpdated(uint256 itemIndex, AuctionItem item);
    event AuctionBidPlaced(AuctionItem item, address bidder);
    event AuctionItemDeleted(uint256 itemIndex, AuctionItem item);

    struct WhiteListItem {
        uint256 index;
        uint8 supply;
        uint8 supplyLeft;
        uint256 pricePerItem;
        uint256 endTime;
    }

    struct AuctionItem {
        uint256 index;
        address highestBidder;
        uint256 highestBid;
        uint256 endTime;
    }

    //  <-  Admin Functions  ->  //
    mapping(address => bool) public adminMapping;

    function addAdmin(address _address) external onlyOwner {
        adminMapping[_address] = true;
    }

    function removeAdmin(address _address) external onlyOwner {
        adminMapping[_address] = false;
    }

    modifier onlyOwnerOrAdmin() {
        require(
            msg.sender == owner() || adminMapping[msg.sender],
            "Function only accessible to Admin and Owner"
        );
        _;
    }

    //  <-  Storage  ->  //
    WhiteListItem[] public whiteListItems;
    mapping(uint256 => address[]) whiteListItemBuyers;
    mapping(address => WhiteListItem[]) public ownedItems;

    AuctionItem[] public auctionItems;
    mapping(address => AuctionItem[]) public ownedAuctionItems;

    modifier requireSignature(bytes memory signature) {
        require(
            _getSigner(_hashTx(msg.sender, nonce), signature) == signerAddress,
            "Invalid Signature"
        );
        nonce += 1;
        _;
    }

    function addWhiteListItem(
        bytes memory signature,
        WhiteListItem memory whiteListItem,
        uint256 endTime
    ) external onlyOwnerOrAdmin requireSignature(signature) {
        whiteListItem.endTime = block.timestamp + endTime;
        whiteListItems.push(whiteListItem);
        emit WhiteListItemAdded(whiteListItem);
    }

    function addAuctionItem(
        bytes memory signature,
        AuctionItem memory auctionItem,
        uint256 endTime
    ) external onlyOwnerOrAdmin requireSignature(signature) {
        auctionItem.endTime = block.timestamp + endTime;
        auctionItems.push(auctionItem);
        emit AuctionItemAdded(auctionItem);
    }

    function updateWhiteListItem(
        bytes memory signature,
        uint256 itemIndex,
        WhiteListItem memory whiteListItem,
        uint256 endTime
    ) external onlyOwnerOrAdmin requireSignature(signature) {
        whiteListItem.endTime = block.timestamp + endTime;
        whiteListItems[itemIndex] = whiteListItem;
        emit WhiteListItemUpdated(itemIndex, whiteListItem);
    }

    function updateAuctionItem(
        bytes memory signature,
        uint256 itemIndex,
        AuctionItem memory auctionItem,
        uint256 endTime
    ) external onlyOwnerOrAdmin requireSignature(signature) {
        auctionItem.endTime = block.timestamp + endTime;
        auctionItems[itemIndex] = auctionItem;
        emit AuctionItemUpdated(itemIndex, auctionItem);
    }

    function buyWhiteListItem(
        bytes memory signature,
        uint256 itemIndex,
        uint8 amount
    ) external payable requireSignature(signature) {
        WhiteListItem memory item = whiteListItems[itemIndex];

        require(amount > 0, "Invalid Buy Amount");
        require(item.endTime >= block.timestamp, "Participation time ends");
        require(item.supplyLeft >= amount, "Not enough supply");
        require(msg.value == item.pricePerItem * amount, "Not enough value");

        whiteListItems[itemIndex].supplyLeft -= amount;

        WhiteListItem memory owned = WhiteListItem(
            itemIndex,
            amount,
            amount,
            item.pricePerItem,
            block.timestamp
        );
        ownedItems[msg.sender].push(owned);
        whiteListItemBuyers[itemIndex].push(msg.sender);
        emit WhiteListItemBuyed(item, msg.sender);
    }

    function placeBid(bytes memory signature, uint256 itemIndex)
        external
        payable
        requireSignature(signature)
    {
        AuctionItem memory item = auctionItems[itemIndex];

        require(msg.value > item.highestBid, "Bid Amount Low than highest Bid");
        require(item.endTime >= block.timestamp, "Bid time ends");

        require(address(this).balance >= auctionItems[itemIndex].highestBid, "Not enough fund in the contract");
        payable(auctionItems[itemIndex].highestBidder).transfer(auctionItems[itemIndex].highestBid);

        auctionItems[itemIndex].highestBid = msg.value;
        auctionItems[itemIndex].highestBidder = msg.sender;
        emit AuctionBidPlaced(item, msg.sender);
    }

    function deleteWhiteListItem(bytes memory signature, uint256 itemIndex)
        external
        onlyOwnerOrAdmin
        requireSignature(signature)
    {
        WhiteListItem memory item = whiteListItems[itemIndex];
        uint256 lastIndex = whiteListItems.length - 1;

        whiteListItems[itemIndex] = whiteListItems[lastIndex];
        whiteListItems.pop();

        whiteListItemBuyers[itemIndex] = whiteListItemBuyers[lastIndex];
        delete whiteListItemBuyers[lastIndex];

        emit WhiteListItemDeleted(itemIndex, item);
    }

    function deleteAuctionItem(
        bytes memory signature,
        uint256 itemIndex,
        bool returnBidAmount
    ) external onlyOwnerOrAdmin requireSignature(signature) {
        AuctionItem memory item = auctionItems[itemIndex];
        uint256 lastIndex = auctionItems.length - 1;

        auctionItems[itemIndex] = auctionItems[lastIndex];
        auctionItems.pop();

        if (returnBidAmount && item.highestBid > 0) {
            require(
                address(this).balance >= item.highestBid,
                "Not enough fund available"
            );
            payable(item.highestBidder).transfer(item.highestBid);
        }
        emit AuctionItemDeleted(itemIndex, item);
    }

    enum UpKeepFor{ WhiteListRemove, AuctionRemove, AuctionTimeEnd }

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory performData, UpKeepFor upKeepFor) {
        for (uint256 i = 0; i < auctionItems.length; i++) {
            AuctionItem memory item = auctionItems[i];
            bool timePassed = block.timestamp > item.endTime;
            bool removeTimePassed = block.timestamp > item.endTime + itemsRemoveTime;

            if (removeTimePassed) {
                upkeepNeeded = (removeTimePassed);
                return (upkeepNeeded, abi.encodePacked(i), UpKeepFor.AuctionRemove);
            }
            if (timePassed) {
                upkeepNeeded = (timePassed);
                return (upkeepNeeded, abi.encodePacked(i), UpKeepFor.AuctionTimeEnd);
            }
        }
        for (uint256 i = 0; i < whiteListItems.length; i++) {
            WhiteListItem memory item = whiteListItems[i];
            // Time Passed true => after 7 days of Item EndTime
            bool timePassed = block.timestamp > item.endTime + itemsRemoveTime;

            if (timePassed) {
                upkeepNeeded = (timePassed);
                return (upkeepNeeded, abi.encodePacked(i), UpKeepFor.WhiteListRemove);
            }
        }
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external {
        (bool upkeepNeeded, bytes memory data, UpKeepFor upkeepFor) = checkUpkeep("");
        require(upkeepNeeded, "Raffle Upkeep Not Needed");

        if(upkeepFor == UpKeepFor.WhiteListRemove) {
            uint256 whiteListItemIndex = uint256(bytes32(data));
            removeWhiteListItem(whiteListItemIndex);
        }
        if(upkeepFor == UpKeepFor.AuctionRemove) {
            uint256 auctionItemIndex = uint256(bytes32(data));
            removeAuctionItem(auctionItemIndex);
        }
        if(upkeepFor == UpKeepFor.AuctionTimeEnd) {
            uint256 auctionItemIndex = uint256(bytes32(data));
            AuctionItem memory item = auctionItems[auctionItemIndex];
            ownedAuctionItems[item.highestBidder].push(item);
        }
    }

    function removeAuctionItem(uint256 auctionItemIndex) internal {
        uint256 lastIndex = auctionItems.length - 1;

        auctionItems[auctionItemIndex] = auctionItems[lastIndex];
        auctionItems.pop();
    }

    function removeWhiteListItem(uint256 whiteListItemIndex) internal {
        uint256 lastIndex = whiteListItems.length - 1;

        whiteListItems[whiteListItemIndex] = whiteListItems[lastIndex];
        whiteListItems.pop();
    }

    //  <- Getter Functions  ->  //
    function getAllWhiteListItems()
        external
        view
        returns (WhiteListItem[] memory)
    {
        return whiteListItems;
    }

    function getAllWhiteListItemBuyers(uint256 index)
        external
        view
        returns (address[] memory)
    {
        return whiteListItemBuyers[index];
    }

    function getAllAuctionItems() external view returns (AuctionItem[] memory) {
        return auctionItems;
    }

    function getWhiteListOwnedItems(address _address)
        external
        view
        returns (WhiteListItem[] memory)
    {
        return ownedItems[_address];
    }

    function getAuctionOwnedItems(address _address)
        external
        view
        returns (AuctionItem[] memory)
    {
        return ownedAuctionItems[_address];
    }

    function getNextWhiteListItemIndex() external view returns (uint256) {
        return whiteListItems.length;
    }

    function getNextAuctionItemIndex() external view returns (uint256) {
        return auctionItems.length;
    }

    function getKenomiBalance() external view returns(uint256){
        return address(this).balance;
    }

    function withDraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}