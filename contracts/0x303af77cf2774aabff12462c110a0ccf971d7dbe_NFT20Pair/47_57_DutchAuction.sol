pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../interfaces/INFT20Pair.sol";

contract DutchAuction is Ownable, ERC1155Holder, ERC721Holder {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Auction {
        uint256 id;
        address seller;
        address nft20Pair;
        uint256 tokenId;
        uint256 startingPrice; // wei
        uint256 endingPrice; // wei
        uint256 duration; // seconds
        uint256 startedAt; // time
    }

    uint256 public daoFee;
    address public daoAddress;

    uint256 public auctionId = 1; // max is 18446744073709551615

    // to query auctiosn by each pair
    mapping(address => EnumerableSet.UintSet) private _auction;

    mapping(uint256 => Auction) internal auctionIdToAuction;

    event AuctionCreated(
        uint256 auctionId,
        address indexed seller,
        address indexed nft20Pair,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration
    );
    event AuctionCancelled(
        uint64 auctionId,
        address indexed seller,
        address indexed nft20Pair,
        uint256 tokenId
    );

    event AuctionSuccessful(
        uint256 auctionId,
        address indexed seller,
        address indexed nft20Pair,
        uint256 tokenId,
        uint256 totalPrice,
        address winner
    );

    constructor(address _daoAddress, uint256 _daoFee) public {
        daoAddress = _daoAddress;
        daoFee = _daoFee;
    }

    function createAuction(
        address _nft20Pair,
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    ) external {
        require(_duration >= 1 minutes);
        require(
            _startingPrice > _endingPrice,
            "!starting price should be higher"
        ); //not sure about this, need to also check getCurrentPrice()
        INFT20Pair nft20pair = INFT20Pair(_nft20Pair);

        if (nft20pair.nftType() == 721) {
            require(
                IERC721(nft20pair.nftAddress()).ownerOf(_tokenId) == msg.sender,
                "!owner"
            );
        } else if (nft20pair.nftType() == 1155) {
            require(
                IERC1155(nft20pair.nftAddress()).balanceOf(
                    msg.sender,
                    _tokenId
                ) >= 1,
                "!owner"
            );
        }

        auctionIdToAuction[auctionId] = Auction(
            auctionId,
            msg.sender,
            _nft20Pair,
            _tokenId,
            _startingPrice,
            _endingPrice,
            _duration,
            block.timestamp
        );

        _auction[_nft20Pair].add(auctionId);

        emit AuctionCreated(
            auctionId,
            msg.sender,
            _nft20Pair,
            _tokenId,
            _startingPrice,
            _endingPrice,
            block.timestamp
        );

        auctionId++;
    }

    function getAuctionByAuctionId(uint256 _auctionId)
        public
        view
        returns (
            uint256 _id,
            address _seller,
            address _nft20Pair,
            uint256 _tokenId,
            uint256 _startingPrice,
            uint256 _endingPrice,
            uint256 _duration,
            uint256 _startedAt,
            uint256 _currentPrice
        )
    {
        Auction storage auction = auctionIdToAuction[_auctionId];
        require(auction.startedAt > 0); // Not sure why this
        _id = auction.id;
        _seller = auction.seller;
        _nft20Pair = address(auction.nft20Pair);
        _tokenId = auction.tokenId;
        _startingPrice = auction.startingPrice;
        _endingPrice = auction.endingPrice;
        _duration = auction.duration;
        _startedAt = auction.startedAt;
        _currentPrice = getCurrentPrice(auction);
    }

    function cancelAuctionByAuctionId(uint64 _auctionId) external {
        Auction storage auction = auctionIdToAuction[_auctionId];

        require(auction.startedAt > 0);
        require(msg.sender == auction.seller);

        _auction[auction.nft20Pair].remove(_auctionId);

        delete auctionIdToAuction[_auctionId];
        emit AuctionCancelled(
            _auctionId,
            auction.seller,
            address(auction.nft20Pair),
            auction.tokenId
        );
    }

    function bid(uint256 _auctionId, uint256 _bid) external {
        Auction storage auction = auctionIdToAuction[_auctionId];
        require(auction.startedAt > 0);

        uint256 price = getCurrentPrice(auction);
        require(_bid >= price);

        uint256 auctionId_temp = auction.id;
        INFT20Pair nft20Pair = INFT20Pair(auction.nft20Pair);

        address seller = auction.seller;
        delete auctionIdToAuction[auctionId_temp];

        if (price > 0) {
            nft20Pair.transferFrom(
                msg.sender,
                address(this),
                price.mul(daoFee).div(100)
            );
            nft20Pair.transferFrom(
                msg.sender,
                seller,
                price.mul(uint256(100).sub(daoFee)).div(100)
            );
        }

        transferNft(
            nft20Pair.nftAddress(),
            nft20Pair.nftType(),
            seller,
            msg.sender,
            auction.tokenId
        );

        _auction[auction.nft20Pair].remove(_auctionId);

        emit AuctionSuccessful(
            auctionId_temp,
            auction.seller,
            address(nft20Pair),
            auction.tokenId,
            price,
            msg.sender
        );
    }

    function getCurrentPriceByAuctionId(uint64 _auctionId)
        public
        view
        returns (uint256)
    {
        Auction storage auction = auctionIdToAuction[_auctionId];
        return getCurrentPrice(auction);
    }

    // TODO Let's check this and add safe math maybe.
    function getCurrentPrice(Auction storage _thisauction)
        internal
        view
        returns (uint256)
    {
        require(_thisauction.startedAt > 0);
        uint256 secondsPassed = 0;

        secondsPassed = now.sub(_thisauction.startedAt);

        if (secondsPassed >= _thisauction.duration) {
            return _thisauction.endingPrice;
        } else {
            uint256 totalPriceChange =
                _thisauction.startingPrice.sub(_thisauction.endingPrice);

            uint256 currentPriceChange =
                (totalPriceChange.mul(secondsPassed)).div(
                    _thisauction.duration
                );

            uint256 currentPrice =
                _thisauction.startingPrice.sub(currentPriceChange);

            return currentPrice;
        }
    }

    // maybe we can rethink this for less gas?
    function transferNft(
        address nftAddress,
        uint256 nftType,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        if (nftType == 721) {
            IERC721(nftAddress).safeTransferFrom(_from, _to, _tokenId);
        } else if (nftType == 1155) {
            IERC1155(nftAddress).safeTransferFrom(_from, _to, _tokenId, 1, "");
        }
    }

    function auctionsAmountByPair(address _nft20pair)
        public
        view
        returns (uint256)
    {
        require(
            _nft20pair != address(0),
            "ERC721: balance query for the zero address"
        );

        return _auction[_nft20pair].length();
    }

    function auctionOfPairByIndex(address _nft20pair, uint256 index)
        public
        view
        returns (uint256)
    {
        return _auction[_nft20pair].at(index);
    }

    function recoverERC20(
        address tokenAddress,
        address receiver,
        uint256 tokenAmount
    ) public onlyOwner {
        INFT20Pair(tokenAddress).transfer(receiver, tokenAmount);
    }
}