pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IStaking {
    function depositsOf(address account) external view returns (uint256[] memory);
}

contract AuctionMint is ERC721URIStorage, Ownable, Pausable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    event Mint(address indexed sender, uint256 startWith, uint256 times);
    event AuctionStarted(uint256 auctionID);
    event AuctionEnded(uint256 auctionID);
    event BidPlaced(uint256 indexed auctionID, address indexed bidder, uint256 bidIndex, uint256 unitPrice, uint256 quantity);
    event BidRefunded(address indexed bidder, uint256 refundAmount, uint256 tokensRefunded);
    event WinnerChosen(uint256 indexed auctionID, address indexed bidder, uint256 unitPrice, uint256 quantity);
    struct Bid {
        uint256 quantityToMint;
        uint256 costPerMint;
    }
    struct Status {
        bool started;
        bool ended;
    }
    Counters.Counter private auctionCounter;
    Counters.Counter private bidCounter;

    address public contractAddress;
    IERC20 public erc20Token;
    IStaking public stakingContract;
    uint256 public requiredERC20HoldingAmt;
    uint256 public constant MAX_SUPPLY = 9000;
    uint256 public immutable AUCTION_MINT_QTY;
    uint256 public constant MAX_BID_QUANTITY = 10;
    uint256 public constant NUM_AUCTIONS = 3;
    uint256 public constant MIN_UNIT_PRICE = 0.05 ether;

    uint256 public currentSupply;
    string public baseURI;
    bool public allowRefunds;

    bool private hasAuctionStarted;
    bool private hasAuctionFinished;
    mapping(address => uint256) private auctionWhitelist;
    mapping (uint256 => Status) private auctionStatus;
    mapping(address => Bid) private bids;
    mapping (uint256 => uint256) private auctionRemaingItems;
    mapping(address => uint256) private spentERC20Tokens;

    constructor(uint256 auctionMintQty) ERC721("AuctionMintContract", "AMC") {
        contractAddress = address(this);
        AUCTION_MINT_QTY = auctionMintQty;
        for(uint256 i = 0; i < NUM_AUCTIONS; i++) {
            auctionRemaingItems[i] = auctionMintQty;
        }
        pause(); // start paused to ensure nothing happens
    }
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }
    function setContracts(address erc20Address, address stakingAddress) public onlyOwner {
        erc20Token = IERC20(erc20Address);
        stakingContract = IStaking(stakingAddress);
    }
    function setERC20HoldingAmount(uint256 erc20HoldingAmt) public onlyOwner {
        requiredERC20HoldingAmt = erc20HoldingAmt;
    }
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist.");
        
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : ".json";
    }
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }
    modifier requireContractsSet() {
        require(address(erc20Token) != address(0) && address(stakingContract) != address(0), "Contracts not set");
        _;
    }
    modifier whenAuctionEnded() {
        require(currentAuctionStatus().started && currentAuctionStatus().ended, "Auction has not been completed");
        _;
    }
    modifier whenAuctionActive() {
        require(currentAuctionStatus().started && !currentAuctionStatus().ended, "Auction is not active.");
        _;
    }
    modifier whenRefundsAllowed() {
        require(allowRefunds, "Refunds currently not allowed.");
        _;
    }
    function currentAuctionStatus() public view returns (Status memory) {
        return auctionStatus[auctionCounter.current()];
    }
    function getCurrentAuction() external view returns (uint) {
        return auctionCounter.current();
    }
    function incrementAuction() external onlyOwner whenPaused {
        auctionCounter.increment();
        require(auctionCounter.current() < NUM_AUCTIONS, "Max number of auctions reached.");
    }
    function decrementAuction() external onlyOwner whenPaused {
        auctionCounter.decrement();
    }
    function startCurrentAuction() external onlyOwner whenPaused requireContractsSet {
        uint256 currentAuctionID = auctionCounter.current();
        require(!currentAuctionStatus().started && !currentAuctionStatus().ended, "Auction cannot be started again");
        auctionStatus[currentAuctionID].started = true;
        unpause();
        emit AuctionStarted(currentAuctionID);
    }
    function endCurrentAuction() external onlyOwner whenAuctionActive {
        uint256 currentAuctionID = auctionCounter.current();
        auctionStatus[currentAuctionID].ended = true;
        if (!paused()) {
            pause();
        }
        emit AuctionEnded(currentAuctionID);
    }
    function getBid(address bidAddress) external view returns (Bid memory) {
        return bids[bidAddress];
    }
    function getCostPerMintValue(address bidder) external view returns(uint256) {
        return bids[bidder].costPerMint;
    }
    function getRemainingItemsForAuction(uint256 auctionID) external view returns (uint256) {
        require(auctionID < NUM_AUCTIONS, "Invalid auction");
        return auctionRemaingItems[auctionID];
    }
    function setAllowRefunds(bool allowed) external onlyOwner {
        allowRefunds = allowed;
    }
    function bid(uint256 _times) public payable whenNotPaused whenAuctionActive {
        if(requiredERC20HoldingAmt > 0 && spentERC20Tokens[_msgSender()] == 0) {
            require(erc20Token.balanceOf(_msgSender()) >= requiredERC20HoldingAmt, "Not enough ERC20 tokens");
            uint256[] memory deposits = stakingContract.depositsOf(_msgSender());
            require(deposits.length > 0, "Staked ERC721 tokens required");
            erc20Token.transferFrom(_msgSender(), address(this), requiredERC20HoldingAmt);
            spentERC20Tokens[_msgSender()] += requiredERC20HoldingAmt;
        }
        uint256 quantity = bids[_msgSender()].quantityToMint;
        uint256 costPer = bids[_msgSender()].costPerMint;
        // Allow users with previous mint bids to pump up their total bid up
        require(quantity > 0 || _times > 0, "Invalid number of mints");
        require(quantity + _times <= MAX_BID_QUANTITY, "Quantity too high for auction");
        uint256 totalCost = msg.value + (costPer * quantity);
        quantity += _times;
        costPer = totalCost / quantity;
        require(costPer >= MIN_UNIT_PRICE, "Price per mint too low");
        bids[_msgSender()].quantityToMint = quantity;
        bids[_msgSender()].costPerMint = costPer;
        emit BidPlaced(auctionCounter.current(), _msgSender(), bidCounter.current(), costPer, quantity);
        bidCounter.increment();
    }
    // The input must be sorted off chain by collecting the BidPlaced events.
    function pickWinners(address[] calldata bidders) external onlyOwner whenPaused whenAuctionEnded {
        uint256 auctionID = auctionCounter.current();
        for(uint256 i = 0; i < bidders.length; i++) {
            address bidderCur = bidders[i];
            uint256 bidUnitPrice = bids[bidderCur].costPerMint;
            uint256 bidQuantity = bids[bidderCur].quantityToMint;

            if (bidUnitPrice == 0 || bidQuantity == 0) {
                continue;
            }

            // If this bid uses the last of the available mints, end the loop and choose this last winner
            if (auctionRemaingItems[auctionID] == bidQuantity) {
                auctionWhitelist[bidderCur] += bids[bidderCur].quantityToMint;
                bids[bidderCur] = Bid(0, 0);
                emit WinnerChosen(auctionID, bidderCur, bidUnitPrice, bidQuantity);
                auctionRemaingItems[auctionID] = 0;
                break;
            }
            // If there isn't enough available mints to satisfy the entire bid, give the remaining mints to the winner
            else if(auctionRemaingItems[auctionID] < bidQuantity) {
                auctionWhitelist[bidderCur] += auctionRemaingItems[auctionID];
                emit WinnerChosen(auctionID, bidderCur, bidUnitPrice, auctionRemaingItems[auctionID]);
                bids[bidderCur].quantityToMint -= auctionRemaingItems[auctionID];
                auctionRemaingItems[auctionID] = 0;
                break;
            }
            // The bid doesn't end the auction selection, so choose the bid and move on
            else {
                auctionWhitelist[bidderCur] += bids[bidderCur].quantityToMint;
                bids[bidderCur] = Bid(0, 0);
                emit WinnerChosen(auctionID, bidderCur, bidUnitPrice, bidQuantity);
                auctionRemaingItems[auctionID] -= bidQuantity;
            }
        }
    }
    // Refunds losing bidders from the contract's balance.
    function refundBidders(address payable[] calldata bidders) external onlyOwner whenPaused whenAuctionEnded {
        uint256 totalRefundAmount = 0;
        for(uint256 i = 0; i < bidders.length; i++) {
            address payable bidder = bidders[i];
            uint256 refundAmt = bids[bidder].costPerMint * bids[bidder].quantityToMint;
            if(refundAmt == 0) {
                continue;
            }
            bids[bidder] = Bid(0,0);
            uint256 tokens = spentERC20Tokens[bidder];
            if(tokens > 0) {
                spentERC20Tokens[bidder] = 0;
                erc20Token.transfer(bidder, tokens);
            }
            bidder.transfer(refundAmt);
            totalRefundAmount += refundAmt;
            emit BidRefunded(bidder, refundAmt, tokens);
        }
    }
    // Allow people to claim their own rewards if desired, only when auction has ended and withdrawls are allowed
    function claimRefund() external whenRefundsAllowed whenAuctionEnded {
        require(auctionCounter.current() == NUM_AUCTIONS - 1, "The final auction has not ended");
        uint256 refundAmt = bids[_msgSender()].costPerMint * bids[_msgSender()].quantityToMint;
        require(refundAmt > 0, "Refund amount is 0.");
        bids[_msgSender()] = Bid(0,0);
        uint256 tokens = spentERC20Tokens[_msgSender()];
        if(tokens > 0) {
            spentERC20Tokens[_msgSender()] = 0;
            erc20Token.transfer(_msgSender(), tokens);
        }
        payable(_msgSender()).transfer(refundAmt);
        emit BidRefunded(_msgSender(), refundAmt, tokens);
    }
    function claimAuctionMints() public whenAuctionEnded {
        require(auctionCounter.current() == NUM_AUCTIONS - 1, "The final auction has not ended");
        require(auctionWhitelist[_msgSender()] > 0, "Address didn't win auction");
        uint256 startingSupply = currentSupply;
        for(uint256 i = 0; i < auctionWhitelist[_msgSender()]; i++){
            if(currentSupply >= MAX_SUPPLY) {
                // if the collection mints out before the user is done with what they bid,
                // move to the losing bids to allow the rest to be refunded
                break;
            }
            _mint(_msgSender(), ++currentSupply);
        }
        if(currentSupply - startingSupply < auctionWhitelist[_msgSender()]) {
            auctionWhitelist[_msgSender()] -= (currentSupply - startingSupply);
        }
        else {
            auctionWhitelist[_msgSender()] = 0;
        }
        emit Mint(_msgSender(), startingSupply + 1, currentSupply - startingSupply);
    }
    function withdraw() external onlyOwner whenAuctionEnded {
        require(auctionCounter.current() == NUM_AUCTIONS - 1, "The final auction has not ended");
        payable(_msgSender()).transfer(address(this).balance);
    }
    
}