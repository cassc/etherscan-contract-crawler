//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./GameNFT.sol";

import "./interface/IMarketStateManager.sol";

contract EthMartAttach {
    constructor(address payable mart) payable {
        mart.transfer(msg.value);
    }
}

contract Market is ReentrancyGuardUpgradeable, OwnableUpgradeable {
    IMarketStateManager private marketStateManagerAddress; //MARKET STATE MANAGER CONTRACT ADDRESS

    using SafeERC20 for IERC20;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        Types.PaymentMethod paymentMethod
    );

    event MarketItemSold(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        Types.PaymentMethod paymentMethod
    );

    event MarketItemBidPlaced(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address bidder,
        address seller,
        uint256 amount,
        Types.PaymentMethod paymentMethod
    );

    event MarketItemRemoved(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller
    );

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    function updateStateManagerAddress(
        address _newMarketStateManagerAddress
    ) external onlyOwner {
        marketStateManagerAddress = IMarketStateManager(
            _newMarketStateManagerAddress
        );
    }

    function getListingPrice() external view returns (uint256) {
        return marketStateManagerAddress.getListingPrice();
    }

    function getMarketContracts() external view returns (address[] memory) {
        return marketStateManagerAddress.getMarketContracts();
    }

    function createMarketItem(
        Types.TokenStandard tokenStandard,
        address nftContract,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 price,
        Types.PaymentMethod _paymentMethod,
        Types.PaymentOptions _paymentOption,
        uint256 royalty,
        uint256 _auctionEndTime
    ) public payable nonReentrant {
        if (tokenStandard == Types.TokenStandard.ERC721) {}
        if (_paymentMethod == Types.PaymentMethod.BRN_TOKEN) {
            require(
                (marketStateManagerAddress.allowBRN()) == true,
                "BRN Token is not allowed on this chain"
            );
        }
        require(price > 0, "Price must be at least 1 wei");
        require(
            _paymentOption == Types.PaymentOptions.FixedPrice ||
                _paymentOption == Types.PaymentOptions.OpenForBids ||
                _paymentOption == Types.PaymentOptions.TimedAuction,
            "Invalid payment option"
        );
        if (_paymentOption == Types.PaymentOptions.TimedAuction) {
            require(
                _auctionEndTime > block.timestamp,
                "Auction end time <= now" //Auction end time must be in the future
            );
        }
        require(tokenAmount > 0, "No product"); //Product amount must be at least 1
        require(tokenAmount > 0, "No product"); //Product amount must be at least 1
        uint256 _listingPrice = tokenAmount > 1
            ? tokenAmount * marketStateManagerAddress.getListingPrice()
            : marketStateManagerAddress.getListingPrice();

        require(
            msg.value >= _listingPrice,
            "msg.value must be equal greater than listing price"
        );
        require(royalty <= 10, "Royalty must be less than or equal to 10%");
        if (
            (_paymentOption == Types.PaymentOptions.OpenForBids ||
                _paymentOption == Types.PaymentOptions.TimedAuction) &&
            tokenStandard == Types.TokenStandard.ERC1155
        ) {
            require(
                tokenAmount == 1,
                "token amount > 1" //only token with a balance of 1 can be listed on auction
            );
        }
        if (tokenStandard == Types.TokenStandard.ERC721) {
            require(
                tokenAmount == 1,
                "token amount > 1" //ERC721 is one of one
            );
        }

        uint256 itemId = marketStateManagerAddress.getItemsCount();

        IMarketStateManager.CreatorStruct
            memory tokenToCreatorStruct = marketStateManagerAddress
                .getTokenToCreatorStruct(nftContract, tokenId);
        if (tokenToCreatorStruct.creator == address(0)) {
            marketStateManagerAddress.updateTokenToCreatorStruct(
                msg.sender,
                nftContract,
                tokenId,
                royalty
            );
        }

        if (!marketStateManagerAddress.getIsMarketContract(nftContract)) {
            marketStateManagerAddress.updateMarketContractsList(nftContract);
        }

        IMarketStateManager.MarketItemStruct
            memory marketItemInstance = IMarketStateManager.MarketItemStruct(
                itemId,
                tokenStandard,
                nftContract,
                tokenId,
                payable(msg.sender),
                payable(address(0)),
                price,
                tokenAmount,
                tokenAmount,
                _paymentMethod,
                false,
                0,
                _paymentOption,
                _auctionEndTime
            );

        marketStateManagerAddress.addItemIdToMarketplaceMapping(
            itemId,
            marketItemInstance
        );

        marketStateManagerAddress.updateItemsCount();
        payable(owner()).transfer(msg.value); //listing price sent

        if (tokenStandard == Types.TokenStandard.ERC721) {
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
        IMarketStateManager.MarketItemStruct
            memory marketItem = marketStateManagerAddress
                .getItemIdToMarketplaceMapping(itemId);
        require(marketItem.sold == false, "Item is already sold");
        require(
            msg.sender == marketItem.seller,
            "Only seller can remove item from marketplace"
        );
        uint256 tokenAmount = marketItem.inventoryBalance;
        require(tokenAmount > 0, "Out of stock"); //Only remove products that are in stock

        if (
            marketItem.paymentOption == Types.PaymentOptions.TimedAuction ||
            marketItem.paymentOption == Types.PaymentOptions.OpenForBids
        ) {
            IMarketStateManager.BidStruct[]
                memory itemBidsList = marketStateManagerAddress.getItemBids(
                    itemId
                );

            if (itemBidsList.length > 0) {
                require(itemBidsList[itemBidsList.length - 1].active);
                require(
                    itemBidsList[itemBidsList.length - 1].isAccepted == false
                );

                marketStateManagerAddress.updateItemBidStatus(
                    itemId,
                    itemBidsList.length - 1,
                    false
                );

                IMarketStateManager.BidStruct[]
                    memory userBidsList = marketStateManagerAddress.getUserBids(
                        itemBidsList[itemBidsList.length - 1].user
                    );
                for (uint256 i = 0; i < userBidsList.length; i++) {
                    if (userBidsList[i].itemId == itemId) {
                        marketStateManagerAddress.updateUserBidStatus(
                            itemBidsList[itemBidsList.length - 1].user,
                            i,
                            false
                        );
                        break;
                    }
                }

                if (
                    marketItem.paymentMethod == Types.PaymentMethod.NATIVE_TOKEN
                ) {
                    payable(itemBidsList[itemBidsList.length - 1].user)
                        .transfer(itemBidsList[itemBidsList.length - 1].amount);
                } else {
                    IERC20(marketStateManagerAddress.BRN()).safeTransfer(
                        itemBidsList[itemBidsList.length - 1].user,
                        itemBidsList[itemBidsList.length - 1].amount
                    );
                }
            }
        }

        if (marketItem.tokenStandard == Types.TokenStandard.ERC721) {
            marketItem.owner = payable(msg.sender); // updated marketItem with updateItemIdToMarketplaceMapping
        }
        marketItem.sold = true; // updated marketItem with updateItemIdToMarketplaceMapping

        marketStateManagerAddress.updateItemIdToMarketplaceMapping(
            itemId,
            marketItem
        );

        if (marketItem.tokenStandard == Types.TokenStandard.ERC721) {
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
        marketStateManagerAddress.updateSoldItemsCount();

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
        IMarketStateManager.MarketItemStruct
            memory marketItem = marketStateManagerAddress
                .getItemIdToMarketplaceMapping(itemId);
        if (marketItem.paymentMethod == Types.PaymentMethod.NATIVE_TOKEN) {
            require(
                msg.value >= (marketItem.price * amount),
                "msg.value must be equal or greater than price"
            );
        } else {
            require(
                IERC20(marketStateManagerAddress.BRN()).allowance(
                    msg.sender,
                    address(this)
                ) >=
                    (marketItem.price * amount) &&
                    IERC20(marketStateManagerAddress.BRN()).balanceOf(
                        msg.sender
                    ) >=
                    (marketItem.price * amount),
                "user's BRN must be equal or greater than price"
            );
        }
        require(
            marketItem.paymentOption == Types.PaymentOptions.FixedPrice,
            "can only buy fixed priced items"
        );
        require(
            marketItem.sold == false && marketItem.seller != msg.sender,
            "Item is already sold out or the user is seller"
        );

        if (marketItem.tokenStandard == Types.TokenStandard.ERC721) {
            marketItem.owner = payable(msg.sender);
            marketItem.sold = true;
            marketItem.numSold = 1;
            marketStateManagerAddress.updateSoldItemsCount();
        } else {
            require(marketItem.inventoryBalance >= amount, "Out of stock");
            marketItem.inventoryBalance = marketItem.inventoryBalance - amount;
            marketItem.numSold = marketItem.numSold + amount;
            if (marketItem.inventoryBalance == 0) {
                marketItem.sold = true;
                marketStateManagerAddress.updateSoldItemsCount();
            }
        }

        marketStateManagerAddress.updateItemIdToMarketplaceMapping(
            itemId,
            marketItem
        );

        IMarketStateManager.CreatorStruct
            memory tokenToCreatorStruct = marketStateManagerAddress
                .getTokenToCreatorStruct(
                    marketItem.nftContract,
                    marketItem.tokenId
                );

        uint256 royaltyFee = tokenToCreatorStruct.creator != marketItem.seller
            ? (marketItem.price * amount * tokenToCreatorStruct.royalty) / 100
            : 0;

        uint salesCommission = marketStateManagerAddress.getSalesCommission();

        uint commission = (marketItem.price * amount * salesCommission) / 1000;
        if (marketItem.paymentMethod == Types.PaymentMethod.NATIVE_TOKEN) {
            marketItem.seller.transfer(
                (marketItem.price * amount) - royaltyFee - commission
            );
            if (royaltyFee > 0) {
                tokenToCreatorStruct.creator.transfer(royaltyFee);
            }
            payable(owner()).transfer(commission);
        } else {
            IERC20(marketStateManagerAddress.BRN()).safeTransferFrom(
                msg.sender,
                marketItem.seller,
                (marketItem.price * amount) - royaltyFee - commission
            );
            if (royaltyFee > 0) {
                IERC20(marketStateManagerAddress.BRN()).safeTransferFrom(
                    msg.sender,
                    tokenToCreatorStruct.creator,
                    royaltyFee
                );
            }
            IERC20(marketStateManagerAddress.BRN()).safeTransferFrom(
                msg.sender,
                owner(),
                commission
            );
        }

        if (marketItem.tokenStandard == Types.TokenStandard.ERC721) {
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
        IMarketStateManager.MarketItemStruct
            memory marketItem = marketStateManagerAddress
                .getItemIdToMarketplaceMapping(itemId);
        require(
            marketItem.paymentOption == Types.PaymentOptions.OpenForBids ||
                marketItem.paymentOption == Types.PaymentOptions.TimedAuction,
            "can only bid for timed auction or open for bid items"
        );
        if (marketItem.paymentOption == Types.PaymentOptions.TimedAuction) {
            require(
                block.timestamp < marketItem.auctionEndTime,
                "timed auction has ended"
            );
        }
        require(
            marketItem.sold == false && marketItem.seller != msg.sender,
            "Item is already sold out or the user is seller"
        );
        IMarketStateManager.BidStruct[]
            memory itemBidsList = marketStateManagerAddress.getItemBids(itemId);
        if (itemBidsList.length > 0) {
            if (marketItem.paymentMethod == Types.PaymentMethod.NATIVE_TOKEN) {
                require(bidAmount == msg.value, "bad move");
                require(
                    msg.value > itemBidsList[itemBidsList.length - 1].amount,
                    "bid must be greater than last bid"
                );
            } else {
                require(
                    IERC20(marketStateManagerAddress.BRN()).allowance(
                        msg.sender,
                        address(this)
                    ) >=
                        bidAmount &&
                        IERC20(marketStateManagerAddress.BRN()).balanceOf(
                            msg.sender
                        ) >=
                        bidAmount,
                    "bad move"
                );
                require(
                    bidAmount > itemBidsList[itemBidsList.length - 1].amount,
                    "user's BRN balance must be greater than last bid"
                );
            }
        } else {
            if (marketItem.paymentMethod == Types.PaymentMethod.NATIVE_TOKEN) {
                require(
                    msg.value >= marketItem.price,
                    "bid must be greater than or equal to starting price"
                );
            } else {
                require(
                    IERC20(marketStateManagerAddress.BRN()).allowance(
                        msg.sender,
                        address(this)
                    ) >=
                        marketItem.price &&
                        IERC20(marketStateManagerAddress.BRN()).balanceOf(
                            msg.sender
                        ) >=
                        marketItem.price,
                    "user's BRN balance must be greater than or equal to starting price"
                );
            }
        }
        require(marketItem.sold == false, "Item is already sold");
        if (itemBidsList.length > 0) {
            marketStateManagerAddress.updateItemBidStatus(
                itemId,
                itemBidsList.length - 1,
                false
            );

            IMarketStateManager.BidStruct[]
                memory userBidsList = marketStateManagerAddress.getUserBids(
                    itemBidsList[itemBidsList.length - 1].user
                );
            for (uint256 i = 0; i < userBidsList.length; i++) {
                if (userBidsList[i].itemId == itemId) {
                    marketStateManagerAddress.updateUserBidStatus(
                        itemBidsList[itemBidsList.length - 1].user,
                        i,
                        false
                    );
                    break;
                }
            }
            if (marketItem.paymentMethod == Types.PaymentMethod.NATIVE_TOKEN) {
                payable(itemBidsList[itemBidsList.length - 1].user).transfer(
                    itemBidsList[itemBidsList.length - 1].amount
                );
            } else {
                IERC20(marketStateManagerAddress.BRN()).safeTransferFrom(
                    msg.sender,
                    address(this),
                    bidAmount
                );
                IERC20(marketStateManagerAddress.BRN()).safeTransfer(
                    itemBidsList[itemBidsList.length - 1].user,
                    itemBidsList[itemBidsList.length - 1].amount
                );
            }
        } else {
            if (marketItem.paymentMethod == Types.PaymentMethod.BRN_TOKEN) {
                IERC20(marketStateManagerAddress.BRN()).safeTransferFrom(
                    msg.sender,
                    address(this),
                    bidAmount
                );
            }
        }
        marketStateManagerAddress.addItemBid(
            itemId,
            IMarketStateManager.BidStruct(
                msg.sender,
                bidAmount,
                itemId,
                true,
                false,
                block.timestamp
            )
        );
        marketStateManagerAddress.addUserBid(
            msg.sender,
            IMarketStateManager.BidStruct(
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
        IMarketStateManager.MarketItemStruct
            memory marketItem = marketStateManagerAddress
                .getItemIdToMarketplaceMapping(itemId);
        require(
            marketItem.paymentOption == Types.PaymentOptions.OpenForBids ||
                marketItem.paymentOption == Types.PaymentOptions.TimedAuction,
            "can only accept bid for timed auction or open for bid items"
        );
        require(marketItem.sold == false, "Item is already sold");
        IMarketStateManager.BidStruct[]
            memory itemBidsList = marketStateManagerAddress.getItemBids(itemId);
        require(itemBidsList.length > 0, "no bids to accept");
        require(msg.sender == marketItem.seller, "only seller can accept bid");

        require(itemBidsList[itemBidsList.length - 1].active);
        require(itemBidsList[itemBidsList.length - 1].isAccepted == false);

        marketStateManagerAddress.updateItemBidStatus(
            itemId,
            itemBidsList.length - 1,
            false
        );
        marketStateManagerAddress.updateItemBidAccepted(
            itemId,
            itemBidsList.length - 1,
            true
        );

        IMarketStateManager.BidStruct[]
            memory userBidsList = marketStateManagerAddress.getUserBids(
                itemBidsList[itemBidsList.length - 1].user
            );
        for (uint256 i = 0; i < userBidsList.length; i++) {
            if (userBidsList[i].itemId == itemId) {
                marketStateManagerAddress.updateUserBidStatus(
                    itemBidsList[itemBidsList.length - 1].user,
                    i,
                    false
                );
                marketStateManagerAddress.updateUserBidAccepted(
                    itemBidsList[itemBidsList.length - 1].user,
                    i,
                    true
                );
                break;
            }
        }

        marketItem.owner = payable(itemBidsList[itemBidsList.length - 1].user);
        marketItem.sold = true;
        marketItem.numSold = 1;

        marketStateManagerAddress.updateItemIdToMarketplaceMapping(
            itemId,
            marketItem
        );

        IMarketStateManager.CreatorStruct
            memory tokenToCreatorStruct = marketStateManagerAddress
                .getTokenToCreatorStruct(
                    marketItem.nftContract,
                    marketItem.tokenId
                );

        uint256 royaltyFee = marketItem.seller != tokenToCreatorStruct.creator
            ? (itemBidsList[itemBidsList.length - 1].amount *
                tokenToCreatorStruct.royalty) / 100
            : 0;

        uint salesCommission = marketStateManagerAddress.getSalesCommission();

        uint commission = (itemBidsList[itemBidsList.length - 1].amount *
            salesCommission) / 1000;
        if (marketItem.paymentMethod == Types.PaymentMethod.NATIVE_TOKEN) {
            marketItem.seller.transfer(
                itemBidsList[itemBidsList.length - 1].amount -
                    (royaltyFee) -
                    commission
            );
            if (royaltyFee > 0) {
                tokenToCreatorStruct.creator.transfer(royaltyFee);
            }
            payable(owner()).transfer(commission);
        } else {
            IERC20(marketStateManagerAddress.BRN()).safeTransfer(
                marketItem.seller,
                itemBidsList[itemBidsList.length - 1].amount -
                    royaltyFee -
                    commission
            );
            if (royaltyFee > 0) {
                IERC20(marketStateManagerAddress.BRN()).safeTransfer(
                    tokenToCreatorStruct.creator,
                    royaltyFee
                );
            }
            IERC20(marketStateManagerAddress.BRN()).safeTransfer(
                owner(),
                commission
            );
        }

        if (marketItem.tokenStandard == Types.TokenStandard.ERC721) {
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
        marketStateManagerAddress.updateSoldItemsCount();

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
        IMarketStateManager.MarketItemStruct
            memory marketItem = marketStateManagerAddress
                .getItemIdToMarketplaceMapping(itemId);
        require(
            marketItem.paymentOption == Types.PaymentOptions.TimedAuction,
            "can only claim expired timed auction items"
        );
        require(marketItem.sold == false, "Item is already sold");
        require(
            block.timestamp > marketItem.auctionEndTime,
            "auction is not expired"
        );
        IMarketStateManager.BidStruct[]
            memory itemBidsList = marketStateManagerAddress.getItemBids(itemId);
        require(itemBidsList.length > 0, "no bids for item");
        require(itemBidsList[itemBidsList.length - 1].active);
        require(
            msg.sender == itemBidsList[itemBidsList.length - 1].user,
            "only currently active bidder can claim item"
        );

        marketStateManagerAddress.updateItemBidStatus(
            itemId,
            itemBidsList.length - 1,
            false
        );
        marketStateManagerAddress.updateItemBidAccepted(
            itemId,
            itemBidsList.length - 1,
            true
        );

        IMarketStateManager.BidStruct[]
            memory userBidsList = marketStateManagerAddress.getUserBids(
                itemBidsList[itemBidsList.length - 1].user
            );
        for (uint256 i = 0; i < userBidsList.length; i++) {
            if (userBidsList[i].itemId == itemId) {
                marketStateManagerAddress.updateUserBidStatus(
                    itemBidsList[itemBidsList.length - 1].user,
                    i,
                    false
                );
                marketStateManagerAddress.updateUserBidAccepted(
                    itemBidsList[itemBidsList.length - 1].user,
                    i,
                    true
                );
                break;
            }
        }

        marketItem.owner = payable(itemBidsList[itemBidsList.length - 1].user);
        marketItem.sold = true;
        marketItem.numSold = 1;

        marketStateManagerAddress.updateItemIdToMarketplaceMapping(
            itemId,
            marketItem
        );

        IMarketStateManager.CreatorStruct
            memory tokenToCreatorStruct = marketStateManagerAddress
                .getTokenToCreatorStruct(
                    marketItem.nftContract,
                    marketItem.tokenId
                );

        uint256 royaltyFee = marketItem.seller != tokenToCreatorStruct.creator
            ? (itemBidsList[itemBidsList.length - 1].amount *
                tokenToCreatorStruct.royalty) / 100
            : 0;

        uint salesCommission = marketStateManagerAddress.getSalesCommission();

        uint commission = (itemBidsList[itemBidsList.length - 1].amount *
            salesCommission) / 1000;
        if (marketItem.paymentMethod == Types.PaymentMethod.NATIVE_TOKEN) {
            marketItem.seller.transfer(
                itemBidsList[itemBidsList.length - 1].amount -
                    royaltyFee -
                    commission
            );
            if (royaltyFee > 0) {
                tokenToCreatorStruct.creator.transfer(royaltyFee);
            }
            payable(owner()).transfer(commission);
        } else {
            IERC20(marketStateManagerAddress.BRN()).safeTransfer(
                marketItem.seller,
                itemBidsList[itemBidsList.length - 1].amount -
                    royaltyFee -
                    commission
            );
            if (royaltyFee > 0) {
                IERC20(marketStateManagerAddress.BRN()).safeTransfer(
                    tokenToCreatorStruct.creator,
                    royaltyFee
                );
            }
            IERC20(marketStateManagerAddress.BRN()).safeTransfer(
                owner(),
                commission
            );
        }

        if (marketItem.tokenStandard == Types.TokenStandard.ERC721) {
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
        marketStateManagerAddress.updateSoldItemsCount();

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
    ) public view returns (IMarketStateManager.BidStruct[] memory bidsList) {
        bidsList = marketStateManagerAddress.getItemBids(itemId);
    }

    function fetchMarketItems()
        public
        view
        returns (IMarketStateManager.MarketItemStruct[] memory)
    {
        return marketStateManagerAddress.fetchMarketItems();
    }

    function getCollectionSalesData(
        address nftContract
    ) public view returns (uint256 floorPrice, uint256 totalSalesUSD) {
        return marketStateManagerAddress.getCollectionSalesData(nftContract);
    }

    function fetchMarketItemsFromCollection(
        address collectionAddress
    ) public view returns (IMarketStateManager.MarketItemStruct[] memory) {
        return
            marketStateManagerAddress.fetchMarketItemsFromCollection(
                collectionAddress
            );
    }

    function fetchNFTDetailsFromMarket(
        address nftContract,
        uint256 tokenId
    ) public view returns (IMarketStateManager.MarketItemStruct[] memory) {
        return
            marketStateManagerAddress.fetchNFTDetailsFromMarket(
                nftContract,
                tokenId
            );
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