// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./extensions/IHPMarketplaceMint.sol";
import "./extensions/HPApprovedMarketplace.sol";
import "./extensions/IHPRoles.sol";

import "hardhat/console.sol";

contract AuctionMarketplaceV0006 is ReentrancyGuardUpgradeable, OwnableUpgradeable {

    // Variables
    bool private hasInitialized;
    address public mintAdmin;
    address payable private feeAccount;
    uint256 private feePercent;
    CountersUpgradeable.Counter private auctionCount;

    struct Auction {
        uint256 auctionId;
        uint256 tokenId;
        uint256 startingPrice;
        uint256 highestBid;
        address payable seller;
        address highestBidder;
        uint64 auctionEndTime;
        bool ended;
        bool cancelled;
        IERC721Upgradeable nft;
    }

    struct MintItem {
        address royaltyAddress;
        uint96 feeNumerator;
        bool shouldMint;
        string uri;
        string trackId;
    }

    mapping(uint256 => Auction) public auctions;
    mapping(address => uint256) public pendingReturns;
    mapping(uint256 => MintItem) public mintItems;

    address public hpRolesContractAddress;
    bool private hasUpgradeInitialzed;
    uint256 private initialFeePercent;
    
    // Events
    event AuctionStarted(
        uint256 auctionId, 
        IERC721Upgradeable indexed nft,
        uint256 tokenId,
        uint256 startingPrice,
        uint64 auctionEndTime,
        address indexed seller
    );
    event HighestBidIncrease(
        uint256 auctionId, 
        address indexed nft,
        uint256 tokenId,
        uint256 price,
        address indexed seller, 
        address indexed buyer,
        uint64 bidTime
    );
    event Bought(
        uint256 auctionId,
        address indexed nft,
        uint256 tokenId,
        uint256 price,
        address indexed seller,
        address indexed buyer
    );

    event Cancelled(
        uint256 indexed itemId,
        address indexed nft,
        uint256 indexed tokenId
    );

    event PaymentSplit(
        uint256 itemId,
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed from,
        address indexed to
    );

    event EndedWithoutSale(
        uint256 itemId,
        address indexed nft
    );

    /**
    * _biddingTime the amount of time in seconds
    * _beneficiary who gets paid
    */
    function initialize(uint256 _feePercent, address payable _feeAccount, address _mintAdmin, uint256 _initialFeePercent, address _hpRolesContractAddress) initializer public {
        require(hasInitialized == false, "This has already been initialized");
        hasInitialized = true;
        mintAdmin = _mintAdmin;
        feePercent = _feePercent;
        initialFeePercent = _initialFeePercent;
        feeAccount = _feeAccount;
        __Ownable_init_unchained();

        hasUpgradeInitialzed = true;
        hpRolesContractAddress = _hpRolesContractAddress;

    }

    function upgrader(address _hpRolesContractAddress) external {
        require(hasUpgradeInitialzed == false, "already upgraded");
        hasUpgradeInitialzed = true;
        hpRolesContractAddress = _hpRolesContractAddress;
    }

    function setHasUpgradeInitialized(bool upgraded) external onlyOwner {
        hasUpgradeInitialzed = upgraded;
    }

    function makeAuction(IERC721Upgradeable _nft, uint256 _tokenId, uint256 _startingPrice, uint64 _biddingTime) external nonReentrant {
        
        (uint256 newAuctionId, uint64 auctionEndTime) = generateAuction(_nft, _tokenId, _startingPrice, _biddingTime, false);

        emit AuctionStarted (
            newAuctionId,
            _nft,
            _tokenId,
            _startingPrice,
            auctionEndTime,
            msg.sender
        );
    }

    function makeItemMintable(
        IERC721Upgradeable _nft, 
        uint _startingPrice,
        address _royaltyAddress, 
        uint64 _biddingTime,
        uint96 _feeNumerator,
        string memory _uri,
        string memory _trackId
        ) public nonReentrant {
            IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));
            require(mintAdmin == msg.sender || hpRoles.isAdmin(msg.sender) == true, "Admin rights required");

            IHPMarketplaceMint marketplaceNft = IHPMarketplaceMint(address(_nft));
            require(marketplaceNft.canMarketplaceMint() == true, "This token is not compatible with marketplace minting");
            (uint256 newAuctionId, uint64 auctionEndTime) = generateAuction(_nft, 0, _startingPrice, _biddingTime, true);

            mintItems[newAuctionId] = MintItem (
                _royaltyAddress,
                _feeNumerator,
                true,
                _uri,
                _trackId
            );

            emit AuctionStarted (
            newAuctionId,
            _nft,
            0,
            _startingPrice,
            auctionEndTime,
            msg.sender
        );
    }

    function generateAuction(IERC721Upgradeable _nft, uint _tokenId, uint256 _startingPrice, uint64 _biddingTime, bool minting) private returns (uint256, uint64) {
        calculateFee(_startingPrice, feePercent); // Check if the figure is too small
        uint256 newAuctionId = CountersUpgradeable.current(auctionCount);

        if (!minting) {
            _nft.transferFrom(msg.sender, address(this), _tokenId);
        }
        
        uint64 _auctionEndTime = uint64(block.timestamp) + _biddingTime;

        auctions[newAuctionId] = Auction(
            newAuctionId,
            _tokenId,
            _startingPrice,
            _startingPrice,
            payable(msg.sender),
            address(0),
            _auctionEndTime,
            false,
            false,
            _nft
        );

        CountersUpgradeable.increment(auctionCount);

        return (newAuctionId, _auctionEndTime);
    }

    function bid(uint256 _auctionId) external payable nonReentrant {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp < auction.auctionEndTime, "The auction has already ended.");
        require(auction.cancelled == false, "The auction has been canceled.");
        require(auction.seller != msg.sender, "The auction seller cannot bid.");
        require(auction.highestBidder != msg.sender, "You cannot bid as you are the highest bidder.");
        if (auction.highestBidder == address(0)) {
            require(msg.value >= auction.highestBid, "There is already a higher or equal bid.");
        } else {
            require(msg.value > auction.highestBid, "You bid must be greater than the current bid.");
        }

        if (auction.highestBidder != address(0)) { //
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        emit HighestBidIncrease(
            _auctionId, 
            address(auction.nft), 
            auction.tokenId, 
            msg.value, 
            auction.seller, 
            msg.sender,
            uint64(block.timestamp)
        );
    }

    function withdraw() public nonReentrant returns(bool) {
        uint256 amount = pendingReturns[msg.sender];
        
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            if(!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function auctionEnd(uint256 _auctionId) external nonReentrant {
        Auction storage auction = auctions[_auctionId];
        require(auction.cancelled == false, "The auction has been canceled.");
        require(block.timestamp > auction.auctionEndTime, "The auction has not ended yet.");
        require(auction.ended == false, "Auction end has already been executed.");
        MintItem memory mintingItem = mintItems[_auctionId];
        bool shouldMint = mintingItem.shouldMint;
        auction.ended = true;

        uint256 tokenId = auction.tokenId;
        if (auction.highestBidder == address(0) && shouldMint) {
            emit EndedWithoutSale (
                _auctionId,
                address(auction.nft)
            );
        } else if (auction.highestBidder == address(0)) { // Auction did not sell, send it back to the owner
            auction.nft.transferFrom(address(this), auction.highestBidder, auction.tokenId);
        } else {
            if (shouldMint) {
                tokenId = purchaseMintItem(_auctionId, auction, mintingItem);
            } else {
                purchaseResaleItem(_auctionId, auction);
            }

            emit Bought (
                _auctionId,
                address(auction.nft),
                tokenId,
                auction.highestBid,
                auction.seller,
                auction.highestBidder
            );
        }
    }

    function purchaseMintItem(uint256 _auctionId, Auction memory auction, MintItem memory mintingItem) private returns(uint256) { 
        uint256 fee = getInitialFee(_auctionId);

        uint256 sellerTransferAmount = auction.highestBid - fee;
        auction.seller.transfer(sellerTransferAmount);
        feeAccount.transfer(fee);

        IHPMarketplaceMint hpMarketplaceNft = IHPMarketplaceMint(address(auction.nft));
        uint256 newTokenId = hpMarketplaceNft.marketplaceMint(
            auction.highestBidder, 
            mintingItem.royaltyAddress,
            mintingItem.feeNumerator,
            mintingItem.uri,
            mintingItem.trackId);

        emit PaymentSplit(
            _auctionId,
            address(auction.nft),
            newTokenId,
            sellerTransferAmount,
            msg.sender,
            auction.seller);

        emit PaymentSplit(
            _auctionId,
            address(auction.nft),
            newTokenId,
            fee,
            msg.sender,
            feeAccount);

        return newTokenId;
    }

    function purchaseResaleItem(uint256 _auctionId, Auction memory auction) private { 
            uint256 fee = getFee(_auctionId);
            uint256 sellerTransferAmount = auction.highestBid - fee;

            IERC2981Upgradeable royaltyNft = IERC2981Upgradeable(address(auction.nft));
            try royaltyNft.royaltyInfo(auction.tokenId, auction.highestBid) returns (address receiver, uint256 amount) {
                auction.seller.transfer(auction.highestBid - fee - amount);
                feeAccount.transfer(fee);
                payable(receiver).transfer(amount);

                emit PaymentSplit(
                    _auctionId,
                    address(auction.nft),
                    auction.tokenId,
                    sellerTransferAmount,
                    msg.sender,
                    auction.seller);

                emit PaymentSplit(
                    _auctionId,
                    address(auction.nft),
                    auction.tokenId,
                    amount,
                    msg.sender,
                    receiver);
            } catch {
                auction.seller.transfer(auction.highestBid - fee);
                feeAccount.transfer(fee);

                emit PaymentSplit(
                    _auctionId,
                    address(auction.nft),
                    auction.tokenId,
                    sellerTransferAmount,
                    msg.sender,
                    auction.seller);
            }
            emit PaymentSplit(
                _auctionId,
                address(auction.nft),
                auction.tokenId,
                fee,
                msg.sender,
                feeAccount);

            auction.nft.transferFrom(address(this), auction.highestBidder, auction.tokenId);
    }

    function cancelAuction(uint256 _auctionId) external nonReentrant {
        Auction storage auction = auctions[_auctionId];
        require (auction.seller == msg.sender, "Only the seller can cancel the auction");
        require(block.timestamp < auction.auctionEndTime, "The auction has already concluded.");
        require (auction.ended == false, "The auction has already concluded");
        MintItem memory mintingItem = mintItems[_auctionId];
        bool shouldMint = mintingItem.shouldMint;
        if (!shouldMint) {
            require(auction.nft.ownerOf(auction.tokenId) == address(this), "The contract does not have ownership of token");
            auction.nft.transferFrom(address(this), auction.seller, auction.tokenId);
        }
        else {
            IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));
            require(hpRoles.isAdmin(msg.sender) == true, "You don't have a permission to cancel this auction");
        }
        auction.cancelled = true;

        if (auction.highestBid != 0 && auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }
        
        emit Cancelled (
            auction.auctionId,
            address(auction.nft),
            auction.tokenId
        );
    }

    function getHpRolesContractAddress() public view returns(address) {
        return hpRolesContractAddress;
    }

    function setHpRolesContractAddress(address contractAddress) external onlyOwner {
        hpRolesContractAddress = contractAddress;
    }

    // Utilities
    function getFee(uint256 _auctionId) view public returns(uint256) {
        return calculateFee(auctions[_auctionId].highestBid, feePercent);
    }

    function getInitialFee(uint256 _auctionId) view public returns(uint256) {
        return calculateFee(auctions[_auctionId].highestBid, initialFeePercent);
    }

    function calculateFee(uint256 amount, uint256 percentage)
        public
        pure
        returns (uint256)
    {
        require((amount / 10000) * 10000 == amount, "Too Small");
        return (amount * percentage) / 10000;
    }

    // Fees
    function setInitialPlatformFee(uint256 _initialFeePercent) onlyOwner external {
        initialFeePercent = _initialFeePercent;
    }

    function setPlatformFee(uint256 _feePercent) onlyOwner external {
        feePercent = _feePercent;
    }
}