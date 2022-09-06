// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SignatureCheckerUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {ITransferManagerSelector} from "../interfaces/ITransferManagerSelector.sol";
import {ITransferManager} from "../interfaces/ITransferManager.sol";
import {IRoyaltyEngine} from "../interfaces/IRoyaltyEngine.sol";
import {IMarketplaceFeeEngine} from "../interfaces/IMarketplaceFeeEngine.sol";
import {IStrategyManager} from "../interfaces/IStrategyManager.sol";
import {ICurrencyManager} from "../interfaces/ICurrencyManager.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";
import {IXExchange} from "../interfaces/IXExchange.sol";
import {IWeth} from "../interfaces/IWeth.sol";
import {XExchangeStorage} from "./XExchangeStorage.sol";
import {OrderTypes} from "../libraries/OrderTypes.sol";

contract XExchange is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IXExchange,
    XExchangeStorage
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IWeth;
    using SignatureCheckerUpgradeable for address;
    using OrderTypes for OrderTypes.MakerOrder;

    function initialize(
        IWeth _weth,
        ICurrencyManager _currencyManager,
        IStrategyManager _strategyManager,
        IMarketplaceFeeEngine _marketplaceFeeEngine,
        IRoyaltyEngine _royaltyEngine
    ) external initializer {
        __Ownable_init();
        domainSeperator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("XExchange"),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
        weth = _weth;
        currencyManager = _currencyManager;
        strategyManager = _strategyManager;
        marketplaceFeeEngine = _marketplaceFeeEngine;
        royaltyEngine = _royaltyEngine;
    }

    // For UUPSUpgradeable
    function _authorizeUpgrade(address) internal view override {
        require(_msgSender() == owner(), "XE: caller is not owner");
    }

    function matchAskWithTakerBidUsingETH(
        OrderTypes.MakerOrder calldata makerAsk,
        OrderTypes.TakerOrder calldata takerBid
    ) external payable override nonReentrant {
        require(makerAsk.isAsk && !takerBid.isAsk, "XE: wrong sides");
        require(_msgSender() == takerBid.taker, "XE: invalid sender");
        require(makerAsk.currency == address(0x0), "XE: eth only");

        bytes32 orderItemHash = _validateOrder(makerAsk, takerBid);
        orderStatus[orderItemHash] = true;
        (bool canExecute, uint256 tokenId, uint256 amount) = IStrategy(
            makerAsk.strategy
        ).canExecuteTakerBid(makerAsk, takerBid);
        require(canExecute, "XE: cannot execute");

        OrderTypes.Fulfillment memory fulfillment = OrderTypes.Fulfillment({
            collection: makerAsk.items[takerBid.itemIdx].collection,
            tokenId: tokenId,
            amount: amount,
            currency: makerAsk.currency,
            price: makerAsk.items[takerBid.itemIdx].price
        });
        require(fulfillment.price == msg.value, "XE: invalid payment");

        _transferFeesFromExchange(
            makerAsk.items[takerBid.itemIdx].collection,
            tokenId,
            payable(makerAsk.signer),
            makerAsk.items[takerBid.itemIdx].price,
            makerAsk.marketplace,
            makerAsk.minPercentageToAsk
        );
        _transferNFT(
            makerAsk.items[takerBid.itemIdx].collection,
            tokenId,
            amount,
            makerAsk.signer,
            takerBid.taker
        );
        _emitTakerBid(makerAsk, takerBid, orderItemHash, fulfillment);
    }

    function matchAskWithTakerBid(
        OrderTypes.MakerOrder calldata makerAsk,
        OrderTypes.TakerOrder calldata takerBid
    ) external override nonReentrant {
        require(makerAsk.isAsk && !takerBid.isAsk, "XE: wrong sides");
        require(_msgSender() == takerBid.taker, "XE: invalid sender");

        bytes32 orderItemHash = _validateOrder(makerAsk, takerBid);
        orderStatus[orderItemHash] = true;
        (bool canExecute, uint256 tokenId, uint256 amount) = IStrategy(
            makerAsk.strategy
        ).canExecuteTakerBid(makerAsk, takerBid);
        require(canExecute, "XE: cannot execute");

        OrderTypes.Fulfillment memory fulfillment = OrderTypes.Fulfillment({
            collection: makerAsk.items[takerBid.itemIdx].collection,
            tokenId: tokenId,
            amount: amount,
            currency: makerAsk.currency,
            price: makerAsk.items[takerBid.itemIdx].price
        });
        _transferFees(
            makerAsk.items[takerBid.itemIdx].collection,
            tokenId,
            makerAsk.currency,
            takerBid.taker,
            makerAsk.signer,
            makerAsk.items[takerBid.itemIdx].price,
            makerAsk.marketplace,
            makerAsk.minPercentageToAsk
        );
        _transferNFT(
            makerAsk.items[takerBid.itemIdx].collection,
            tokenId,
            amount,
            makerAsk.signer,
            takerBid.taker
        );
        _emitTakerBid(makerAsk, takerBid, orderItemHash, fulfillment);
    }

    function _emitTakerBid(
        OrderTypes.MakerOrder calldata makerAsk,
        OrderTypes.TakerOrder calldata takerBid,
        bytes32 orderItemHash,
        OrderTypes.Fulfillment memory fulfillment
    ) internal {
        emit TakerBid(
            takerBid.taker,
            makerAsk.signer,
            makerAsk.strategy,
            makerAsk.hash(),
            takerBid.itemIdx,
            orderItemHash,
            fulfillment,
            makerAsk.marketplace
        );
    }

    function matchBidWithTakerAsk(
        OrderTypes.MakerOrder calldata makerBid,
        OrderTypes.TakerOrder calldata takerAsk
    ) external override nonReentrant {
        require(!makerBid.isAsk && takerAsk.isAsk, "XE: wrong sides");
        require(_msgSender() == takerAsk.taker, "XE: invalid sender");

        bytes32 orderItemHash = _validateOrder(makerBid, takerAsk);
        orderStatus[orderItemHash] = true;
        (bool canExecute, uint256 tokenId, uint256 amount) = IStrategy(
            makerBid.strategy
        ).canExecuteTakerAsk(makerBid, takerAsk);
        require(canExecute, "XE: cannot execute");

        OrderTypes.Fulfillment memory fulfillment = OrderTypes.Fulfillment({
            collection: makerBid.items[takerAsk.itemIdx].collection,
            tokenId: tokenId,
            amount: amount,
            currency: makerBid.currency,
            price: makerBid.items[takerAsk.itemIdx].price
        });
        _transferFees(
            fulfillment.collection,
            tokenId,
            makerBid.currency,
            makerBid.signer,
            takerAsk.taker,
            fulfillment.price,
            takerAsk.marketplace,
            takerAsk.minPercentageToAsk
        );
        _transferNFT(
            fulfillment.collection,
            tokenId,
            amount,
            takerAsk.taker,
            makerBid.signer
        );
        _emitTakerAsk(makerBid, takerAsk, orderItemHash, fulfillment);
    }

    function _emitTakerAsk(
        OrderTypes.MakerOrder calldata makerBid,
        OrderTypes.TakerOrder calldata takerAsk,
        bytes32 orderItemHash,
        OrderTypes.Fulfillment memory fulfillment
    ) internal {
        emit TakerAsk(
            takerAsk.taker,
            makerBid.signer,
            makerBid.strategy,
            makerBid.hash(),
            takerAsk.itemIdx,
            orderItemHash,
            fulfillment,
            takerAsk.marketplace
        );
    }

    function cancelAllOrdersForSender(uint256 nonce) external override {
        require(nonce > userMinNonce[_msgSender()], "XE: invalid nonce");
        userMinNonce[_msgSender()] = nonce;
        emit CancelAllOrders(_msgSender(), nonce);
    }

    function cancelMultipleOrders(
        OrderTypes.MakerOrder[] calldata orders,
        uint256[][] calldata itemIdxs
    ) external override {
        require(orders.length == itemIdxs.length, "XE: length mismatch");
        uint256 totalOrders;
        for (uint256 i = 0; i < orders.length; i++) {
            totalOrders += itemIdxs[i].length;
        }
        bytes32[] memory orderItemHashes = new bytes32[](totalOrders);
        uint256 processed = 0;

        for (uint256 i = 0; i < orders.length; i++) {
            OrderTypes.MakerOrder calldata order = orders[i];
            require(_msgSender() == order.signer, "XE: invalid sender");
            require(
                order.nonce >= userMinNonce[order.signer],
                "XE: invalid nonce"
            );
            for (uint256 j = 0; j < itemIdxs[i].length; j++) {
                uint256 idx = itemIdxs[i][j];
                require(idx < order.items.length, "XE: itemIdx out of range");
                bytes32 orderItemHash = order.hashOrderItem(idx);
                require(
                    !orderStatus[orderItemHash],
                    "XE: order already processed"
                );
                orderStatus[orderItemHash] = true;
                orderItemHashes[processed++] = orderItemHash;
            }
        }
        emit CancelMultipleOrders(orderItemHashes);
    }

    function _validateOrder(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.TakerOrder calldata takerOrder
    ) internal view returns (bytes32) {
        require(
            makerOrder.nonce >= userMinNonce[makerOrder.signer],
            "XE: invalid nonce"
        );
        require(
            strategyManager.isValid(makerOrder.strategy),
            "XE: invalid strategy"
        );
        verifyOrderSignature(makerOrder);
        require(
            currencyManager.isValid(makerOrder.currency),
            "XE: invalid currency"
        );
        require(
            takerOrder.itemIdx < makerOrder.items.length,
            "XE: itemIdx out of range"
        );
        bytes32 orderItemHash = makerOrder.hashOrderItem(takerOrder.itemIdx);
        require(!orderStatus[orderItemHash], "XE: order already processed");
        return orderItemHash;
    }

    function _transferNFT(
        address collection,
        uint256 tokenId,
        uint256 amount,
        address from,
        address to
    ) internal {
        address tm = transferManager.getTransferManager(collection);
        require(tm != address(0), "XE: no available TM");
        ITransferManager(tm).transferNFT(collection, tokenId, amount, from, to);
    }

    function _transferFees(
        address collection,
        uint256 tokenId,
        address currency,
        address from,
        address to,
        uint256 value,
        bytes32 marketplace,
        uint256 minPercentageToAsk
    ) internal {
        uint256 remainingValue = value;
        (
            address payable[] memory receivers,
            uint256[] memory fees
        ) = marketplaceFeeEngine.getMarketplaceFee(
                marketplace,
                collection,
                value
            );
        for (uint256 i = 0; i < receivers.length; i++) {
            if (fees[i] != 0 && receivers[i] != address(0)) {
                remainingValue -= fees[i];
                IERC20Upgradeable(currency).safeTransferFrom(
                    from,
                    receivers[i],
                    fees[i]
                );
            }
        }
        emit MarketplaceFeePayment(marketplace, currency, receivers, fees);
        (receivers, fees) = royaltyEngine.getRoyalty(
            collection,
            tokenId,
            value
        );
        for (uint256 i = 0; i < receivers.length; i++) {
            if (fees[i] != 0 && receivers[i] != address(0)) {
                remainingValue -= fees[i];
                IERC20Upgradeable(currency).safeTransferFrom(
                    from,
                    receivers[i],
                    fees[i]
                );
            }
        }
        require(
            remainingValue * 10000 >= minPercentageToAsk * value,
            "XE: exceeds minPercentageToAsk"
        );
        IERC20Upgradeable(currency).safeTransferFrom(from, to, remainingValue);
    }

    function _transferFeesFromExchange(
        address collection,
        uint256 tokenId,
        address payable to,
        uint256 value,
        bytes32 marketplace,
        uint256 minPercentageToAsk
    ) internal {
        uint256 remainingValue = value;
        bool success;
        (
            address payable[] memory receivers,
            uint256[] memory fees
        ) = marketplaceFeeEngine.getMarketplaceFee(
                marketplace,
                collection,
                value
            );
        for (uint256 i = 0; i < receivers.length; i++) {
            if (fees[i] != 0 && receivers[i] != address(0)) {
                remainingValue -= fees[i];
                // solhint-disable-next-line avoid-low-level-calls
                (success, ) = receivers[i].call{value: fees[i]}("");
                require(success, "XE: transfer failed");
            }
        }
        emit MarketplaceFeePayment(marketplace, address(0x0), receivers, fees);
        (receivers, fees) = royaltyEngine.getRoyalty(
            collection,
            tokenId,
            value
        );
        for (uint256 i = 0; i < receivers.length; i++) {
            if (fees[i] != 0 && receivers[i] != address(0)) {
                remainingValue -= fees[i];
                // solhint-disable-next-line avoid-low-level-calls
                (success, ) = receivers[i].call{value: fees[i]}("");
                require(success, "XE: transfer failed");
            }
        }
        require(
            remainingValue * 10000 >= minPercentageToAsk * value,
            "XE: exceeds minPercentageToAsk"
        );
        // solhint-disable-next-line avoid-low-level-calls
        (success, ) = to.call{value: remainingValue}("");
        require(success, "XE: transfer failed");
    }

    function verifyOrderSignature(OrderTypes.MakerOrder calldata makerOrder)
        public
        view
    {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeperator, makerOrder.hash())
        );
        require(
            makerOrder.signer.isValidSignatureNow(
                digest,
                abi.encodePacked(makerOrder.r, makerOrder.s, makerOrder.v)
            ),
            "XE: invalid signature"
        );
    }

    function updateTransferManagerSelector(ITransferManagerSelector selector)
        external
        onlyOwner
    {
        transferManager = selector;
        emit TransferManagerSelectorUpdated(address(selector));
    }

    function updateRoyaltyEngine(IRoyaltyEngine engine) external onlyOwner {
        royaltyEngine = engine;
        emit RoyaltyEngineUpdated(address(engine));
    }

    function updateMarketplaceFeeEngine(IMarketplaceFeeEngine engine)
        external
        onlyOwner
    {
        marketplaceFeeEngine = engine;
        emit MarketplaceFeeEngineUpdated(address(engine));
    }

    function updateStrategyManager(IStrategyManager manager)
        external
        onlyOwner
    {
        strategyManager = manager;
        emit StrategyManagerUpdated(address(manager));
    }

    function updateCurrencyManager(ICurrencyManager manager)
        external
        onlyOwner
    {
        currencyManager = manager;
        emit CurrencyManagerUpdated(address(manager));
    }
}