// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../libs/utils/ERC721OnlySelfInitHolder.sol";
import "./StakingParts/NFTOrdersStorage.sol";
import "./StakingParts/Erc20Treasury.sol";
import "./StakingParts/Erc721Treasury.sol";

contract NPOSTMarketPlace is
    Initializable,
    OwnableUpgradeable,
    NFTOrdersStorage,
    Erc20Treasury,
    Erc721Treasury
{

    function initialize(
        uint256 _feeInPromille,
        address _NPOSTtoken,
        address _uniswapV2Router
    )
        public
        initializer
    {
        __Ownable_init();
        __init_NFTOrdersStorage();
        __init_Erc20Treasury(
            _feeInPromille,
            _NPOSTtoken,
            _uniswapV2Router
        );
        __init_Unlocked();
    }

//////////////////////////////////////////// Erc20Treasury

    function editFee(
        uint256 _feeInPromille
    )
        public
        onlyOwner
    {
        _editFee(_feeInPromille);
    }

//////////////////////////////////////////// events

    event CreateOrder(
        uint256 orderId,
        address receivePaymentAccount,
        address seller,
        address buyer,
        uint256 priceInETH,
        uint256 fee,
        address tokenAddress,
        uint256 tokenId,
        uint256 deadline
    );

    event ExecuteOrder(
        uint256 orderId,
        address seller,
        address buyer
    );

    event RedeemNftFromOrder(
        uint256 orderId
    );

//////////////////////////////////////////// order methods view

    function getSelfSellerOrders()
        public
        view
        returns (OrderInfo[] memory)
    {
        return _getSellerOrders(_msgSender());
    }

    function getSelfOpenSellerOrders()
        public
        view
        returns (OrderInfo[] memory)
    {
        return _getOpenSellerOrders(_msgSender());
    }

    function getSelfBuyerOrders()
        public
        view
        returns (OrderInfo[] memory)
    {
        return _getBuyerOrders(_msgSender());
    }

    function getSelfOpenBuyerOrders()
        public
        view
        returns (OrderInfo[] memory)
    {
        return _getOpenBuyerOrders(_msgSender());
    }

    function getPublicOpenBuyerOrders()
        public
        view
        returns (OrderInfo[] memory)
    {
        return _getOpenBuyerOrders(address(0));
    }

//////////////////////////////////////////// order methods write

    function createOrder(
        address _receivePaymentAccount,
        address _buyer,
        uint256 _priceInETH,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _deadline
    )
        public
    {
        _takeErc721FromTokenOwner(
            _tokenAddress,
            _tokenId
        );
        uint256 feeInEth = calculateFeeInEth(_priceInETH);
        OrderInfo storage order = _createOrder(
            _receivePaymentAccount,
            _msgSender(),
            _buyer,
            _priceInETH,
            feeInEth,
            _tokenAddress,
            _tokenId,
            _deadline
        );

        emit CreateOrder(
            order.orderId,
            order.receivePaymentAccount,
            order.seller,
            order.buyer,
            order.priceInETH,
            order.fee,
            order.tokenAddress,
            order.tokenId,
            order.deadline
        );
    }


    function tryExecuteOrder(
        uint256 _orderId,
        address _nftReceiver
    )
        public
        payable
    {
        OrderInfo storage order = _tryExecuteOrder(
            _orderId,
            _msgSender()
        );
        require(order.priceInETH <= msg.value, 'tryExecuteOrder: msg.value should be same order.priceInETH');
        _takeEthAndBurnFee(
            order.fee
        );
        _sendEth(
            order.priceInETH - order.fee,
            order.receivePaymentAccount
        );

        _sendErc721ToAccount(
            _nftReceiver == address(0) ? _msgSender() : _nftReceiver,
            order.tokenAddress,
            order.tokenId
        );

        emit ExecuteOrder(
            order.orderId,
            order.seller,
            order.buyer
        );
    }

    function tryRedeemNftFromOrder(
        uint256 _orderId
    )
        public
    {
        OrderInfo storage order = _tryRedeemNftFromOrder(
            _orderId,
            _msgSender()
        );
        _sendErc721ToAccount(
            order.seller,
            order.tokenAddress,
            order.tokenId
        );

        emit RedeemNftFromOrder(
            order.orderId
        );
    }
}