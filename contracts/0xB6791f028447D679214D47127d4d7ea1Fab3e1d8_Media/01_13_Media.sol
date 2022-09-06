//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./interfaces/IERC721Minter.sol";
import "./interfaces/IERC1155Minter.sol";
import "./interfaces/IMarket.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Media is Ownable {
    IMarket private epikoMarket;
    IERC1155Minter private epikoErc1155;
    IERC721Minter private epikoErc721;

    uint256 private constant PERCENTAGE_DENOMINATOR = 10000;

    /// @dev mapping from uri to bool
    mapping(string => bool) private _isUriExist;

    event Mint(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event MarketItemCreated(
        address indexed nftAddress,
        address indexed seller,
        uint256 price,
        uint256 indexed tokenId,
        uint256 quantity
    );
    event AuctionCreated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price,
        uint256 quantity,
        uint256 startTime,
        uint256 endTime
    );

    constructor(
        address erc721Address,
        address erc1155Address,
        address marketAddress
    ) {
        require(erc721Address != address(0), "Media: address Zero provided");
        require(erc1155Address != address(0), "Media: address Zero provided");
        require(marketAddress != address(0), "Media: address Zero provided");

        epikoErc721 = IERC721Minter(erc721Address);
        epikoErc1155 = IERC1155Minter(erc1155Address);
        epikoMarket = IMarket(marketAddress);
    }

    /* Mint nft */
    function mint(
        uint256 amount,
        uint256 royaltyFraction,
        string memory uri,
        bool isErc721
    ) external {
        require(amount > 0, "Media: amount zero provided");
        require(
            royaltyFraction <= PERCENTAGE_DENOMINATOR,
            "Media: invalid royaltyFraction provided"
        );
        require(_isUriExist[uri] != true, "Media: uri already exist");

        address _user = msg.sender;
        if (isErc721) {
            require(amount == 1, "Media: amount must be 1");
            uint256 id = epikoErc721.mint(_user, royaltyFraction, uri);
            emit Mint(address(0), _user, id);
        } else {
            require(amount > 0, "Media: amount must greater than 0");

            uint256 id = epikoErc1155.mint(
                _user,
                amount,
                royaltyFraction,
                uri,
                "0x00"
            );
            emit Mint(address(0), _user, id);
        }
        _isUriExist[uri] = true;
    }

    /* Burn nft (only contract Owner)*/
    function burn(uint256 tokenId) external onlyOwner {
        require(tokenId > 0, "Media: Not valid tokenId");

        epikoErc721.burn(tokenId);
        // delete _isUriExist[]
    }

    /* Burn nft (only contract Owner)*/
    function burn(
        address from,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        require(tokenId > 0, "Not valid tokenId");

        epikoErc1155.burn(from, tokenId, amount);
    }

    /* Places item for sale on the marketplace */
    function sellitem(
        address nftAddress,
        address erc20Token,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external {
        require(nftAddress != address(0), "Media: Address zero provided");
        require(
            tokenId > 0 && price > 0 && amount > 0,
            "Media: not valid id or price or quantity"
        );

        epikoMarket.sellitem(
            nftAddress,
            erc20Token,
            msg.sender,
            tokenId,
            amount,
            price
        );
    }

    function buyItem(
        address nftAddress,
        address seller,
        uint256 tokenId,
        uint256 quantity
    ) external payable {
        validator(nftAddress, seller, tokenId);
        require(quantity > 0, "Media: Not Valid NFT id");
        require(seller != msg.sender, "Media: Owner not Allowed");
        epikoMarket.buyItem{value: msg.value}(
            nftAddress,
            seller,
            msg.sender,
            tokenId,
            quantity
        );
    }

    function createAuction(
        address nftAddress,
        address erc20Token,
        uint256 tokenId,
        uint256 amount,
        uint256 basePrice,
        uint256 endTime
    ) external {
        require(nftAddress != address(0), "Media: Address zero provided");
        require(tokenId > 0, "Media: Not Valid NFT id");
        require(amount > 0, "Media: Not Valid Quantity");
        require(basePrice > 0, "Media: BasePrice must be greater than 0");
        require(
            endTime > block.timestamp,
            "Media: endtime must be greater then current time"
        );
        uint256 startTime = block.timestamp;

        epikoMarket.createAuction(
            nftAddress,
            erc20Token,
            msg.sender,
            tokenId,
            amount,
            basePrice,
            endTime
        );
        emit AuctionCreated(
            nftAddress,
            tokenId,
            msg.sender,
            basePrice,
            amount,
            startTime,
            endTime
        );
    }

    function placeBid(
        address nftAddress,
        address seller,
        uint256 tokenId,
        uint256 price
    ) external payable {
        validator(nftAddress, seller, tokenId);
        epikoMarket.placeBid{value: msg.value}(
            nftAddress,
            msg.sender,
            seller,
            tokenId,
            price
        );
    }

    function approveBid(
        address nftAddress,
        address seller,
        uint256 tokenId,
        address bidder
    ) external {
        validator(nftAddress, seller, tokenId);

        epikoMarket.approveBid(nftAddress, seller, tokenId, bidder);
    }

    function claimNft(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external {
        validator(nftAddress, seller, tokenId);

        epikoMarket.claimNft(nftAddress, msg.sender, seller, tokenId);
    }

    function cancelBid(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external {
        validator(nftAddress, seller, tokenId);

        epikoMarket.cancelBid(nftAddress, msg.sender, seller, tokenId);
    }

    function revokeAuction(address nftAddress, uint256 tokenId) external {
        require(nftAddress != address(0), "Media: address zero provided");
        require(tokenId > 0, "Media: invalid tokenId");
        epikoMarket.revokeAuction(nftAddress, msg.sender, tokenId);
    }

    function cancelSell(address nftAddress, uint256 tokenId) external {
        validator(nftAddress, msg.sender, tokenId);

        epikoMarket.cancelSell(nftAddress, msg.sender, tokenId);
    }

    function cancelAuction(address nftAddress, uint256 tokenId) external {
        validator(nftAddress, msg.sender, tokenId);

        epikoMarket.cancelAuction(nftAddress, msg.sender, tokenId);
    }

    function validator(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) internal pure {
        require(nftAddress != address(0), "Media: address zero provided");
        require(seller != address(0), "Media: address zero provided");
        require(tokenId > 0, "Media: provide valid tokenid");
    }
}