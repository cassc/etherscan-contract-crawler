// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "../ethregistrar/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../ethregistrar/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";




contract ERC721Holder is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

interface IPartner {

   function safeMint(address, uint256) external returns(uint256);
   function updateBaseURI(string memory) external;
   function getDnsOfNFT(uint256) external view returns(uint256);
   function ownerOf(uint256) external view returns(address);
}



contract TomiDNSMarketplace is ERC721Holder, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    /// @notice Token used for payments
    IERC20 public tomiToken;

    /// @notice NFT used for auctions
    IERC721 public tomiDNS;

    /// @notice Name Wrapper
    address public contractor;

    /// @notice Minter NFT
    IPartner public partnerNFT;

    /// @notice DaoTreasury
    address public treasury;

    /// @notice tomi team
    address public tomiWallet;

    /// @notice Minimum delta between current and previous bid
    uint8 public minBidIncrementPercentage;

    /// @notice Duration of bidding for an auction
    uint256 public auctionDuration;

    uint256 public auctionBufferTime;
    uint256 public auctionBumpTime;

    /// @notice Distribution percentage of minter, bidders and affiliates
    uint8[3] public distributionPercentages;

    uint256 public expiryTime;

    mapping (bytes32 => bool) private _isHashClaimed;

    address public signerWallet;

    // structs

    struct Bidding {
        address bidder;
        uint256 amount;
    }

    struct Auction {
        uint256 tokenId;
        address minter;
        uint256 mintAmount;
        uint256 startTime;
        uint256 expiryTime;
        bool isClaimed;
        bool biddingStarted;
        uint256 CashBackAmount;
        uint256 partnerAmount;
        uint256 partnerClaimedAmount;
        uint256 affiliateAmount;
        uint256 affiliateClaimedAmount;
        uint256 DaoAndTomiAmount;
        uint256 partnerId;
    }






    // mappings

    /// @notice Gives the active/highest bid for an NFT
    mapping (uint256 => Bidding) public getBiddings;

    /// @notice Gives the auction details for an NFT
    mapping (uint256 => Auction) public getAuctions;

    // events

    event UpdatedContractor(address indexed oldContractor, address indexed newContractor);

    event UpdatedReservePrice(uint256 oldReservePrice, uint256 newReservePrice);

    event UpdatedMinBidIncrementPercentage(uint256 oldMinBidIncrementPercentage, uint256 newMinBidIncrementPercentage);

    event UpdatedAuctionBufferTime(uint256 oldAuctionBufferTime, uint256 newAuctionBufferTime);

    event UpdatedAuctionBumpTime(uint256 oldAuctionBumpTime, uint256 newAuctionBumpTime);

    event UpdatedReclaimDiscount(uint256 oldReclaimDiscount, uint256 newReclaimDiscount);

    event PartnerClaimed(uint256 partnerId , uint256 _tokenId, uint256 amount , address claimedBy);

    event CashbackClaimed(uint256 _tokenId, uint256 amount , address claimedBy);

    event AffiliateClaimed(uint256 _tokenId, uint256 amount, address claimedBy);



    event AuctionCreated(
        uint256 tokenId,
        address indexed minter,
        uint256 mintAmount,
        uint256 startTime,
        uint256 expiryTime,
        string label,
        bytes32 indexed labelhash,
        string tld,
        uint256 partnerId 
    );

    event AuctionExtended(
        uint256 tokenId,
        uint256 expiryTime
    );

    event BidCreated(
        uint256 tokenId,
        address indexed bidder,
        uint256 amount,
        uint256 difference
    );

    event Claimed(
        uint256 tokenId,
        address indexed minter,
        address indexed claimer,
        uint256 amount
    );

    event Reclaimed(
        uint256 tokenId,
        address indexed minter,
        uint256 amount
    );

    constructor( IERC20 _tomi , IERC721 _dns , address _contracter, IPartner _partner, address _signerWallet ) {
        treasury = 0x834335177a99F952da03b15ba6FA3859B175f1e1;
        tomiWallet = 0x379D1e20c4FCe5E0b7914277dB448a8439b5245b;
        minBidIncrementPercentage = 15;

        // TODO change
        auctionDuration = 1715773475;

        // TODO change
        auctionBumpTime = 10 minutes;
        auctionBufferTime = 10 minutes;

        distributionPercentages = [25, 20 , 30];

        tomiToken = _tomi;
        tomiDNS = _dns;
        contractor = _contracter;
        partnerNFT = _partner;

        signerWallet = _signerWallet;
    }

    function updateContractor(address _contractor) external onlyOwner {
        require(_contractor != contractor, "TomiDNSMarketplace: Contractor is already this address");
        emit UpdatedContractor(contractor, _contractor);
        contractor = _contractor;
    }

    function updateNFT(address _NFT) external onlyOwner {
        require(_NFT != contractor, "TomiDNSMarketplace: NFT is already this address");
        emit UpdatedContractor(contractor, _NFT);
        tomiDNS = IERC721(_NFT);
    }

    function updateDistributionPercentages(uint8[3] calldata _distributionPercentages) external onlyOwner {
        require(_distributionPercentages[0] + _distributionPercentages[1] == 100,
            "TomiDNSMarketplace: Total percentage should always equal 100");
        distributionPercentages = _distributionPercentages;
    }

    function updateMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external onlyOwner {
        require(_minBidIncrementPercentage != minBidIncrementPercentage,
            "TomiDNSMarketplace: Minimum Bid Increment Percentage is already this value");
        emit UpdatedMinBidIncrementPercentage(minBidIncrementPercentage, _minBidIncrementPercentage);
        minBidIncrementPercentage = _minBidIncrementPercentage;
    }

    function updateAuctionBufferTime(uint256 _auctionBufferTime) external onlyOwner {
        require(_auctionBufferTime != auctionBufferTime, "TomiDNSMarketplace: Auction Buffer Time is already this value");
        emit UpdatedAuctionBufferTime(auctionBufferTime, _auctionBufferTime);
        auctionBufferTime = _auctionBufferTime;
    }

    function updateAuctionBumpTime(uint256 _auctionBumpTime) external onlyOwner {
        require(_auctionBumpTime != auctionBumpTime, "TomiDNSMarketplace: Auction Bump Time is already this value");
        emit UpdatedAuctionBumpTime(auctionBumpTime, _auctionBumpTime);
        auctionBumpTime = _auctionBumpTime;
    }

    function changeSigner(address _signer) external onlyOwner {
        signerWallet = _signer;
    }


    function setOnAuction(
        address _minter,
        uint256 _tokenId,
        string memory _label,
        bytes32 _labelhash,
        string memory _tld,
        uint256 amount
    ) external onlyContract {
        Auction memory auction;
        auction.tokenId = _tokenId;
        auction.minter = _minter;
        auction.mintAmount = amount;
        auction.startTime = block.timestamp;

        if(auctionDuration < block.timestamp){
            auction.expiryTime = block.timestamp.add(2 weeks);
        }else{
            auction.expiryTime = auctionDuration;
        }

        auction.CashBackAmount = amount.mul(5).div(100);
        auction.affiliateAmount = amount.mul(distributionPercentages[2]).div(100);
        auction.DaoAndTomiAmount = amount.sub(auction.CashBackAmount).sub(auction.affiliateAmount);

        uint256 partnerId = partnerNFT.safeMint(_minter, _tokenId);

        auction.partnerId = partnerId;

        getAuctions[_tokenId] = auction;

        Bidding storage bidding = getBiddings[_tokenId];

        bidding.bidder = _minter;
        bidding.amount = amount;

        emit AuctionCreated(
            _tokenId,
            auction.minter,
            auction.mintAmount,
            auction.startTime,
            auction.expiryTime,
            _label,
            _labelhash,
            _tld,
            partnerId
        );

        emit BidCreated(_tokenId, _minter, amount, 0);

    }

    function bid(uint256 _tokenId, uint256 _amount) external nonReentrant {
        Auction storage auction = getAuctions[_tokenId];

        require(_tokenId == auction.tokenId, "TomiDNSMarketplace: Not on auction");
        require(!auction.isClaimed, "TomiDNSMarketplace: Already claimed");
        require(block.timestamp < auction.expiryTime, "TomiDNSMarketplace: Auction finished");

        Bidding storage bidding = getBiddings[_tokenId];

        require(
            _amount >= bidding.amount.add(bidding.amount.mul(minBidIncrementPercentage).div(100)),
            "TomiDNSMarketplace: Bid should exceed last bid by a certain perceentage"
        );

        tomiToken.transferFrom(_msgSender(), address(this), _amount);

        uint256 diff = _amount.sub(bidding.amount);

        uint256 forPartner = diff.mul(distributionPercentages[0]).div(100);
        uint256 forBidder = diff.mul(distributionPercentages[1]).div(100);
        uint256 forAffiliate = diff.mul(distributionPercentages[2]).div(100);
        uint256 forDaoAndTomi;

        auction.partnerAmount = auction.partnerAmount.add(forPartner);
        auction.affiliateAmount = auction.affiliateAmount.add(forAffiliate);

        if(auction.biddingStarted){
            tomiToken.transfer(bidding.bidder, bidding.amount.add(forBidder));
            forDaoAndTomi = diff.sub(forPartner).sub(forBidder).sub(forAffiliate);
            
        }else{
            tomiToken.transfer(bidding.bidder, forBidder);
            auction.biddingStarted = true;
            forDaoAndTomi  = _amount.sub(forPartner).sub(forBidder).sub(forAffiliate);
        }

        auction.DaoAndTomiAmount = auction.DaoAndTomiAmount.add(forDaoAndTomi);
        bool isBufferTime = auction.expiryTime - block.timestamp < auctionBufferTime;

        if (isBufferTime) {
            auction.expiryTime += auctionBumpTime;
            emit AuctionExtended(_tokenId, auction.expiryTime);
        }

        bidding.bidder = _msgSender();
        bidding.amount = _amount;

        emit BidCreated(_tokenId, _msgSender(), _amount , diff);
    }

    function claim(uint256 _tokenId) external nonReentrant {
        Auction storage auction = getAuctions[_tokenId];

        require(_tokenId == auction.tokenId, "TomiDNSMarketplace: Not on auction");
        require(!auction.isClaimed, "TomiDNSMarketplace: Already claimed");
        require(block.timestamp >= auction.expiryTime, "TomiDNSMarketplace: Auction not yet finished");

        Bidding memory bidding = getBiddings[_tokenId];

        uint256 treasuryAmount = auction.DaoAndTomiAmount.div(2);
        uint256 tomiAmount = auction.DaoAndTomiAmount.div(2);

        tomiToken.transfer(treasury, treasuryAmount);
        tomiToken.transfer(tomiWallet, tomiAmount);

        tomiDNS.transferFrom(address(this), bidding.bidder, _tokenId);

        auction.isClaimed = true;
        emit Claimed(_tokenId, auction.minter, bidding.bidder, bidding.amount);

    }


    function getPartnerReward(uint256 id) view public returns(uint256){
        uint256 _tokenId = partnerNFT.getDnsOfNFT(id);
        Auction memory auction = getAuctions[_tokenId];
        return auction.partnerAmount.sub(auction.partnerClaimedAmount);
    }

     function partnerClaimReward(uint256 id) public nonReentrant {
        uint256 toClaim = getPartnerReward(id);
        uint256 _tokenId = partnerNFT.getDnsOfNFT(id);
        address sendTo = partnerNFT.ownerOf(id);
        Auction storage auction = getAuctions[_tokenId];
        auction.partnerClaimedAmount = auction.partnerClaimedAmount.add(toClaim);
        tomiToken.transfer(sendTo, toClaim);
        emit PartnerClaimed(id, _tokenId, toClaim, sendTo);
    }

    function partnerClaimRewardMultiple(uint256[] memory ids) public {
        for(uint256 i = 0 ; i < ids.length ; i++){
            partnerClaimReward(ids[i]);
        }
    }



     function getCashbackReward(uint256 _tokenId) view public returns(uint256){
        Auction memory auction = getAuctions[_tokenId];
        return auction.CashBackAmount;
    }

     function minterCashbackClaim(uint256 _tokenId, uint8 v, bytes32 r, bytes32 s) public nonReentrant {
        verifySignCashBack(_tokenId, v, r, s);
        Auction storage auction = getAuctions[_tokenId];
        address sendTo = auction.minter;
        uint256 amount = getCashbackReward(_tokenId);
        auction.CashBackAmount = 0;
        tomiToken.transfer(sendTo, amount);
        emit CashbackClaimed(_tokenId, amount, sendTo);
    }

    function minterCashbackClaimMultiple(uint256[] memory _tokenIds, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) public {
        for(uint256 i = 0 ; i < _tokenIds.length ; i++){
            minterCashbackClaim(_tokenIds[i], v[i], r[i], s[i]);
        }
    }


    function affiliateClaim(uint256 _tokenId, uint256 amount, string memory id, uint8 v, bytes32 r, bytes32 s) public nonReentrant {
        verifySign(amount, _tokenId, id, v, r, s);
        Auction storage auction = getAuctions[_tokenId];
        address sendTo = _msgSender();
        require(auction.affiliateClaimedAmount.add(amount) <= auction.affiliateAmount , "TomiDNSMarketplace: Invalid amount");
        auction.affiliateClaimedAmount = auction.affiliateClaimedAmount.add(amount);
        tomiToken.transfer(sendTo, amount);
        emit AffiliateClaimed(_tokenId, amount, sendTo);
    }

    function affiliateClaimMultiple(uint256[] memory _tokenIds , uint256[] memory amounts, string[] memory ids, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) public {
        for(uint256 i = 0 ; i < _tokenIds.length ; i++){
            affiliateClaim(_tokenIds[i] , amounts[i] , ids[i], v[i], r[i], s[i]);
        }
    }


    function updatePartnerBaseURI(string memory _uri) public onlyOwner{
        partnerNFT.updateBaseURI(_uri);
    }


    function verifySignCashBack(uint256 _tokenId, uint8 v, bytes32 r, bytes32 s) internal view returns(bool){
        bytes32 encodedMessageHash = keccak256(abi.encodePacked(address(this), _msgSender(), bytes32(_tokenId)));
        require(signerWallet == ecrecover(getSignedHash(encodedMessageHash), v, r, s), "Invalid Claim");
        return true;
    }

    function verifySign(uint256 amount, uint256 _tokenId, string memory id, uint8 v, bytes32 r, bytes32 s) internal returns(bool){
        bytes32 encodedMessageHash = keccak256(abi.encodePacked(address(this), _msgSender(), amount, bytes32(_tokenId) , id));
        require(_isHashClaimed[encodedMessageHash] == false, "Already claimed");
        require(signerWallet == ecrecover(getSignedHash(encodedMessageHash), v, r, s), "Invalid Claim");
        _isHashClaimed[encodedMessageHash] = true;
        return true;
    }
    


    function getSignedHash(bytes32 _messageHash) private pure returns(bytes32){
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    // modifiers

    modifier onlyContract {
        require(msg.sender == contractor, "TomiDNSMarketplace: Only Registrar Contract can call this function");
        _;
    }
}