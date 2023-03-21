/**
 *     ___  ________      ___    ___ ________
 *    |\  \|\   __  \    |\  \  /  /|\   ___  \
 *    \ \  \ \  \|\  \   \ \  \/  / | \  \\ \  \
 *  __ \ \  \ \  \\\  \   \ \    / / \ \  \\ \  \
 * |\  \\_\  \ \  \\\  \   \/  /  /   \ \  \\ \  \
 * \ \________\ \_______\__/  / /      \ \__\\ \__\
 *  \|________|\|_______|\___/ /        \|__| \|__|
 *                      \|___|/
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IRoyaltyEngineV1.sol";
import "../interfaces/IJoynMarketplace.sol";
import "../interfaces/IWETH9.sol";

error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error ItemNotForSale(address nftAddress, uint256 tokenId);
error NotListed(address nftAddress, uint256 tokenId);
error AlreadyListed(address nftAddress, uint256 tokenId);
error NotOwner();
error NotListingOwner();
error NotApprovedForMarketplace();
error PriceMustBeAboveZero();
error MarketplaceFeeExceedsLimit();
error TransferEthFailed();
error TransferProceedsToSellerFailed();
error ProceedWithdrawalFailed();
error FeesHigherThanSalePrice();

contract JoynMarketplace is
    IJoynMarketplace,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    uint256 public constant PERCENTAGE_DIVIDER = 10000;

    uint256 private s_marketplaceFee;

    uint256 private listingCount;

    // State Variables
    mapping(address => mapping(uint256 => Listing)) private s_listings;
    IRoyaltyEngineV1 _royaltyEngine;
    IWETH9 weth;

    uint32 public referrerFee;

    uint32 public constant MAX_MARKETPLACE_FEE = 10000;

    modifier isTokenOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721Upgradeable nft = IERC721Upgradeable(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NotOwner();
        }
        _;
    }

    modifier isListingOwner(
        address seller,
        address nftAddress,
        uint256 tokenId
    ) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (seller != listing.seller) {
            revert NotListingOwner();
        }
        _;
    }

    function initialize() external initializer {
        __Context_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        referrerFee = 420;
    }

    function _validateListing(
        address nftAddress,
        uint256 tokenId,
        bool shouldListed,
        address seller
    ) private view {
        Listing storage listing = s_listings[nftAddress][tokenId];
        if (shouldListed) {
            if (listing.price == 0) {
                revert NotListed(nftAddress, tokenId);
            }
        } else {
            if (listing.price != 0 && listing.seller == seller) {
                revert AlreadyListed(nftAddress, tokenId);
            }
        }
    }

    function _distributeRoyalties(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 listingId
    ) private returns (uint256) {
        (
            address payable[] memory recipients,
            uint256[] memory amounts
        ) = _royaltyEngine.getRoyaltyView(address(nftAddress), tokenId, price);

        address payable receiver;
        uint256 sumOfRoyalties;
        uint256 royalty;
        for (uint i = 0; i < recipients.length; ++i) {
            receiver = recipients[i];
            if (receiver != address(0)) {
                royalty = amounts[i];
                sumOfRoyalties += royalty;

                transferEth(receiver, royalty);

                emit RoyaltyTransfered(
                    receiver,
                    royalty,
                    tokenId,
                    nftAddress,
                    listingId
                );
            }
        }

        return sumOfRoyalties;
    }

    function _distributeReferrerFee(
        address referrerAddress,
        address nftAddress,
        uint256 price,
        uint256 tokenId,
        uint256 listingId
    ) private returns (uint256) {
        uint256 referrerFeeAmount = (price * referrerFee) / PERCENTAGE_DIVIDER;

        if (referrerFeeAmount != 0) {
            transferEth(referrerAddress, referrerFeeAmount);

            emit ReferrerFeeTransferred(
                referrerAddress,
                referrerFeeAmount,
                tokenId,
                nftAddress,
                listingId
            );
        }

        return referrerFeeAmount;
    }

    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint32 marketplaceFee
    ) external isTokenOwner(nftAddress, tokenId, _msgSender()) {
        _validateListing(nftAddress, tokenId, false, _msgSender());

        if (price == 0) {
            revert PriceMustBeAboveZero();
        }
        if (marketplaceFee > MAX_MARKETPLACE_FEE) {
            revert MarketplaceFeeExceedsLimit();
        }

        address collectionAddress = nftAddress;
        uint256 listingTokenId = tokenId;
        if (
            IERC721Upgradeable(collectionAddress).getApproved(tokenId) !=
            address(this)
        ) {
            revert NotApprovedForMarketplace();
        }

        Listing storage list = s_listings[collectionAddress][listingTokenId];
        list.listingId = ++listingCount;
        list.price = price;
        list.marketplaceFee = marketplaceFee;
        list.seller = _msgSender();
        list.buyer = address(0);
        emit ItemListed(
            _msgSender(),
            collectionAddress,
            listingTokenId,
            listingCount,
            price,
            marketplaceFee
        );
    }

    function cancelListing(
        address nftAddress,
        uint256 tokenId
    ) external isListingOwner(_msgSender(), nftAddress, tokenId) {
        _validateListing(nftAddress, tokenId, true, _msgSender());

        Listing storage list = s_listings[nftAddress][tokenId];
        list.price = 0;
        emit ItemCanceled(_msgSender(), nftAddress, tokenId, list.listingId);
    }

    function buyItem(
        address nftAddress,
        uint256 tokenId,
        address referrerAddress
    ) external payable nonReentrant {
        _validateListing(nftAddress, tokenId, true, _msgSender());

        Listing storage listedItem = s_listings[nftAddress][tokenId];
        if (msg.value != listedItem.price) {
            revert PriceNotMet(nftAddress, tokenId, listedItem.price);
        }

        IERC721Upgradeable(nftAddress).safeTransferFrom(
            listedItem.seller,
            _msgSender(),
            tokenId
        );

        listedItem.buyer = _msgSender();
        uint256 itemPrice = listedItem.price;
        uint256 marketplaceFeeAmount = (itemPrice * listedItem.marketplaceFee) /
            PERCENTAGE_DIVIDER;
        s_marketplaceFee += marketplaceFeeAmount;
        listedItem.marketplaceFeeAmount = marketplaceFeeAmount;

        uint256 sumOfRoyalties = _distributeRoyalties(
            nftAddress,
            tokenId,
            itemPrice,
            listedItem.listingId
        );

        uint256 referrerFeeAmount;
        if (referrerAddress != address(0)) {
            referrerFeeAmount = _distributeReferrerFee(
                referrerAddress,
                nftAddress,
                itemPrice,
                tokenId,
                listedItem.listingId
            );
        }
        uint256 totalFees = marketplaceFeeAmount +
            sumOfRoyalties +
            referrerFeeAmount;

        if (totalFees > itemPrice) {
            revert FeesHigherThanSalePrice();
        }

        uint256 amountDueToSeller = itemPrice - totalFees;

        (bool success, ) = payable(listedItem.seller).call{
            value: amountDueToSeller
        }("");
        if (!success) {
            revert TransferProceedsToSellerFailed();
        }

        emit ItemBought(
            listedItem.seller,
            _msgSender(),
            nftAddress,
            tokenId,
            listedItem.listingId,
            listedItem.price,
            amountDueToSeller,
            marketplaceFeeAmount
        );
    }

    function updateListingMarketplaceFeeAndPrice(
        address nftAddress,
        uint256 tokenId,
        uint32 marketplaceFee,
        uint256 price
    ) external nonReentrant isListingOwner(_msgSender(), nftAddress, tokenId) {
        _validateListing(nftAddress, tokenId, true, _msgSender());

        if (marketplaceFee > MAX_MARKETPLACE_FEE) {
            revert MarketplaceFeeExceedsLimit();
        }
        if (price == 0) {
            revert PriceMustBeAboveZero();
        }

        Listing storage listing = s_listings[nftAddress][tokenId];
        listing.marketplaceFee = marketplaceFee;
        listing.price = price;
        emit ListingUpdated(
            _msgSender(),
            nftAddress,
            tokenId,
            listing.listingId,
            price,
            marketplaceFee
        );
    }

    function withdrawFee(address receiver) external onlyOwner {
        (bool withdrawFeeTransferSuccess, ) = payable(receiver).call{
            value: s_marketplaceFee
        }("");

        if (!withdrawFeeTransferSuccess) {
            revert ProceedWithdrawalFailed();
        }

        s_marketplaceFee = 0;
    }

    function setRoyaltyEngine(address royaltyEngine) external onlyOwner {
        _royaltyEngine = IRoyaltyEngineV1(royaltyEngine);
    }

    function getMarketplaceFeeAmount() external view returns (uint256) {
        return s_marketplaceFee;
    }

    function getListing(
        address nftAddress,
        uint256 tokenId
    ) external view returns (Listing memory) {
        return s_listings[nftAddress][tokenId];
    }

    function setWETH(address _weth) external onlyOwner {
        weth = IWETH9(_weth);
    }

    function setReferrerFee(uint32 newReferrerFee) external onlyOwner {
        referrerFee = newReferrerFee;
    }

    function transferEth(address receiver, uint256 amount) internal {
        (bool EthTransferSuccess, ) = payable(receiver).call{
            gas: 21000,
            value: amount
        }("");

        if (!EthTransferSuccess) {
            weth.deposit{value: amount}();
            bool WETHTransferSuccess = weth.transfer(receiver, amount);
            if (!WETHTransferSuccess) {
                revert TransferEthFailed();
            }
        }
    }
}