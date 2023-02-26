//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TicketAuction is Ownable, IERC721Receiver, IERC1155Receiver, ReentrancyGuard {

    enum Phase {
        INIT,
        NFT_RECEIVED,
        AUCTION,
        CLAIM,
        DONE
    }
    Phase public currentPhase = Phase.INIT;

    struct BidValue {
        uint256 ethAmountInWei;
        uint256 ticketAmount;
    }

    struct Bid {
        address bidder;
        BidValue value;
    }

    Bid public currentWinningBid;
    uint256 public amountBids;

    event BidEvent(address bidder, uint256 ethAmountInWei, uint256 ticketAmount, uint256 usdValue, uint256 timestamp);
    event AuctionExtended(uint oldEndTime, uint newEndTime);

    IERC1155 public ticketContract;
    uint256 public ticketTokenId;

    IERC721 public nftContract;
    uint256 public nftTokenId;

    AggregatorV3Interface public ethUSDPriceFeed;
    uint256 public ticketUSDValue;

    address auctionBeneficiary;

    uint public endTime;
    uint public extensionTime;
    
    /**
        @dev    ticketUSDValue should be in USD * 10^18 (wei conversion),      
                e.g. 22 USD = 22000000000000000000
    */
    constructor(address ethUSDFeedAddress, uint256 _ticketUSDValue, 
                address _ticketContract, uint256 _ticketTokenId, 
                address _nftContract, uint256 _nftTokenId,
                address _auctionBeneficiary
    ) {
        ethUSDPriceFeed = AggregatorV3Interface(ethUSDFeedAddress);
        ticketUSDValue = _ticketUSDValue;

        IERC165 check1155 = IERC165(_ticketContract);
        require(check1155.supportsInterface(type(IERC1155).interfaceId), "Ticket Contract address must be ERC1155");
        ticketContract = IERC1155(_ticketContract);
        ticketTokenId = _ticketTokenId;

        IERC165 check721 = IERC165(_nftContract);
        require(check721.supportsInterface(type(IERC721).interfaceId), "NFT Contract address must be ERC721");
        nftContract = IERC721(_nftContract);
        nftTokenId = _nftTokenId;

        currentWinningBid = Bid(0x0000000000000000000000000000000000000000, BidValue(0, 0));
        auctionBeneficiary = _auctionBeneficiary;
    }

    // Auction functions

    function bid(uint256 ticketAmount) external payable nonReentrant {
        require(msg.sender == tx.origin, "No contract bidding");
        require(currentPhase == Phase.AUCTION, "Must be in auction phase");
        require(block.timestamp < endTime, "Must be before auction has ended!");
        require(msg.value > 0 || ticketAmount > 0, "Bid must be nonzero!");

        uint256 newBidUSD = ethAndTicketsToUSD(msg.value, ticketAmount);
        require(newBidUSD > bidValueToUSD(currentWinningBid.value), "Must be a greater bid than the current bid!");
        if (ticketAmount > 0) {
            ticketContract.safeTransferFrom(msg.sender, address(this), ticketTokenId, ticketAmount, "0x0");
        }

        if (currentWinningBid.value.ticketAmount > 0) {
            ticketContract.safeTransferFrom(address(this), currentWinningBid.bidder, ticketTokenId, currentWinningBid.value.ticketAmount, "0x0");
        }
        if (currentWinningBid.value.ethAmountInWei > 0) {
            payable(currentWinningBid.bidder).transfer(currentWinningBid.value.ethAmountInWei);
        }

        currentWinningBid = Bid(msg.sender, BidValue(msg.value, ticketAmount));

        if (endTime - block.timestamp < extensionTime) {
            uint newEndTime = block.timestamp + extensionTime;
            emit AuctionExtended(endTime, newEndTime);
            endTime = newEndTime;
        }

        // Sanity checks
        require(ticketContract.balanceOf(address(this), ticketTokenId) == ticketAmount, "Ticket transfer failed");
        require(address(this).balance == msg.value, "ETH transfer failed");

        emit BidEvent(msg.sender, msg.value, ticketAmount, newBidUSD, block.timestamp);
        amountBids++;
    }

    function topupBid(uint256 ticketAmount) external payable nonReentrant {
        require(msg.sender == tx.origin, "No contract bidding");
        require(currentPhase == Phase.AUCTION, "Must be in auction phase");
        require(block.timestamp < endTime, "Must be before auction has ended!");
        require(currentWinningBid.bidder == msg.sender, "Must be current winning bidder to topup bid");
        require(msg.value > 0 || ticketAmount > 0, "Bid must be nonzero!");
        
        uint256 newEthAmount = msg.value + currentWinningBid.value.ethAmountInWei;
        uint256 newTicketAmount = ticketAmount + currentWinningBid.value.ticketAmount;
        uint256 newBidUSD = ethAndTicketsToUSD(newEthAmount, newTicketAmount);
        if (ticketAmount > 0) {
            ticketContract.safeTransferFrom(msg.sender, address(this), ticketTokenId, ticketAmount, "0x0");
        }

        currentWinningBid.value = BidValue(newEthAmount, newTicketAmount);

        if (endTime - block.timestamp < extensionTime) {
            uint newEndTime = block.timestamp + extensionTime;
            emit AuctionExtended(endTime, newEndTime);
            endTime = newEndTime;
        }

        // Sanity checks
        require(ticketContract.balanceOf(address(this), ticketTokenId) == newTicketAmount, "Ticket transfer failed");
        require(address(this).balance == newEthAmount, "ETH transfer failed");

        emit BidEvent(msg.sender, newEthAmount, newTicketAmount, newBidUSD, block.timestamp);
        amountBids++;
    }

    function claim() external {
        if (currentPhase == Phase.AUCTION && block.timestamp >= endTime) {
            currentPhase = Phase.CLAIM;
        }
        require(currentPhase == Phase.CLAIM, "Must be claim phase!");
        require(msg.sender == currentWinningBid.bidder, "Must be the winner of the auction!");
        nftContract.safeTransferFrom(address(this), msg.sender, nftTokenId);
        currentPhase = Phase.DONE;
    }

    // Owner Functions

    function commitNFT(address nftOwner) external onlyOwner {
        require(currentPhase == Phase.INIT);
        nftContract.safeTransferFrom(nftOwner, address(this), nftTokenId);
    }

    function startAuction(uint _endTime, uint _extensionTime) external onlyOwner {
        require(currentPhase == Phase.NFT_RECEIVED, "Must have sent the NFT to the contract!");
        require(block.timestamp < _endTime, "End time must be in future");
        endTime = _endTime;
        extensionTime = _extensionTime;
        currentPhase = Phase.AUCTION;
    }

    function withdrawValue() public onlyOwner {
        if (currentPhase == Phase.AUCTION && block.timestamp >= endTime) {
            currentPhase = Phase.CLAIM;
        }
        require(currentPhase == Phase.CLAIM || currentPhase == Phase.DONE, "Must withdraw in correct phase");
        ticketContract.safeTransferFrom(address(this), auctionBeneficiary, ticketTokenId, ticketContract.balanceOf(address(this), ticketTokenId), "0x0");
        payable(auctionBeneficiary).transfer(address(this).balance);
    }

    function ownerFinishClaim() external onlyOwner {
        if (currentPhase == Phase.AUCTION && block.timestamp >= endTime) {
            currentPhase = Phase.CLAIM;
        }
        require(currentPhase == Phase.CLAIM, "Must be claim phase!");
        if (currentWinningBid.bidder == address(0)) {
            nftContract.safeTransferFrom(address(this), auctionBeneficiary, nftTokenId);
        } else {
            nftContract.safeTransferFrom(address(this), currentWinningBid.bidder, nftTokenId);
        }
        currentPhase = Phase.DONE;
        withdrawValue();
    }

    function setExtensionTime(uint _extensionTime) external onlyOwner {
        extensionTime = _extensionTime;
    }

    // OnReceived

    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 tokenId,
        bytes calldata /* data */
    ) external returns (bytes4) {
        require(msg.sender == address(nftContract), "ERC721 Received must be from correct contract!");
        require(tokenId == nftTokenId, "ERC721 Received must be correct token ID!");
        require(currentPhase == Phase.INIT, "Phase must be INIT.");
        currentPhase = Phase.NFT_RECEIVED;
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address /* from */,
        uint256 /* id */,
        uint256 /* value */,
        bytes calldata /* data */
    ) external view returns (bytes4) {
        require(msg.sender == address(ticketContract), "ERC1155 Received must be from correct contract!");
        require(operator == address(this), "Must be operated by this contract!");
        require(currentPhase == Phase.AUCTION, "Must be in the auction phase!");
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address /* operator */,
        address /* from */,
        uint256[] calldata /* ids */,
        uint256[] calldata /* values */,
        bytes calldata /* data */
    ) external pure returns (bytes4) {
        revert("No batch receiving");
    }

    // Views

    function getInfo(address user) public view 
    returns (
        Phase phase, Bid memory winningBid,
        uint256 tickets, bool hasApproved,
        uint256 auctionEndTime, bool hasAuctionEnded, 
        uint256 topBidValue, uint256 ethUSDPrice,
        uint256 ticketUSDPrice, uint256 userBalance,
        uint256 blockHeight
    ) {
        phase = currentPhase;
        winningBid = currentWinningBid;
        if (user != address(0)) {
            tickets = ticketContract.balanceOf(user, ticketTokenId);
            hasApproved = ticketContract.isApprovedForAll(user, address(this));
            userBalance = payable(user).balance;
        } else {
            tickets = 0;
            hasApproved = false;
            userBalance = 0;
        }
        auctionEndTime = endTime;
        hasAuctionEnded = block.timestamp >= endTime;
        topBidValue = bidValueToUSD(currentWinningBid.value);
        ethUSDPrice = getETHUSDPrice();
        ticketUSDPrice = ticketUSDValue;
        blockHeight = block.number;
    }

    /**
        @dev    returns in wei format (usd * 10^18)
    */
    function getETHUSDPrice() public view returns (uint256) {
        (, int256 answer, , ,) = ethUSDPriceFeed.latestRoundData();
        require(answer > 0, "ETH/USD Price invalid");
        return uint256(answer) * 10**10;
    }

    /**
        @dev    returns in wei format (usd * 10^18)
    */
    function ethToUSD(uint256 amountInWei) public view returns (uint256) {
        return (amountInWei * getETHUSDPrice()) / 10**18;
    }

    function ethAndTicketsToUSD(uint256 ethAmountInWei, uint256 ticketAmount) public view returns (uint256) {
        return ethToUSD(ethAmountInWei) + (ticketAmount * ticketUSDValue);
    }

    /**
        @dev    returns in wei format (usd * 10^18)
    */
    function bidValueToUSD(BidValue memory bidValue) public view returns (uint256) {
        return ethToUSD(bidValue.ethAmountInWei) + (bidValue.ticketAmount * ticketUSDValue);
    }

    function getTopBid() public view returns (Bid memory topBid, uint256 value) {
        topBid = currentWinningBid;
        value = bidValueToUSD(currentWinningBid.value);
    }

    // Setters

    function setTicketUSDValue(uint256 _ticketUSDValue) external onlyOwner {
        ticketUSDValue = _ticketUSDValue;
    }

    // IERC165

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC721Receiver).interfaceId;
    }

}