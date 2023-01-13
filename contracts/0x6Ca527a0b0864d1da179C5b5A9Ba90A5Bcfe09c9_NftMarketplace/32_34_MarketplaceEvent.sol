// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IMarketplaceEvent.sol";

contract MarketplaceEvent is Initializable, UUPSUpgradeable, OwnableUpgradeable, IMarketplaceEvent {
    address public marketPlace;

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setMarketPlace(address _marketPlace) external onlyOwner {
        marketPlace = _marketPlace;
        emit NewMarketplace(_marketPlace);
    }

    function emitExecuteSwap(
        bytes32 sellHash,
        bytes32 buyHash,
        LibSignature.Order calldata sellOrder,
        LibSignature.Order calldata buyOrder,
        uint8[2] calldata v,
        bytes32[2] calldata r,
        bytes32[2] calldata s
    ) external returns (bool) {
        require(msg.sender == marketPlace);
        emit Match(
            sellHash,
            buyHash,
            sellOrder.auctionType,
            Sig(v[0], r[0], s[0]),
            Sig(v[1], r[1], s[1]),
            sellOrder.taker != address(0x0)
        );

        emit Match2A(
            sellHash,
            sellOrder.maker,
            sellOrder.taker,
            sellOrder.start,
            sellOrder.end,
            sellOrder.nonce,
            sellOrder.salt
        );

        emitMatch2(sellOrder, sellHash, buyOrder, buyHash);

        return true;
    }

    function emitBuyNow(
        bytes32 sellHash,
        LibSignature.Order calldata sellOrder,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool) {
        require(msg.sender == marketPlace);
        emit Match(
            sellHash,
            0x0000000000000000000000000000000000000000000000000000000000000000,
            sellOrder.auctionType,
            Sig(v, r, s),
            Sig(
                0,
                0x0000000000000000000000000000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000000000000000000000000000
            ),
            sellOrder.taker != address(0x0)
        );

        emit BuyNowInfo(sellHash, msg.sender);

        emit Match2A(
            sellHash,
            sellOrder.maker,
            sellOrder.taker,
            sellOrder.start,
            sellOrder.end,
            sellOrder.nonce,
            sellOrder.salt
        );

        emitMatch2(sellOrder, sellHash, sellOrder, 0x0000000000000000000000000000000000000000000000000000000000000000);

        return true;
    }

    function emitMatch2(
        LibSignature.Order calldata sellOrder,
        bytes32 sellStructHash,
        LibSignature.Order calldata buyOrder,
        bytes32 buyStructHash
    ) private {
        uint256 totalSellOrderTakeAssets = sellOrder.takeAssets.length;
        bytes[] memory sellerMakerOrderAssetData = new bytes[](sellOrder.makeAssets.length);
        bytes[] memory sellerMakerOrderAssetTypeData = new bytes[](sellOrder.makeAssets.length);
        bytes4[] memory sellerMakerOrderAssetClass = new bytes4[](sellOrder.makeAssets.length);
        for (uint256 i = 0; i < sellOrder.makeAssets.length; i++) {
            sellerMakerOrderAssetData[i] = sellOrder.makeAssets[i].data;
            sellerMakerOrderAssetTypeData[i] = sellOrder.makeAssets[i].assetType.data;
            sellerMakerOrderAssetClass[i] = sellOrder.makeAssets[i].assetType.assetClass;
        }

        bytes[] memory sellerTakerOrderAssetData = new bytes[](sellOrder.takeAssets.length);
        bytes[] memory sellerTakerOrderAssetTypeData = new bytes[](sellOrder.takeAssets.length);
        bytes4[] memory sellerTakerOrderAssetClass = new bytes4[](sellOrder.takeAssets.length);
        for (uint256 i = 0; i < totalSellOrderTakeAssets;) {
            sellerTakerOrderAssetData[i] = sellOrder.takeAssets[i].data;
            sellerTakerOrderAssetTypeData[i] = sellOrder.takeAssets[i].assetType.data;
            sellerTakerOrderAssetClass[i] = sellOrder.takeAssets[i].assetType.assetClass;
            unchecked {
                i++;
            }
        }

        emit Match2B(
            sellStructHash,
            sellerMakerOrderAssetData,
            sellerMakerOrderAssetTypeData,
            sellerMakerOrderAssetClass,
            sellerTakerOrderAssetData,
            sellerTakerOrderAssetTypeData,
            sellerTakerOrderAssetClass
        );

        // buy order
        if (buyStructHash != 0x0000000000000000000000000000000000000000000000000000000000000000) {
            emitMatch3(buyStructHash, buyOrder);
        }
    }

    function emitMatch3(bytes32 buyStructHash, LibSignature.Order calldata buyOrder) private {
        bytes[] memory buyerMakerOrderAssetData = new bytes[](buyOrder.makeAssets.length);
        bytes[] memory buyerMakerOrderAssetTypeData = new bytes[](buyOrder.makeAssets.length);
        bytes4[] memory buyerMakerOrderAssetClass = new bytes4[](buyOrder.makeAssets.length);
        uint256 totalBuyOrderMakeAssets = buyOrder.makeAssets.length;
        for (uint256 i = 0; i < totalBuyOrderMakeAssets;) {
            buyerMakerOrderAssetData[i] = buyOrder.makeAssets[i].data;
            buyerMakerOrderAssetTypeData[i] = buyOrder.makeAssets[i].assetType.data;
            buyerMakerOrderAssetClass[i] = buyOrder.makeAssets[i].assetType.assetClass;
            unchecked {
                ++i;
            }
        }

        bytes[] memory buyerTakerOrderAssetData = new bytes[](buyOrder.takeAssets.length);
        bytes[] memory buyerTakerOrderAssetTypeData = new bytes[](buyOrder.takeAssets.length);
        bytes4[] memory buyerTakerOrderAssetClass = new bytes4[](buyOrder.takeAssets.length);
        uint256 totalBuyOrderTakeAssets = buyOrder.takeAssets.length;
        for (uint256 i = 0; i < totalBuyOrderTakeAssets;) {
            buyerTakerOrderAssetData[i] = buyOrder.takeAssets[i].data;
            buyerTakerOrderAssetTypeData[i] = buyOrder.takeAssets[i].assetType.data;
            buyerTakerOrderAssetClass[i] = buyOrder.takeAssets[i].assetType.assetClass;
            unchecked {
                ++i;
            }
        }

        emit Match3A(
            buyStructHash,
            buyOrder.maker,
            buyOrder.taker,
            buyOrder.start,
            buyOrder.end,
            buyOrder.nonce,
            buyOrder.salt
        );

        emit Match3B(
            buyStructHash,
            buyerMakerOrderAssetData,
            buyerMakerOrderAssetTypeData,
            buyerMakerOrderAssetClass,
            buyerTakerOrderAssetData,
            buyerTakerOrderAssetTypeData,
            buyerTakerOrderAssetClass
        );
    }
}