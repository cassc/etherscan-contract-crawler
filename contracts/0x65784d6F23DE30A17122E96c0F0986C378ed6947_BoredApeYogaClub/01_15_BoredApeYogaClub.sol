pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

interface IWETH {
    function deposit() external payable;
}

contract BoredApeYogaClub is Pausable, ERC721, ReentrancyGuard, Ownable {
    using Strings for *;
    
    struct Auction {
        uint apeId;
        uint highestBidAmount;
        uint256 startTime;
        uint256 endTime;
        address highestBidder;
    }
    
    struct AuctionConfig {
        uint timeBuffer;
        uint reservePrice;
        uint minBidAmountIfCurrentBidZero;
        uint minBidIncrementPercentage;
        uint auctionDuration;
    }
    
    mapping(uint => uint) public reservePriceOverrides;
    
    struct ContractConfig {
        address wethContract;
        string externalURL;
        string imageURI;
        string baseTokenURI;
        string description;
        uint96 sellerFeeBasisPoints;
        address mikeAddress;
        address withdrawAddress;
    }
    
    Auction[10_000] public auctions;
    AuctionConfig public auctionConfig;
    ContractConfig public contractConfig;
    
    uint public ethAvailableToWithdraw;

    event AuctionStarted(uint indexed apeId, uint startTime, uint endTime);
    event AuctionBid(uint indexed apeId, address bidder, uint bidValue, bool auctionExtended);
    event AuctionExtended(uint indexed apeId, uint endTime);
    event AuctionSettled(uint indexed apeId, address winner, uint amount);
    
    event AuctionBatchBid(uint[] indexed apeIds, address bidder, bool anySuccesses, uint[] bidValues, bool[] successfulBids, uint refundAmount);
    
    event AuctionConfigUpdated(AuctionConfig newConfig);
    event ContractConfigUpdated(ContractConfig newConfig);
    
    event ReservePriceOverridesUpdated(uint[] apeIds, uint[] newReservePrices);
    
    event PreMint(uint[] apeIds);
    
    event Withdraw(uint indexed total);

    constructor(
        AuctionConfig memory _auctionConfig,
        ContractConfig memory _contractConfig
    ) ERC721("Bored Ape Yoga Club", "BAYC") {
        auctionConfig = _auctionConfig;
        contractConfig = _contractConfig;
        
        _pause();
    }
    
    function preMintIds(uint[] calldata idsToPremint) external onlyOwner {
        for (uint i; i < idsToPremint.length; ++i) {
            Auction memory auction = auctions[idsToPremint[i]];
            
            require(auction.startTime == 0, "Can't premint after auction has started");
            
            _mint(contractConfig.mikeAddress, idsToPremint[i]);
        }
        
        emit PreMint(idsToPremint);
    }
    
    function exists(uint _apeId) public view returns (bool) {
        return _exists(_apeId);
    }
    
    function bidOnMultipleApes(uint[] calldata apeIds) external payable whenNotPaused nonReentrant {
        uint availableEth = msg.value;
        bool anySuccesses;
        
        uint[] memory bidValues = new uint[](apeIds.length);
        bool[] memory successfulBids = new bool[](apeIds.length);
        uint refundAmount;
        
        for (uint i; i < apeIds.length; i++) {
            (bool success, uint amountSpent) = bidOnApe(apeIds[i], availableEth, 0);
            
            if (success) {
                bidValues[i] = amountSpent;
                successfulBids[i] = true;
                
                availableEth -= amountSpent;
                anySuccesses = true; 
            }
        }
        
        require(anySuccesses, "No apes were successfully bid on");
        
        if (availableEth > 0) {
            refundAmount = availableEth;
            _safeTransferETHWithFallback(msg.sender, refundAmount);
        }
        
        emit AuctionBatchBid(apeIds, msg.sender, anySuccesses, bidValues, successfulBids, refundAmount);
    }
    
    function setReservePriceOverrides(uint[] calldata apeIds, uint[] calldata reserves) external onlyOwner {
        require(apeIds.length == reserves.length, "apeIds and reserves must be the same length");
        
        for (uint i; i < apeIds.length; ++i) {
            reservePriceOverrides[apeIds[i]] = reserves[i];
        }
        
        emit ReservePriceOverridesUpdated(apeIds, reserves);
    }
    
    function reservePrice(uint apeId) public view returns (uint) {
        return reservePriceOverrides[apeId] > 0 ?
               reservePriceOverrides[apeId] :
               auctionConfig.reservePrice;
    }
    
    function bidOnSingleApe(uint apeId) external payable whenNotPaused nonReentrant {
        (bool success,) = bidOnApe(apeId, msg.value, msg.value);
        
        require(success, "Bid failed");
    }
    
    function bidOnApe(uint apeId, uint availableEth, uint forceBidAmount) internal returns (bool success, uint amountSpent) {
        Auction storage auction = auctions[apeId];
        
        bool auctionStarted = auction.startTime > 0;
        
        uint minBidAmountIfCurrentBidPositive = auction.highestBidAmount + ((auction.highestBidAmount * auctionConfig.minBidIncrementPercentage) / 100);
        uint amountToBid;
        
        if (auctionStarted) {
            amountToBid = auction.highestBidAmount == 0 ?
                          auctionConfig.minBidAmountIfCurrentBidZero :
                          minBidAmountIfCurrentBidPositive;
        } else {
            amountToBid = reservePrice(apeId);
        }
        
        if (forceBidAmount > amountToBid) {
            amountToBid = forceBidAmount;
        }
        
        bool canBidOnApe = !_exists(apeId) &&
            (auction.endTime == 0 || block.timestamp < auction.endTime) &&
            (availableEth >= amountToBid);
        
        if (!canBidOnApe) {
            return (false, 0);
        }
        
        if (auction.startTime == 0) {
            auction.startTime = block.timestamp;
            auction.endTime = block.timestamp + auctionConfig.auctionDuration;
            emit AuctionStarted(apeId, auction.startTime, auction.endTime);
        }
        
        if (auction.highestBidder != address(0)) {
            _safeTransferETHWithFallback(auction.highestBidder, auction.highestBidAmount);
        }
        
        auction.highestBidAmount = amountToBid;
        auction.highestBidder = msg.sender;
        
        bool extendAuction = auction.endTime - block.timestamp < auctionConfig.timeBuffer;
        if (extendAuction) {
            auction.endTime = block.timestamp + auctionConfig.timeBuffer;
            emit AuctionExtended(apeId, auction.endTime);
        }

        emit AuctionBid(apeId, auction.highestBidder, auction.highestBidAmount, extendAuction);
        
        return (true, auction.highestBidAmount);
    }
    
    function settleAuction(uint apeId) external nonReentrant whenNotPaused {
        Auction memory auction = auctions[apeId];
        
        require(!_exists(apeId), "Auction already settled");
        require(auction.startTime != 0, "Auction hasn't begun");
        require(block.timestamp >= auction.endTime, "Auction hasn't completed");
        
        _mint(auction.highestBidder, apeId);
        
        ethAvailableToWithdraw += auction.highestBidAmount;
        
        emit AuctionSettled(apeId, auction.highestBidder, auction.highestBidAmount);
    }
    
    function tokenURI(uint tokenId) public view override returns (string memory) {
        return string.concat(contractConfig.baseTokenURI, tokenId.toString(), ".json");
    }
    
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setAuctionConfig(AuctionConfig memory _auctionConfig) external onlyOwner {
        auctionConfig = _auctionConfig;
        emit AuctionConfigUpdated(auctionConfig);
    }
    
    function setContractConfig(ContractConfig memory _contractConfig) external onlyOwner {
        contractConfig = _contractConfig;
        emit ContractConfigUpdated(contractConfig);
    }

    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(contractConfig.wethContract).deposit{ value: amount }();
            IERC20(contractConfig.wethContract).transfer(to, amount);
        }
    }

    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = payable(to).call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }
    
    function withdraw() external {
        require(msg.sender == tx.origin, "No contracts");
        
        uint balance = ethAvailableToWithdraw;
        
        require(balance > 0, "Nothing to withdraw");
        
        emit Withdraw(balance);
        
        ethAvailableToWithdraw = 0;
        
        _safeTransferETHWithFallback(contractConfig.withdrawAddress, balance);
    }
    
    fallback (bytes calldata _inputText) external payable returns (bytes memory _output) {}
    receive () external payable {}
    
    // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
    //     return super.supportsInterface(interfaceId);
    // }
}