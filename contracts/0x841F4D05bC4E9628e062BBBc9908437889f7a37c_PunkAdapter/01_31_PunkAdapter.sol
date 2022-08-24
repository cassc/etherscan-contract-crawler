// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {ICryptoPunksMarket} from "../interfaces/ICryptoPunksMarket.sol";
import {IWrappedPunks} from "../interfaces/IWrappedPunks.sol";

import {BaseAdapter} from "./BaseAdapter.sol";

contract PunkAdapter is BaseAdapter {
    string public constant NAME = "Punk Downpayment Adapter";
    string public constant VERSION = "1.0";
    // keccak256("Params(uint256 punkIndex,uint256 buyPrice,uint256 nonce)")
    bytes32 private constant _PARAMS_TYPEHASH = 0x6b29cf124b3dc1aa17558842fd2132ad2ce1b133d72a92d497136ab79534ccad;

    ICryptoPunksMarket public punksMarket;
    IWrappedPunks public wrappedPunks;
    address public wpunkProxy;

    struct Params {
        uint256 punkIndex;
        uint256 buyPrice;
    }

    function initialize(
        address _downpayment,
        address _cryptoPunksMarket,
        address _wrappedPunks
    ) external initializer {
        __BaseAdapter_init(NAME, VERSION, _downpayment);

        punksMarket = ICryptoPunksMarket(_cryptoPunksMarket);
        wrappedPunks = IWrappedPunks(_wrappedPunks);
        wrappedPunks.registerProxy();
        wpunkProxy = wrappedPunks.proxyInfo(address(this));
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
        Params memory _orderParams = _decodeParams(_params);

        ICryptoPunksMarket.Offer memory _sellOffer = punksMarket.punksOfferedForSale(_orderParams.punkIndex);

        // Check order params
        require(_sellOffer.isForSale, "Adapter: punk not actually for sale");
        require(_orderParams.buyPrice == _sellOffer.minValue, "Adapter: order price must be same");
        require(_sellOffer.onlySellTo == address(0), "Adapter: order must sell to zero address");

        return
            BaseParams({
                nftAsset: address(wrappedPunks),
                nftTokenId: _orderParams.punkIndex,
                currency: address(0),
                salePrice: _sellOffer.minValue,
                paramsHash: _hashParams(_orderParams, _nonce)
            });
    }

    function _hashParams(Params memory _orderParams, uint256 _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(_PARAMS_TYPEHASH, _orderParams.punkIndex, _orderParams.buyPrice, _nonce));
    }

    function _exchange(BaseParams memory _baseParams, bytes memory _params) internal override {
        Params memory _orderParams = _decodeParams(_params);
        WETH.withdraw(_baseParams.salePrice);
        punksMarket.buyPunk{value: _orderParams.buyPrice}(_orderParams.punkIndex);
    }

    function _beforeBorrowWETH(
        address _nftAsset,
        uint256 _nftTokenId,
        address _onBehalfOf,
        uint256 _amount
    ) internal override {
        _nftAsset;
        _nftTokenId;
        _onBehalfOf;
        _amount;

        require(address(wrappedPunks) == _nftAsset, "Adapter: not wpunks");
        require(punksMarket.punkIndexToAddress(_nftTokenId) == address(this), "Adapter: not owner of punkIndex");
        punksMarket.transferPunk(wpunkProxy, _nftTokenId);
        wrappedPunks.mint(_nftTokenId);
    }

    function _decodeParams(bytes memory _params) internal pure returns (Params memory) {
        return abi.decode(_params, (Params));
    }
}