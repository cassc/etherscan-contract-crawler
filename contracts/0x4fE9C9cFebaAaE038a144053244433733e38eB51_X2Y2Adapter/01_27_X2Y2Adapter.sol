// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {IX2Y2} from "../interfaces/IX2Y2.sol";

import {BaseAdapter, IERC721Upgradeable} from "./BaseAdapter.sol";

contract X2Y2Adapter is BaseAdapter {
    string public constant NAME = "X2Y2 Downpayment Adapter";
    string public constant VERSION = "1.0";
    // keccak256("Params(Order[] orders,SettleDetail[] details,SettleShared shared,bytes32 r,bytes32 s,uint8 v,uint256 nonce)Fee(uint256 percentage,address to)Order(uint256 salt,address user,uint256 network,uint256 intent,uint256 delegateType,uint256 deadline,address currency,bytes dataMask,OrderItem[] items,bytes32 r,bytes32 s,uint8 v,uint8 signVersion)OrderItem(uint256 price,bytes data)SettleDetail(uint8 op,uint256 orderIdx,uint256 itemIdx,uint256 price,bytes32 itemHash,address executionDelegate,bytes dataReplacement,uint256 bidIncentivePct,uint256 aucMinIncrementPct,uint256 aucIncDurationSecs,Fee[] fees)SettleShared(uint256 salt,uint256 deadline,uint256 amountToEth,uint256 amountToWeth,address user,bool canFail)");
    bytes32 private constant _PARAMS_TYPEHASH = 0x4970e504235e7e28e94eb3c39f434a3f0bff5ace4a9c85d12d2ccdee5f1c817b;
    // keccak256("Order(uint256 salt,address user,uint256 network,uint256 intent,uint256 delegateType,uint256 deadline,address currency,bytes dataMask,OrderItem[] items,bytes32 r,bytes32 s,uint8 v,uint8 signVersion)OrderItem(uint256 price,bytes data)");
    bytes32 internal constant _ORDER_TYPEHASH = 0x0acf5922e9fc92c7d9c4f760e6299407f9efd13ed9fc1eae5ed5679215c7ab97;
    // keccak256("SettleDetail(uint8 op,uint256 orderIdx,uint256 itemIdx,uint256 price,bytes32 itemHash,address executionDelegate,bytes dataReplacement,uint256 bidIncentivePct,uint256 aucMinIncrementPct,uint256 aucIncDurationSecs,Fee[] fees)Fee(uint256 percentage,address to)");
    bytes32 internal constant _SETTLE_DETAIL_TYPEHASH =
        0x3a15a1532dd9387f7c9bec440182e37f57b71f2423acb7f1dd8ac829679f716f;
    // keccak256("SettleShared(uint256 salt,uint256 deadline,uint256 amountToEth,uint256 amountToWeth,address user,bool canFail)");
    bytes32 internal constant _SETTLE_SHARED_TYPEHASH =
        0xf59a0c572b0a186ccb28f93b38e176e972ed6ecb66854e47fc48062c81640728;
    // keccak256("OrderItem(uint256 price,bytes data)")
    bytes32 internal constant _ORDER_ITEM_TYPEHASH = 0xc3a0c300c66ade339734c0629cf933940eaccc55b682952080d263a95c718462;
    // keccak256("Fee(uint256 percentage,address to)")
    bytes32 internal constant _FEE_TYPEHASH = 0x344dbc10d88fd7c760a8077a8b87d029ff225a6f373716dee2f82c55cdee0db9;

    IX2Y2 public x2y2;

    function initialize(address _downpayment, address _x2y2) external initializer {
        __BaseAdapter_init(NAME, VERSION, _downpayment);
        x2y2 = IX2Y2(_x2y2);
    }

    struct ERC721Pair {
        address token;
        uint256 tokenId;
    }

    function _checkParams(
        address,
        uint256,
        uint256,
        bytes memory _params,
        uint256 _nonce
    ) internal view override returns (BaseParams memory) {
        IX2Y2.RunInput memory _orderParams = _decodeParams(_params);
        // Check order params
        require(_orderParams.details.length == 1, "Adapter: order details exceed");

        IX2Y2.SettleDetail memory detail = _orderParams.details[0];
        IX2Y2.Order memory order = _orderParams.orders[detail.orderIdx];
        IX2Y2.OrderItem memory item = order.items[detail.itemIdx];

        require(
            address(0) == order.currency || address(downpayment.WETH()) == order.currency,
            "Adapter: currency should be ETH or WETH"
        );
        require(IX2Y2.Op.COMPLETE_SELL_OFFER == detail.op, "Adapter: order op error");

        ERC721Pair[] memory nfts = abi.decode(item.data, (ERC721Pair[]));

        require(nfts.length == 1, "Adapter: order items error");

        return
            BaseParams({
                nftAsset: nfts[0].token,
                nftTokenId: nfts[0].tokenId,
                currency: order.currency,
                salePrice: detail.price,
                paramsHash: _hashParams(_orderParams, _nonce)
            });
    }

    function _hashParams(IX2Y2.RunInput memory _orderParams, uint256 _nonce) internal pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    abi.encode(
                        _PARAMS_TYPEHASH,
                        _hashOrders(_orderParams.orders),
                        _hashDetails(_orderParams.details),
                        _hashShared(_orderParams.shared),
                        _orderParams.r,
                        _orderParams.s,
                        _orderParams.v,
                        _nonce
                    )
                )
            );
    }

    function _hashOrders(IX2Y2.Order[] memory orders) internal pure returns (bytes32) {
        bytes memory encoded;
        for (uint256 i = 0; i < orders.length; i++) {
            IX2Y2.Order memory order = (orders[i]);
            encoded = bytes.concat(
                encoded,
                keccak256(
                    abi.encode(
                        _ORDER_TYPEHASH,
                        order.salt,
                        order.user,
                        order.network,
                        order.intent,
                        order.delegateType,
                        order.deadline,
                        order.currency,
                        keccak256(order.dataMask),
                        _hashOrderItems(order.items),
                        order.r,
                        order.s,
                        order.v,
                        order.signVersion
                    )
                )
            );
        }
        return keccak256(encoded);
    }

    function _hashOrderItems(IX2Y2.OrderItem[] memory items) internal pure returns (bytes32) {
        bytes memory encoded;
        for (uint256 i = 0; i < items.length; i++) {
            IX2Y2.OrderItem memory item = (items[i]);
            encoded = bytes.concat(
                encoded,
                keccak256(abi.encode(_ORDER_ITEM_TYPEHASH, item.price, keccak256(item.data)))
            );
        }
        return keccak256(encoded);
    }

    function _hashDetails(IX2Y2.SettleDetail[] memory details) internal pure returns (bytes32) {
        bytes memory encoded;
        for (uint256 i = 0; i < details.length; i++) {
            IX2Y2.SettleDetail memory detail = (details[i]);
            encoded = bytes.concat(
                encoded,
                keccak256(
                    abi.encode(
                        _SETTLE_DETAIL_TYPEHASH,
                        detail.op,
                        detail.orderIdx,
                        detail.itemIdx,
                        detail.price,
                        detail.itemHash,
                        detail.executionDelegate,
                        keccak256(detail.dataReplacement),
                        detail.bidIncentivePct,
                        detail.aucMinIncrementPct,
                        detail.aucIncDurationSecs,
                        _hashFees(detail.fees)
                    )
                )
            );
        }
        return keccak256(encoded);
    }

    function _hashFees(IX2Y2.Fee[] memory fees) internal pure returns (bytes32) {
        bytes memory encoded;
        for (uint256 i = 0; i < fees.length; i++) {
            IX2Y2.Fee memory fee = (fees[i]);
            encoded = bytes.concat(encoded, keccak256(abi.encode(_FEE_TYPEHASH, fee.percentage, fee.to)));
        }
        return keccak256(encoded);
    }

    function _hashShared(IX2Y2.SettleShared memory share) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _SETTLE_SHARED_TYPEHASH,
                    share.salt,
                    share.deadline,
                    share.amountToEth,
                    share.amountToWeth,
                    share.user,
                    share.canFail
                )
            );
    }

    function _exchange(BaseParams memory _baseParams, bytes memory _params) internal override {
        IX2Y2.RunInput memory _orderParams = _decodeParams(_params);
        uint256 paymentValue = _baseParams.salePrice;
        if (_baseParams.currency == address(0)) {
            downpayment.WETH().withdraw(paymentValue);
            x2y2.run{value: paymentValue}(_orderParams);
        } else {
            downpayment.WETH().approve(address(x2y2), paymentValue);
            x2y2.run(_orderParams);
            downpayment.WETH().approve(address(x2y2), 0);
        }
    }

    function _decodeParams(bytes memory _params) internal pure returns (IX2Y2.RunInput memory) {
        return abi.decode(_params, (IX2Y2.RunInput));
    }
}