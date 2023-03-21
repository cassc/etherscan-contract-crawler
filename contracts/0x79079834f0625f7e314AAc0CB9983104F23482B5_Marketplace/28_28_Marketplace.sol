//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./GameNFT.sol";

interface IPancakeRouter {
    function WETH() external pure returns (address);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

contract Marketplace is ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    IERC20 public BRN;
    IPancakeRouter router;
    AggregatorV3Interface priceFeed;

    bool public allowBRN;

    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    mapping(address => mapping(uint256 => CreatorStruct))
        public tokenToCreatorStruct;

    uint256 listingPrice;

    enum PaymentOptions {
        FixedPrice,
        OpenForBids,
        TimedAuction
    }

    enum PaymentMethod {
        NATIVE_TOKEN,
        BRN_TOKEN
    }

    struct CreatorStruct {
        address payable creator;
        uint256 royalty;
    }

    struct BidStruct {
        address user;
        uint256 amount;
        uint256 itemId;
        bool active;
        bool isAccepted;
        uint256 time;
    }

    struct MarketItem {
        uint256 itemId;
        TokenStandard tokenStandard;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price; // lowest price for open for bids and timed auction
        uint256 inventoryBalance; // inventory balance for items remaining (if ERC721, inventory balance == 1)
        PaymentMethod paymentMethod;
        bool sold;
        PaymentOptions paymentOption;
        uint256 auctionEndTime; // only for timed auction
    }

