// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CGAuction is Ownable {
    bool public isAuctionOpen = false;
    struct Bid {
        address bidder;
        uint256 value;
    }
    address public winner;
    Bid[] bids;
    constructor(){}
    function setIsAuctionOpen(bool _isAuctionOpen) public onlyOwner {
        isAuctionOpen = _isAuctionOpen;
    }

    function increaseBid() public payable returns (bool success){
        require(isAuctionOpen, "Auction is not open!");
        require(msg.value > 0, "You did not send any ETH!");
        if (bids.length == 0) {
            bids.push(
                Bid(
                    msg.sender,
                    msg.value
                )
            );
            return true;
        }
        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].bidder == msg.sender) {
                bids[i].value += msg.value;
                return true;
            } else if (i == bids.length - 1) {
                bids.push(
                    Bid(
                        msg.sender,
                        msg.value
                    )
                );
                return true;
            }
        }
        return false;
    }

    function getAllBids() public view returns(Bid[] memory) {
        return bids;
    }

    function decreaseBid(uint256 _value) public returns (bool success) {
        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].bidder == msg.sender) {
                bids[i].value -= _value;
                (bool sent,) = payable(msg.sender).call{value: _value}("");
                require(sent, "Failed to send Ether");
                return sent;
            }
        }
        return false;
    }

    function endAuction() public onlyOwner {
        require(isAuctionOpen, "Auction not open!");
        isAuctionOpen = false;
        Bid memory highestBid;
        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].value > highestBid.value) {
                highestBid = bids[i];
            }
        }
        winner = highestBid.bidder;
        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].bidder == winner) {
                (bool sent,) = payable(super.owner()).call{value: highestBid.value}("");
                require(sent, "Failed to send Ether");
            } else if (bids[i].value > 0) {
                (bool sent,) = payable(bids[i].bidder).call{value: bids[i].value}("");
                require(sent, "Failed to send Ether");
            }
        }
    }
}