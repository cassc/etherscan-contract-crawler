// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

////////////interface of lazy nft///////////////////
interface lazyNft {
    function ownerOfToken(uint256 tokenId) external view returns (address);

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);
}

////////////////////////////////////////////////////

interface ISimpleMarketplaceNativeERC721 {
    event NewListing(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed NFT,
        uint256 price,
        address currency,
        uint256 timestamp
    );
    event Sold(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        address NFT,
        uint256 price,
        address currency,
        uint256 timestamp
    );
    event delisted(
        address indexed NFT,
        uint256 indexed tokenId,
        address indexed seller
    );
    event madeOffer(
        address indexed offerSender,
        address indexed NFT,
        uint256 indexed tokenId,
        uint256 offerAmount
    );
    event acceptedOffer(
        address indexed offerMaker,
        address indexed offerTaker,
        address indexed NFT,
        uint256 tokenId,
        uint256 amount
    );
    event deletedOffer(
        address indexed offerMaker,
        address indexed NFT,
        uint256 indexed tokenId,
        uint256 amountRefunded
    );
    event auctionStart(
        address indexed auctioner,
        address indexed NFT,
        uint256 indexed tokenId,
        uint256 auctionTime
    );
    event auctionEnd(
        address indexed auctioner,
        address indexed NFT,
        uint256 indexed tokenId,
        address auctionWinner,
        uint256 highestBid,
        uint256 timeEnded
    );
    event auctionBid(
        address indexed auctioner,
        address indexed bidder,
        address indexed NFT,
        uint256 tokenId,
        uint256 bid,
        uint256 bidTime
    );

    function list(
        uint256 tokenId,
        uint256 price,
        address
    ) external;

    function buy(address nftAddress, uint256 tokenId) external payable;
}

