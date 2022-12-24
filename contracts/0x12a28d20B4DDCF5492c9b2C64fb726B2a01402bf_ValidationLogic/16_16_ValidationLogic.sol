// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IValidationLogic.sol";

contract ValidationLogic is Initializable, UUPSUpgradeable, OwnableUpgradeable, IValidationLogic {
    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     *  @dev validateSingleAssetMatch1 makes sure two assets can be matched (same index in LibSignature array)
     *  @param buyTakeAsset what the buyer is hoping to take
     *  @param sellMakeAsset what the seller is hoping to make
     *  @return true if valid
     */
    function validateSingleAssetMatch1(LibAsset.Asset calldata buyTakeAsset, LibAsset.Asset calldata sellMakeAsset)
        internal
        pure
        returns (bool)
    {
        (uint256 sellMakeValue, ) = abi.decode(sellMakeAsset.data, (uint256, uint256));
        (uint256 buyTakeValue, ) = abi.decode(buyTakeAsset.data, (uint256, uint256));

        return
            // asset being sold
            (sellMakeAsset.assetType.assetClass == buyTakeAsset.assetType.assetClass) &&
            // sell value == buy take
            sellMakeValue == buyTakeValue;
    }

    /**
     * @dev validAssetTypeData checks if tokenIds are the same (only for NFTs)
     *  @param sellTakeAssetClass (bytes4 of type in LibAsset)
     *  @param buyMakeAssetTypeData assetTypeData for makeAsset on buyOrder
     *  @param sellTakeAssetTypeData assetTypeData for takeAsset on sellOrder
     *  @return true if valid
     */
    function validAssetTypeData(
        bytes4 sellTakeAssetClass,
        bytes memory buyMakeAssetTypeData,
        bytes memory sellTakeAssetTypeData
    ) internal pure returns (bool) {
        if (
            sellTakeAssetClass == LibAsset.ERC721_ASSET_CLASS ||
            sellTakeAssetClass == LibAsset.ERC1155_ASSET_CLASS ||
            sellTakeAssetClass == LibAsset.CRYPTO_KITTY
        ) {
            (address buyMakeAddress, uint256 buyMakeTokenId, ) = abi.decode(
                buyMakeAssetTypeData,
                (address, uint256, bool)
            );

            (address sellTakeAddress, uint256 sellTakeTokenId, bool sellTakeAllowAll) = abi.decode(
                sellTakeAssetTypeData,
                (address, uint256, bool)
            );

            require(buyMakeAddress == sellTakeAddress, "vatd !match");

            if (sellTakeAllowAll) {
                return true;
            } else {
                return buyMakeTokenId == sellTakeTokenId;
            }
        } else if (sellTakeAssetClass == LibAsset.ERC20_ASSET_CLASS) {
            return abi.decode(buyMakeAssetTypeData, (address)) == abi.decode(sellTakeAssetTypeData, (address));
        } else if (sellTakeAssetClass == LibAsset.ETH_ASSET_CLASS) {
            // no need to handle LibAsset.ETH_ASSET_CLASS since that is handled during execution
            return true;
        } else {
            // should not come here
            return false;
        }
    }

    /**
     *  @dev validateSingleAssetMatch2 makes sure two assets can be matched (same index in LibSignature array)
     *  @param sellTakeAsset what the seller is hoping to take
     *  @param buyMakeAsset what the buyer is hoping to make
     *  @return true if valid
     */
    function validateSingleAssetMatch2(LibAsset.Asset calldata sellTakeAsset, LibAsset.Asset calldata buyMakeAsset)
        internal
        pure
        returns (bool)
    {
        (uint256 buyMakeValue, ) = abi.decode(buyMakeAsset.data, (uint256, uint256));
        (, uint256 sellTakeMinValue) = abi.decode(sellTakeAsset.data, (uint256, uint256));

        return
            // token denominating sell order listing
            (sellTakeAsset.assetType.assetClass == buyMakeAsset.assetType.assetClass) &&
            // buyOrder must be within bounds
            buyMakeValue >= sellTakeMinValue &&
            // make sure tokenIds match if NFT AND contract address matches
            validAssetTypeData(
                sellTakeAsset.assetType.assetClass,
                buyMakeAsset.assetType.data,
                sellTakeAsset.assetType.data
            );

        // NOTE: sellTakeMin could be 0 and buyer could offer 0;
        // NOTE: (in case seller wants to make a list of optional assets to select from)
    }

    /**
     *  @dev validateMatch makes sure two orders (on sell side and buy side) match correctly
     *  @param sellOrder the listing
     *  @param buyOrder bid for a listing
     *  @param sender person sending the transaction
     *  @param viewOnly true for viewOnly (primarily for testing purposes)
     *  @return true if orders can match
     */
    function validateMatch(
        LibSignature.Order calldata sellOrder,
        LibSignature.Order calldata buyOrder,
        address sender,
        bool viewOnly
    ) internal pure returns (bool) {
        // flag to ensure ETH is not used multiple timese
        bool ETH_ASSET_USED = false;

        require(
            (sellOrder.auctionType == LibSignature.AuctionType.English) &&
                (buyOrder.auctionType == LibSignature.AuctionType.English),
            "vm auctionType"
        );

        // sellOrder taker must be valid
        require(
            (sellOrder.taker == address(0) || sellOrder.taker == buyOrder.maker) &&
                // buyOrder taker must be valid
                (buyOrder.taker == address(0) || buyOrder.taker == sellOrder.maker),
            "vm !match"
        );

        // must be selling something and make and take must match
        require(
            sellOrder.makeAssets.length != 0 && buyOrder.takeAssets.length == sellOrder.makeAssets.length,
            "vm assets > 0"
        );

        require(
            buyOrder.makeAssets.length != 0 && sellOrder.takeAssets.length == buyOrder.makeAssets.length,
            "vm assets > 0"
        );

        // check if seller maker and buyer take match on every corresponding index
        for (uint256 i = 0; i < sellOrder.makeAssets.length;) {
            if (!validateSingleAssetMatch1(buyOrder.takeAssets[i], sellOrder.makeAssets[i])) {
                return false;
            }

            // if ETH, seller must be sending ETH / calling
            if (sellOrder.makeAssets[i].assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
                require(!ETH_ASSET_USED, "vm eth");
                require(viewOnly || sender != buyOrder.maker, "vma sellerEth"); // buyer cannot pay ETH, seller must
                ETH_ASSET_USED = true;
            }

            unchecked {
                ++i;
            }
        }

        // if seller's takeAssets = 0, that means seller doesn't make what buyer's makeAssets are, so ignore
        // if seller's takeAssets > 0, seller has a specified list
        if (sellOrder.takeAssets.length != 0) {
            require(sellOrder.takeAssets.length == buyOrder.makeAssets.length, "vm assets_len");
            // check if seller maker and buyer take match on every corresponding index
            for (uint256 i = 0; i < sellOrder.takeAssets.length;) {
                if (!validateSingleAssetMatch2(sellOrder.takeAssets[i], buyOrder.makeAssets[i])) {
                    return false;
                }

                // if ETH, buyer must be sending ETH / calling
                if (buyOrder.makeAssets[i].assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
                    require(!ETH_ASSET_USED, "vm eth2");
                    require(viewOnly || sender != sellOrder.maker, "vmb buyerEth"); // seller cannot pay ETH, buyer must
                    ETH_ASSET_USED = true;
                }

                unchecked {
                    ++i;
                }
            }
        }

        return true;
    }

    function decreasingValidation(LibSignature.Order calldata sellOrder) private pure {
        require(sellOrder.takeAssets.length == 1, "dv 1_len");
        require(
            (sellOrder.takeAssets[0].assetType.assetClass == LibAsset.ETH_ASSET_CLASS) ||
                (sellOrder.takeAssets[0].assetType.assetClass == LibAsset.ERC20_ASSET_CLASS),
            "dv fung" // only fungible tokens
        );
    }

    /**
     *  @dev validateBuyNow makes sure a buyer can fulfill the sellOrder and that the sellOrder is formatted properly
     *  @param sellOrder the listing
     *  @param buyer potential executor of sellOrder
     *  @return true if validBuyNow
     */
    function validateBuyNow(LibSignature.Order calldata sellOrder, address buyer) public view override returns (bool) {
        require((sellOrder.taker == address(0) || sellOrder.taker == buyer), "vbn !match");
        require(sellOrder.makeAssets.length != 0, "vbn make > 0");
        require(sellOrder.takeAssets.length != 0, "vbn take > 0");

        if (sellOrder.auctionType == LibSignature.AuctionType.Decreasing) {
            decreasingValidation(sellOrder);

            require(sellOrder.start != 0 && sellOrder.start < block.timestamp, "vbn start");
            require(sellOrder.end != 0 && sellOrder.end > block.timestamp, "vbn end");
        }

        return true;
    }

    /**
     *  @dev public facing function to make sure orders can execute
     *  @param sellOrder the listing
     *  @param buyOrder bid for a listing
     *  @param viewOnly true for viewOnly (primarily for testing purposes)
     *  @return true if valid match
     */
    function validateMatch_(
        LibSignature.Order calldata sellOrder,
        LibSignature.Order calldata buyOrder,
        address sender,
        bool viewOnly
    ) public pure override returns (bool) {
        return validateMatch(sellOrder, buyOrder, sender, viewOnly);
    }

    /**
     *  @dev public facing function to get current price of a decreasing price auction
     *  @param sellOrder the listing
     *  @return current price denominated in the asset specified
     */
    function getDecreasingPrice(LibSignature.Order calldata sellOrder) public view override returns (uint256) {
        require(sellOrder.auctionType == LibSignature.AuctionType.Decreasing, "gdp !decreasing");
        decreasingValidation(sellOrder);

        uint256 secondsPassed = 0;
        uint256 publicSaleDurationSeconds = sellOrder.end - sellOrder.start;
        uint256 finalPrice;
        uint256 initialPrice;

        (initialPrice, finalPrice) = abi.decode(sellOrder.takeAssets[0].data, (uint256, uint256));

        secondsPassed = block.timestamp - sellOrder.start;

        if (secondsPassed >= publicSaleDurationSeconds) {
            return finalPrice;
        } else {
            uint256 totalPriceChange = initialPrice - finalPrice;
            uint256 currentPriceChange = (totalPriceChange * secondsPassed) / publicSaleDurationSeconds;
            return initialPrice - currentPriceChange;
        }
    }
}