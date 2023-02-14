// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.17;

import "./LoveBirds.sol";
import "openzeppelin-contracts/token/ERC721/IERC721.sol";

contract LoveBirdsAuction {

    uint256 public startingPrice;
    uint256 public reservePrice;
    uint256 public minBid;
    uint256 public currentTopBid;

    address public contractToMint;
    address public highestBidder;
    address public auctionBeneficiary;
    
    bool public isLive;

    mapping(address => bool) isAdmin;

    event BidPlaced( address bidder, uint256 amount);
    event BidReturned(address bidder, uint256 amount);
    event AuctionEnded (address winner);
    event AuctionCancelled (address _highestBidder, uint256 refundAmount);
    
    error BidFailed();
    error InvalidAuctionState();
    error InvalidAddress();
    error InvalidBid();
    error InsufficientFunds();
    error PaymentFailed();
    error Unauthorized();

    constructor(){
        isAdmin[msg.sender] = true;
    }

    modifier adminRequired() {
        if (!isAdmin[msg.sender]) revert Unauthorized();
        _;
    }

    receive() external payable {
    }

    function toggleAdmin(address newAdmin)external adminRequired{
        isAdmin[newAdmin] = ! isAdmin[newAdmin];
    }

    function setUpAuction(
        address _contractToMint, 
        uint256 _startingPrice,
        uint256 _reservePrice,
        uint256 _minBid,
        address _auctionBeneficiary
    )external adminRequired{
        if(_contractToMint == address(0)) revert InvalidAddress();
        contractToMint = _contractToMint;
        startingPrice = _startingPrice;
        reservePrice = _reservePrice;
        minBid = _minBid;
        currentTopBid = 0;
        highestBidder = address(0);
        auctionBeneficiary = _auctionBeneficiary;
    }

    function startAuction () external adminRequired{
        if(isLive) revert InvalidAuctionState();
        if(contractToMint == address(0)) revert InvalidAddress();
        if(auctionBeneficiary == address(0)) revert InvalidAddress();
        isLive = true;
    }

    function placeBid(
        uint256 _amount
    )external payable{
        if(_amount <  Math.max(currentTopBid, startingPrice) + minBid ) revert InvalidBid();
        if(msg.value < _amount) revert InsufficientFunds();
        if(!isLive) revert InvalidAuctionState();
        if(LoveBirds(contractToMint).balanceOf(msg.sender) > 0) revert InvalidBid();
        bool sent = payable(address(this)).send(_amount);
        if(!sent) revert BidFailed();
        if(highestBidder != address(0)){
            returnCurrentBid();
        }
        highestBidder = msg.sender;
        currentTopBid = _amount;
        emit BidPlaced(msg.sender, _amount);
    }

    function toggleAuctionStatus() public adminRequired{
        isLive = !isLive;
    }

    function settleAuction()external adminRequired{
        if(auctionBeneficiary == address(0)) revert InvalidAddress();
        if(currentTopBid >= reservePrice){
            isLive = false;
            bool sent = payable(auctionBeneficiary).send(address(this).balance);
            if(!sent) revert PaymentFailed();
            LoveBirds(contractToMint).mint(highestBidder);
            emit AuctionEnded(highestBidder);
        }else{
            cancelAuction();
        }
    }

    function cancelAuction () public  adminRequired{
        if(highestBidder  != address(0)){
            returnCurrentBid();
        }
        isLive = false;
        emit AuctionCancelled (highestBidder, currentTopBid);
    }

    function withdrawContractFunds(address _recipient, uint256 _amount) external adminRequired{
        if(_amount == 0 || _amount > address(this).balance){
            _amount = address(this).balance;
        }
         bool sent = payable(_recipient).send(address(this).balance);
         if(!sent) revert PaymentFailed();
    }

    function returnCurrentBid () internal {
        payable(highestBidder).transfer(currentTopBid);
        emit BidReturned(highestBidder, currentTopBid);
    }

}