contract auditedMarketplace is
    Ownable,
    ISimpleMarketplaceNativeERC721,
    ReentrancyGuard,
    Pausable
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private lastListingId;
    Counters.Counter private lastBiddingId;

    struct Listing {
        address seller;
        address currency;
        uint256 tokenId;
        uint256 price;
        bool isSold;
        bool exist;
    }

    struct Bidding {
        address buyer;
        uint256 tokenId;
        uint256 offer;
    }

    struct Auction {
        address auctioner;
        uint256 minimumBid;
        address highestBidder;
        uint256 highestBid;
        uint256 endTime;
    }

    // address founouniAddress = 0x7cb0167a57E98b07ec3bf293291fd4665D86B058; // contract address

    //////////////////multiple contracts//////////////////
    mapping(address => mapping(uint256 => Listing)) public contractListing;
    mapping(address => mapping(uint256 => Bidding)) public contractBids;
    mapping(address => mapping(uint256 => bool)) public contractTokensListing;
    mapping(address => mapping(uint256 => bool)) public contractTokensBidding;
    mapping(address => uint256) public biddingRedeemableFunds;

    mapping(address => mapping(uint256 => Auction)) public contractAuction;
    mapping(address => mapping(uint256 => bool)) public contractTokensAuction;
    mapping(address => uint256) public auctionRedeemableFunds;

    mapping(address => mapping(uint256 => address)) public stakedNftOwner;

    mapping(address => uint256) public artistFee;
    /////////////////////////////////////////////////////////////

    address lazyAddress;


    address adminWallet = 0xd4b3D8710f1b207162a29d2975fa2eE22e2D379f;
    uint256 percentRoyalty = 5;

    constructor() {}

    modifier onlyItemOwner(uint256 tokenId, address addy) {
        isItemOwner(tokenId, addy);
        _;
    }

    modifier onlyTransferApproval(address owner, address addy) {
        isTransferApproval(owner, addy);
        _;
    }

    function isItemOwner(uint256 tokenId, address nftAddy) internal view {
        IERC721 token = IERC721(nftAddy);
        require(
            token.ownerOf(tokenId) == _msgSender(),
            "Marketplace: Not the item owner"
        );
    }

    function isTransferApproval(address owner, address nftAddy) internal view {
        IERC721 token = IERC721(nftAddy);
        require(
            token.isApprovedForAll(owner, address(this)),
            "Marketplace: Marketplace is not approved to use this tokenId"
        );
    }

    function setAdminWallet(address wallet) external onlyOwner {
        adminWallet = wallet;
    }

    function list(
        uint256 tokenId,
        uint256 price,
        address nftAddress
    )
        external
        override
        onlyItemOwner(tokenId, nftAddress)
        onlyTransferApproval(msg.sender, nftAddress)
        whenNotPaused
    {
        require(
            !isAuctioned(nftAddress, tokenId),
            "Marketplace: cannot list an auctioned token."
        );
        require(
            contractTokensListing[nftAddress][tokenId] == false,
            "Marketplace: the token is already listed"
        );

        contractTokensListing[nftAddress][tokenId] = true;

        Listing memory _list = contractListing[nftAddress][tokenId];
        require(_list.exist == false, "Marketplace: List already exist");
        require(
            _list.isSold == false,
            "Marketplace: Can not list an already sold item"
        );

        Listing memory newListing = Listing(
            msg.sender,
            address(0),
            tokenId,
            price,
            false,
            true
        );

        contractListing[nftAddress][tokenId] = newListing;

        emit NewListing(
            tokenId,
            msg.sender,
            nftAddress,
            price,
            address(0),
            block.timestamp
        );
    }

    //custom function
    function removeListing(address nftAddress, uint256 tokenId)
        public
        onlyItemOwner(tokenId, nftAddress)
        whenNotPaused
    {
        require(
            contractTokensListing[nftAddress][tokenId] == true,
            "Marketplace: token was never listed"
        );
        Listing memory _list = contractListing[nftAddress][tokenId];
        require(_list.isSold == false, "Marketplace: token is already sold");

        emit delisted(nftAddress, tokenId, msg.sender);
        clearStorage(nftAddress, tokenId);
    }

    //custom function
    function makeOffer(
        address nftAddress,
        uint256 tokenId,
        uint256 offer
    ) external payable whenNotPaused {
        require(
            offer == msg.value,
            "Marketplace: offer does not equal transfered amount"
        );
        IERC721 token = getToken(nftAddress);
        require(
            token.ownerOf(tokenId) != msg.sender,
            "Marketplace: bidder is the token owner"
        );
        require(
            offer > contractBids[nftAddress][tokenId].offer,
            "Marketplace: a higher bid already exists for this token"
        );
        Bidding memory _bid = Bidding(msg.sender, tokenId, offer);
        if (
            contractTokensBidding[nftAddress][tokenId] &&
            contractBids[nftAddress][tokenId].offer < _bid.offer
        ) {
            biddingRedeemableFunds[
                contractBids[nftAddress][tokenId].buyer
            ] += contractBids[nftAddress][tokenId].offer;
        }

        contractBids[nftAddress][tokenId] = _bid;
        contractTokensBidding[nftAddress][tokenId] = true;
        emit madeOffer(msg.sender, nftAddress, tokenId, msg.value);
    }

        function withdrawOfferFunds() external whenNotPaused {
            if (biddingRedeemableFunds[msg.sender] > 0) {
                uint256 transferAmount = biddingRedeemableFunds[msg.sender];
                delete biddingRedeemableFunds[msg.sender];
                bool sent = payable(msg.sender).send(
                    transferAmount
                ); //need to return last bidders funds so they dont get stuck in the contract
                require(
                    sent,
                    "Marketplace: failed to send previous bidder their funds"
                );
            }
        }
    function acceptOffer(address nftAddress, uint256 tokenId)
        external
        nonReentrant
        onlyItemOwner(tokenId, nftAddress)
        onlyTransferApproval(msg.sender, nftAddress)
        whenNotPaused
    {
        require(
            contractTokensBidding[nftAddress][tokenId] == true,
            "Marketplace: the token has no active offers"
        );
        uint256 amount = contractBids[nftAddress][tokenId].offer;

        SendFunds(msg.sender, amount, tokenId, nftAddress);

        IERC721 token = getToken(nftAddress);
        token.safeTransferFrom(
            msg.sender,
            contractBids[nftAddress][tokenId].buyer,
            tokenId,
            ""
        );
        emit acceptedOffer(
            contractBids[nftAddress][tokenId].buyer,
            msg.sender,
            nftAddress,
            tokenId,
            amount
        );
        delete contractBids[nftAddress][tokenId];
        delete contractTokensBidding[nftAddress][tokenId];
        if (contractTokensListing[nftAddress][tokenId]) {
            removeListing(nftAddress, tokenId);
        }
    }

    function deleteOffer(address nftAddress, uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
    {
        require(
            contractBids[nftAddress][tokenId].buyer == msg.sender,
            "Marketplace: cannot delete a bid that is not yours"
        );
        uint256 amount = contractBids[nftAddress][tokenId].offer;
        bool sent = payable(contractBids[nftAddress][tokenId].buyer).send(
            amount
        );
        require(sent, "Marketplace: failed to return funds to bidder");
        delete contractBids[nftAddress][tokenId];
        delete contractTokensBidding[nftAddress][tokenId];
        emit deletedOffer(msg.sender, nftAddress, tokenId, amount);
    }

    function declineOffer(address nftAddress, uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
    {
        IERC721 token = getToken(nftAddress);
        require(
            token.ownerOf(tokenId) == msg.sender,
            "Marketplace: cannot decline an offer to a token you do not own."
        );
        uint256 amount = contractBids[nftAddress][tokenId].offer;
        bool sent = payable(contractBids[nftAddress][tokenId].buyer).send(
            amount
        );
        require(sent, "Marketplace: failed to return funds to bidder");
        delete contractBids[nftAddress][tokenId];
        delete contractTokensBidding[nftAddress][tokenId];
        emit deletedOffer(msg.sender, nftAddress, tokenId, amount);
    }

    function viewOffer(address nftAddress, uint256 tokenId)
        external
        view
        returns (Bidding memory tokenBid)
    {
        return contractBids[nftAddress][tokenId];
    }

    function buy(address nftAddress, uint256 tokenId)
        external
        payable
        override
        whenNotPaused
    {
        Listing memory _list = contractListing[nftAddress][tokenId];
        require(
            _list.price == msg.value,
            "Marketplace: The sent value doesn't equal the price"
        );
        require(_list.isSold == false, "Marketplace: item is already sold");
        require(_list.exist == true, "Marketplace: item does not exist");
        require(
            _list.currency == address(0),
            "Marketplace: item currency is not the native one"
        );
        require(
            _list.seller != msg.sender,
            "Marketplace: seller has the same address as buyer"
        );
        clearStorage(nftAddress, tokenId);
        IERC721 token = getToken(nftAddress);
        token.safeTransferFrom(_list.seller, msg.sender, tokenId, "");
        // payable(_list.seller).transfer(msg.value);

        SendFunds(_list.seller, msg.value, tokenId, nftAddress);

        _list.isSold = true;

        emit Sold(
            tokenId,
            _list.seller,
            msg.sender,
            nftAddress,
            msg.value,
            address(0),
            block.timestamp
        );
    }

    ////////////////////////auction functions///////////////////////////////////////////////

    function startAuction(
        address nftAddress,
        uint256 tokenId,
        uint256 minimumBid,
        uint256 auctionTime
    )
        external
        onlyItemOwner(tokenId, nftAddress)
        onlyTransferApproval(msg.sender, nftAddress)
        whenNotPaused
    {
        require(
            !contractTokensListing[nftAddress][tokenId],
            "Marketplace: cannot auction a listed token!"
        );
        require(
            !contractTokensAuction[nftAddress][tokenId],
            "Marketplace: Should end previous auction before starting a new one."
        );
        // require(minimumBid >= 0, "Marketplace: minimum bid is invalid");

        Auction memory newAuction = Auction(
            msg.sender,
            minimumBid,
            address(0),
            0,
            block.timestamp + auctionTime
        );
        contractTokensAuction[nftAddress][tokenId] = true;
        contractAuction[nftAddress][tokenId] = newAuction;

        IERC721 token = getToken(nftAddress);
        stakedNftOwner[nftAddress][tokenId] = msg.sender;

        token.safeTransferFrom(msg.sender, address(this), tokenId, "");

        emit auctionStart(
            msg.sender,
            nftAddress,
            tokenId,
            contractAuction[nftAddress][tokenId].endTime
        );
    }

    function makeAuctionBid(
        address nftAddress,
        uint256 tokenId,
        uint256 bid
    ) external payable nonReentrant whenNotPaused {
        require(
            msg.value == bid,
            "Marketplace: bid is not equal to sent value"
        );
        require(bid == msg.value, "Marketplace: Bid does not equal sent value");
        require(
            contractTokensAuction[nftAddress][tokenId],
            "Marketplace: no auction exists for this token"
        );
        require(
            contractAuction[nftAddress][tokenId].highestBid < bid,
            "Marketplace: a higher bid already exists for this token"
        );
        require(
            contractAuction[nftAddress][tokenId].minimumBid <= bid,
            "Marketplace: bid should be higher than minimum bid"
        );
        require(
            contractAuction[nftAddress][tokenId].highestBidder != msg.sender,
            "Marketplace: You are already the highest bidder for this token."
        );
        require(
            block.timestamp <= contractAuction[nftAddress][tokenId].endTime,
            "Marketplace: auction has expired for this token"
        );

        uint256 amount = contractAuction[nftAddress][tokenId].highestBid;
        auctionRedeemableFunds[
            contractAuction[nftAddress][tokenId].highestBidder
        ] += amount;
        contractAuction[nftAddress][tokenId].highestBidder = msg.sender;
        contractAuction[nftAddress][tokenId].highestBid = bid;

        emit auctionBid(
            contractAuction[nftAddress][tokenId].auctioner,
            msg.sender,
            nftAddress,
            tokenId,
            bid,
            block.timestamp
        );
    }

    function endAuction(address nftAddress, uint256 tokenId)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        Auction memory auction = contractAuction[nftAddress][tokenId];
        require(
            block.timestamp > auction.endTime,
            "Marketplace: cannot end an auction before time expires"
        );

        IERC721 token = getToken(nftAddress);
        if (auction.highestBidder != address(0)) {
            SendFunds(
                auction.auctioner,
                auction.highestBid,
                tokenId,
                nftAddress
            );

            token.safeTransferFrom(
                address(this),
                auction.highestBidder,
                tokenId,
                ""
            );
        } else {
            token.safeTransferFrom(
                address(this),
                stakedNftOwner[nftAddress][tokenId],
                tokenId,
                ""
            );
        }

        delete stakedNftOwner[nftAddress][tokenId];

        emit auctionEnd(
            auction.auctioner,
            nftAddress,
            tokenId,
            auction.highestBidder,
            auction.highestBid,
            auction.endTime
        );
        removeAuction(nftAddress, tokenId);
    }

    function isAuctioned(address nftAddress, uint256 tokenId)
        public
        view
        returns (bool)
    {
        if (contractTokensAuction[nftAddress][tokenId]) {
            return
                contractAuction[nftAddress][tokenId].endTime >= block.timestamp;
        }
        return false;
    }

    function removeAuction(address nftAddress, uint256 tokenId) internal {
        delete contractAuction[nftAddress][tokenId];
        delete contractTokensAuction[nftAddress][tokenId];
    }

    function withdrawBiddingFunds() external whenNotPaused {
        if (auctionRedeemableFunds[msg.sender] != 0) {
            uint256 biddingTransferAmount = auctionRedeemableFunds[msg.sender];
            delete auctionRedeemableFunds[msg.sender];
            bool sent = payable(msg.sender).send(
                biddingTransferAmount
            ); //need to return last bidders funds so they dont get stuck in the contract
            require(
                sent,
                "Marketplace: failed to send previous bidder their funds"
            );
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    ///////////////////////////////royalties functions ///////////////////////////////////

    function setLazyAddress(address _lazyAddress) external onlyOwner {
        lazyAddress = _lazyAddress;
    }

    function getLazyAddress() external view returns(address) {
        return lazyAddress;
    }

    function setArtistFee(address _lazyAddress, uint256 percentage) external {
        require(
            lazyNft(_lazyAddress).hasRole(
                0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6,
                msg.sender
            ),
            "Marketplace: can't set fee if you are not an artist."
        );
        require(percentage <= 10, "Marketplace: set percentage exceeds limit.");
        artistFee[msg.sender] = percentage;
    }

    ////////////////////////////////////////////////////////////////////////////////////

    function pause(bool isPaused) external onlyOwner {
        if (isPaused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function getToken(address nftAddress) internal pure returns (IERC721) {
        IERC721 token = IERC721(nftAddress);
        return token;
    }

    function clearStorage(address nftAddress, uint256 tokenId) internal {
        delete contractListing[nftAddress][tokenId];
        delete contractTokensListing[nftAddress][tokenId];
    }

    function SendFunds(
        address recipient,
        uint256 amount,
        uint256 tokenId,
        address nftAddress
    ) internal {
        uint256 adminRoyalty = (amount * percentRoyalty) / 100;
        (bool hs, ) = payable(adminWallet).call{value: adminRoyalty}("");
        require(hs, "Marketplace: admin wallet failed to recieve their funds");

        if (nftAddress == lazyAddress) {
            address artistAddress = lazyNft(lazyAddress).ownerOfToken(tokenId);
            require(
                artistAddress != address(0),
                "Marketplace: token has not been redeemed yet"
            );

            uint256 artistRoyalty = (amount * artistFee[artistAddress]) / 100;
            (bool artistSent, ) = payable(artistAddress).call{
                value: artistRoyalty
            }("");
            require(
                artistSent,
                "Marketplace: artist failed to recieve their funds"
            );

            uint256 recipientFunds = amount - (artistRoyalty + adminRoyalty);
            (bool sent, ) = payable(recipient).call{value: recipientFunds}("");
            require(
                sent,
                "Marketplace: recipient failed to recieve their funds"
            );
        } else {
            uint256 recipientFunds = amount - (adminRoyalty);
            (bool sent, ) = payable(recipient).call{value: recipientFunds}("");
            require(
                sent,
                "Marketplace: recipient failed to recieve their funds"
            );
        }
    }


    function setAdminRoyalty(uint256 _adminRoyalty) external onlyOwner {
        require(_adminRoyalty <= 90, "Marketplace: cannot have royalties greater than 90%");
        percentRoyalty = _adminRoyalty;
    }

    function getAdminRoyalty() external view returns(uint256) {
        return percentRoyalty;
    }

 
}