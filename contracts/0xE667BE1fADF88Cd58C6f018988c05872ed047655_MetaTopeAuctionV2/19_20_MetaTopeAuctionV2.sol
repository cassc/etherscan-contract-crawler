//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./MetaTopeIERC1155Receiver.sol";

/**
 * @title Contract for MetaTope Auction V2
 * Copyright 2022 MetaTope
 */
contract MetaTopeAuctionV2 is MetaTopeIERC1155Receiver, Ownable {
    ERC1155 public rewardToken;
    ERC20 public depositToken;
    uint128 public rewardTokenId;

    struct AuctionBid {
        uint256 tokenAmount;
        uint256 pricePerToken;
        uint256 totalPrice;
        uint128 createdAt;
        bool canceled;
        bool claimed;
    }

    struct WinAuctionBid {
        uint256 tokenAmount;
        uint256 pricePerToken;
        uint256 totalPrice;
        bool claimed;
        address bidderAddress;
    }

    mapping(address => AuctionBid) public bidders;
    mapping(address => WinAuctionBid) public winners;
    WinAuctionBid[] public sortedBids;
    address[] public bidderAddresses;
    address[] public winnerAddresses;
    address public withdrawAddress;

    bool public started;
    bool public winnersComputed;
    bool public tokensTransferred;
    bool public bidsSorted;

    bool private tmpSubSortInterrupted;
    WinAuctionBid private tmpSubSortBid;
    uint256 private tmpSubSortIndex;

    uint128 public startAt;
    uint128 public endAt;
    uint256 public totalTokenAmount;
    uint256 public minPricePerToken;
    uint256 public maxTokenPerAddress;
    uint256 public lowestPrice;
    uint256 public computedIndex;
    uint256 public transferredIndex;
    uint256 public sortedIndex = 0;
    uint256 public totalTokenWon;

    event StartAuction();
    event MakeBid(
        address indexed user,
        uint256 tokenAmount,
        uint256 pricePerToken,
        uint256 totalPrice,
        uint128 createdAt
    );
    event UpdateBid(
        address indexed user,
        uint256 tokenAmount,
        uint256 pricePerToken,
        uint256 totalPrice,
        uint128 updatedAt
    );
    event CancelBid(address indexed user);
    event EndAuction();
    event Withdraw(address to);
    event TokensTransferred();
    event WinnersComputed();

    modifier onlyStarted() {
        require(started == true, "Auction should not be ended");
        require(endAt >= block.timestamp, "Auction was already ended");
        _;
    }

    modifier onlyEnded() {
        require(started == false, "Auction should be ended");
        _;
    }

    modifier notContract() {
        require((!_isContract(msg.sender)) && (msg.sender == tx.origin), "Contract not allowed");
        _;
    }

    /**
     * @dev Constructor
     * @param _rewardToken reward token after auction finished
     * @param _depositToken deposit token for bidding WETH
     * @param _rewardTokenId reward token id by default 0
     * @param _withdrawAddress address to withdraw to
     */
    constructor(
        ERC1155 _rewardToken,
        ERC20 _depositToken,
        uint128 _rewardTokenId,
        address _withdrawAddress
    ) {
        rewardToken = _rewardToken;
        rewardTokenId = _rewardTokenId; // 0
        depositToken = _depositToken;
        withdrawAddress = _withdrawAddress;
    }

    /**
     * @dev Function to start auction
     * @param _totalTokenAmount set totalTokenAmount
     * @param _minPricePerToken set min token price per token
     * @param _endDuration set auction duration
     * @param _maxTokenPerAddress set max amountof tokens
     */
    function start(
        uint256 _totalTokenAmount,
        uint256 _minPricePerToken,
        uint128 _endDuration,
        uint256 _maxTokenPerAddress
    ) external onlyOwner {
        require(started == false, "Auction should not be started yet");
        require(endAt == 0, "Auction cannot be restarted");
        require(
            _totalTokenAmount > 0,
            "TotalTokenAmount should be greater than zero"
        );
        require(_minPricePerToken > 0, "MinPrice should be greater than zero");

        totalTokenAmount = _totalTokenAmount;
        minPricePerToken = _minPricePerToken;
        maxTokenPerAddress = _maxTokenPerAddress;
        started = true;
        startAt = uint128(block.timestamp);
        endAt = startAt + (_endDuration * 1 days);

        rewardToken.safeTransferFrom(
            msg.sender,
            address(this),
            rewardTokenId,
            totalTokenAmount,
            ""
        );

        emit StartAuction();
    }

    /**
     * @dev Function to bid or update. Called by the user
     * @param _tokenAmount Token Amount
     * @param _pricePerToken Price Per Token
     */
    function bid(uint256 _tokenAmount, uint256 _pricePerToken)
        external
        onlyStarted
        notContract
    {
        require(_tokenAmount > 0, "TokenAmount should be greater than zero");
        require(maxTokenPerAddress >= _tokenAmount, "TokenAmount should be less than maxTokenPerAddress");
        require(
            _pricePerToken >= minPricePerToken,
            "PricePerToken should be greater than minPricePerToken"
        );
        uint256 _approvedAmount = depositToken.allowance(
            msg.sender,
            address(this)
        );
        uint256 _totalPrice = _pricePerToken * _tokenAmount;

        require(
            _approvedAmount >= _totalPrice,
            "ApprovedAmount should be greater than totalPrice"
        );
        AuctionBid memory auction = AuctionBid({
            tokenAmount: _tokenAmount,
            totalPrice: _totalPrice,
            pricePerToken: _pricePerToken,
            createdAt: uint128(block.timestamp),
            canceled: false,
            claimed: false
        });
        uint256 oldTokenAmount = bidders[msg.sender].tokenAmount;
        bidders[msg.sender] = auction;
        if (oldTokenAmount == 0) {
            bidderAddresses.push(msg.sender);
            emit MakeBid(
                msg.sender,
                _tokenAmount,
                _pricePerToken,
                _totalPrice,
                auction.createdAt
            );
        } else {
            emit UpdateBid(
                msg.sender,
                _tokenAmount,
                _pricePerToken,
                _totalPrice,
                auction.createdAt
            );
        }
    }

    /**
     * @dev Function to get bidder addresses in chunks
     */
    function getBidderAddresses(uint256 _from, uint256 _count) external view returns(address[] memory) {
        uint256 from = _from;
        uint256 range = _from + _count;
        uint256 index = 0;
        address[] memory mBidders = new address[](range);
        for (from; from < range; ++from) {
            if (from >= bidderAddresses.length) break;
            mBidders[index] = bidderAddresses[from];
            index++;
        }
        return mBidders;
    }

    /**
     * @dev Function to get winner addresses in chunks
     */
    function getWinnerAddresses(uint256 _from, uint256 _count) external view returns(address[] memory) {
        uint256 from = _from;
        uint256 range = _from + _count;
        uint256 index = 0;
        address[] memory mWinners = new address[](range);
        for (from; from < range; ++from) {
            if (from >= winnerAddresses.length) break;
            mWinners[index] = winnerAddresses[from];
            index++;
        }
        return mWinners;
    }

    /**
     * @dev get the sorted bids in chunks
     */
    function getSortedBids(uint256 _from, uint256 _count) external view returns(address[] memory) {
        uint256 from = _from;
        uint256 range = _from + _count;
        uint256 index = 0;
        address[] memory mBids = new address[](range);
        for (from; from < range; ++from) {
            if (from >= sortedBids.length) break;
            mBids[index] = sortedBids[from].bidderAddress;
            index++;
        }
        return mBids;
    }

    /**
     * @dev Function to get all bids
     * @param _bidderAddresses addresses to get bids
     */
    function getBids(address[] memory _bidderAddresses) external view returns(AuctionBid[] memory) {
        AuctionBid[] memory mBidders = new AuctionBid[](_bidderAddresses.length);
        for (uint256 i; i < _bidderAddresses.length; ++i) {
            mBidders[i] = bidders[_bidderAddresses[i]];
        }
        return mBidders;
    }

    /**
     * @dev Function to get winnerbids
     * @param _winnerAddresses addresses to get bids
     */
    function getWinBids(address[] memory _winnerAddresses) external view returns(WinAuctionBid[] memory) {
        WinAuctionBid[] memory mWinners = new WinAuctionBid[](_winnerAddresses.length);
        for (uint256 i; i < _winnerAddresses.length; ++i) {
            mWinners[i] = winners[_winnerAddresses[i]];
        }
        return mWinners;
    }

    /**
     * @dev Function to cancel bid
     */
    function cancel() external onlyStarted {
        bidders[msg.sender].canceled = true;
        emit CancelBid(msg.sender);
    }

    /**
     * @dev Function to end auction
     */
    function endAuction() external onlyOwner onlyStarted {
        endAt = uint128(block.timestamp);
        started = false;
        emit EndAuction();
    }

    /**
     * @dev Function to set sorted bids from highest pricePerToken to lowest
     */
    function setSortedBids(address[] memory _bidderAddresses) external onlyOwner onlyEnded {
        require(!bidsSorted, "Should not be sorted");
        require(_bidderAddresses.length > 0, "BidderAddresses should be greater than 0");
        require(bidderAddresses.length > 0, "Bids should be greater than 0");

        for (uint256 i = 0; i < _bidderAddresses.length; ++i) {
            WinAuctionBid memory wonBid = WinAuctionBid({
                tokenAmount: bidders[_bidderAddresses[i]].tokenAmount,
                pricePerToken: bidders[_bidderAddresses[i]].pricePerToken,
                totalPrice: bidders[_bidderAddresses[i]].totalPrice,
                claimed: bidders[_bidderAddresses[i]].claimed,
                bidderAddress: _bidderAddresses[i]
            });
            sortedBids.push(wonBid);

            if ((sortedIndex + i) >= bidderAddresses.length - 1) {
                bidsSorted = true;
                break;
            }
        }
        sortedIndex = sortedIndex + _bidderAddresses.length;
    }

    /**
     * @dev Function to compute the winners ended
     */
    function computeWinners(uint256 _batchSize) external onlyOwner onlyEnded {
        require(!winnersComputed, "Winners should not be computed yet");
        require(bidsSorted, "Should be sorted");
        require(_batchSize >= 1, "BatchSize should be greater than 0");

        uint256 range = computedIndex + _batchSize;
        for (computedIndex; computedIndex < range; ++computedIndex) {
            if (computedIndex > sortedBids.length - 1) {
                winnersComputed = true;
                emit WinnersComputed();
                break;
            }

            WinAuctionBid memory _bid = sortedBids[computedIndex];

            if (_bid.claimed) continue;


            if (totalTokenWon + _bid.tokenAmount > totalTokenAmount && totalTokenWon < totalTokenAmount) {
                _bid.tokenAmount = totalTokenAmount - totalTokenWon;
            } else if (totalTokenWon >= totalTokenAmount) {
                winnersComputed = true;
                emit WinnersComputed();
                break;
            }

            totalTokenWon = totalTokenWon + _bid.tokenAmount;

            uint256 price = _bid.tokenAmount * lowestPrice;
            uint256 _depositTokenAmount = depositToken.balanceOf(_bid.bidderAddress);
            uint256 _approvedAmount = depositToken.allowance(
                _bid.bidderAddress,
                address(this)
            );

            if (price > _depositTokenAmount || price > _approvedAmount) {
                totalTokenWon = totalTokenWon - _bid.tokenAmount;
                continue;
            }

            winners[_bid.bidderAddress] = _bid;
            winnerAddresses.push(_bid.bidderAddress);

            if (lowestPrice == 0) {
                lowestPrice = _bid.pricePerToken;
            } else if (_bid.pricePerToken < lowestPrice) {
                lowestPrice = _bid.pricePerToken;
            }
        }
    }

    /**
     * @dev Function to transfer tokens for winners
     */
    function transferTokens(uint256 _batchSize) external onlyOwner onlyEnded {
        require(bidderAddresses.length > 0, "Winners should be greater than 0");
        require(winnersComputed, "Winners should be computed first");
        require(_batchSize >= 1, "BatchSize should be greater than 0");

        uint256 range = transferredIndex + _batchSize;
        for (transferredIndex; transferredIndex < range; ++transferredIndex) {
            if (transferredIndex >= winnerAddresses.length) {
                tokensTransferred = true;
                emit TokensTransferred();
                break;
            }

            address winnerAddress = winnerAddresses[transferredIndex];
            if (winnerAddress == address(0)) continue;

            WinAuctionBid memory _bid = winners[winnerAddress];
            uint256 price = _bid.tokenAmount * lowestPrice;

            uint256 _depositTokenAmount = depositToken.balanceOf(winnerAddress);
            uint256 _approvedAmount = depositToken.allowance(
                winnerAddress,
                address(this)
            );
            if (price > _depositTokenAmount || price > _approvedAmount) {
                continue;
            }

            require(depositToken.transferFrom(
                winnerAddress,
                address(this),
                price
            ), "Deposit token was not transferred");

            rewardToken.safeTransferFrom(
                address(this),
                winnerAddress,
                rewardTokenId,
                winners[winnerAddress].tokenAmount,
                "0x"
            );

            winners[winnerAddress].claimed = true;
            bidders[winnerAddress].claimed = true;
        }
    }

    /**
     * @dev Function to withdraw funds
     */
    function withdraw() external onlyOwner onlyEnded {
        uint256 _depositTokenAmount = depositToken.balanceOf(address(this));
        uint256 _rewardTokenAmount = rewardToken.balanceOf(address(this), rewardTokenId);

        require(depositToken.transfer(withdrawAddress, _depositTokenAmount), "Token not transferred");

        if (_rewardTokenAmount > 0) {
            rewardToken.safeTransferFrom(address(this), withdrawAddress, rewardTokenId, _rewardTokenAmount, "0x");
        }

        emit Withdraw(withdrawAddress);
    }

    /**
     * @dev get total count of bids
     */
    function getBidCount() external view returns(uint) {
        return bidderAddresses.length;
    }

    /**
     * @dev Function to check if address is contract address
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}