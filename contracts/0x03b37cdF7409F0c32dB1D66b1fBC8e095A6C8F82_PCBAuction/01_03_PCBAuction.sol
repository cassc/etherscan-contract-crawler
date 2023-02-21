// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PCBAuction is Ownable {
    struct Auction {
        uint128 start;
        uint128 end;
        uint96 highestBid;
        address highestBidder;
        bytes32 jsonHash;
    }

    event AuctionCreated(uint256 id, uint256 start, uint256 end, uint256 minBid);
    event AuctionExtended(uint256 indexed id, uint256 newDeadline);
    event Bid(uint256 indexed id, address bidder, uint256 value);

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => bool) public collected;

    function bid(uint256 id) external payable {
        Auction memory auctionPre = auctions[id];
        require(
            auctionPre.start <= block.timestamp
            && block.timestamp <= auctionPre.end
        );
        require(
            msg.value >= auctionPre.highestBid*11_000/10_000
            || (
                auctionPre.highestBidder == address(0)
                && msg.value >= auctionPre.highestBid
            )
        );
        auctions[id].highestBid = uint96(msg.value);
        auctions[id].highestBidder = msg.sender;
        emit Bid(id, msg.sender, msg.value);

        if (auctionPre.end - block.timestamp <= 5 minutes) {
            uint128 newTime = auctionPre.end + 5 minutes;
            auctions[id].end = newTime;
            emit AuctionExtended(id, newTime);
        }

        if (auctionPre.highestBidder != address(0)) {
            (bool success,) = auctionPre.highestBidder.call{
                value: auctionPre.highestBid,
                gas: 30_000
            }("");
            if (!success) {
                IWETH(WETH).deposit{value: auctionPre.highestBid}();
                IWETH(WETH).transfer(auctionPre.highestBidder, auctionPre.highestBid);
            }
        }
    }

    function distributeProceeds(
        address beneficiary,
        uint256[] calldata ids
    ) external onlyOwner {
        uint256 total;

        for(uint256 i; i < ids.length; i++) {
            Auction memory auction = auctions[ids[i]];
            if(
                auction.highestBidder != address(0) &&
                auction.end < block.timestamp &&
                collected[ids[i]] == false
            ) {
                total += auction.highestBid;
                collected[ids[i]] = true;
            }
        }

        (bool success,) = beneficiary.call{value: total}("");
        require(success);
    }

    function createAuction(
        uint256 id,
        bytes32 jsonHash,
        uint256 start,
        uint256 end,
        uint256 startingBid
    ) public {
        require(auctions[id].end == 0);
        require(start < end);
        require(startingBid > 0);
        require(jsonHash != bytes32(0));

        auctions[id] = Auction(
            uint128(start),
            uint128(end),
            uint96(startingBid),
            address(0),
            jsonHash
        );

        emit AuctionCreated(id, start, end, startingBid);
    }

    function createAuctionBatch(
        uint256[] calldata ids,
        bytes32[] calldata hashes,
        uint256 start,
        uint256 end,
        uint256 startingBid
    ) external {
        require(ids.length == hashes.length);
        for (uint256 i; i < ids.length; i++) {
            createAuction(ids[i], hashes[i], start, end, startingBid);
        }
    }

    function canMint(
        address to,
        uint256 id,
        bytes32 jsonHash
    ) external view returns(bool) {
        Auction memory auction = auctions[id];
        return (auction.end < block.timestamp)
            && (
                auction.highestBidder == to
                || (
                    auction.highestBidder == address(0)
                    && to == owner()
                )
            ) && (jsonHash == auction.jsonHash);
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 amount) external;
}