    mapping(uint256 => MarketItem) private _idToMarketItem;
    mapping(uint256 => BidStruct[]) private _idToBids; // for open for bids and timed auction
    mapping(address => BidStruct[]) private _userToBids; // for user bids

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        PaymentMethod paymentMethod
    );

    event MarketItemSold(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        PaymentMethod paymentMethod
    );

    event MarketItemBidPlaced(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address bidder,
        address seller,
        uint256 amount,
        PaymentMethod paymentMethod
    );

    event MarketItemRemoved(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller
    );

    address[] marketContracts;
    mapping(address => bool) private isMarketContract;

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    enum TokenStandard {
        ERC721,
        ERC1155
    }

    function initialize(
        address _brn,
        address _router,
        address _priceFeed
    ) public initializer {
        listingPrice = 0.0025 ether;
        BRN = IERC20(_brn);
        router = IPancakeRouter(_router);
        priceFeed = AggregatorV3Interface(_priceFeed);
        allowBRN = block.chainid == 56 ? true : false;
        __ReentrancyGuard_init();
        __Ownable_init();
    }

    function getMarketContracts() external view returns (address[] memory) {
        return marketContracts;
    }

    /// @notice - gets ETH/USD price
    /// @return - USD amount
    function getRate() public view returns (uint256, uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function updateListingPrice(uint256 _amount) external onlyOwner {
        listingPrice = _amount;
    }

    function createMarketItem(
        TokenStandard tokenStandard,
        address nftContract,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 price,
        PaymentMethod _paymentMethod,
        PaymentOptions _paymentOption,
        uint256 royalty,
        uint256 _auctionEndTime
    ) public payable nonReentrant {
        if (tokenStandard == TokenStandard.ERC721) {}
        if (_paymentMethod == PaymentMethod.BRN_TOKEN) {
            require(allowBRN == true, "BRN Token is not allowed on this chain");
        }
        require(price > 0, "Price must be at least 1 wei");
        require(
            _paymentOption == PaymentOptions.FixedPrice ||
                _paymentOption == PaymentOptions.OpenForBids ||
                _paymentOption == PaymentOptions.TimedAuction,
            "Invalid payment option"
        );
        if (_paymentOption == PaymentOptions.TimedAuction) {
            require(
                _auctionEndTime > block.timestamp,
                "Auction end time <= now" //Auction end time must be in the future
            );
        }
        require(tokenAmount > 0, "No product"); //Product amount must be at least 1
        require(tokenAmount > 0, "No product"); //Product amount must be at least 1
        uint256 _listingPrice = tokenAmount > 1
            ? tokenAmount * listingPrice
            : listingPrice;

        require(
            msg.value >= _listingPrice,
            "msg.value must be equal greater than listing price"
        );
        require(royalty <= 10, "Royalty must be less than or equal to 10%");
        if (
            (_paymentOption == PaymentOptions.OpenForBids ||
                _paymentOption == PaymentOptions.TimedAuction) &&
            tokenStandard == TokenStandard.ERC1155
        ) {
            require(
                tokenAmount == 1,
                "token amount > 1" //only token with a balance of 1 can be listed on auction
            );
        }
        if (tokenStandard == TokenStandard.ERC721) {
            require(
                tokenAmount == 1,
                "token amount > 1" //ERC721 is one of one
            );
        }

        uint256 itemId = _itemIds.current();

        if (tokenToCreatorStruct[nftContract][tokenId].creator == address(0)) {
            tokenToCreatorStruct[nftContract][tokenId].creator = payable(
                msg.sender
            );
            tokenToCreatorStruct[nftContract][tokenId].royalty = royalty;
        }

        if (!isMarketContract[nftContract]) {
            marketContracts.push(nftContract);
            isMarketContract[nftContract] = true;
        }

        _idToMarketItem[itemId] = MarketItem(
            itemId,
            tokenStandard,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            tokenAmount,
            _paymentMethod,
            false,
            _paymentOption,
            _auctionEndTime
        );

        _itemIds.increment();
        payable(owner()).transfer(msg.value); //listing price sent

        if (tokenStandard == TokenStandard.ERC721) {
            IERC721(nftContract).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId
            );
        } else {
            GameNFT(nftContract).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId,
                tokenAmount,
                "0x00"
            );
        }

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            _paymentMethod
        );
    }

    function removeItemFromMarketplace(uint256 itemId) public nonReentrant {
        MarketItem storage marketItem = _idToMarketItem[itemId];
        require(marketItem.sold == false, "Item is already sold");
        require(
            msg.sender == marketItem.seller,
            "Only seller can remove item from marketplace"
        );
        uint256 tokenAmount = marketItem.inventoryBalance;
        require(tokenAmount > 0, "Out of stock"); //Only remove products that are in stock

        if (
            marketItem.paymentOption == PaymentOptions.TimedAuction ||
            marketItem.paymentOption == PaymentOptions.OpenForBids
        ) {
            BidStruct[] storage itemBidsList = _idToBids[itemId];

            if (itemBidsList.length > 0) {
                require(itemBidsList[itemBidsList.length - 1].active);
                require(
                    itemBidsList[itemBidsList.length - 1].isAccepted == false
                );

                itemBidsList[itemBidsList.length - 1].active = false;

                BidStruct[] storage userBidsList = _userToBids[
                    itemBidsList[itemBidsList.length - 1].user
                ];
                for (uint256 i = 0; i < userBidsList.length; i++) {
                    if (userBidsList[i].itemId == itemId) {
                        userBidsList[i].active = false;
                        break;
                    }
                }

                if (marketItem.paymentMethod == PaymentMethod.NATIVE_TOKEN) {
                    payable(itemBidsList[itemBidsList.length - 1].user)
                        .transfer(itemBidsList[itemBidsList.length - 1].amount);
                } else {
                    BRN.safeTransfer(
                        itemBidsList[itemBidsList.length - 1].user,
                        itemBidsList[itemBidsList.length - 1].amount
                    );
                }
            }
        }

        if (marketItem.tokenStandard == TokenStandard.ERC721) {
            marketItem.owner = payable(msg.sender);
        }
        marketItem.sold = true;

        if (marketItem.tokenStandard == TokenStandard.ERC721) {
            IERC721(marketItem.nftContract).safeTransferFrom(
                address(this),
                marketItem.seller,
                marketItem.tokenId
            );
        } else {
            GameNFT(marketItem.nftContract).safeTransferFrom(
                address(this),
                marketItem.seller,
                marketItem.tokenId,
                tokenAmount,
                ""
            );
        }
        for (uint256 i; i < tokenAmount; i++) {
            _itemsSold.increment();
        }

        emit MarketItemRemoved(
            itemId,
            marketItem.nftContract,
            marketItem.tokenId,
            marketItem.seller
        );
    }

    function createMarketSale(
        uint256 itemId,
        uint256 amount
    ) public payable nonReentrant {
        MarketItem storage marketItem = _idToMarketItem[itemId];
        if (marketItem.paymentMethod == PaymentMethod.NATIVE_TOKEN) {
            require(
                msg.value >= (marketItem.price * amount),
                "msg.value must be equal or greater than price"
            );
        } else {
            require(
                BRN.allowance(msg.sender, address(this)) >=
                    (marketItem.price * amount) &&
                    BRN.balanceOf(msg.sender) >= (marketItem.price * amount),
                "user's BRN must be equal or greater than price"
            );
        }
        require(
            marketItem.paymentOption == PaymentOptions.FixedPrice,
            "can only buy fixed priced items"
        );
        require(
            marketItem.sold == false && marketItem.seller != msg.sender,
            "Item is already sold out or the user is seller"
        );

        marketItem.owner = payable(msg.sender);
        marketItem.sold = true;

        uint256 royaltyFee = tokenToCreatorStruct[marketItem.nftContract][
            marketItem.tokenId
        ].creator != marketItem.seller
            ? (marketItem.price *
                amount *
                tokenToCreatorStruct[marketItem.nftContract][marketItem.tokenId]
                    .royalty) / 100
            : 0;
        if (marketItem.paymentMethod == PaymentMethod.NATIVE_TOKEN) {
            marketItem.seller.transfer(
                (marketItem.price * amount) - royaltyFee
            );
            if (royaltyFee > 0) {
                tokenToCreatorStruct[marketItem.nftContract][marketItem.tokenId]
                    .creator
                    .transfer(royaltyFee);
            }
        } else {
            BRN.safeTransferFrom(
                msg.sender,
                marketItem.seller,
                (marketItem.price * amount) - royaltyFee
            );
            if (royaltyFee > 0) {
                BRN.safeTransferFrom(
                    msg.sender,
                    tokenToCreatorStruct[marketItem.nftContract][
                        marketItem.tokenId
                    ].creator,
                    royaltyFee
                );
            }
        }

        if (marketItem.tokenStandard == TokenStandard.ERC721) {
            IERC721(marketItem.nftContract).safeTransferFrom(
                address(this),
                msg.sender,
                marketItem.tokenId
            );
        } else {
            GameNFT(marketItem.nftContract).safeTransferFrom(
                address(this),
                msg.sender,
                marketItem.tokenId,
                amount,
                "0x00"
            );
        }
        for (uint256 i; i < amount; i++) {
            _itemsSold.increment();
        }

        emit MarketItemSold(
            itemId,
            marketItem.nftContract,
            marketItem.tokenId,
            marketItem.seller,
            msg.sender,
            marketItem.price,
            marketItem.paymentMethod
        );
    }

    function createMarketBid(
        uint256 itemId,
        uint256 bidAmount
    ) public payable nonReentrant {
        MarketItem storage marketItem = _idToMarketItem[itemId];
        require(
            marketItem.paymentOption == PaymentOptions.OpenForBids ||
                marketItem.paymentOption == PaymentOptions.TimedAuction,
            "can only bid for timed auction or open for bid items"
        );
        if (marketItem.paymentOption == PaymentOptions.TimedAuction) {
            require(
                block.timestamp < marketItem.auctionEndTime,
                "timed auction has ended"
            );
        }
        require(
            marketItem.sold == false && marketItem.seller != msg.sender,
            "Item is already sold out or the user is seller"
        );
        BidStruct[] storage itemBidsList = _idToBids[itemId];
        if (itemBidsList.length > 0) {
            if (marketItem.paymentMethod == PaymentMethod.NATIVE_TOKEN) {
                require(bidAmount == msg.value, "bad move");
                require(
                    msg.value > itemBidsList[itemBidsList.length - 1].amount,
                    "bid must be greater than last bid"
                );
            } else {
                require(
                    BRN.allowance(msg.sender, address(this)) >= bidAmount &&
                        BRN.balanceOf(msg.sender) >= bidAmount,
                    "bad move"
                );
                require(
                    bidAmount > itemBidsList[itemBidsList.length - 1].amount,
                    "user's BRN balance must be greater than last bid"
                );
            }
        } else {
            if (marketItem.paymentMethod == PaymentMethod.NATIVE_TOKEN) {
                require(
                    msg.value >= marketItem.price,
                    "bid must be greater than or equal to starting price"
                );
            } else {
                require(
                    BRN.allowance(msg.sender, address(this)) >=
                        marketItem.price &&
                        BRN.balanceOf(msg.sender) >= marketItem.price,
                    "user's BRN balance must be greater than or equal to starting price"
                );
            }
        }
        require(marketItem.sold == false, "Item is already sold");
        if (itemBidsList.length > 0) {
            itemBidsList[itemBidsList.length - 1].active = false;
            BidStruct[] storage userBidsList = _userToBids[
                itemBidsList[itemBidsList.length - 1].user
            ];
            for (uint256 i = 0; i < userBidsList.length; i++) {
                if (userBidsList[i].itemId == itemId) {
                    userBidsList[i].active = false;
                    break;
                }
            }
            if (marketItem.paymentMethod == PaymentMethod.NATIVE_TOKEN) {
                payable(itemBidsList[itemBidsList.length - 1].user).transfer(
                    itemBidsList[itemBidsList.length - 1].amount
                );
            } else {
                BRN.safeTransferFrom(msg.sender, address(this), bidAmount);
                BRN.safeTransfer(
                    itemBidsList[itemBidsList.length - 1].user,
                    itemBidsList[itemBidsList.length - 1].amount
                );
            }
        }
        itemBidsList.push(
            BidStruct(
                msg.sender,
                bidAmount,
                itemId,
                true,
                false,
                block.timestamp
            )
        );
        _userToBids[msg.sender].push(
            BidStruct(
                msg.sender,
                bidAmount,
                itemId,
                true,
                false,
                block.timestamp
            )
        );
        emit MarketItemBidPlaced(
            itemId,
            marketItem.nftContract,
            marketItem.tokenId,
            msg.sender,
            marketItem.seller,
            bidAmount,
            marketItem.paymentMethod
        );
    }

    function acceptBid(uint256 itemId) public nonReentrant {
        MarketItem storage marketItem = _idToMarketItem[itemId];
        require(
            marketItem.paymentOption == PaymentOptions.OpenForBids ||
                marketItem.paymentOption == PaymentOptions.TimedAuction,
            "can only accept bid for timed auction or open for bid items"
        );
        require(marketItem.sold == false, "Item is already sold");
        BidStruct[] storage itemBidsList = _idToBids[itemId];
        require(itemBidsList.length > 0, "no bids to accept");
        require(msg.sender == marketItem.seller, "only seller can accept bid");

        require(itemBidsList[itemBidsList.length - 1].active);
        require(itemBidsList[itemBidsList.length - 1].isAccepted == false);

        itemBidsList[itemBidsList.length - 1].active = false;
        itemBidsList[itemBidsList.length - 1].isAccepted = true;

        BidStruct[] storage userBidsList = _userToBids[
            itemBidsList[itemBidsList.length - 1].user
        ];
        for (uint256 i = 0; i < userBidsList.length; i++) {
            if (userBidsList[i].itemId == itemId) {
                userBidsList[i].active = false;
                userBidsList[i].isAccepted = true;
                break;
            }
        }

        marketItem.owner = payable(itemBidsList[itemBidsList.length - 1].user);
        marketItem.sold = true;

        uint256 royaltyFee = marketItem.seller !=
            tokenToCreatorStruct[marketItem.nftContract][marketItem.tokenId]
                .creator
            ? (itemBidsList[itemBidsList.length - 1].amount *
                tokenToCreatorStruct[marketItem.nftContract][marketItem.tokenId]
                    .royalty) / 100
            : 0;

        if (marketItem.paymentMethod == PaymentMethod.NATIVE_TOKEN) {
            marketItem.seller.transfer(
                itemBidsList[itemBidsList.length - 1].amount - (royaltyFee)
            );
            if (royaltyFee > 0) {
                tokenToCreatorStruct[marketItem.nftContract][marketItem.tokenId]
                    .creator
                    .transfer(royaltyFee);
            }
        } else {
            BRN.safeTransfer(
                marketItem.seller,
                itemBidsList[itemBidsList.length - 1].amount - royaltyFee
            );
            if (royaltyFee > 0) {
                BRN.safeTransfer(
                    tokenToCreatorStruct[marketItem.nftContract][
                        marketItem.tokenId
                    ].creator,
                    royaltyFee
                );
            }
        }

        if (marketItem.tokenStandard == TokenStandard.ERC721) {
            IERC721(marketItem.nftContract).safeTransferFrom(
                address(this),
                itemBidsList[itemBidsList.length - 1].user,
                marketItem.tokenId
            );
        } else {
            GameNFT(marketItem.nftContract).safeTransferFrom(
                address(this),
                itemBidsList[itemBidsList.length - 1].user,
                marketItem.tokenId,
                1,
                "0x00"
            );
        }
        _itemsSold.increment();

        emit MarketItemSold(
            itemId,
            marketItem.nftContract,
            marketItem.tokenId,
            marketItem.seller,
            itemBidsList[itemBidsList.length - 1].user,
            itemBidsList[itemBidsList.length - 1].amount,
            marketItem.paymentMethod
        );
    }

    function claimExpiredTimedAuctionItem(uint256 itemId) public nonReentrant {
        MarketItem storage marketItem = _idToMarketItem[itemId];
        require(
            marketItem.paymentOption == PaymentOptions.TimedAuction,
            "can only claim expired timed auction items"
        );
        require(marketItem.sold == false, "Item is already sold");
        require(
            block.timestamp > marketItem.auctionEndTime,
            "auction is not expired"
        );

        BidStruct[] storage itemBidsList = _idToBids[itemId];
        require(itemBidsList.length > 0, "no bids for item");
        require(itemBidsList[itemBidsList.length - 1].active);
        require(
            msg.sender == itemBidsList[itemBidsList.length - 1].user,
            "only currently active bidder can claim item"
        );

        itemBidsList[itemBidsList.length - 1].active = false;
        itemBidsList[itemBidsList.length - 1].isAccepted = true;

        BidStruct[] storage userBidsList = _userToBids[
            itemBidsList[itemBidsList.length - 1].user
        ];
        for (uint256 i = 0; i < userBidsList.length; i++) {
            if (userBidsList[i].itemId == itemId) {
                userBidsList[i].active = false;
                userBidsList[i].isAccepted = true;
                break;
            }
        }

        marketItem.owner = payable(itemBidsList[itemBidsList.length - 1].user);
        marketItem.sold = true;

        uint256 royaltyFee = marketItem.seller !=
            tokenToCreatorStruct[marketItem.nftContract][marketItem.tokenId]
                .creator
            ? (itemBidsList[itemBidsList.length - 1].amount *
                tokenToCreatorStruct[marketItem.nftContract][marketItem.tokenId]
                    .royalty) / 100
            : 0;

        if (marketItem.paymentMethod == PaymentMethod.NATIVE_TOKEN) {
            marketItem.seller.transfer(
                itemBidsList[itemBidsList.length - 1].amount - royaltyFee
            );
            if (royaltyFee > 0) {
                tokenToCreatorStruct[marketItem.nftContract][marketItem.tokenId]
                    .creator
                    .transfer(royaltyFee);
            }
        } else {
            BRN.safeTransfer(
                marketItem.seller,
                itemBidsList[itemBidsList.length - 1].amount - royaltyFee
            );
            if (royaltyFee > 0) {
                BRN.safeTransfer(
                    tokenToCreatorStruct[marketItem.nftContract][
                        marketItem.tokenId
                    ].creator,
                    royaltyFee
                );
            }
        }

        if (marketItem.tokenStandard == TokenStandard.ERC721) {
            IERC721(marketItem.nftContract).safeTransferFrom(
                address(this),
                msg.sender,
                marketItem.tokenId
            );
        } else {
            GameNFT(marketItem.nftContract).safeTransferFrom(
                address(this),
                msg.sender,
                marketItem.tokenId,
                1,
                "0x00"
            );
        }
        _itemsSold.increment();

        emit MarketItemSold(
            itemId,
            marketItem.nftContract,
            marketItem.tokenId,
            marketItem.seller,
            itemBidsList[itemBidsList.length - 1].user,
            itemBidsList[itemBidsList.length - 1].amount,
            marketItem.paymentMethod
        );
    }

    function fetchMarketItemBids(
        uint256 itemId
    ) public view returns (BidStruct[] memory) {
        return _idToBids[itemId];
    }

    /*
    function fetchMyActiveBids() public view returns (BidStruct[] memory) {
        BidStruct[] memory userBidsList = _userToBids[msg.sender];

        uint256 itemCount;
        uint256 index = 0;

        for (uint256 i = 0; i < userBidsList.length; i++) {
            if (userBidsList[i].active && !userBidsList[i].isAccepted) {
                itemCount++;
            }
        }

        BidStruct[] memory items = new BidStruct[](itemCount);
        for (uint256 i = 0; i < userBidsList.length; i++) {
            if (userBidsList[i].active && !userBidsList[i].isAccepted) {
                items[index] = userBidsList[i];
                index++;
            }
        }

        return items;
    }
    */

    function fetchMarketItems() public view returns (MarketItem[] memory) {
        MarketItem[] memory marketItems = new MarketItem[](
            _itemIds.current() - _itemsSold.current()
        );
        uint256 index = 0;

        for (uint256 i = 0; i < _itemIds.current(); i++) {
            MarketItem memory marketItem = _idToMarketItem[i];
            if (!marketItem.sold && marketItem.owner == address(0)) {
                marketItems[index] = _idToMarketItem[marketItem.itemId];
                index++;
            }
        }
        return marketItems;
    }

    function getCollectionSalesData(
        address nftContract
    ) public view returns (uint256 floorPrice, uint256 totalSalesUSD) {
        uint256 totalSalesAmount;
        for (uint256 i = 0; i < _itemIds.current(); i++) {
            MarketItem memory marketItem = _idToMarketItem[i];
            if (marketItem.nftContract == nftContract) {
                if (marketItem.price < floorPrice || floorPrice == 0) {
                    floorPrice = marketItem.price;
                }
                if (
                    marketItem.sold &&
                    marketItem.owner != address(0) &&
                    marketItem.owner != marketItem.seller
                ) {
                    if (marketItem.paymentOption == PaymentOptions.FixedPrice) {
                        if (
                            marketItem.paymentMethod ==
                            PaymentMethod.NATIVE_TOKEN
                        ) {
                            totalSalesAmount += marketItem.price;
                        } else {
                            address[] memory path = new address[](2);
                            path[0] = address(BRN);
                            path[1] = router.WETH();
                            uint[] memory itemPriceETH = router.getAmountsOut(
                                marketItem.price,
                                path
                            );
                            totalSalesAmount += itemPriceETH[1];
                        }
                    } else {
                        BidStruct[] storage itemBidsList = _idToBids[
                            marketItem.itemId
                        ];
                        totalSalesAmount += itemBidsList[
                            itemBidsList.length - 1
                        ].amount;
                    }
                }
            }
        }
        if (totalSalesAmount > 0) {
            (uint256 price, uint256 decimals) = getRate();
            totalSalesUSD = (totalSalesAmount * price) / (10 ** decimals);
        } else {
            totalSalesUSD = 0;
        }
    }

    /*
    function fetchUserCollectedNFTCollections(address user)
        public
        view
        returns (address[] memory)
    {
        uint256 itemCount;
        uint256 index;

        for (uint256 i = 0; i < _itemIds.current(); i++) {
            MarketItem memory marketItem = _idToMarketItem[i];
            if (
                ((marketItem.seller == user && !marketItem.sold) ||
                    user ==
                    IERC721(marketItem.nftContract).ownerOf(
                        marketItem.tokenId
                    )) &&
                tokenToCreatorStruct[marketItem.nftContract][marketItem.tokenId]
                    .creator !=
                user
            ) {
                itemCount++;
            }
        }

        address[] memory collectedCollections = new address[](itemCount);
        for (uint256 i; i < _itemIds.current(); i++) {
            MarketItem memory marketItem = _idToMarketItem[i];
            if (
                ((marketItem.seller == user && !marketItem.sold) ||
                    user ==
                    IERC721(marketItem.nftContract).ownerOf(
                        marketItem.tokenId
                    )) &&
                tokenToCreatorStruct[marketItem.nftContract][marketItem.tokenId]
                    .creator !=
                user
            ) {
                collectedCollections[index] = _idToMarketItem[marketItem.itemId]
                    .nftContract;
                index++;
            }
        }

        return collectedCollections;
    }
    */

    function fetchMarketItemsFromCollection(
        address collectionAddress
    ) public view returns (MarketItem[] memory) {
        uint256 itemCount;
        uint256 index;

        for (uint256 i = 0; i < _itemIds.current(); i++) {
            MarketItem memory marketItem = _idToMarketItem[i];
            if (
                marketItem.nftContract == collectionAddress &&
                !marketItem.sold &&
                marketItem.owner == address(0)
            ) {
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i; i < _itemIds.current(); i++) {
            MarketItem memory marketItem = _idToMarketItem[i];
            if (
                marketItem.nftContract == collectionAddress &&
                !marketItem.sold &&
                marketItem.owner == address(0)
            ) {
                items[index] = _idToMarketItem[marketItem.itemId];
                index++;
            }
        }

        return items;
    }

    /*
    function fetchUserNFTsFromCollection(
        address collectionAddress,
        address user
    ) public view returns (MarketItem[] memory) {
        uint256 itemCount;
        uint256 index;

        for (uint256 i = 0; i < _itemIds.current(); i++) {
            MarketItem memory marketItem = _idToMarketItem[i];
            
            //if (
            //    marketItem.nftContract == collectionAddress &&
            //    ((marketItem.seller == user && !marketItem.sold) ||
            //        user ==
            //        IERC721(marketItem.nftContract).ownerOf(marketItem.tokenId))
            //) {
            //    itemCount++;
            //}
            if (
                marketItem.nftContract == collectionAddress &&
                (marketItem.seller == user && !marketItem.sold)
            ) {
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i; i < _itemIds.current(); i++) {
            MarketItem memory marketItem = _idToMarketItem[i];
            //if (
            //    marketItem.nftContract == collectionAddress &&
            //    ((marketItem.seller == user && !marketItem.sold) ||
            //        user ==
            //        IERC721(marketItem.nftContract).ownerOf(marketItem.tokenId))
            //) {
            //    items[index] = _idToMarketItem[marketItem.itemId];
            //    index++;
            //}
            if (
                marketItem.nftContract == collectionAddress &&
                (marketItem.seller == user && !marketItem.sold)
            ) {
                items[index] = _idToMarketItem[marketItem.itemId];
                index++;
            }
        }

        return items;
    }
    */

    function fetchNFTDetailsFromMarket(
        address nftContract,
        uint256 tokenId
    ) public view returns (MarketItem memory) {
        MarketItem memory nft;
        for (uint256 i = 0; i < _itemIds.current(); i++) {
            MarketItem memory marketItem = _idToMarketItem[i];
            if (
                nftContract == marketItem.nftContract &&
                tokenId == marketItem.tokenId &&
                !marketItem.sold &&
                marketItem.owner == address(0)
            ) {
                nft = marketItem;
                break;
            }
        }
        return nft;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return (interfaceId == _INTERFACE_ID_ERC165 ||
            interfaceId == _INTERFACE_ID_ERC1155);
    }
}