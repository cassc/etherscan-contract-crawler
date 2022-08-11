// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {IOpenseaExchage} from "../interfaces/IOpenseaExchage.sol";

import {BaseAdapter, IERC721Upgradeable} from "./BaseAdapter.sol";

import "hardhat/console.sol";

contract OpenseaAdapter is BaseAdapter {
    string public constant NAME = "Opensea Downpayment Adapter";
    string public constant VERSION = "1.0";
    // keccak256("Sig(uint8 v,bytes32 r,bytes32 s)")
    bytes32 internal constant _SIGNATURE_TYPEHASH = 0x7113392a96292fcdb631e265c62d67694adea92a7ecaaab03d2b75203232c507;
    // keccak256("Params(address nftAsset,uint256 nftTokenId,Order buy,Sig buySig,Order sell,Sig sellSig,bytes32 metadata,uint256 nonce)Order(address exchange,address maker,address taker,uint256 makerRelayerFee,uint256 takerRelayerFee,uint256 makerProtocolFee,uint256 takerProtocolFee,address feeRecipient,uint8 feeMethod,uint8 side,uint8 saleKind,address target,uint8 howToCall,bytes calldata,bytes replacementPattern,address staticTarget,bytes staticExtradata,address paymentToken,uint256 basePrice,uint256 extra,uint256 listingTime,uint256 expirationTime,uint256 salt)Sig(uint8 v,bytes32 r,bytes32 s)")
    bytes32 private constant _PARAMS_TYPEHASH = 0x45a3a5167053dac828db3853d0bf488bf3f097cddee9ea72e6e57ef7c40c4e40;
    // keccak256("Order(address exchange,address maker,address taker,uint256 makerRelayerFee,uint256 takerRelayerFee,uint256 makerProtocolFee,uint256 takerProtocolFee,address feeRecipient,uint8 feeMethod,uint8 side,uint8 saleKind,address target,uint8 howToCall,bytes calldata,bytes replacementPattern,address staticTarget,bytes staticExtradata,address paymentToken,uint256 basePrice,uint256 extra,uint256 listingTime,uint256 expirationTime,uint256 salt)")
    bytes32 private constant _ORDER_TYPEHASH = 0xe8278750458fc9dce622c9801945913be199be75b96fd73d1432029651d75b7f;

    IOpenseaExchage public openseaExchange;
    address private proxy;

    struct Params {
        // bend params
        address nftAsset;
        uint256 nftTokenId;
        // opensea params
        address[14] addrs;
        uint256[18] uints;
        uint8[8] feeMethodsSidesKindsHowToCalls;
        bytes calldataBuy;
        bytes calldataSell;
        bytes replacementPatternBuy;
        bytes replacementPatternSell;
        bytes staticExtradataBuy;
        bytes staticExtradataSell;
        uint8[2] vs;
        bytes32[5] rssMetadata;
    }

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Order {
        address exchange;
        address maker;
        address taker;
        uint256 makerRelayerFee;
        uint256 takerRelayerFee;
        uint256 makerProtocolFee;
        uint256 takerProtocolFee;
        address feeRecipient;
        uint8 feeMethod;
        uint8 side;
        uint8 saleKind;
        address target;
        uint8 howToCall;
        bytes data;
        bytes replacementPattern;
        address staticTarget;
        bytes staticExtradata;
        address paymentToken;
        uint256 basePrice;
        uint256 extra;
        uint256 listingTime;
        uint256 expirationTime;
        uint256 salt;
    }

    function initialize(address _downpayment, address _openseaExchange) external initializer {
        __BaseAdapter_init(NAME, VERSION, _downpayment);
        openseaExchange = IOpenseaExchage(_openseaExchange);
        proxy = openseaExchange.tokenTransferProxy();
    }

    function initWETH() external reinitializer(2) {
        __BaseAdapter_init(NAME, VERSION, address(downpayment));
    }

    struct CheckOrderParamsLocalVars {
        address buyerpaymentToken;
        address sellerpaymentToken;
        uint256 buyPrice;
        uint256 sellPrice;
    }

    function _checkParams(
        address,
        uint256,
        uint256,
        bytes memory _params,
        uint256 _nonce
    ) internal view override returns (BaseParams memory) {
        CheckOrderParamsLocalVars memory vars;

        Params memory _orderParams = _decodeParams(_params);
        address _WETH = address(WETH);

        // Check order params
        require(address(this) == _orderParams.addrs[1], "Adapter: buyer address error");
        vars.buyerpaymentToken = _orderParams.addrs[6];
        vars.sellerpaymentToken = _orderParams.addrs[13];
        require(
            address(0) == vars.buyerpaymentToken || _WETH == vars.buyerpaymentToken,
            "Adapter: buyer payment token should be ETH or WETH"
        );
        require(
            address(0) == vars.sellerpaymentToken || _WETH == vars.buyerpaymentToken,
            "Adapter: seller payment token should be ETH or WETH"
        );
        require(
            _orderParams.feeMethodsSidesKindsHowToCalls[2] == _orderParams.feeMethodsSidesKindsHowToCalls[6] &&
                0 == _orderParams.feeMethodsSidesKindsHowToCalls[2],
            "Adapter: order must be fixed price sale kind"
        );

        vars.buyPrice = _orderParams.uints[4];
        vars.sellPrice = _orderParams.uints[13];
        require(vars.buyPrice == vars.sellPrice, "Adapter: order price must be same");

        return
            BaseParams({
                nftAsset: _orderParams.nftAsset,
                nftTokenId: _orderParams.nftTokenId,
                currency: vars.buyerpaymentToken,
                salePrice: vars.sellPrice,
                paramsHash: _hashParams(_orderParams, _nonce)
            });
    }

    function _hashParams(Params memory _orderParams, uint256 _nonce) internal pure returns (bytes32) {
        Order memory buy;
        {
            buy.exchange = _orderParams.addrs[0];
            buy.maker = _orderParams.addrs[1];
            buy.taker = _orderParams.addrs[2];
            buy.makerRelayerFee = _orderParams.uints[0];
            buy.takerRelayerFee = _orderParams.uints[1];
            buy.makerProtocolFee = _orderParams.uints[2];
            buy.takerProtocolFee = _orderParams.uints[3];
            buy.feeRecipient = _orderParams.addrs[3];
            buy.feeMethod = _orderParams.feeMethodsSidesKindsHowToCalls[0];
            buy.side = _orderParams.feeMethodsSidesKindsHowToCalls[1];
            buy.saleKind = _orderParams.feeMethodsSidesKindsHowToCalls[2];
            buy.target = _orderParams.addrs[4];
            buy.howToCall = _orderParams.feeMethodsSidesKindsHowToCalls[3];
            buy.data = _orderParams.calldataBuy;
            buy.replacementPattern = _orderParams.replacementPatternBuy;
            buy.staticTarget = _orderParams.addrs[5];
            buy.staticExtradata = _orderParams.staticExtradataBuy;
            buy.paymentToken = _orderParams.addrs[6];
            buy.basePrice = _orderParams.uints[4];
            buy.extra = _orderParams.uints[5];
            buy.listingTime = _orderParams.uints[6];
            buy.expirationTime = _orderParams.uints[7];
            buy.salt = _orderParams.uints[8];
        }
        Order memory sell;
        {
            sell.exchange = _orderParams.addrs[7];
            sell.maker = _orderParams.addrs[8];
            sell.taker = _orderParams.addrs[9];
            sell.makerRelayerFee = _orderParams.uints[9];
            sell.takerRelayerFee = _orderParams.uints[10];
            sell.makerProtocolFee = _orderParams.uints[11];
            sell.takerProtocolFee = _orderParams.uints[12];
            sell.feeRecipient = _orderParams.addrs[10];
            sell.feeMethod = _orderParams.feeMethodsSidesKindsHowToCalls[4];
            sell.side = _orderParams.feeMethodsSidesKindsHowToCalls[5];
            sell.saleKind = _orderParams.feeMethodsSidesKindsHowToCalls[6];
            sell.target = _orderParams.addrs[11];
            sell.howToCall = _orderParams.feeMethodsSidesKindsHowToCalls[7];
            sell.data = _orderParams.calldataSell;
            sell.replacementPattern = _orderParams.replacementPatternSell;
            sell.staticTarget = _orderParams.addrs[12];
            sell.staticExtradata = _orderParams.staticExtradataSell;
            sell.paymentToken = _orderParams.addrs[13];
            sell.basePrice = _orderParams.uints[13];
            sell.extra = _orderParams.uints[14];
            sell.listingTime = _orderParams.uints[15];
            sell.expirationTime = _orderParams.uints[16];
            sell.salt = _orderParams.uints[17];
        }

        Sig memory buySig;
        {
            buySig.v = _orderParams.vs[0];
            buySig.r = _orderParams.rssMetadata[0];
            buySig.s = _orderParams.rssMetadata[1];
        }

        Sig memory sellSig;
        {
            sellSig.v = _orderParams.vs[1];
            sellSig.r = _orderParams.rssMetadata[2];
            sellSig.s = _orderParams.rssMetadata[3];
        }

        return
            keccak256(
                abi.encode(
                    _PARAMS_TYPEHASH,
                    _orderParams.nftAsset,
                    _orderParams.nftTokenId,
                    _hashOrder(buy),
                    _hashSig(buySig),
                    _hashOrder(sell),
                    _hashSig(sellSig),
                    _orderParams.rssMetadata[4],
                    _nonce
                )
            );
    }

    function _hashSig(Sig memory sig) internal pure returns (bytes32) {
        return keccak256(abi.encode(_SIGNATURE_TYPEHASH, sig.v, sig.r, sig.s));
    }

    function _hashOrder(Order memory order) internal pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    abi.encode(
                        _ORDER_TYPEHASH,
                        order.exchange,
                        order.maker,
                        order.taker,
                        order.makerRelayerFee,
                        order.takerRelayerFee,
                        order.makerProtocolFee,
                        order.takerProtocolFee,
                        order.feeRecipient,
                        order.feeMethod,
                        order.side,
                        order.saleKind,
                        order.target,
                        order.howToCall
                    ),
                    abi.encode(
                        keccak256(order.data),
                        keccak256(order.replacementPattern),
                        order.staticTarget,
                        keccak256(order.staticExtradata),
                        order.paymentToken,
                        order.basePrice,
                        order.extra,
                        order.listingTime,
                        order.expirationTime,
                        order.salt
                    )
                )
            );
    }

    function _exchange(BaseParams memory _baseParams, bytes memory _params) internal override {
        Params memory _orderParams = _decodeParams(_params);
        uint256 paymentValue = _baseParams.salePrice;
        if (_baseParams.currency == address(0)) {
            WETH.withdraw(paymentValue);
            openseaExchange.atomicMatch_{value: paymentValue}(
                _orderParams.addrs,
                _orderParams.uints,
                _orderParams.feeMethodsSidesKindsHowToCalls,
                _orderParams.calldataBuy,
                _orderParams.calldataSell,
                _orderParams.replacementPatternBuy,
                _orderParams.replacementPatternSell,
                _orderParams.staticExtradataBuy,
                _orderParams.staticExtradataSell,
                _orderParams.vs,
                _orderParams.rssMetadata
            );
        } else {
            WETH.approve(proxy, paymentValue);
            openseaExchange.atomicMatch_(
                _orderParams.addrs,
                _orderParams.uints,
                _orderParams.feeMethodsSidesKindsHowToCalls,
                _orderParams.calldataBuy,
                _orderParams.calldataSell,
                _orderParams.replacementPatternBuy,
                _orderParams.replacementPatternSell,
                _orderParams.staticExtradataBuy,
                _orderParams.staticExtradataSell,
                _orderParams.vs,
                _orderParams.rssMetadata
            );
            WETH.approve(proxy, 0);
        }
    }

    function _decodeParams(bytes memory _params) internal pure returns (Params memory) {
        return abi.decode(_params, (Params));
    }
}