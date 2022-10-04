// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;

import "./AnastasisAct1.sol";
import "./IERC1155.sol";

contract AnastasisAuction {

    uint256 public _startingPrice;
    uint256 public _reservePrice;
    uint256 public _minBid;
    uint256 public _currentTopBid;

    address public _contractToMint;
    address public _highestBidder;
    address public _auctionBeneficiary;
    
    bool public _isLive;

    mapping(address => bool) _isAdmin;

    event BidPlaced( address bidder, uint256 amount);
    event BidReturned(address bidder, uint256 amount);
    event AuctionEnded (address winner);
    event AuctionCancelled (address _highestBidder, uint256 refundAmount);


    constructor(){
        _isAdmin[msg.sender] = true;
    }

    function approveAdmin(address newAdmin)external{
        require(_isAdmin[msg.sender]);
        _isAdmin[newAdmin] = true;
    }

    function removeAdmin(address exAdmin)external{
        require(_isAdmin[msg.sender]);
        _isAdmin[exAdmin] = false;
    }

    function setUpAuction(
        address contractToMint, 
        uint256 startingPrice,
        uint256 reservePrice,
        uint256 minBid,
        address auctionBeneficiary
    )external{
        require(_isAdmin[msg.sender], "Only an admin can start an auction");
        require(contractToMint != address (0), "Invalid contract address");
        _contractToMint = contractToMint;
        _startingPrice = startingPrice;
        _reservePrice = reservePrice;
        _minBid = minBid;
        _currentTopBid = 0;
        _highestBidder = address(0);
        _auctionBeneficiary = auctionBeneficiary;
    }

    function startAuction()external{
        require(_isAdmin[msg.sender], "Only an admin can start an auction");
        require(!_isLive, "Auction is already opened");
        require(_contractToMint != address (0), "Cannot start an auction if contract to be minted not defined");
        require(_auctionBeneficiary != address (0), "Cannot start an auction if no auction beneficiary is defined");
        _isLive = true;
    }

    receive() external payable {
    }


    function placeBid(
        uint256 amount
    )external payable{
        require(amount >= _currentTopBid + _minBid, "Bid too small");
        require(msg.value >= amount, "Not enough funds sent");
        require(_isLive, "Auction is closed");
        bool sent = payable(address(this)).send(amount);
        require(sent, "Bid failed");
        if(_highestBidder != address(0)){
            returnCurrentBid();
        }
        _highestBidder = msg.sender;
        _currentTopBid = amount;
        emit BidPlaced(msg.sender, amount);
    }

    function closeAuction()external{
        require(_isAdmin[msg.sender], "Only an admin can close an auction");
        require(_isLive, "Auction is already closed");
        require(_auctionBeneficiary != address(0)   , "Auction beneficiary can't be 0 address");
        if(_currentTopBid >= _reservePrice){
            _isLive = false;
            bool sent = payable(_auctionBeneficiary).send(address(this).balance);
            require(sent, "Transfer failed");
            Anastasis_Act1(_contractToMint).mint(_highestBidder);
            emit AuctionEnded(_highestBidder);
        }else{
            cancelAuction();
        }
    }

    function cancelAuction()public{
        require(_isAdmin[msg.sender], "Only an admin can cancel an auction");
        require(_isLive, "You cannot cancel a closed Auction");
        returnCurrentBid();
        _isLive = false;
        emit AuctionCancelled (_highestBidder, _currentTopBid);
    }

    function withdrawContractFunds(address recipient) external {
        require(_isAdmin[msg.sender], "Only an admin can retrun the funds auction");
         bool sent = payable(recipient).send(address(this).balance);
         require(sent, "Transfer failed");
    }

    function addAdmin(address newAdmin) external{
        require(_isAdmin[msg.sender], "Only an admin can add another one");
        _isAdmin[newAdmin] = true;
    }

    function returnCurrentBid()internal{
        require(_highestBidder != address(0), "Cannot refund the 0 address");
        require(_currentTopBid >= 0, "Cannot refund a bid of 0");
        bool sent = payable(_highestBidder).send(_currentTopBid);
        require(sent, "Transfer failed");
        emit BidReturned(_highestBidder, _currentTopBid);
    }

}