//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./interfaces/IERC721Minter.sol";
import "./interfaces/IERC1155Minter.sol";
import "./interfaces/IMarket.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EpikoMarketplace is IMarket, Ownable {
    IERC1155Minter private epikoErc1155;
    IERC721Minter private epikoErc721;

    uint256 private _buyTax = 110; //divide by 100
    uint256 private _sellTax = 110; //divide by 100
    uint256 private constant PERCENTAGE_DENOMINATOR = 10000;
    address private mediaContract;
    bytes4 private constant ERC721INTERFACEID = 0x80ac58cd; // Interface Id of ERC721
    bytes4 private constant ERC1155INTERFACEID = 0xd9b67a26; // Interface Id of ERC1155
    bytes4 private constant ROYALTYINTERFACEID = 0x2a55205a; // interface Id of Royalty

    /// @dev mapping from NFT contract to user address to tokenId is item on auction check
    mapping(address => mapping(address => mapping(uint256 => bool)))
        private itemIdOnAuction;
    /// @dev mapping from NFT contract to user address to tokenId is item on sale check
    mapping(address => mapping(address => mapping(uint256 => bool)))
        private itemIdOnSale;
    /// @dev Mapping from Nft contract to tokenId to Auction structure
    mapping(address => mapping(address => mapping(uint256 => Auction)))
        public nftAuctionItem;
    /// @dev Mapping from Nft contract to tokenId to Sale structure
    mapping(address => mapping(address => mapping(uint256 => Sale)))
        public nftSaleItem;
    /// @dev Mapping from NFT contract to tokenId to bidders address
    mapping(address => mapping(uint256 => address[])) private bidderList;
    /// @dev mapping from NFT conntract to tokenid to bidder address to bid value
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        private fundsByBidder;

    /// @dev mapping from Nft contract to tokenId to bid array
    mapping(address => mapping(uint256 => Bid[])) private bidAndValue;

    constructor() Ownable() {}

    fallback() external {}

    receive() external payable {}

    function onlyMedia() internal view {
        require(msg.sender == mediaContract, "Market: unauthorized Access");
    }

    function configureMedia(address _mediaContract) external onlyOwner {
        require(
            _mediaContract != address(0),
            "Market: Media address is invalid"
        );
        require(
            mediaContract == address(0),
            "Market: Media is already configured"
        );
        mediaContract = _mediaContract;
    }

    /* Places item for sale on the marketplace */
    function sellitem(
        address nftAddress,
        address erc20Token,
        address seller,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external override {
        onlyMedia();

        Sale storage sale = nftSaleItem[nftAddress][seller][tokenId];

        require(
            !itemIdOnSale[nftAddress][seller][tokenId],
            "Market: Nft already on Sale"
        );
        require(
            !itemIdOnAuction[nftAddress][seller][tokenId],
            "Market: Nft already on Auction"
        );
        sale.tokenId = tokenId;
        sale.price = price;
        sale.seller = seller;
        sale.erc20Token = erc20Token;
        sale.quantity = amount;
        sale.time = block.timestamp;

        itemIdOnSale[nftAddress][seller][tokenId] = true;

        emit MarketItemCreated(nftAddress, msg.sender, price, tokenId, amount);
    }

    /* Place buy order for Multiple item on marketplace */
    function buyItem(
        address nftAddress,
        address seller,
        address buyer,
        uint256 tokenId,
        uint256 quantity
    ) external payable override {
        onlyMedia();

        Sale storage sale = nftSaleItem[nftAddress][seller][tokenId];
        require(
            quantity <= sale.quantity,
            "Market: not enough quantity available"
        );
        validSale(nftAddress, seller, tokenId);

        uint256 price = sale.price;

        // ItemForSellOrForAuction storage sellItem = _itemOnSellAuction[tokenId][seller];

        if (IERC721(nftAddress).supportsInterface(ERC721INTERFACEID)) {
            uint256 totalNftValue = price * quantity;

            if (!IERC721(nftAddress).supportsInterface(ROYALTYINTERFACEID)) {
                _transferTokens(
                    totalNftValue,
                    0,
                    sale.seller,
                    buyer,
                    address(0),
                    sale.erc20Token
                );
                IERC721(nftAddress).transferFrom(
                    sale.seller,
                    buyer,
                    sale.tokenId
                );
            } else {
                (address user, uint256 royaltyAmount) = IERC2981(nftAddress)
                    .royaltyInfo(sale.tokenId, totalNftValue);
                _transferTokens(
                    totalNftValue,
                    royaltyAmount,
                    sale.seller,
                    buyer,
                    user,
                    sale.erc20Token
                );
                IERC721(nftAddress).transferFrom(
                    sale.seller,
                    buyer,
                    sale.tokenId
                );
            }

            sale.sold = true;
            itemIdOnSale[nftAddress][seller][tokenId] = false;

            delete nftSaleItem[nftAddress][seller][tokenId];
            // sellItem.onSell = false;
            emit Buy(seller, buyer, price, tokenId, sale.quantity);
        } else if (
            IERC1155Minter(nftAddress).supportsInterface(ERC1155INTERFACEID)
        ) {
            uint256 totalNftValue = price * quantity;

            if (!IERC1155(nftAddress).supportsInterface(ROYALTYINTERFACEID)) {
                _transferTokens(
                    totalNftValue,
                    0,
                    sale.seller,
                    buyer,
                    address(0),
                    sale.erc20Token
                );
                IERC1155(nftAddress).safeTransferFrom(
                    sale.seller,
                    buyer,
                    sale.tokenId,
                    quantity,
                    ""
                );
                sale.quantity -= quantity;
            } else {
                (address user, uint256 royaltyAmount) = IERC2981(nftAddress)
                    .royaltyInfo(sale.tokenId, totalNftValue);
                _transferTokens(
                    totalNftValue,
                    royaltyAmount,
                    sale.seller,
                    buyer,
                    user,
                    sale.erc20Token
                );
                IERC1155(nftAddress).safeTransferFrom(
                    sale.seller,
                    buyer,
                    sale.tokenId,
                    quantity,
                    ""
                );
                sale.quantity -= quantity;
            }

            if (sale.quantity == 0) {
                sale.sold = true;
                itemIdOnSale[nftAddress][seller][tokenId] = false;
                delete nftSaleItem[nftAddress][seller][tokenId];
            }
            // sellItem.onSell = false;
            emit Buy(seller, buyer, price, tokenId, quantity);
        } else {
            revert("Market: Token not exist");
        }
    }

    /* Create Auction for item on marketplace */
    function createAuction(
        address nftAddress,
        address erc20Token,
        address seller,
        uint256 tokenId,
        uint256 amount,
        uint256 basePrice,
        uint256 endTime
    ) external override {
        onlyMedia();

        require(
            !itemIdOnSale[nftAddress][seller][tokenId],
            "Market: NFT already on sale"
        );
        require(
            !itemIdOnAuction[nftAddress][seller][tokenId],
            "Market: NFT already on auction"
        );

        uint256 startTime = block.timestamp;

        Auction storage auction = nftAuctionItem[nftAddress][seller][tokenId];

        if (IERC721(nftAddress).supportsInterface(ERC721INTERFACEID)) {
            require(!auction.sold, "Market: Already on sell");
            require(
                IERC721(nftAddress).ownerOf(tokenId) == seller,
                "Market: not nft owner"
            );
            require(
                IERC721(nftAddress).getApproved(tokenId) == address(this),
                "Market: nft not approved for auction"
            );

            _addItemtoAuction(
                nftAddress,
                erc20Token,
                tokenId,
                amount,
                basePrice,
                startTime,
                endTime,
                seller
            );
            emit AuctionCreated(
                nftAddress,
                tokenId,
                seller,
                basePrice,
                amount,
                startTime,
                endTime
            );
        } else if (IERC1155(nftAddress).supportsInterface(ERC1155INTERFACEID)) {
            require(!auction.sold, "Market: Already on sell");
            require(
                IERC1155(nftAddress).balanceOf(seller, tokenId) >= amount,
                "Market: Not enough nft Balance"
            );
            require(
                IERC1155(nftAddress).isApprovedForAll(seller, address(this)),
                "Market: NFT not approved for auction"
            );

            _addItemtoAuction(
                nftAddress,
                erc20Token,
                tokenId,
                amount,
                basePrice,
                startTime,
                endTime,
                seller
            );
            emit AuctionCreated(
                nftAddress,
                tokenId,
                seller,
                basePrice,
                amount,
                startTime,
                endTime
            );
        } else {
            revert("Market: Token not Exist");
        }
    }

    /* Place bid for item  on marketplace */
    function placeBid(
        address nftAddress,
        address bidder,
        address seller,
        uint256 tokenId,
        uint256 price
    ) external payable override {
        onlyMedia();

        Auction storage auction = nftAuctionItem[nftAddress][seller][tokenId];
        validAuction(nftAddress, seller, tokenId);

        require(auction.endTime > block.timestamp, "Market: Auction ended");
        require(
            auction.startTime < block.timestamp,
            "Market: Auction not started"
        );
        require(
            price >= auction.basePrice && price > auction.highestBid.bid,
            "Market: place highest bid"
        );
        require(auction.seller != bidder, "Market: seller not allowed");

        if (auction.erc20Token != address(0)) {
            require(
                IERC20(auction.erc20Token).allowance(bidder, address(this)) >=
                    price,
                "Market: please proivde asking price"
            );
            IERC20(auction.erc20Token).transferFrom(
                bidder,
                address(this),
                price
            );
        } else {
            require(msg.value >= price, "Market: please proivde asking price");
        }

        auction.highestBid.bid = price;
        auction.highestBid.bidder = bidder;
        // fundsByBidder[nftAddress][tokenId][bidder] = price;
        // bidAndValue[nftAddress][tokenId].push(Bid(bidder, price));
        auction.bids.push(Bid(bidder, price));

        emit PlaceBid(nftAddress, bidder, price, tokenId);
    }

    /* To Approve bid*/
    function approveBid(
        address nftAddress,
        address seller,
        uint256 tokenId,
        address bidder
    ) external override {
        onlyMedia();

        Auction storage auction = nftAuctionItem[nftAddress][seller][tokenId];
        validAuction(nftAddress, seller, tokenId);

        // require(
        //     fundsByBidder[nftAddress][tokenId][bidder] != 0,
        //     "Market: bidder not found"
        // );
        require(
            getBidAndBidder(auction, bidder) != 0,
            "Market: bidder not found"
        );
        require(auction.endTime > block.timestamp, "Market: Auction ended");
        require(
            auction.startTime < block.timestamp,
            "Market: Auction not started"
        );
        require(auction.seller == seller, "Market: not authorised");
        require(auction.tokenId == tokenId, "Market: Auction not found");

        uint256 bidderValue = getBidAndBidder(auction, bidder);
        // uint256 bidderValue = fundsByBidder[nftAddress][tokenId][bidder];

        if (IERC721(nftAddress).supportsInterface(ERC721INTERFACEID)) {
            if (!IERC721(nftAddress).supportsInterface(ROYALTYINTERFACEID)) {
                _tokenDistribute(
                    auction,
                    bidderValue,
                    0,
                    auction.seller,
                    address(0),
                    bidder,
                    auction.erc20Token
                );
                IERC721(nftAddress).transferFrom(
                    auction.seller,
                    bidder,
                    auction.tokenId
                );
            } else {
                (address user, uint256 amount) = IERC2981(nftAddress)
                    .royaltyInfo(auction.tokenId, bidderValue);
                _tokenDistribute(
                    auction,
                    bidderValue,
                    amount,
                    auction.seller,
                    user,
                    bidder,
                    auction.erc20Token
                );
                IERC721(nftAddress).transferFrom(
                    auction.seller,
                    bidder,
                    auction.tokenId
                );
            }

            auction.sold = true;
            itemIdOnAuction[nftAddress][auction.seller][tokenId] = false;
            emit Buy(
                auction.seller,
                bidder,
                bidderValue,
                tokenId,
                auction.quantity
            );

            delete nftAuctionItem[nftAddress][seller][tokenId];
        } else if (IERC1155(nftAddress).supportsInterface(ERC1155INTERFACEID)) {
            if (!IERC721(nftAddress).supportsInterface(ROYALTYINTERFACEID)) {
                _tokenDistribute(
                    auction,
                    bidderValue,
                    0,
                    auction.seller,
                    address(0),
                    bidder,
                    auction.erc20Token
                );
                IERC1155(nftAddress).safeTransferFrom(
                    auction.seller,
                    bidder,
                    auction.tokenId,
                    auction.quantity,
                    ""
                );
            } else {
                (address user, uint256 amount) = IERC2981(nftAddress)
                    .royaltyInfo(auction.tokenId, bidderValue);
                _tokenDistribute(
                    auction,
                    bidderValue,
                    amount,
                    auction.seller,
                    user,
                    bidder,
                    auction.erc20Token
                );
                IERC1155(nftAddress).safeTransferFrom(
                    auction.seller,
                    bidder,
                    auction.tokenId,
                    auction.quantity,
                    ""
                );
            }

            auction.sold = true;
            itemIdOnAuction[nftAddress][auction.seller][tokenId] = false;
            emit Buy(
                auction.seller,
                bidder,
                bidderValue,
                tokenId,
                auction.quantity
            );

            delete nftAuctionItem[nftAddress][seller][tokenId];
        } else {
            revert("Market: NFT not supported");
        }
    }

    /* To Claim NFT bid*/
    function claimNft(
        address nftAddress,
        address bidder,
        address seller,
        uint256 tokenId
    ) external override {
        onlyMedia();

        Auction storage auction = nftAuctionItem[nftAddress][seller][tokenId];

        require(nftAddress != address(0), "Market: address zero given");
        require(tokenId > 0, "Market: not valid nft id");
        require(auction.endTime < block.timestamp, "Market: Auction not ended");
        require(
            auction.highestBid.bidder == bidder,
            "Market: Only highest bidder can claim"
        );

        uint256 bidderValue = getBidAndBidder(auction, bidder);
        // uint256 bidderValue = fundsByBidder[nftAddress][tokenId][bidder];

        if (IERC721(nftAddress).supportsInterface(ERC721INTERFACEID)) {
            if (!IERC721(nftAddress).supportsInterface(ROYALTYINTERFACEID)) {
                _tokenDistribute(
                    auction,
                    bidderValue,
                    0,
                    auction.seller,
                    address(0),
                    bidder,
                    auction.erc20Token
                );
                IERC721(nftAddress).transferFrom(
                    auction.seller,
                    bidder,
                    auction.tokenId
                );
            } else {
                (address user, uint256 amount) = IERC2981(nftAddress)
                    .royaltyInfo(auction.tokenId, bidderValue);
                _tokenDistribute(
                    auction,
                    bidderValue,
                    amount,
                    auction.seller,
                    user,
                    bidder,
                    auction.erc20Token
                );
                IERC721(nftAddress).transferFrom(
                    auction.seller,
                    bidder,
                    auction.tokenId
                );
            }

            auction.sold = true;
            itemIdOnAuction[nftAddress][auction.seller][tokenId] = false;
            emit Buy(
                auction.seller,
                bidder,
                bidderValue,
                tokenId,
                auction.quantity
            );

            delete nftAuctionItem[nftAddress][seller][tokenId];
        } else if (IERC1155(nftAddress).supportsInterface(ERC1155INTERFACEID)) {
            if (!IERC721(nftAddress).supportsInterface(ROYALTYINTERFACEID)) {
                _tokenDistribute(
                    auction,
                    bidderValue,
                    0,
                    auction.seller,
                    address(0),
                    bidder,
                    auction.erc20Token
                );
                IERC1155(nftAddress).safeTransferFrom(
                    auction.seller,
                    bidder,
                    auction.tokenId,
                    auction.quantity,
                    ""
                );
            } else {
                (address user, uint256 amount) = IERC2981(nftAddress)
                    .royaltyInfo(auction.tokenId, bidderValue);
                _tokenDistribute(
                    auction,
                    bidderValue,
                    amount,
                    auction.seller,
                    user,
                    bidder,
                    auction.erc20Token
                );
                IERC1155(nftAddress).safeTransferFrom(
                    auction.seller,
                    bidder,
                    auction.tokenId,
                    auction.quantity,
                    ""
                );
            }

            auction.sold = true;
            itemIdOnAuction[nftAddress][auction.seller][tokenId] = false;
            emit Buy(
                auction.seller,
                bidder,
                bidderValue,
                tokenId,
                auction.quantity
            );

            delete nftAuctionItem[nftAddress][seller][tokenId];
        } else {
            revert("Market: NFT not supported");
        }
    }

    /* To cancel Auction */
    function cancelAuction(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external override {
        onlyMedia();

        Auction storage auction = nftAuctionItem[nftAddress][seller][tokenId];
        require(
            auction.seller == seller || owner() == seller,
            "Market: only seller or owner can cancel sell"
        );
        validAuction(nftAddress, seller, tokenId);

        require(auction.endTime > block.timestamp, "Market: Auction ended");
        require(!auction.sold, "Market: Already sold");

        if (auction.highestBid.bid > 0) {
            for (uint256 index = auction.bids.length - 1; index >= 0; index--) {
                IERC20(auction.erc20Token).transfer(
                    auction.bids[index].bidder,
                    auction.bids[index].bid
                );
                delete auction.bids[index];
                // bidAndValue[nftAddress][tokenId][index] = bidAndValue[nftAddress][tokenId][bidAndValue[nftAddress][tokenId].length - 1];
                auction.bids.pop();
                if (index == 0) {
                    break;
                }
            }
        }
        delete nftAuctionItem[nftAddress][seller][tokenId];
        itemIdOnAuction[nftAddress][seller][tokenId] = false;
    }

    /* To cancel sell */
    function cancelSell(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external override {
        onlyMedia();

        Sale storage sale = nftSaleItem[nftAddress][seller][tokenId];

        require(
            (sale.seller == seller) || owner() == seller,
            "Market: Only seller or owner can cancel sell"
        );
        validSale(nftAddress, seller, tokenId);

        require(
            !nftSaleItem[nftAddress][seller][tokenId].sold,
            "Market: NFT Sold"
        );

        delete nftSaleItem[nftAddress][seller][tokenId];
        itemIdOnSale[nftAddress][seller][tokenId] = false;
    }

    // function unsafe_inc(uint256 i) private pure returns (uint256) {
    //     unchecked {
    //         return i + 1;
    //     }
    // }

    /* To cancel auction bid */
    function cancelBid(
        address nftAddress,
        address bidder,
        address seller,
        uint256 tokenId
    ) external override {
        onlyMedia();

        Auction storage auction = nftAuctionItem[nftAddress][seller][tokenId];

        require(
            nftAuctionItem[nftAddress][seller][tokenId].endTime >
                block.timestamp,
            "Market: Auction ended"
        );
        require(
            getBidAndBidder(auction, bidder) > 0,
            "Market: not bided on auction"
        );
        // require(
        //     fundsByBidder[nftAddress][tokenId][bidder] > 0,
        //     "Market: not bided on auction"
        // );
        // uint256 bidLength = bidAndValue[nftAddress][tokenId].length;
        uint256 bidLength = auction.bids.length;
        for (uint256 index = 0; index < bidLength; index++) {
            if (auction.bids[index].bidder == bidder) {
                if (auction.erc20Token != address(0)) {
                    IERC20(auction.erc20Token).transfer(
                        auction.bids[index].bidder,
                        auction.bids[index].bid
                    );
                } else {
                    payable(auction.bids[index].bidder).transfer(
                        auction.bids[index].bid
                    );
                }

                delete auction.bids[index];
                auction.bids[index].bidder = auction.bids[bidLength - 1].bidder;
                auction.bids[index].bid = auction.bids[bidLength - 1].bid;
                auction.bids.pop();
                if (auction.highestBid.bidder == bidder) {
                    auction.highestBid.bidder = auction
                        .bids[auction.bids.length - 1]
                        .bidder;
                    auction.highestBid.bid = auction
                        .bids[auction.bids.length - 1]
                        .bid;
                }
                // bidAndValue[nftAddress][tokenId].pop();
                break;
            }
        }
        if (bidLength < 1) {
            auction.highestBid.bidder = address(0);
            auction.highestBid.bid = 0;
        }

        emit CancelBid(tokenId, seller, bidder);
    }

    /* To check list of bidder */
    // function checkBidderList(address nftAddress, uint256 tokenId)
    //     external
    //     view
    //     returns (Bid[] memory bid)
    // {
    //     require(tokenId > 0, "Market: not valid id");

    //     return bidAndValue[nftAddress][tokenId];
    // }

    /* To transfer nfts from `from` to `to` */
    function transfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external {
        require(to != address(0), "Market: Transfer to zero address");
        require(from != address(0), "Market: Transfer from zero address");
        require(tokenId > 0, "Market: Not valid tokenId");

        if (epikoErc721._isExist(tokenId)) {
            epikoErc721.transferFrom(from, to, tokenId);
        } else if (epikoErc1155._isExist(tokenId)) {
            epikoErc1155.safeTransferFrom(from, to, tokenId, amount, "");
        }
    }

    /* owner can set selltax(fees) */
    function setSellTax(uint256 percentage) external onlyOwner {
        require(
            percentage <= PERCENTAGE_DENOMINATOR,
            "Market: percentage must be less than 100"
        );
        _sellTax = percentage;
    }

    /* owner can set buytax(fees) */
    function setBuyTax(uint256 percentage) external onlyOwner {
        require(
            percentage <= PERCENTAGE_DENOMINATOR,
            "Market: percentage must be less than 100"
        );
        _buyTax = percentage;
    }

    function getBuyTax() public view returns (uint256) {
        return _buyTax;
    }

    function getSellTax() public view returns (uint256) {
        return _sellTax;
    }

    function getBidAndBidder(Auction memory auction, address bidder)
        internal
        pure
        returns (uint256 bid)
    {
        for (uint256 index = 0; index < auction.bids.length; index++) {
            if (auction.bids[index].bidder == bidder) {
                return auction.bids[index].bid;
            }
        }
    }

    function _transferTokens(
        uint256 price,
        uint256 royaltyAmount,
        address _seller,
        address _buyer,
        address royaltyReceiver,
        address token
    ) private {
        uint256 amountForOwner;
        // uint256 buyingValue = price.add(price.mul(_sellTax)).div(PERCENTAGE_DENOMINATOR);
        uint256 buyingValue = price +
            (price * _sellTax) /
            PERCENTAGE_DENOMINATOR;
        uint256 amountForSeller = price -
            (price * _buyTax) /
            PERCENTAGE_DENOMINATOR;
        amountForOwner = buyingValue - amountForSeller;

        if (token != address(0)) {
            require(
                IERC20(token).allowance(_buyer, address(this)) >= buyingValue,
                "Market: please proivde asking price"
            );
            IERC20(token).transferFrom(_buyer, address(this), buyingValue);
            IERC20(token).transfer(owner(), amountForOwner);
            IERC20(token).transfer(_seller, amountForSeller - royaltyAmount);
            if (royaltyReceiver != address(0)) {
                IERC20(token).transfer(royaltyReceiver, royaltyAmount);
            }
        } else {
            require(msg.value >= buyingValue, "Market: Provide asking price");

            payable(owner()).transfer(amountForOwner);
            payable(_seller).transfer(amountForSeller - royaltyAmount);
            if (royaltyReceiver != address(0)) {
                payable(royaltyReceiver).transfer(royaltyAmount);
            }
        }
    }

    function _tokenDistribute(
        Auction memory auction,
        uint256 price,
        uint256 _amount,
        address _seller,
        address royaltyReceiver,
        address _bidder,
        address token
    ) private {
        uint256 amountForOwner;
        uint256 amountForSeller = price -
            ((price * (_buyTax + _sellTax)) / PERCENTAGE_DENOMINATOR);
        // uint256 amountForSeller = price.sub(price.mul(_buyTax.add(_sellTax))).div(PERCENTAGE_DENOMINATOR);

        amountForOwner = price - amountForSeller;
        amountForSeller = amountForSeller - _amount;

        if (token != address(0)) {
            IERC20(token).transfer(owner(), amountForOwner);
            IERC20(token).transfer(_seller, amountForSeller);

            if (royaltyReceiver != address(0)) {
                IERC20(token).transfer(royaltyReceiver, _amount);
            }
        } else {
            if (royaltyReceiver != address(0)) {
                payable(royaltyReceiver).transfer(_amount);
            }
        }

        for (uint256 index = 0; index < auction.bids.length; index++) {
            if (auction.bids[index].bidder != _bidder) {
                if (token != address(0)) {
                    IERC20(token).transfer(
                        auction.bids[index].bidder,
                        auction.bids[index].bid
                    );
                } else {
                    payable(auction.bids[index].bidder).transfer(
                        auction.bids[index].bid
                    );
                }
            }
        }
    }

    function _addItemtoAuction(
        address nftAddress,
        address erc20Token,
        uint256 tokenId,
        uint256 _amount,
        uint256 basePrice,
        uint256 startTime,
        uint256 endTime,
        address _seller
    ) private {
        Auction storage auction = nftAuctionItem[nftAddress][_seller][tokenId];

        auction.nftContract = nftAddress;
        auction.erc20Token = erc20Token;
        auction.tokenId = tokenId;
        auction.basePrice = basePrice;
        auction.seller = _seller;
        auction.quantity = _amount;
        auction.time = block.timestamp;
        auction.startTime = startTime;
        auction.endTime = endTime;

        itemIdOnAuction[nftAddress][_seller][tokenId] = true;
    }

    function revokeAuction(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external override {
        onlyMedia();
        validAuction(nftAddress, seller, tokenId);
        require(
            nftAuctionItem[nftAddress][seller][tokenId].endTime <
                block.timestamp,
            "Auction is not ended"
        );
        require(
            nftAuctionItem[nftAddress][seller][tokenId].highestBid.bid == 0,
            "Revoke not Allowed"
        );

        itemIdOnAuction[nftAddress][seller][tokenId] = false;
    }

    function validAuction(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) internal view {
        require(
            itemIdOnAuction[nftAddress][seller][tokenId],
            "Market: NFT not on sale"
        );
    }

    function validSale(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) internal view {
        require(
            itemIdOnSale[nftAddress][seller][tokenId],
            "Market: NFT not on sale"
        );
    }
}