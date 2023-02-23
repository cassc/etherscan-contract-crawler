// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Auction is Ownable, IERC721Receiver {
    error WithdrawComplete();
    error AuctionRunning();
    error BidderNotFound();
    error NotEnoughBids();
    error AuctionClosed();
    error BidTooLow();

    event LeaderboardShuffled();
    event NewEndTimestamp(uint256 value);

    struct AuctionData {
        address owner;
        uint96 bid;
    }

    uint256 public constant START_TIMESTAMP = 1677092400; 
    uint256 public constant LEADERBOARD_SIZE = 20;
    uint256 public constant REWARDS_SIZE = 6;
    uint256 private constant PACKED_REWARDS = 0 + (1 << 8) + (3 << 16) + (6 << 24) + (14 << 32) + (40 << 40);
    uint256 private constant REWARD_MASK = (1 << 8) - 1;
    
    IERC20 public immutable tokenContract;
    IERC721 public immutable rewardContract;

    uint32 public bidCount;
    uint64 public endTimestamp;
    uint64 public timeExtension = 60;
    uint96 public minBid = 1000 * 10**18;

    mapping(uint256 => AuctionData) public leaderboard;

    constructor(
        IERC20 _tokenContract,
        IERC721 _rewardContact,
        uint64 _endTimestamp
    ) {
        tokenContract = _tokenContract;
        rewardContract = _rewardContact;

        endTimestamp = _endTimestamp;
    }

    modifier isRunning() {
        if (block.timestamp < START_TIMESTAMP || block.timestamp >= endTimestamp) revert AuctionClosed();
        _;
    }

    modifier extendsTime() {
        if (endTimestamp - block.timestamp <= timeExtension) {
            unchecked {
                endTimestamp += timeExtension;
            }
            
            emit NewEndTimestamp(endTimestamp);
        }
        _;
    }

    function fetchLeaderboard() external view returns(AuctionData[LEADERBOARD_SIZE] memory result) {
        for (uint256 i = 0; i < LEADERBOARD_SIZE;) {
            result[i] = leaderboard[i + 1];
            unchecked {
                ++i;
            }
        }
    }

    function createBid(uint96 _bid) external isRunning extendsTime {
        AuctionData memory data = leaderboard[LEADERBOARD_SIZE];

        if (_bid <= data.bid || _bid - data.bid < minBid) revert BidTooLow();
        if (!tokenContract.transferFrom(msg.sender, address(this), _bid)) revert();

        if (!(data.owner == address(0) || tokenContract.transfer(data.owner, data.bid))) revert();

        uint32 _bidCount = bidCount;
        if (_bidCount < LEADERBOARD_SIZE) {
            unchecked {
                ++_bidCount;
            }
            bidCount = _bidCount;
        }

        data.owner = msg.sender;
        data.bid = _bid;
     
        for (; _bidCount > 1;) {
            AuctionData memory _data = leaderboard[_bidCount - 1];

            if (data.bid <= _data.bid) {
                break;
            }

            leaderboard[_bidCount] = _data;

            unchecked {
                --_bidCount;
            }
        }

        leaderboard[_bidCount] = data;

        emit LeaderboardShuffled();
    }

    function increaseBid(uint96 _bid) external isRunning extendsTime {
        if (_bid < minBid) revert BidTooLow();
        if (!tokenContract.transferFrom(msg.sender, address(this), _bid)) revert();

        uint32 _bidCount = bidCount;
        AuctionData memory data;
        for (; _bidCount > 0;) {
            AuctionData memory _data = leaderboard[_bidCount];

            if(data.owner == msg.sender) {
                if(data.bid > _data.bid) {
                    leaderboard[_bidCount + 1] = _data;
                } else {
                    break;
                }
            }

            if(_data.owner == msg.sender) {
                data.owner = _data.owner;
                data.bid = _data.bid + _bid;
            }

            unchecked {
                --_bidCount;
            }
        }

        if(data.owner == address(0)) revert BidderNotFound();

        leaderboard[_bidCount + 1] = data;

        emit LeaderboardShuffled();
    }

    function withdraw() external {
        if (block.timestamp < endTimestamp) revert AuctionRunning();
        if (bidCount < LEADERBOARD_SIZE) revert NotEnoughBids(); 
        if (rewardContract.balanceOf(address(this)) == 0)
            revert WithdrawComplete();

        for (uint256 i = 0; i < LEADERBOARD_SIZE;) {
            AuctionData memory _data = leaderboard[i + 1];
            if(i < REWARDS_SIZE) {
                rewardContract.transferFrom(address(this), _data.owner, (PACKED_REWARDS >> i * 8) & REWARD_MASK);     
            }
            else {
                tokenContract.transfer(_data.owner, _data.bid);
            }
            unchecked {
                ++i;
            }
        }
    }

    function withdrawContractBalance(address to) external onlyOwner {
        uint256 balance = tokenContract.balanceOf(address(this));
        if (!tokenContract.transfer(to, balance)) revert();
    }

    function withdrawPrize(address to, uint256 id) external onlyOwner {
        rewardContract.transferFrom(address(this), to, id);
    }

    function setEndTimestamp(uint64 _endTimestamp) external onlyOwner {
        endTimestamp = _endTimestamp;
        emit NewEndTimestamp(_endTimestamp);
    }

    function setTimeExtension(uint64 _timeExtension) external onlyOwner {
        timeExtension = _timeExtension;
    }

    function setMinBid(uint96 _minBid) external onlyOwner {
        minBid = _minBid;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}