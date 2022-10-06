// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*
Degenesis.sol
Written by: mousedev.eth
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Degenesis is ERC721, Ownable {
    struct Bid {
        address bidder;
        uint128 bidAmount;
        uint32 bidId;
        bool hasSettled;
        bool exists;
    }

    mapping(uint256 => Bid) public bids;
    mapping(address => uint256) public userToBidId;

    string public contractURI =
        "ipfs://Qmdn8KkBwtPPM4hgFzetcq7vcTdJdUu9mddK4RRZaEhing";
    string public unrevealedURI = "ipfs://QmWwKbTdxe2kMB8EU2WWPaLzWH7Sx88cdbJTEJJx1icGhf";

    string public baseURI;
    string public baseURIEXT = ".json";

    bool public revealed;

    uint256 public shiftAmount;
    uint256 internal commitBlock;

    uint256 public currentBidId = 1;
    uint256 public totalSupply = 0;

    uint256 public minimumBid = 0.15 ether;
    uint256 public minimumBidIncrement = 0.01 ether;

    uint256 public finalPrice;

    uint256 public auctionStartTime;
    uint256 public auctionEndTime;

    event BidAdded(uint128 bidAmount, address bidder);
    event BidAdjusted(uint128 bidAmount, address bidder);

    constructor(uint256 _auctionStartTime, uint256 _auctionEndTime)
        ERC721("Degenesis", "DGNS")
    {
        auctionStartTime = _auctionStartTime;
        auctionEndTime = _auctionEndTime;
    }

    function getAllBids() public view returns (Bid[] memory) {
        return getBids(uint32(currentBidId) - 1, 1);
    }

    function getBids(uint32 _quantity, uint256 _startingId)
        public
        view
        returns (Bid[] memory)
    {
        Bid[] memory _bids = new Bid[](_quantity);
        uint256 _currentBidsArrayIndex = 0;

        for (
            uint256 thisBidId = _startingId;
            thisBidId < _startingId + _quantity;
            thisBidId++
        ) {
            _bids[_currentBidsArrayIndex] = bids[thisBidId];
            _currentBidsArrayIndex++;
        }

        return _bids;
    }

    //Bids are non revokable.
    function bid() public payable {
        //Require auction is started.
        require(
            block.timestamp >= auctionStartTime &&
                block.timestamp < auctionEndTime,
            "Auction is not active!"
        );

        if (userToBidId[msg.sender] > 0) {
            //Require they are bidding more than minimum bid increment
            require(
                msg.value >= minimumBidIncrement,
                "Bid increment must be higher than minimum bid increment."
            );

            uint256 thisBidId = userToBidId[msg.sender];

            //Create a new bid total which is their previous bid + new bid amount.
            uint128 newBidTotal = bids[thisBidId].bidAmount +
                uint128(msg.value);

            //Create this bid struct with index as the current length.
            bids[thisBidId].bidAmount = newBidTotal;

            //Emit event.
            emit BidAdjusted(newBidTotal, msg.sender);
        } else {
            //Require they are bidding more than minimum bid amount
            require(
                msg.value >= minimumBid,
                "Bid must be higher than minimum amount."
            );

            //They have not bid yet, create a new bid Id.
            uint256 thisBidId = currentBidId;

            //Create their bid record.
            bids[thisBidId] = Bid(
                msg.sender,
                uint128(msg.value),
                uint32(thisBidId),
                false,
                true
            );

            //Store their bid id.
            userToBidId[msg.sender] = thisBidId;

            //Increment current id.
            ++currentBidId;

            //Emit event.
            emit BidAdded(uint128(msg.value), msg.sender);
        }
    }

    function setFinalPrice(uint128 _finalPrice) public onlyOwner {
        //Require auction has passed.
        require(block.timestamp >= auctionEndTime, "Auction is still active!");

        //Require final price has not been set.
        require(finalPrice == 0, "Final price already set!");

        //Set final price.
        finalPrice = _finalPrice;
    }

    function settleBids(uint256[] memory _bidIds) public onlyOwner {
        //Require auction has passed.
        require(block.timestamp >= auctionEndTime, "Auction is still active!");
        require(finalPrice > 0, "Final price has not been set!");

        for (uint256 i = 0; i < _bidIds.length; ++i) {
            uint256 thisBidId = _bidIds[i];

            //Store thisBid in memory to avoid storage reads.
            Bid memory _thisBid = bids[thisBidId];

            //Require they haven't settled their bid.
            require(!_thisBid.hasSettled, "You've already settled your bid!");

            require(_thisBid.exists, "Bid doesn't exist!");

            //Mark as settled.
            bids[thisBidId].hasSettled = true;

            //If their bid lost, or if the total supply is hit.
            if (_thisBid.bidAmount < finalPrice || totalSupply >= 250) {
                //They lost.
                //Send their bid back.
                (bool succ, ) = payable(_thisBid.bidder).call{
                    value: _thisBid.bidAmount
                }("");
                require(succ, "transfer failed");
            } else {
                //They won.
                //Mint them the next tokenId
                _mint(_thisBid.bidder, totalSupply);

                //Increment totalSupply by one.
                totalSupply++;

                //Calculate refund amount.
                uint256 refund = _thisBid.bidAmount - finalPrice;

                //Send refund.
                if (refund > 0) {
                    (bool succ, ) = payable(_thisBid.bidder).call{
                        value: refund
                    }("");
                    require(succ, "transfer failed");
                }
            }
        }
    }

    function adjustTimes(uint256 _auctionStartTime, uint256 _auctionEndTime)
        public
        onlyOwner
    {
        auctionStartTime = _auctionStartTime;
        auctionEndTime = _auctionEndTime;
    }

    function mintTeam(uint256 _quantity, address _receiver) public onlyOwner {
        require(totalSupply + _quantity <= 300, "Total supply exceeded!");
        for (uint256 i = 0; i < _quantity; i++) {
            _mint(_receiver, totalSupply + i);
        }
        totalSupply += _quantity;
    }

    function withdrawInitialETH() public onlyOwner {
        (bool succ, ) = payable(msg.sender).call{value: finalPrice * 250}("");
        require(succ, "transfer failed");
    }

    function withdrawFinalETH() public onlyOwner {
        require(
            block.timestamp >= auctionStartTime + 1 weeks,
            "Not enough time has passed!"
        );

        (bool succ, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(succ, "transfer failed");
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setBaseURIEXT(string memory _baseURIEXT) public onlyOwner {
        baseURIEXT = _baseURIEXT;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setRevealData(string memory _unrevealedURI) public onlyOwner {
        unrevealedURI = _unrevealedURI;
    }

    function commit(string memory _baseURI) public onlyOwner {
        require(commitBlock == 0, "Commit block already set!");

        commitBlock = block.number + 5;
        baseURI = _baseURI;
    }

    function reveal() public onlyOwner {
        require(block.number >= commitBlock, "Hasn't passed commit block!");
        require(commitBlock > 0, "Commit block not set!");
        require(!revealed, "Has already been revealed");

        shiftAmount = uint256(blockhash(commitBlock));
        revealed = true;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (revealed) {
            uint256 _newTokenId = (_tokenId + shiftAmount) % totalSupply;
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(_newTokenId),
                        baseURIEXT
                    )
                );
        } else {
            return unrevealedURI;
        }
    }
}