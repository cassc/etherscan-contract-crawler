// SPDX-License-Identifier: GPL-3.0

// LICENSE
//
// TransitionAuctionHouse.sol is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/blob/54a12ec1a6cf562e49f0a4917990474b11350a2d/contracts/AuctionHouse.sol
//
// TransitionAuctionHouse.sol source code Copyright Zora licensed under the GPL-3.0 license.

pragma solidity ^0.8.6;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ITransitionAuctionHouse} from "./ITransitionAuctionHouse.sol";

import {Transition} from "./Transition.sol";
import {IWETH} from "./IWETH.sol";

// #################################################
// #################################################
//
//         THE TRANSITION AUCTION HOUSE
//
// #################################################
// #################################################

contract TransitionAuctionHouse is ITransitionAuctionHouse, ReentrancyGuard {
    address payable public deployer;
    Transition public transition;
    bool transitionFinalized;
    ITransitionAuctionHouse.Auction public auction;

    address public weth;
    uint256 public timeBuffer;
    uint256 public reservePrice;
    uint8 public minBidIncrementPercentage;
    uint256 public duration;

    uint256 public tokenId = 99;
    bool public started = false;
    bool public done = false;

    address public vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
    address public ethFoundation = 0xde0B295669a9FD93d5F28D9Ec85E40f4cb697BAe;
    bool public vitalikOrEFClaimed = false;

    constructor(
        address _weth,
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _duration
    ) {
        deployer = payable(msg.sender);
        weth = _weth;
        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        duration = _duration;
    }

    /**
     * @dev Vitalik and the Ethereum Foundation can claim all un-auctioned NFTs
     */
    function vitalikOrEthFoundationSpecialClaim() public {
        require(msg.sender == vitalik || msg.sender == ethFoundation);
        require(
            vitalikOrEFClaimed == false && done == false && started == true
        );

        vitalikOrEFClaimed = true;
        done = true;

        for (uint256 id = 0; id <= tokenId - 1; id++) {
            transition.transferFrom(address(this), msg.sender, id);
        }
    }

    /**
     * @dev Settle the current auction, and begin next auction
     */
    function settleCurrentAndCreateNewAuction() external override nonReentrant {
        if (started == false) {
            require(transition.balanceOf(address(this)) == 100);
            started = true;
            _createAuction();
            return;
        }

        _settleAuction();
        _createAuction();
    }

    /**
     * @dev Create a bid for a Noun, with a given amount.
     * This contract only accepts payment in ETH.
     */
    function createBid(uint256 transitionId)
        external
        payable
        override
        nonReentrant
    {
        ITransitionAuctionHouse.Auction memory _auction = auction;

        require(
            _auction.transitionId == transitionId,
            "Transition ID not up for auction"
        );
        require(block.timestamp < _auction.endTime, "Auction expired");
        require(msg.value >= reservePrice, "Must send at least reservePrice");
        require(
            msg.value >=
                _auction.amount +
                    ((_auction.amount * minBidIncrementPercentage) / 100),
            "Must send more than last bid by minBidIncrementPercentage amount"
        );

        address payable lastBidder = _auction.bidder;

        if (lastBidder != address(0)) {
            _safeTransferETHWithFallback(lastBidder, _auction.amount);
        }

        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);

        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = block.timestamp + timeBuffer;
        }

        emit AuctionBid(_auction.transitionId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(_auction.transitionId, _auction.endTime);
        }
    }

    /**
     * @dev Set Transition token address.
     */
    function setTransition(Transition _transition) public {
        require(msg.sender == deployer);
        require(!transitionFinalized);
        transition = _transition;
        transitionFinalized = true;
    }

    /**
     * @dev Create an auction.
     * Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     */
    function _createAuction() internal {
        if (done || vitalikOrEFClaimed) {
            return;
        }
        if (tokenId == 0) {
            done = true;
        }

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;

        auction = Auction({
            transitionId: tokenId,
            amount: 0,
            startTime: startTime,
            endTime: endTime,
            bidder: payable(0),
            settled: false
        });

        emit AuctionCreated(tokenId, startTime, endTime);
    }

    /**
     * @dev Settle an auction, finalizing the bid and paying out to the owner.
     * If there are no bids, the Transition is burned.
     */
    function _settleAuction() internal {
        ITransitionAuctionHouse.Auction memory _auction = auction;

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, "Auction has already been settled");
        require(
            block.timestamp >= _auction.endTime,
            "Auction hasn't completed"
        );

        auction.settled = true;

        if (_auction.bidder == address(0)) {
            transition.burn(_auction.transitionId);
        } else {
            transition.transferFrom(
                address(this),
                _auction.bidder,
                _auction.transitionId
            );
        }

        if (_auction.amount > 0) {
            _safeTransferETHWithFallback(deployer, _auction.amount);
        }

        emit AuctionSettled(
            _auction.transitionId,
            _auction.bidder,
            _auction.amount
        );

        if (done || vitalikOrEFClaimed) {
            tokenId = 0;
        } else if (tokenId != 0) {
            tokenId -= 1;
        }
    }

    /**
     * @dev Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{value: amount}();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @dev Transfer ETH and return the success status.
     * This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }
}