// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {IBendExchange} from "../interfaces/IBendExchange.sol";
import {IAuthorizationManager} from "../interfaces/IAuthorizationManager.sol";

import {BaseAdapter} from "./BaseAdapter.sol";

contract BendExchangeAdapter is BaseAdapter {
    string public constant NAME = "Bend Exchange Downpayment Adapter";
    string public constant VERSION = "1.0";

    //keccak256("Params(bool isOrderAsk,address maker,address collection,uint256 price,uint256 tokenId,uint256 amount,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes params,address interceptor,bytes interceptorExtra,uint8 v,bytes32 r,bytes32 s,uint256 nonce2)");
    bytes32 private constant _PARAMS_TYPEHASH = 0x6482968240152d913828da2846e216aa4e202dd2e56802d8dfd4767d64867463;

    IBendExchange public bendExchange;
    address private proxy;

    function initialize(address _downpayment, address _bendExchange) external initializer {
        __BaseAdapter_init(NAME, VERSION, _downpayment);

        bendExchange = IBendExchange(_bendExchange);
        proxy = IAuthorizationManager(bendExchange.authorizationManager()).registerProxy();
    }

    function initWETH() external reinitializer(2) {
        __BaseAdapter_init(NAME, VERSION, address(downpayment));
    }

    function _checkParams(
        address,
        uint256,
        uint256,
        bytes memory _params,
        uint256 _nonce
    ) internal view override returns (BaseParams memory) {
        IBendExchange.MakerOrder memory _orderParams = _decodeParams(_params);

        // Check order params
        require(_orderParams.isOrderAsk, "Adapter: maker must ask order");
        require(
            _orderParams.currency == address(WETH) || _orderParams.currency == address(0),
            "Adapter: currency must be ETH or WETH"
        );
        return
            BaseParams({
                nftAsset: _orderParams.collection,
                nftTokenId: _orderParams.tokenId,
                currency: _orderParams.currency,
                salePrice: _orderParams.price,
                paramsHash: _hashParams(_orderParams, _nonce)
            });
    }

    function _hashParams(IBendExchange.MakerOrder memory _orderParams, uint256 _nonce) internal pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    abi.encode(
                        _PARAMS_TYPEHASH,
                        _orderParams.isOrderAsk,
                        _orderParams.maker,
                        _orderParams.collection,
                        _orderParams.price,
                        _orderParams.tokenId,
                        _orderParams.amount,
                        _orderParams.strategy,
                        _orderParams.currency,
                        _orderParams.nonce,
                        _orderParams.startTime,
                        _orderParams.endTime,
                        _orderParams.minPercentageToAsk
                    ),
                    abi.encode(
                        keccak256(_orderParams.params),
                        _orderParams.interceptor,
                        keccak256(_orderParams.interceptorExtra),
                        _orderParams.v,
                        _orderParams.r,
                        _orderParams.s,
                        _nonce
                    )
                )
            );
    }

    function _exchange(BaseParams memory _baseParams, bytes memory _params) internal override {
        IBendExchange.MakerOrder memory makerAsk = _decodeParams(_params);
        IBendExchange.TakerOrder memory takerBid;
        {
            takerBid.isOrderAsk = false;
            takerBid.taker = address(this);
            takerBid.price = makerAsk.price;
            takerBid.tokenId = makerAsk.tokenId;
            takerBid.minPercentageToAsk = 0;
            takerBid.params = new bytes(0);
            takerBid.interceptor = address(0);
            takerBid.interceptorExtra = new bytes(0);
        }

        WETH.approve(proxy, _baseParams.salePrice);
        bendExchange.matchAskWithTakerBidUsingETHAndWETH(takerBid, makerAsk);
        WETH.approve(proxy, 0);
    }

    function _decodeParams(bytes memory _params) internal pure returns (IBendExchange.MakerOrder memory) {
        return abi.decode(_params, (IBendExchange.MakerOrder));
    }
}