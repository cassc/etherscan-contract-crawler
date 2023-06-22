// SPDX-License-Identifier: WAGDIE
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; 

contract WagdieBid is Ownable {

    event AuctionUpdated(uint16 auctionId, string reward, string imageUrl, uint40 endsAt);
    event CurrentAuction(uint16 auctionId);
    event AuctionFinished(uint16 auctionId, address winner);

    event BidWagdie(uint256 wagdieId, uint16 auctionId, address bidder);
    event BidRemoved(uint256 wagdieId, uint16 auctionId, address bidder);
    
    address constant public WAGDIE = 0x659A4BdaAaCc62d2bd9Cb18225D9C89b5B697A5A;
    uint16 public currentAuction = 0;

    uint16 public auctionsCreated = 0;

    uint16 lastAuctionId = 0;
    
    bool private emergencyWithdrawActive = false;

    mapping(uint16 => Auction) public auctions;
    mapping(uint16 => Wagdie) public wagdieBids;

    struct Auction {
        address winner;
        uint40 endsAt;
        bool finished;
        string reward;
        string imageUrl;
    }

    struct Wagdie {
        address owner;
        uint16 auctionId;
    }

    constructor() {

    }

    function _addTimeToAuction(uint16 _auctionId) internal {
        Auction storage auction = auctions[_auctionId];

        auction.endsAt = auction.endsAt + 10 minutes;

        emit AuctionUpdated(_auctionId, auction.reward, auction.imageUrl, auction.endsAt);
    }


    function bidWagdie(uint16[] calldata wagdieIds) public {
        Auction memory auction = auctions[currentAuction];

        require(auction.endsAt != 0, "Auction is not set");
        require(!auction.finished, "Auction is finished");
        require(block.timestamp < auction.endsAt, "Auction is finished");
        require(wagdieIds.length > 0, "You must bid at least 1 wagdie");

        if(auction.endsAt - block.timestamp <= 10 minutes)
            _addTimeToAuction(currentAuction);

        for(uint i = 0; i < wagdieIds.length; i++)
            _bidWagdie(wagdieIds[i], currentAuction);
    }

    function _bidWagdie(uint16 wagdieId, uint16 auctionId) internal {
        IERC721(WAGDIE).transferFrom(msg.sender, address(this), wagdieId);

        wagdieBids[wagdieId] = Wagdie(msg.sender, auctionId);

        emit BidWagdie(wagdieId, auctionId, msg.sender);
    }

    function removeBids(uint16[] calldata wagdieIds) public {

        for(uint i = 0; i < wagdieIds.length; i++)
            _removeBid(wagdieIds[i]);

    }

    function _removeBid(uint16 wagdieId) internal {

        Wagdie memory wagdie = wagdieBids[wagdieId];
        require(wagdie.owner == msg.sender, "You are not the owner of this wagdie");

        Auction memory auction = auctions[wagdie.auctionId];
        require(auction.finished, "Auction is not finished");
        require(auction.winner != msg.sender, "You are the winner of this auction");

        IERC721(WAGDIE).transferFrom(address(this), msg.sender, wagdieId);

        emit BidRemoved(wagdieId, wagdie.auctionId, msg.sender);
    }

    function emergencyWithdraw(uint16[] calldata wagdieIds) public {
        require(emergencyWithdrawActive, "Emergency withdraw is not active");

        for(uint i = 0; i < wagdieIds.length; i++) {
            require(wagdieBids[wagdieIds[i]].owner == msg.sender, "You are not the owner of this wagdie");

            IERC721(WAGDIE).transferFrom(address(this), msg.sender, wagdieIds[i]);
        }
    }

    function finishAuction(address winner) public onlyOwner {
        Auction storage auction = auctions[currentAuction];

        require(!auction.finished, "Current auction is already finished");
        require(block.timestamp >= auction.endsAt, "Auction is not finished");

        auction.finished = true;
        auction.winner = winner;

        emit AuctionFinished(currentAuction, winner);
    }

    function createAuction(string memory _reward, string memory _imageUrl, uint40 _length) public onlyOwner {
        uint16 _auctionId = ++auctionsCreated;

        lastAuctionId = _auctionId;

        Auction storage auction = auctions[_auctionId];

        require(_length > 0, "Length must be more than 0");

        require(!auction.finished, "Current auction is already finished");
        require(auction.endsAt == 0, "Auction is already set");

        auction.reward = _reward;
        auction.imageUrl = _imageUrl;

        //Length of auction in hours for easy input, example _length = 12 will be 12 hours of auction time.
        _length = _length * 1 hours;

        auction.endsAt = uint40(block.timestamp) + _length;

        emit AuctionUpdated(_auctionId, _reward, _imageUrl, auction.endsAt);
    }

    function updateAuction(uint16 _auctionId, string memory _reward, string memory _imageUrl, uint40 _length) public onlyOwner {
        Auction storage auction = auctions[_auctionId];

        require(!auction.finished, "Current auction is already finished");

        auction.reward = _reward;
        auction.imageUrl = _imageUrl;

        //Length of auction in hours for easy input, example _length = 12 will be 12 hours of auction time.
        _length = _length * 1 hours;

        auction.endsAt = uint40(block.timestamp) + _length;

        emit AuctionUpdated(_auctionId, _reward, _imageUrl, auction.endsAt);
    }

    function setCurrentAuction(uint16 _auctionId) public onlyOwner {
        require(auctions[_auctionId].endsAt != 0, "Set the auction before setting it as current");

        currentAuction = _auctionId;

        emit CurrentAuction(_auctionId);
    }

    function getLastAuctionCreated() public view returns (uint16) {
        return lastAuctionId;
    }

    function setEmergencyWithdrawl(bool _emergencyWithdraw) public onlyOwner {
        emergencyWithdrawActive = _emergencyWithdraw;
    }

    function moveWinnersWagdies(uint16 auctionId, uint16[] calldata wagdieIds, address to) public onlyOwner {
        Auction memory auction = auctions[auctionId];

        require(auction.finished, "Auction is not finished");

        for(uint i = 0; i < wagdieIds.length; i++) {
            Wagdie storage wagdie = wagdieBids[wagdieIds[i]];

            require(wagdie.owner == auction.winner, "WAGDIE does not belong to the winner");

            IERC721(WAGDIE).transferFrom(address(this), to, wagdieIds[i]);

            emit BidRemoved(wagdieIds[i], auctionId, wagdie.owner);

            wagdie.auctionId = 0;
            wagdie.owner = address(0);

        }
    }


}