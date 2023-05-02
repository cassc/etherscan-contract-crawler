// SPDX-License-Identifier: GPL-3.0

// The Wildxyz ReserveAuction.sol

/* ReserveAuction.sol is a modified early-version of OasisAuctionHouse.sol

specifically: https://github.com/WILD-xyz/Oasis/blob/1ce5e883f09f5459f1959c275dbf4520fb022d93/contracts/OasisAuctionHouse.sol
from commit: https://github.com/WILD-xyz/Oasis/commit/1ce5e883f09f5459f1959c275dbf4520fb022d93

Only handles one auction! Not repeatable!
*/

pragma solidity ^0.8.18;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import './WildNFT.sol';
import './IReserveAuction.sol';

interface SanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}

contract ReserveAuction is
    IReserveAuction,
    Pausable,
    ReentrancyGuard,
    Ownable
{

    /* STATE VARIABLES */

    WildNFT public nft; // The NFT contract

    bool nftMinted = false;

    address payable public payee; // The artist address that receives funds from the auction
    address payable public wildWallet; // Wild's wallet address

    uint256 public wildPrimaryRoyalty; // 10% of the final bid price
    uint256 public feeNumerator;

    uint256 public reservePrice;// = .01 ether; // The minimum price accepted in an auction

    uint256 public timeBuffer;// = 60*15; // min amount of time left in an auction after last bid (15 min)
    uint256 public duration;// = 86400; // 86400 == 1 day /The duration of a single auction in seconds
    
    uint256 public currentTokenId; // The current token ID being auctioned

    uint8 public minBidIncrementPercentage;// = 2; // The minimum bid increment percentage

    // The active auction
    IReserveAuction.Auction public auction;

    SanctionsList public sanctionsList;

    /* CONSTRUCTOR */

    constructor(
        WildNFT _nft,
        address _sanctions,
        address _payee,
        address _wildWallet,
        uint256 _wildPrimaryRoyalty,
        uint256 _feeNumerator,
        uint256 _reservePrice,
        uint256 _duration,
        uint256 _timeBuffer,
        uint8 _minBidIncrementPercentage
    ) {
        nft = _nft;

        sanctionsList = SanctionsList(_sanctions);

        payee = payable(_payee);
        wildWallet = payable(_wildWallet);

        wildPrimaryRoyalty = _wildPrimaryRoyalty;
        feeNumerator = _feeNumerator;

        reservePrice = _reservePrice;

        duration = _duration;
        timeBuffer = _timeBuffer;

        minBidIncrementPercentage = _minBidIncrementPercentage;
        
        _pause();
    }

    /* MODIFIERS */

    // Only allow the auction functions to be active when not paused
    modifier onlyUnpaused() {
        require(!paused(), 'AuctionHouse: paused');
        _;
    }

    // Not on OFAC list
    modifier onlyUnsanctioned(address _to) {
        bool isToSanctioned = sanctionsList.isSanctioned(_to);
        require(!isToSanctioned, "Blocked: OFAC sanctioned address");
        _;
    }

    /* PUBLIC GETTERS FUNCTIONS */

    // Returns the current auction and parameters needed for frontend
    function getCurrentAuction()
        external
        view
        returns (IReserveAuction.Auction memory, uint256, uint256)
    {
        return (auction, reservePrice, minBidIncrementPercentage);
    }

    /* ADMIN SINGLE USE MINTING METHOD */
    function mint() public onlyOwner {
        require(!nftMinted, "ReserveAuction: NFT has already been minted!");

        // mint a token to this contract
        uint256 tokenId = nft.mint(address(this));
        
        currentTokenId = tokenId;

        nftMinted = true;
    }

    /* ADMIN VARIABLE SETTERS FUNCTIONS */

    // set the 721 contract address
    function set721ContractAddress(WildNFT _nft) public onlyOwner {
        nft = _nft;
    }

    // set the time buffer
    function setTimeBuffer(uint256 _timeBuffer) external onlyOwner override {
        timeBuffer = _timeBuffer;
        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    // set the reserve price
    function setReservePrice(uint256 _reservePrice) external onlyOwner {
        reservePrice = _reservePrice;
    }

    // set the duration
    function setDuration(uint256 _duration) external onlyOwner override {
        duration = _duration;
        emit AuctionDurationUpdated(_duration);
    }

    // set the min bid increment percentage
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage)
        external
        onlyOwner
        override
    {
        minBidIncrementPercentage = _minBidIncrementPercentage;
        emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    // set payee for withdraw
    function setPayee(address payable _payee) public onlyOwner {
        payee = _payee;
    }

    // set wildWallet for withdraw
    function setWildWallet(address payable _wildWallet) public onlyOwner {
        wildWallet = _wildWallet;
    }

    // set wildPrimaryRoyalty
    function setWildPrimaryRoyalty(uint256 _wildPrimaryRoyalty) public onlyOwner {
        wildPrimaryRoyalty = _wildPrimaryRoyalty;
    }

    // set feeNumerator
    function setFeeNumerator(uint256 _feeNumerator) public onlyOwner {
        feeNumerator = _feeNumerator;
    }

    // set auction End Time
    function setAuctionEndTime(uint256 _auctionEndTime) public onlyOwner {
        auction.endTime = _auctionEndTime;
    }

    // pause
    function pause() external onlyOwner override {
        _pause();
    }

    // unpause
    function unpause() external onlyOwner override {
        _unpause();
    }

    /* END ADMIN VARIABLE SETTERS FUNCTIONS */

    /* PUBLIC FUNCTIONS */

    // Settles auction
    function settleAuction() external nonReentrant override onlyOwner {
        _settleAuction();
        //require(block.timestamp >= auction.startTime, 'AuctionHouse: auction not started');
    }

    // Creates bids for the current auction
    function createBid(uint256 _currentTokenId) external payable nonReentrant override onlyUnpaused onlyUnsanctioned(msg.sender) {

        // Check that the auction is live
        require(_currentTokenId == auction.tokenId, 'ReserveAuction: Bid on wrong tokenId.');

        uint256 bidAmount = msg.value;
        address bidder = msg.sender;

        // check if reserve price has been met
        if (auction.reservePriceMet) {
            // if reserve price met, check auction variables
            require(block.timestamp < auction.endTime, 'ReserveAuction: Auction has ended.');
            require(block.timestamp > auction.startTime, 'ReserveAuction: Auction has not started.');

            require(
                bidAmount >= auction.amount + ((auction.amount * minBidIncrementPercentage) / 100), 
                "ReserveAuction: Bid is too low."
            );

            // A reference to benchmark the new bid against
            address payable lastBidder = auction.bidder;

            // Refund the previous highest bidder,
            if (lastBidder != address(0) ) {
                _safeTransferETH(lastBidder, auction.amount);
            }

            // Update the auction state with the new bid bidder and the new amount
            auction.bidder = payable(bidder);
            auction.amount = bidAmount;

            // TODO:
            //emit OutBid(lastBidder, bidder, bidAmount);

        } else {
            // if reserve price not met, check reserve variables
            require(bidAmount >= reservePrice, "ReserveAuction: Bid must be greater than or equal to reserve price.");

            // create auction here
            auction = Auction({
                tokenId: currentTokenId,

                amount: bidAmount,

                startTime: block.timestamp,
                endTime: block.timestamp + duration,
                extendedTime: 0,

                bidder: payable(bidder),

                settled: false,
                reservePriceMet: true
            });

            emit ReserveAuctionCreated(currentTokenId, auction.startTime, auction.endTime);
            //emit ReservePriceMet(true);
        }

        // Extend the auction if the bid was received within the time buffer,
        // only up to the timeBuffer cap.
        uint256 timeLeft = auction.endTime - block.timestamp;
        bool extended = timeLeft < timeBuffer;
        if (extended) {
            uint256 extension = timeBuffer - timeLeft;

            auction.endTime = auction.endTime + extension;
            auction.extendedTime = auction.extendedTime + extension;

            //auction.endTime = auction.endTime + timeBuffer;
            //auction.extendedTime = auction.extendedTime + timeBuffer;
        }

        emit AuctionBid(currentTokenId, bidder, bidAmount, block.timestamp, auction.endTime);

        if (extended) {
            emit AuctionExtended(currentTokenId, auction.endTime);
        }
    }
    

    /* END PUBLIC FUNCTIONS */


    /* INTERNAL FUNCTIONS */

    // should we also make a `public onlyOwner` version of withdraw()?
    function _withdraw() internal {
        // send a fraction of the balance to wild first
        (bool successWild, ) = wildWallet.call{
            value: (address(this).balance * wildPrimaryRoyalty / feeNumerator)
        }("");
        require(successWild, "ReserveAuction: Failed to withdraw to wild wallet.");

        // then, send the rest to payee
        (bool successPayee, ) = payee.call{
            value: address(this).balance
        }("");
        require(successPayee, "ReserveAuction: Failed to withdraw to payee.");
    }

    /**
     * Settle an auction, finalizing the bid and paying out to the owner.
     * If there are no bids, the Oasis is burned.
     */
    function _settleAuction() internal {
        require(auction.startTime != 0, "ReserveAuction: Auction hasn't begun");

        require(!auction.settled, "ReserveAuction: Auction has already been settled");

        require(
            block.timestamp >= auction.endTime,
            "ReserveAuction: Auction hasn't completed"
        );

        auction.settled = true;

        nft.transferFrom(
            address(this),
            auction.bidder,
            auction.tokenId
        );

        _withdraw();

        emit AuctionSettled(auction.tokenId, auction.bidder, auction.amount);
    }
    
    /**
     * Transfer ETH and return the success status.
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