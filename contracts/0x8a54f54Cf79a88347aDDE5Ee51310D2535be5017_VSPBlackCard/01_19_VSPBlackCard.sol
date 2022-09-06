// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "hardhat/console.sol";

contract VSPBlackCard is ERC721Enumerable, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    uint8 currentAuctionStartingIndex;
    uint8 public currentAuctionIndex;
    uint16 refundIndex;
    uint16 refundQueueIndex;
    uint8 public currentAuctionWinnerCount;

    uint256 public beginAuctionTime;
    uint256 public timeToBid;
    uint256 public currentAuctionExtensionTime;

    address public VSPNFT;
    address[] public joinedBlackCardAuction;

    address public signer;
    string public baseURI;

    bool public winnersSet;

    mapping(uint256 => mapping(address => uint256)) public amountBidByAuction;

    // Index with currentAuctionIndex to get the current auction reservers
    mapping(uint256 => mapping(address => uint256[])) public addressBidsByAuction;

    mapping(address => uint256) winners;

    constructor() ERC721("VSP Black Card", "VSPBC") {
        currentAuctionIndex = 1;
    }

    function setVSPContract(address _address) external onlyOwner {
        require(_address != address(0), "Address cannot be the zero address");
        VSPNFT = _address;
    }

    function getTotalAuctionMembers() external view returns(uint256) {
        return joinedBlackCardAuction.length;
    }

    function changeTimeToBid(uint256 _time) external onlyOwner {
        require(block.timestamp < (beginAuctionTime + timeToBid), "Auction has ended");
        timeToBid = _time;
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function timeUntilAuctionEnds() external view returns(uint256) {
        require(block.timestamp > beginAuctionTime, "Auction is not active");
        require(block.timestamp < (beginAuctionTime + timeToBid), "Auction has ended");
        return (beginAuctionTime + timeToBid) - block.timestamp;
    }

    function getFinalValue(uint256[] memory nftIds) pure internal returns(uint256) {
        uint256 val;
        for(uint256 i = 0; i < nftIds.length; ) {
            val += nftIds[i];
            unchecked { ++i; }
        }
        return val;
    }

    function enterBid(uint256[] calldata nfts, uint256[] calldata nftValues, bytes calldata signature) external nonReentrant {
        require(block.timestamp > beginAuctionTime, "Auction is not currently active");
        require(block.timestamp < (timeToBid + beginAuctionTime), "Auction has ended");
        require(verifySignature(nfts, nftValues, signature), "Invalid nft values");
        require(ERC721(VSPNFT).isApprovedForAll(msg.sender, address(this)), "Contract not approved to transfer");

        // If this is the users first time bidding add them to the bidders array which is accurate for the current auction
        // and add them to the addressHasReserved mapping which records bidders for all auctions
        if(addressBidsByAuction[currentAuctionIndex][_msgSender()].length < 1) {
            joinedBlackCardAuction.push(_msgSender());
            unchecked { ++refundQueueIndex; }
        }

        for(uint256 i = 0; i < nfts.length; ) {
            // Transfer all bid NFTs to this contract
            ERC721(VSPNFT).transferFrom(_msgSender(), address(this), nfts[i]);
            // Mapping will be used to burn NFTs for winners and send back NFTs for non winners
            addressBidsByAuction[currentAuctionIndex][_msgSender()].push(nfts[i]);
            unchecked { ++i; } 
        }
        
        amountBidByAuction[currentAuctionIndex][_msgSender()] += getFinalValue(nftValues);

        // If current bid is closer to auction end time than the auction extension time then extend the auction to prevent sniping
        if((beginAuctionTime + timeToBid) - block.timestamp < currentAuctionExtensionTime) {
            timeToBid = (block.timestamp + currentAuctionExtensionTime) - beginAuctionTime;
        }
    }


    // Create auction function (set max winners, auction start time, auction length, extension time) and can't be called until `clearAuction` has run
    function createAuction(uint8 maxWinners, uint256 startTime, uint256 bidTime, uint256 bidSnipeTimer) external onlyOwner {
        require(currentAuctionWinnerCount == 0, "Must clear previous auction before creating another auction");
        require(maxWinners > 0, "maxWinners cannot be 0");
        currentAuctionWinnerCount = maxWinners;
        currentAuctionExtensionTime = bidSnipeTimer;
        beginAuctionTime = startTime;
        timeToBid = bidTime;
        currentAuctionStartingIndex = uint8(totalSupply());
    }


    // Sets winners according to the order of the array, lower index = better placement.
    function setWinners(address[] calldata auctionWinners) external onlyOwner {
        require(auctionWinners.length >= currentAuctionWinnerCount, "Not enough winners of auction");
        require(!winnersSet, "Winners have already been set, clear winners before setting them again");
        for(uint256 i = 0; i < currentAuctionWinnerCount; ) {
            winners[auctionWinners[i]] = i + 1;
            unchecked { ++i; }
        }

        winnersSet = true;
    }

    function sendNFTs(uint256 quantityToSend) external onlyOwner {
        require(winnersSet, "Must set winning addresses first");

        uint256 totalSent;

        uint256 auctionEntries = refundQueueIndex;
        // Iterate through the joinedBlackCardAuction array.
        bool setRefundIndex;
        while(auctionEntries > 0 && !setRefundIndex) {
            uint256 amountSentForAddress;
            uint256[] memory bidderIds = addressBidsByAuction[currentAuctionIndex][joinedBlackCardAuction[auctionEntries - 1]];
            uint256 bidderPlacement = winners[joinedBlackCardAuction[auctionEntries - 1]];
            bool isBidderWinner = bidderPlacement > 0;
            address toAddress = isBidderWinner
                ? 0x000000000000000000000000000000000000dEaD 
                : joinedBlackCardAuction[auctionEntries - 1];

            // Iterate through the array containing all the VSP tokenIDs that the address put up for bid, and burn them
            for(uint256 i = refundIndex; i < bidderIds.length; ) {
                // Break out of this loop if we hit our amountToSend limit
                if (totalSent == quantityToSend) { 
                    refundIndex = uint16(i);
                    setRefundIndex = true;
                    break;
                }

                ERC721(VSPNFT).transferFrom(address(this), toAddress, bidderIds[i]);
                unchecked { ++totalSent; ++amountSentForAddress; ++i; }
            }
            // Only mint BlackCard NFT if all reserved VSPs are burned
            if (setRefundIndex == false && (amountSentForAddress + refundIndex) == bidderIds.length) {                    
                if(isBidderWinner) {
                    _safeMint(joinedBlackCardAuction[auctionEntries - 1], currentAuctionStartingIndex + bidderPlacement);
                    winners[joinedBlackCardAuction[auctionEntries - 1]] = 0;
                }
                unchecked { --auctionEntries; }
            }
            if (!setRefundIndex) {
                refundIndex = 0;
            }
        }
        refundQueueIndex = uint16(auctionEntries);
    }

    function clearAuction() public onlyOwner {
        require(beginAuctionTime > 0, "Auction already cleared");
        require(block.timestamp > beginAuctionTime + timeToBid, "Auction has yet to conclude");
        require(refundQueueIndex == 0, "Must refund all NFTs before clearing auction");
        require(winnersSet, "Winners of the auction have not been set");
        _clearAuction();
    }

    function _clearAuction() internal {
        delete beginAuctionTime;
        delete joinedBlackCardAuction;
        delete currentAuctionWinnerCount;
        delete currentAuctionExtensionTime;
        delete winnersSet;
        delete currentAuctionStartingIndex;

        unchecked { ++currentAuctionIndex; }
    }

    function setSigner(address signer_) external onlyOwner {
        require(signer_ != address(0), "Signer cannot be the zero address");
        signer = signer_;
    }
    
    function ownerClaim(uint256 tokenId) external nonReentrant onlyOwner {
        require(!_exists(tokenId), "Token ID already exists");
        _mint(owner(), tokenId);
    }

    function verifySignature(uint256[] calldata nfts, uint256[] calldata nftValues, bytes calldata signature) internal view returns (bool) {
        require(signer != address(0), "Signer not set");
        bytes32 hash = keccak256(abi.encodePacked(nfts, nftValues));
        bytes32 signedHash = hash.toEthSignedMessageHash();

        return SignatureChecker.isValidSignatureNow(signer, signedHash, signature);
    }

    // In case an ERC20 token needs to be sent from contract
    function ERC20Withdraw(address to, address _token, uint256 quantity) external onlyOwner {
        IERC20 targetToken = IERC20(_token);
        targetToken.transferFrom(address(this), to, quantity);
    }

}