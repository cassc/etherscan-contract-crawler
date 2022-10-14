pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "./TellerV2.sol";

contract TellerV2Mock is TellerV2 {
    constructor(address trustedForwarder) TellerV2(trustedForwarder) {}

    function mockBid(Bid calldata _bid) external {
        bids[bidId] = _bid;
        borrowerBids[_msgSender()].push(bidId);
        bidId++;
    }

    function mockAcceptedTimestamp(uint256 _bidId, uint32 _timestamp) external {
        require(_timestamp > 0, "Accepted timestamp 0");
        bids[_bidId].loanDetails.acceptedTimestamp = _timestamp;
    }

    function mockAcceptedTimestamp(uint256 _bidId) external {
        bids[_bidId].loanDetails.acceptedTimestamp = uint32(block.timestamp);
    }

    function mockLastRepaidTimestamp(uint256 _bidId, uint32 _timestamp)
        external
    {
        require(_timestamp > 0, "Repaid timestamp 0");
        bids[_bidId].loanDetails.lastRepaidTimestamp = _timestamp;
    }

    function setVersion(uint256 _version) public {
        version = _version;
    }
}