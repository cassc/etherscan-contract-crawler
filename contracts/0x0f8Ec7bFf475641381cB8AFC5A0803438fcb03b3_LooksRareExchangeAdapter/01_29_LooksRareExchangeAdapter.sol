// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {ILooksRareExchange} from "../interfaces/ILooksRareExchange.sol";
import {IAuthorizationManager} from "../interfaces/IAuthorizationManager.sol";

import {BaseAdapter} from "./BaseAdapter.sol";

contract LooksRareExchangeAdapter is BaseAdapter {
    string public constant NAME = "LooksRare Exchange Downpayment Adapter";
    string public constant VERSION = "1.0";

    //keccak256("Params(bool isOrderAsk,address maker,address collection,uint256 price,uint256 tokenId,uint256 amount,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes params,uint8 v,bytes32 r,bytes32 s,uint256 nonce2)");
    bytes32 private constant _PARAMS_TYPEHASH = 0x76d79daa40cbf59c4fdf35cabe40443c33a9adda5759136a0734e7e272104c54;

    ILooksRareExchange public looksRareExchange;

    function initialize(address _downpayment, address _looksRareExchange) external initializer {
        __BaseAdapter_init(NAME, VERSION, _downpayment);
        looksRareExchange = ILooksRareExchange(_looksRareExchange);
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
        ILooksRareExchange.MakerOrder memory _orderParams = _decodeParams(_params);

        // Check order params
        require(_orderParams.isOrderAsk, "Adapter: maker must ask order");
        require(_orderParams.currency == address(WETH), "Adapter: currency must be WETH");
        return
            BaseParams({
                nftAsset: _orderParams.collection,
                nftTokenId: _orderParams.tokenId,
                currency: _orderParams.currency,
                salePrice: _orderParams.price,
                paramsHash: _hashParams(_orderParams, _nonce)
            });
    }

    function _hashParams(ILooksRareExchange.MakerOrder memory _orderParams, uint256 _nonce)
        internal
        pure
        returns (bytes32)
    {
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
                    abi.encode(keccak256(_orderParams.params), _orderParams.v, _orderParams.r, _orderParams.s, _nonce)
                )
            );
    }

    function _exchange(BaseParams memory _baseParams, bytes memory _params) internal override {
        ILooksRareExchange.MakerOrder memory makerAsk = _decodeParams(_params);
        ILooksRareExchange.TakerOrder memory takerBid;
        {
            takerBid.isOrderAsk = false;
            takerBid.taker = address(this);
            takerBid.price = makerAsk.price;
            takerBid.tokenId = makerAsk.tokenId;
            takerBid.minPercentageToAsk = 0;
            takerBid.params = new bytes(0);
        }
        WETH.approve(address(looksRareExchange), _baseParams.salePrice);
        looksRareExchange.matchAskWithTakerBidUsingETHAndWETH(takerBid, makerAsk);
        WETH.approve(address(looksRareExchange), 0);
    }

    function _decodeParams(bytes memory _params) internal pure returns (ILooksRareExchange.MakerOrder memory) {
        return abi.decode(_params, (ILooksRareExchange.MakerOrder));
    }
}