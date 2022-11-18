// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract BurnAuction1155 is ReentrancyGuard, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    uint16 public currentAuctionIndex;
    uint16 refundIndex;

    uint256 public beginAuctionTime;
    uint256 public timeToBid;
    uint256 public currentAuctionExtensionTime;

    address public BidNFT;
    address[] public joinedAuction;

    address public signer;
    address[] private batchTransferAddresses;
    uint256[] private batchIds;
    bool private nftsSent;
    bool private auctionCleared;

    struct Bid {
        uint256 tokenId;
        uint256 amount;
    }

    mapping(uint256 => mapping(address => uint256)) public amountBidByAuction;

    // Index with currentAuctionIndex to get the current auction reservers
    mapping(uint256 => mapping(address => Bid[])) public addressBidsByAuction;

    constructor() {
        currentAuctionIndex = 20000;
        batchTransferAddresses = [address(this), address(this), address(this), address(this)];
        batchIds = [0,1,2,3];
        auctionCleared = true;
    }

    function setBidContract(address _address) external onlyOwner {
        require(_address != address(0), "Address cannot be the zero address");
        BidNFT = _address;
    }

    function getTotalAuctionMembers() external view returns(uint256) {
        return joinedAuction.length;
    }

    function changeTimeToBid(uint256 _time) external onlyOwner {
        require(block.timestamp < (beginAuctionTime + timeToBid), "Auction has ended");
        timeToBid = _time;
    }

    function timeUntilAuctionEnds() external view returns(uint256) {
        require(block.timestamp > beginAuctionTime, "Auction is not active");
        require(block.timestamp < (beginAuctionTime + timeToBid), "Auction has ended");
        return (beginAuctionTime + timeToBid) - block.timestamp;
    }

    function getFinalValue(uint256[] memory nftValues) pure internal returns(uint256) {
        uint256 val;
        for(uint256 i = 0; i < nftValues.length; ) {
            val += nftValues[i];
            unchecked { ++i; }
        }
        return val;
    }

    function enterBid(uint256[] calldata nfts, uint256[] calldata nftValues, uint256[] calldata nftAmounts, bytes calldata signature) external nonReentrant {
        require(block.timestamp > beginAuctionTime, "Auction is not currently active");
        require(block.timestamp < (timeToBid + beginAuctionTime), "Auction has ended");
        require(verifySignature(nfts, nftValues, nftAmounts, signature), "Invalid nft values");
        require(IERC1155(BidNFT).isApprovedForAll(msg.sender, address(this)), "Contract not approved to transfer");

        // If this is the users first time bidding add them to the bidders array which is accurate for the current auction
        // and add them to the addressHasReserved mapping which records bidders for all auctions
        if(addressBidsByAuction[currentAuctionIndex][_msgSender()].length < 1) {
            joinedAuction.push(_msgSender());
        }

        // Transfer all bid NFTs to this contract
        IERC1155(BidNFT).safeBatchTransferFrom(_msgSender(), address(this), nfts, nftAmounts, "0x");

        for(uint256 i = 0; i < nfts.length; ) {
            Bid memory bid = Bid(nfts[i], nftAmounts[i]);
            addressBidsByAuction[currentAuctionIndex][_msgSender()].push(bid);
            unchecked { ++i; } 
        }
        
        amountBidByAuction[currentAuctionIndex][_msgSender()] += getFinalValue(nftValues);

        // If current bid is closer to auction end time than the auction extension time then extend the auction to prevent sniping
        if((beginAuctionTime + timeToBid) - block.timestamp < currentAuctionExtensionTime) {
            timeToBid = (block.timestamp + currentAuctionExtensionTime) - beginAuctionTime;
        }
    }

    
    // Create auction function (set auction start time, auction length, extension time) and can't be called until `clearAuction` has run
    function createAuction(uint256 startTime, uint256 bidTime, uint256 bidSnipeTimer) external onlyOwner {
        require(BidNFT != address(0), "Bid NFT needs to be set");
        require(auctionCleared == true, "Previous auction needs to be cleared");

        currentAuctionExtensionTime = bidSnipeTimer;
        beginAuctionTime = startTime;
        timeToBid = bidTime;
        nftsSent = false;
        auctionCleared = false;
    }

    function sendNFTs() external onlyOwner {
        address toDeadAddress = 0x000000000000000000000000000000000000dEaD;        
        uint256[] memory balances = IERC1155(BidNFT).balanceOfBatch(batchTransferAddresses, batchIds);
        IERC1155(BidNFT).safeBatchTransferFrom(address(this), toDeadAddress, batchIds, balances, "0x");
        nftsSent = true;
    }

    function clearAuction() public onlyOwner {
        require(beginAuctionTime > 0, "Auction already cleared");
        require(block.timestamp > beginAuctionTime + timeToBid, "Auction has yet to conclude");
        require(nftsSent == true, "Must send all NFTs before clearing auction");
        _clearAuction();
    }

    function _clearAuction() internal {
        delete beginAuctionTime;
        delete joinedAuction;
        delete currentAuctionExtensionTime;
        auctionCleared = true;

        unchecked { ++currentAuctionIndex; }
    }

    function setSigner(address signer_) external onlyOwner {
        require(signer_ != address(0), "Signer cannot be the zero address");
        signer = signer_;
    }

    function verifySignature(uint256[] calldata nfts, uint256[] calldata nftValues, uint256[] calldata nftAmounts, bytes calldata signature) internal view returns (bool) {
        require(signer != address(0), "Signer not set");
        bytes32 hash = keccak256(abi.encodePacked(nfts, nftValues, nftAmounts));
        bytes32 signedHash = hash.toEthSignedMessageHash();

        return SignatureChecker.isValidSignatureNow(signer, signedHash, signature);
    }

    // In case an ERC20 token needs to be sent from contract
    function ERC20Withdraw(address to, address _token, uint256 quantity) external onlyOwner {
        IERC20 targetToken = IERC20(_token);
        targetToken.transferFrom(address(this), to, quantity);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}