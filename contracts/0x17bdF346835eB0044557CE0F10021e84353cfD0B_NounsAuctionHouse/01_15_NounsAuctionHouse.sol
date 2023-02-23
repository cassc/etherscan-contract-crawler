// SPDX-License-Identifier: GPL-3.0
/// @title The UNouns DAO auction house

/*******************************************************************************
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╩╩╠▒▒▒▒▒╠╩╩╩╩               ╩╩╩╩╠▒▒▒▒▒╠╩╩▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠╩╩  ╠▒╩╩╩╩ε    ▒▒▒▒▒▒  )▒▒▒▒▒▒    ╚╩╩╩╠▒▒  ╩╩▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒╠╩╩▒▒  ▒▒╩╩    ]▒▒▒▒╩╩╩╩╩╩  ╘╩╩╩╩╩╩▒▒▒▒    ,╩╩▒▒  ▒▒╩╩╠▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒Γ  ╚╚▒▒╚╚,,╚▒▒▒╩╚╚╚╚,,,,,,  .,,,,,,╚╚╚╚╠▒▒▒≥,,╚╚▒▒╚╚  ╙▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒,,,,▒▒  ╠▒▒▒╩╚.,,,,▒▒▒▒▒▒  )▒▒▒▒▒▒,,,,╙╚╠▒▒▒╡  ▒▒,,,,╚▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╚╚╠▒╩╚╚▒╠╚╚,,╠▒╚╚½,╔▒▒▒▒▒▒╚╚╚╚  ╘╚╚╚╚▒▒▒▒▒▒,,²╚╚▒▒,,╚╚▒▒╚╚╠▒╩╚╚▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒  ²╚\,,▒Γ  ▒▒▒▒  ]▒▒▒▒▒▒╚╚,,,,  .,,,,╚╚▒▒▒▒▒▒  ]▒▒▒▒  ▒▒,,²╚⌐  ▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒,,,,╓▒╠╚╙,,▒▒╚╚,,]▒▒▒╠╚╚,,╠▒▒▒  )▒▒▒▒,,╚╚╠▒▒▒,,/╚╚▒▒,,╚╚╠▒,,,,,▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒""╠▒╙"╙▒╡  ▒▒▒▒  ▐▒▒▒▒▒▒╓╓▒▒▒▒▒▒  ▐▒▒▒▒▒▒╓╓╢▒▒▒▒▒Γ  ▒▒▒▒  ╠▒╙"╙▒╠"╙▒▒▒▒▒▒
▒▒▒▒▒▒▒╓╓""  ]▒╡  """"  ""╚╬╩╙╙╙╙████╬╬  ║╬╬╙╙╙╙▓███╬╬╙"¬  """"  ╠▒  '"└╓╓▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╓╓╓╓φ▒╡  ╓╓╓╓╓╓╓╓▄╬Γ    ████▓╬╥╓║╬▌    ████╬╬╦╓   ╓╓╓-  ╠▒╓╓╓╓╓▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒""╠▒╙"╙▒╡  ▒▒╬╬╜╙╠╬╣╬Γ    ████▓╬╨╙╟╬▌    ████╬╬▒▒Γ  ▒▒▒▒  ╠▒╙"╙▒╠"╙▒▒▒▒▒▒
▒▒▒▒▒▒▒╓╓""  ]▒╡  ▒▒╬╬  ▐▒╟╬Γ    ████▓╬  ║╬▌    ████╬╬▒▒Γ  ▒▒▒▒  ╠▒  '"└╓╓▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╔╔╔╔φ▒▒╔ε``╠╠╔╔``▐╬▒╗╗╗╗████▒╬  ║╬▌╗╗╗╗████╬╬▒`]╔╔▒▒``╔╔╠▒╔╔╔╔╔▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒``╚▒╩`"▒Γ  ▒▒▒▒  ]╠╠╠╠╠╠╠╠╙╙╙╙  ^╙╙╙╙╠╠╠╠╠╠╠╠  ]▒▒▒▒  ▒▒``╠▒╙`"▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╔╔```  ▒╠╔╔``╠▒╔╔ε`╚▒▒▒▒▒▒╔╔╔╔  «╔╔╔╔▒▒▒▒▒▒``╔╔φ▒╠``╔╔▒▒  ``]╔╔▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒╔╔╔╔╔▒▒▒▒  ╠▒▒▒╦╔⌂````▒▒▒▒▒▒  )▒▒▒▒▒▒````╔╔╠▒▒▒╡  ▒▒▒▒╔╔╔╔φ▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒╙`7▒▒`"▒▒╔╔``╚▒▒▒╦╔╔╔╔``````  ```````╔╔╔╔╠▒▒▒╙`"╔╔▒▒``╠▒"`╙▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒╔╔ε``  ▒▒▒▒╔╔"```╚▒▒▒▒╔╔╔╔╔╔  «╔╔╔╔╔╔▒▒▒▒````]╔╔▒▒▒▒  ``╔╔φ▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒╠φφφφ▒▒  ╠▒φφφφ░    ▒▒▒▒▒▒  )▒▒▒▒▒▒    ╔φφφφ▒╠  ▒▒φφφφ╠▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠    ╠▒▒▒▒▒φφφφφ               φφφφ╠▒▒▒▒▒╡    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠φφφφ╠▒▒▒▒▒▒▒▒▒▒φφφφφφφφφφφφφφφ▒▒▒▒▒▒▒▒▒▒╠φφφφ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░        ╠▒▒▒▒▒Γ        ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░   ]φφφφφφφφ      `φφφφφφφφ    ]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒  ╔▒▒▒▒▒Γ  ▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒Γ    δ▒╠▒▒▒▒▒╠▒φ    ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
*******************************************************************************/


