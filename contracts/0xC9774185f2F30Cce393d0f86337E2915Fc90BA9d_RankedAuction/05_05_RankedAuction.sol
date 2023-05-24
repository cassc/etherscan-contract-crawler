// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RankedAuction is Ownable, Pausable, ReentrancyGuard {
    event Start();
    event Bid(address bidder, uint256 bidAmount);
    event TopUpBid(address bidder, uint256 bidAmount);
    event End();

    struct SellerInfo {
        address seller;
        uint256 bp;
    }

    struct BidState {
        address bidder; // Bidder address
        uint256 bidAmount; // Bid price
    }

    uint256 public constant DENOMINATOR = 10000;
    SellerInfo[3] public sellers;
    uint256 public endAt;
    bool public started;
    bool public ended;
    mapping(uint256 => BidState) public winners;
    uint256 public bidCount;

    constructor(SellerInfo[3] memory infos) ReentrancyGuard() {
        require(
            infos[0].bp + infos[1].bp + infos[2].bp == 10000,
            "invalid bps"
        );

        sellers[0] = infos[0];
        sellers[1] = infos[1];
        sellers[2] = infos[2];
    }

    function start(uint256 duration) external onlyOwner {
        require(!started, "started");

        started = true;
        endAt = block.timestamp + duration;

        emit Start();
    }

    function bid() external payable nonReentrant whenNotPaused {
        require(started, "not started");
        require(block.timestamp < endAt, "ended");
        require(msg.value > 0, "none bid amount");

        if (bidCount < 10) {
            uint256 index = bidCount;
            for (; index > 0; index--) {
                if (msg.value <= winners[index - 1].bidAmount) {
                    break;
                }
                winners[index] = winners[index - 1];
            }
            winners[index].bidder = msg.sender;
            winners[index].bidAmount = msg.value;
            bidCount++;
        } else {
            require(
                msg.value > winners[9].bidAmount,
                "need more fund to be a winner"
            );

            if (block.timestamp + 10 minutes > endAt) {
                endAt = block.timestamp + 10 minutes;
            }

            (bool sent, ) = winners[9].bidder.call{value: winners[9].bidAmount}(
                ""
            );
            if (!sent) {
                // The function call will fail only in case when the winner is a contract and can't recieve eth
                // In this case, the call should not revert.
            }

            uint256 index = 9;
            for (; index > 0; index--) {
                if (msg.value <= winners[index - 1].bidAmount) {
                    break;
                }
                winners[index] = winners[index - 1];
            }
            winners[index].bidder = msg.sender;
            winners[index].bidAmount = msg.value;
        }

        emit Bid(msg.sender, msg.value);
    }

    function topUpBid() external payable nonReentrant whenNotPaused {
        require(started, "not started");
        require(block.timestamp < endAt, "ended");
        require(msg.value > 0, "none bid amount");

        uint256 pos = 0;
        for (; pos < bidCount; pos++) {
            if (winners[pos].bidder == msg.sender) {
                break;
            }
        }

        require(pos < bidCount, "not eligible for top-up-bid");

        if (block.timestamp + 10 minutes > endAt) {
            endAt = block.timestamp + 10 minutes;
        }

        uint256 newBidAmount = winners[pos].bidAmount + msg.value;
        uint256 index = pos;
        for (; index > 0; index--) {
            if (newBidAmount <= winners[index - 1].bidAmount) {
                break;
            }
            winners[index] = winners[index - 1];
        }
        winners[index].bidder = msg.sender;
        winners[index].bidAmount = newBidAmount;

        emit TopUpBid(msg.sender, newBidAmount);
    }

    function end() external nonReentrant whenNotPaused {
        require(started, "not started");
        require(block.timestamp >= endAt, "not ended");
        require(!ended, "ended");

        ended = true;

        // withdraw funds
        uint256 total = address(this).balance;
        uint256 amount1 = (total * sellers[0].bp) / DENOMINATOR;
        transfer(sellers[0].seller, amount1);
        uint256 amount2 = (total * sellers[1].bp) / DENOMINATOR;
        transfer(sellers[1].seller, amount2);
        transfer(sellers[2].seller, total - amount1 - amount2);

        emit End();
    }

    function transfer(address to, uint256 amount) internal {
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function withdraw() external onlyOwner {
        transfer(msg.sender, address(this).balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getAllWinners() public view returns (BidState[] memory) {
        BidState[] memory winnersLst = new BidState[](bidCount);

        for (uint ix = 0; ix < bidCount; ix++) {
            winnersLst[ix] = winners[ix];
        }
        return (winnersLst);
    }
}