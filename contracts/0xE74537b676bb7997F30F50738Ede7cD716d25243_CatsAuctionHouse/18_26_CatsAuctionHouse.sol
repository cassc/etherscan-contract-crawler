// SPDX-License-Identifier: GPL-3.0

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

// LICENSE
// CatsAuctionHouse.sol is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/blob/54a12ec1a6cf562e49f0a4917990474b11350a2d/contracts/AuctionHouse.sol
//
// AuctionHouse.sol source code Copyright Zora licensed under the GPL-3.0 license.
// With modifications by Catders DAO.

pragma solidity 0.8.16;
import { ICatsAuctionHouse } from "./ICatsAuctionHouse.sol";
import { ICats } from "../cats/ICats.sol";
import { IAuctionable } from "../cats/IAuctionable.sol";
import { ICatcoin } from "../catcoin/ICatcoin.sol";
import { ReentrancyGuard } from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import { CatsAuctionHouseStorage } from "./CatsAuctionHouseStorage.sol";
import { AuctionPaymentLibrary } from "./AuctionPaymentLibrary.sol";
import { LibDiamond } from "../diamond/LibDiamond.sol";

contract CatsAuctionHouse is ICatsAuctionHouse, ReentrancyGuard {
    using AuctionPaymentLibrary for ICatsAuctionHouse.Auction;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier whenNotPaused() {
        require(
            !CatsAuctionHouseStorage.layout().paused && CatsAuctionHouseStorage.layout().duration != 0,
            "Pausable: paused"
        );
        _;
    }

    modifier whenPaused() {
        require(
            CatsAuctionHouseStorage.layout().paused || CatsAuctionHouseStorage.layout().duration == 0,
            "Pausable: not paused"
        );
        _;
    }

    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     */
    function setConfig(
        address treasury_,
        address devs_,
        IAuctionable cats_,
        address weth_,
        uint256 timeBuffer_,
        uint256 reservePriceInETH_,
        uint256 reservePriceInCatcoins_,
        uint8 minBidIncrementPercentage_,
        uint8 minBidIncrementUnit_,
        uint256 duration_
    ) external onlyOwner {
        pause();

        CatsAuctionHouseStorage.layout().treasury = treasury_;
        CatsAuctionHouseStorage.layout().devs = devs_;
        CatsAuctionHouseStorage.layout().cats = cats_;
        CatsAuctionHouseStorage.layout().weth = weth_;
        CatsAuctionHouseStorage.layout().timeBuffer = timeBuffer_;
        CatsAuctionHouseStorage.layout().reservePriceInETH = reservePriceInETH_;
        CatsAuctionHouseStorage.layout().reservePriceInCatcoins = reservePriceInCatcoins_;
        CatsAuctionHouseStorage.layout().minBidIncrementPercentage = minBidIncrementPercentage_;
        CatsAuctionHouseStorage.layout().minBidIncrementUnit = minBidIncrementUnit_;
        CatsAuctionHouseStorage.layout().duration = duration_;
        CatsAuctionHouseStorage.layout().ethAuctions = true;
    }

    /**
     * @notice Settle the current auction, mint a new Cat, and put it up for auction.
     * @dev If the auction is in ETH tokenIds is ignored
     */
    function settleCurrentAndCreateNewAuction(uint256[] calldata tokenIds)
        external
        override
        nonReentrant
        whenNotPaused
    {
        _settleAuction(tokenIds);
        _createAuction();
    }

    /**
     * @notice Settle the current auction.
     * @dev This function can only be called when the contract is paused.
     *      If the auction is in ETH tokenIds is ignored
     */
    function settleAuction(uint256[] calldata tokenIds) external override whenPaused nonReentrant {
        _settleAuction(tokenIds);
    }

    /**
     * @notice Create a bid for a Cat, with a given amount.
     * @dev This contract only accepts payment in ETH or Catcoin.
     */
    function createBid(uint256 catId, uint256 amount) external payable override whenNotPaused nonReentrant {
        ICatsAuctionHouse.Auction memory _auction = CatsAuctionHouseStorage.layout().auction;

        require(_auction.catId == catId, "Cat not up for auction");
        require(block.timestamp < _auction.endTime, "Auction expired");
        (bool valid, string memory message) = _auction.isBidValid(amount);
        require(valid, message);

        address payable lastBidder = _auction.bidder;

        // Refund the last bidder, if applicableminBidIncrement
        if (lastBidder != address(0)) {
            _auction.reverseLastBid();
        }

        CatsAuctionHouseStorage.layout().auction.bidder = payable(msg.sender);
        CatsAuctionHouseStorage.layout().auction.amount = amount;

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < CatsAuctionHouseStorage.layout().timeBuffer;
        if (extended) {
            CatsAuctionHouseStorage.layout().auction.endTime = _auction.endTime =
                block.timestamp +
                CatsAuctionHouseStorage.layout().timeBuffer;
        }

        emit AuctionBid(_auction.catId, msg.sender, amount, extended);

        if (extended) {
            emit AuctionExtended(_auction.catId, _auction.endTime);
        }
    }

    /**
     * @notice Pause the Cats auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() public onlyOwner {
        CatsAuctionHouseStorage.layout().paused = true;
    }

    /**
     * @notice Unpause the Cats auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause() external onlyOwner {
        CatsAuctionHouseStorage.layout().paused = false;
        ICatsAuctionHouse.Auction memory _auction = CatsAuctionHouseStorage.layout().auction;
        if (_auction.startTime == 0 || _auction.settled) {
            _createAuction();
        }
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setTimeBuffer(uint256 _timeBuffer) external override onlyOwner {
        CatsAuctionHouseStorage.layout().timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setDuration(uint256 duration_) external override onlyOwner {
        CatsAuctionHouseStorage.layout().duration = duration_;

        emit AuctionDurationUpdated(duration_);
    }

    /**
     * @notice Set the auction reserve price for ETH settled auctions.
     * @dev Only callable by the owner.
     */
    function setReservePriceInETH(uint256 reservePriceInETH_) external override onlyOwner {
        CatsAuctionHouseStorage.layout().reservePriceInETH = reservePriceInETH_;

        emit AuctionReservePriceInETHUpdated(reservePriceInETH_);
    }

    /**
     * @notice Set the auction reserve price for Catcoin settled auctions.
     * @dev Only callable by the owner.
     */
    function setReservePriceInCatcoins(uint256 reservePriceInCatcoins_) external override onlyOwner {
        CatsAuctionHouseStorage.layout().reservePriceInCatcoins = reservePriceInCatcoins_;

        emit AuctionReservePriceInCatcoinsUpdated(reservePriceInCatcoins_);
    }

    /**
     * @notice Set the auction minimum bid increment percentage (e.g 1 is 1%).
     * @dev Only callable by the owner. Used for ETH settled auctions.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external override onlyOwner {
        CatsAuctionHouseStorage.layout().minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    /**
     * @notice Set the auction minimum bid increment in units.
     * @dev Only callable by the owner. Used for Catcoin settled auctions.
     */
    function setMinBidIncrementUnit(uint8 _minBidIncrementUnit) external override onlyOwner {
        CatsAuctionHouseStorage.layout().minBidIncrementUnit = _minBidIncrementUnit;

        emit AuctionMinBidIncrementUnitUpdated(_minBidIncrementUnit);
    }

    /**
     * @notice Set the auction currency
     * @dev Only callable by the owner.
     */
    function setETHAuctions(bool ethAuctions_) external override onlyOwner {
        CatsAuctionHouseStorage.layout().ethAuctions = ethAuctions_;

        emit ETHAuctionsUpdated(ethAuctions_);
    }

    /**
     * @notice Set the devs address
     * @dev Only callable by the owner.
     */
    function setDevs(address devs_) external override onlyOwner {
        CatsAuctionHouseStorage.layout().devs = devs_;
    }

    /**
     * @notice Set the treasury address
     * @dev Only callable by the owner.
     */
    function setTreasury(address treasury_) external override onlyOwner {
        CatsAuctionHouseStorage.layout().treasury = treasury_;
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in minBidIncrementble and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction() internal {
        try CatsAuctionHouseStorage.layout().cats.mintOne(address(this)) returns (uint256 catId) {
            if (catId % 10 == 0) {
                ICats(address(CatsAuctionHouseStorage.layout().cats)).transferFrom(
                    address(this),
                    CatsAuctionHouseStorage.layout().devs,
                    catId
                );
                _createAuction();
                return;
            }
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + CatsAuctionHouseStorage.layout().duration;

            CatsAuctionHouseStorage.layout().auction = Auction({
                catId: catId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false,
                isETH: CatsAuctionHouseStorage.layout().ethAuctions
            });

            emit AuctionCreated(catId, startTime, endTime);
        } catch Error(string memory) {
            pause();
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the Cat is burned.
     */
    function _settleAuction(uint256[] calldata tokenIds) internal {
        ICatsAuctionHouse.Auction memory _auction = CatsAuctionHouseStorage.layout().auction;

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, "Auction has already been settled");
        require(block.timestamp >= _auction.endTime, "Auction hasn't completed");

        CatsAuctionHouseStorage.layout().auction.settled = true;

        if (_auction.amount > 0) {
            _auction.withdraw(CatsAuctionHouseStorage.layout().treasury, tokenIds);
        }

        if (_auction.bidder == address(0)) {
            CatsAuctionHouseStorage.layout().cats.burn(_auction.catId);
        } else {
            ICats(address(CatsAuctionHouseStorage.layout().cats)).transferFrom(
                address(this),
                _auction.bidder,
                _auction.catId
            );
        }

        emit AuctionSettled(_auction.catId, _auction.bidder, _auction.amount);
    }

    function treasury() external view override returns (address) {
        return CatsAuctionHouseStorage.layout().treasury;
    }

    function devs() external view override returns (address) {
        return CatsAuctionHouseStorage.layout().devs;
    }

    function cats() external view override returns (IAuctionable) {
        return CatsAuctionHouseStorage.layout().cats;
    }

    function weth() external view override returns (address) {
        return CatsAuctionHouseStorage.layout().weth;
    }

    function timeBuffer() external view override returns (uint256) {
        return CatsAuctionHouseStorage.layout().timeBuffer;
    }

    function reservePriceInETH() external view override returns (uint256) {
        return CatsAuctionHouseStorage.layout().reservePriceInETH;
    }

    function reservePriceInCatcoins() external view override returns (uint256) {
        return CatsAuctionHouseStorage.layout().reservePriceInCatcoins;
    }

    function minBidIncrementPercentage() external view override returns (uint8) {
        return CatsAuctionHouseStorage.layout().minBidIncrementPercentage;
    }

    function minBidIncrementUnit() external view override returns (uint8) {
        return CatsAuctionHouseStorage.layout().minBidIncrementUnit;
    }

    function duration() external view override returns (uint256) {
        return CatsAuctionHouseStorage.layout().duration;
    }

    function auction() external view override returns (Auction memory) {
        return CatsAuctionHouseStorage.layout().auction;
    }

    function paused() external view override returns (bool) {
        return CatsAuctionHouseStorage.layout().paused;
    }

    function ethAuctions() external view override returns (bool) {
        return CatsAuctionHouseStorage.layout().ethAuctions;
    }
}