// LICENSE
// NounsAuctionHouse.sol is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/blob/54a12ec1a6cf562e49f0a4917990474b11350a2d/contracts/AuctionHouse.sol
//
// AuctionHouse.sol source code Copyright Zora licensed under the GPL-3.0 license.
// With modifications by UNounders DAO.

pragma solidity ^0.8.6;

import { PausableUpgradeable } from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { INounsAuctionHouse } from './interfaces/INounsAuctionHouse.sol';
import { INounsToken } from './interfaces/INounsToken.sol';
import { IWETH } from './interfaces/IWETH.sol';

contract NounsAuctionHouse is INounsAuctionHouse, PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    // The UNouns ERC721 token contract
    INounsToken public nouns;

    // The address of the WETH contract
    address public weth;

    // The address of Nouns DAO treasury
    address public nounsDAOTreasury;

    // The address of hall of fame
    address public halloffame;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The time that Nouns DAO treasury stops receiving rewards
    uint256 public proceedsShareEndTime;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // The duration of a single auction
    uint256 public duration;

    // The active auction
    INounsAuctionHouse.Auction public auction;

    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        INounsToken _nouns,
        address _weth,
        address _nounsDAOTreasury,
        address _halloffame,
        uint256 _timeBuffer,
        uint256 _proceedsShareEndTime,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _duration
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _pause();


        require(
            _nounsDAOTreasury != address(0) && _halloffame != address(0) && _weth != address(0),
            "ZERO ADDRESS"
        );
        require(_reservePrice > 0, "Reserve price is zero");
        require(_minBidIncrementPercentage <= 100, "Min bid increment percentange too high");

        nouns = _nouns;
        weth = _weth;
        nounsDAOTreasury = _nounsDAOTreasury;
        halloffame = _halloffame;
        timeBuffer = _timeBuffer;
        proceedsShareEndTime = _proceedsShareEndTime;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        duration = _duration;
    }

    /**
     * @notice Settle the current auction, mint a new Noun, and put it up for auction.
     */
    function settleCurrentAndCreateNewAuction() external override nonReentrant whenNotPaused {
        _settleAuction();
        _createAuction();
    }

    /**
     * @notice Settle the current auction.
     * @dev This function can only be called when the contract is paused.
     */
    function settleAuction() external override whenPaused nonReentrant {
        _settleAuction();
    }

    /**
     * @notice Create a bid for a Noun, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256 unounId) external payable override nonReentrant {
        INounsAuctionHouse.Auction memory _auction = auction;

        require(_auction.unounId == unounId, 'Noun not up for auction');
        require(block.timestamp < _auction.endTime, 'Auction expired');
        require(msg.value >= reservePrice, 'Must send at least reservePrice');
        require(
            msg.value >= _auction.amount + ((_auction.amount * minBidIncrementPercentage) / 100),
            'Must send more than last bid by minBidIncrementPercentage amount'
        );

        address payable lastBidder = _auction.bidder;

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            _safeTransferETHWithFallback(lastBidder, _auction.amount);
        }

        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = block.timestamp + timeBuffer;
        }

        emit AuctionBid(_auction.unounId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(_auction.unounId, _auction.endTime);
        }
    }

    /**
     * @notice Pause the UNouns auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Finish the proceeds share to Nouns DAO Treasury.
     * @dev This function can only be called by the owner.
     */
    function finishNounsDAOTreasuryShare() external onlyOwner {
        proceedsShareEndTime = 0;
    }

    /**
     * @notice Unpause the UNouns auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause() external override onlyOwner {
        _unpause();

        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setTimeBuffer(uint256 _timeBuffer) external override onlyOwner {
        timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePrice(uint256 _reservePrice) external override onlyOwner {
        reservePrice = _reservePrice;

        emit AuctionReservePriceUpdated(_reservePrice);
    }

    /**
     * @notice Set the auction minimum bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external override onlyOwner {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction() internal {
        try nouns.mint() returns (uint256 unounId) {
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + duration;

            auction = Auction({
                unounId: unounId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false
            });

            emit AuctionCreated(unounId, startTime, endTime);
        } catch Error(string memory) {
            _pause();
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the Noun is burned.
     */
    function _settleAuction() internal {
        INounsAuctionHouse.Auction memory _auction = auction;

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, 'Auction has already been settled');
        require(block.timestamp >= _auction.endTime, "Auction hasn't completed");

        auction.settled = true;

        if (_auction.bidder == address(0)) {
            nouns.transferFrom(address(this), halloffame, _auction.unounId);
        } else {
            nouns.transferFrom(address(this), _auction.bidder, _auction.unounId);
        }

        if (_auction.amount > 0) {
            if (block.timestamp < proceedsShareEndTime) {
                // transfer to UNouns DAO Treasury
                if (_auction.unounId % 100 == 88) {
                    _safeTransferETHWithFallback(nounsDAOTreasury, _auction.amount);
                } else {
                    // transfer to UNouns DAO
                    _safeTransferETHWithFallback(owner(), _auction.amount);
                }
            } else {
                // transfer to UNouns DAO
                _safeTransferETHWithFallback(owner(), _auction.amount);
            }
        }

        if (_auction.bidder == address(0)) {
            emit AuctionSettled(_auction.unounId, halloffame, _auction.amount);
        } else {
            emit AuctionSettled(_auction.unounId, _auction.bidder, _auction.amount);
        }
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{ value: amount }();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }
}