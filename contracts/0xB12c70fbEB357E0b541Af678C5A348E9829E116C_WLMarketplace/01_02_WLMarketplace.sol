// SPDX-License-Identifier: MIT License


pragma solidity ^0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


interface iSabi {
    function balanceOf(address address_) external view returns (uint); 
    function transferFrom(address from_, address to_, uint amount) external returns (bool);
    function burnFrom(address account, uint amount) external;
}

contract WLMarketplace is ReentrancyGuard {

    address public owner;
    address[] public players;
    
    uint256 public ticketPrice = 500000000000000000000; // 500ETH
    uint public maxTicketsPerTx = 20;
    mapping (address => uint256) public userEntries;

    
    /* NEW mapping */
    struct SaleItem {
        uint16 totalSlots;
        uint16 boughtSlots;
        bool isActive;
        uint256 itemPrice;
        address[] buyers;
    }
    mapping (uint => SaleItem) public idToSaleItem;
    // mapping (address => uint) public lastBuyTime;
    //

    constructor() {
        owner = msg.sender;
    }

    address public sabiAddress;
    iSabi public Sabi;
    function setSabi(address _address) external onlyOwner {
        sabiAddress = _address;
        Sabi = iSabi(_address);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /*  ======================
        |---Entry Function---|
        ======================
    */

    function buyWL(uint _id) public nonReentrant {
        // used to have payable word in function sig
        require(idToSaleItem[_id].isActive == true, "sale ended");

        require(Sabi.balanceOf(msg.sender) >= idToSaleItem[_id].itemPrice, "insufficent $SABI");
        // require(lastBuyTime[msg.sender] + 1 hours < block.timestamp, "last buy time is less than 72 hours");
        require(idToSaleItem[_id].boughtSlots < idToSaleItem[_id].totalSlots, "slots filled for saleItem");
        for (uint i=0; i<idToSaleItem[_id].buyers.length; i++) {
            require(idToSaleItem[_id].buyers[i] != msg.sender, "already bought from item");           
        }
        // lastBuyTime[msg.sender] = block.timestamp;
        idToSaleItem[_id].boughtSlots++;
        idToSaleItem[_id].buyers.push(msg.sender);
        Sabi.burnFrom(msg.sender, idToSaleItem[_id].itemPrice);
    }

    function enterDraw(uint256 _numOfTickets) public nonReentrant {
        // require(idToSaleItem[_id].isActive == true, "sale ended");
        

        uint256 totalTicketCost = ticketPrice * _numOfTickets;
        require(Sabi.balanceOf(msg.sender) >= ticketPrice * _numOfTickets, "insufficent $SABI");
        // require(drawLive == true, "cannot enter at this time");
        require(_numOfTickets <= maxTicketsPerTx, "too many per TX");

        uint256 ownerTicketsPurchased = userEntries[msg.sender];
        require(ownerTicketsPurchased + _numOfTickets <= maxTicketsPerTx, "only allowed 20 tickets");
        Sabi.burnFrom(msg.sender, totalTicketCost);

        // player ticket purchasing loop
        for (uint256 i = 1; i <= _numOfTickets; i++) {
            players.push(msg.sender);
            userEntries[msg.sender]++;
        }
        
    }

    /*  ======================
        |---View Functions---|
        ======================
    */

    //HELPERS
    // function getLastBuyTimePlus72Hours(address _buyer) public view returns (uint) {
    //     return lastBuyTime[_buyer] + 1 hours;
    // }

    function buyersOfSaleItem(uint16 _id) public view returns (address[] memory) {
        return idToSaleItem[_id].buyers;
    }

    function buyersOfDraw() public view returns (address[] memory) {
        return players;
    }


    /*  ============================
        |---Owner Only Functions---|
        ============================
    */

    

    function createSaleItem(uint256 _newTicketPrice, uint16 _newId, uint16 _totalSlots) public onlyOwner {
        // ticketPrice = _newTicketPrice;

        idToSaleItem[_newId].totalSlots = _totalSlots;
        idToSaleItem[_newId].boughtSlots = 0;
        idToSaleItem[_newId].isActive = true;
        idToSaleItem[_newId].itemPrice = _newTicketPrice * ticketPrice;
        // idToSaleItem[_newId].buyers = address[]

    }

    function disableSaleItem(uint16 _newId) public onlyOwner {

        idToSaleItem[_newId].isActive = false;

    }



    function setTicketPrice(uint256 _newTicketPrice) public onlyOwner {
        ticketPrice = _newTicketPrice;
    }

    function transferOwnership(address _address) public onlyOwner {
        owner = _address;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}