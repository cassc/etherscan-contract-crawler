// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../registry/Registry.sol";

interface IERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
}

interface IERC721 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
}

struct NiftyEvent {
    uint256 sellerProceeds;
    uint256 price;
    uint256 tokenId; 
    address tokenContract; 
    address seller;
    address buyer;
}

struct NiftyEventHandler {
    uint256 refund; ///
    uint256 sellerProceeds;
    uint256 price;
    uint256 tokenId; 
    address tokenContract; 
    address seller;
    address buyer;
}

struct NiftyEventReceiver {
    uint256 sellerProceeds;
    uint256 price;
    uint256 tokenId;
    address tokenContract;
    address seller;
    address buyer;
    address priceCurrency;
    address[] receiverCreators;
    uint256[] receiverAmounts;
}

struct NiftyEventReceiverHandler {
    uint256 refund; ///
    uint256 sellerProceeds;
    uint256 price;
    uint256 tokenId;
    address tokenContract;
    address seller;
    address buyer;
    address priceCurrency;
    address[] receiverCreators;
    uint256[] receiverAmounts;
}

struct NiftyEventBatch {
    uint256 tokenId;
    uint256 count; /// @notice Value of '0' indicates ERC-721 token
    uint256 sellerProceeds; /// @notice Amount remitted to seller
    uint256 price;
    address priceCurrency; /// @notice Settlement currency (USD, ETH, ERC-20)
    address tokenContract;
    address seller;
    address buyer;
    address[] receiverCreators;
    uint256[] receiverAmounts;
}

/**
 *
 */
abstract contract ExecutorCore is Registry {

    address constant public _priceCurrencyETH = address(0);

    address immutable public _priceCurrencyUSD;

    event NiftySale721(address indexed tokenContract, uint256 tokenId, uint256 price, address priceCurrency);

    event NiftySale1155(address indexed tokenContract, uint256 tokenId, uint256 count, uint256 price, address priceCurrency);

    constructor(address priceCurrencyUSD_, address recoveryAdmin_, address[] memory validSenders_) Registry(recoveryAdmin_, validSenders_) {
        _priceCurrencyUSD = priceCurrencyUSD_;
    }

    /**
     *
     */
    function _transferEth(address recipient, uint256 value) internal {
        (bool success,) = payable(recipient).call{value: value}("");
        require(success, "NiftyExchangeExecutor: Value transfer unsuccessful");
    }

    function _transfer20(uint256 value, address token, address to) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _transfer721(uint256 price, address priceCurrency, uint256 tokenId, address tokenContract, address seller, address buyer) internal {
        IERC721(tokenContract).safeTransferFrom(seller, buyer, tokenId);
        emit NiftySale721(tokenContract, tokenId, price, priceCurrency);
    }

    function _transfer721handler(uint256 price, address priceCurrency, uint256 tokenId, address tokenContract, address seller, address buyer) internal returns (bool) {
        try IERC721(tokenContract).safeTransferFrom(seller, buyer, tokenId) {
            emit NiftySale721(tokenContract, tokenId, price, priceCurrency);
            return true;
        } catch {
            return false;
        }
    }

    function _transfer1155(uint256 count, uint256 price, address priceCurrency, uint256 tokenId, address tokenContract, address seller, address buyer) internal {
        IERC1155(tokenContract).safeTransferFrom(seller, buyer, tokenId, count, "");
        emit NiftySale1155(tokenContract, tokenId, count, price, priceCurrency); /// @notice 'price' describes entire purchase.
    }

    function _transfer1155handler(uint256 count, uint256 price, address priceCurrency, uint256 tokenId, address tokenContract, address seller, address buyer) internal returns (bool) {
        try IERC1155(tokenContract).safeTransferFrom(seller, buyer, tokenId, count, "") {
            emit NiftySale1155(tokenContract, tokenId, count, price, priceCurrency);
            return true;
        } catch {
            return false;
        }
    }

    function _recordSale721(address tokenContract, uint256 tokenId, uint256 price, address priceCurrency) internal {
        emit NiftySale721(tokenContract, tokenId, price, priceCurrency);
    }

    function _recordSale1155(address tokenContract, uint256 tokenId, uint256 count, uint256 price, address priceCurrency) internal {
        emit NiftySale1155(tokenContract, tokenId, count, price, priceCurrency);
    }

    function _executeSwitcher(
        address currency, 
        uint256 sellerProceeds, 
        address seller, 
        address[] calldata receiverCreators, 
        uint256[] calldata receiverAmounts) internal {
        bool eth = currency == _priceCurrencyETH;
        if(sellerProceeds > 0){
            if(eth){
                _transferEth(seller, sellerProceeds);
            } else {
                _transfer20(sellerProceeds, currency, seller);
            }
        }
        uint256 receiverCount = receiverCreators.length;
        if(receiverCount > 0){
            for(uint256 i = 0; i < receiverCount; i++){
                if(eth){
                    _transferEth(receiverCreators[i], receiverAmounts[i]);
                } else {
                    _transfer20(receiverAmounts[i], currency, receiverCreators[i]);
                }
            }
        }
    }

    function _executeRefund(uint256 refund, address currency, address buyer) internal {
        if(refund > 0){
            if(currency == _priceCurrencyETH) {
                _transferEth(buyer, refund);
            } else {
                _transfer20(refund, currency, buyer);
            }
        }
    }

}