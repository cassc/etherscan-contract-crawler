//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../transfer-proxy/ITransferProxy.sol";

error ErrInvalidAmount();
error ErrAlreadyOpen();
error ErrNotOpen();

error ErrExecutedBySeller();
error ErrNotEnoughItems();
error ErrIncorrectEtherValue();

error ErrInvalidServiceFee();

contract CruzoMarket is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    struct Trade {
        uint256 amount;
        uint256 price;
    }

    event TradeOpened(
        address tokenAddress,
        uint256 tokenId,
        address seller,
        uint256 amount,
        uint256 price
    );

    event TradeClosed(address tokenAddress, uint256 tokenId, address seller);

    event TradeExecuted(
        address tokenAddress,
        uint256 tokenId,
        address seller,
        address buyer,
        uint256 amount,
        uint256 price
    );

    event TradePriceChanged(
        address tokenAddress,
        uint256 tokenId,
        address seller,
        uint256 price
    );

    event ServiceFee(uint16 serviceFee);

    event WithdrawalCompleted(address beneficiaryAddress, uint256 _amount);

    ITransferProxy public transferProxy;

    // Service fee percentage in basis point (100bp = 1%)
    uint16 public serviceFee;

    // tokenAddress => tokenId => seller => trade
    mapping(address => mapping(uint256 => mapping(address => Trade)))
        public trades;

    constructor() {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize(ITransferProxy _transferProxy, uint16 _serviceFee)
        public
        initializer
    {
        __Ownable_init();

        transferProxy = _transferProxy;
        setServiceFee(_serviceFee);
    }

    function openTrade(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price
    ) external {
        if (_amount == 0) {
            revert ErrInvalidAmount();
        }

        address seller = _msgSender();

        if (trades[_tokenAddress][_tokenId][seller].amount > 0) {
            revert ErrAlreadyOpen();
        }

        trades[_tokenAddress][_tokenId][seller] = Trade({
            amount: _amount,
            price: _price
        });
        emit TradeOpened(_tokenAddress, _tokenId, seller, _amount, _price);
    }

    function closeTrade(address _tokenAddress, uint256 _tokenId) external {
        address seller = _msgSender();

        if (trades[_tokenAddress][_tokenId][seller].amount == 0) {
            revert ErrNotOpen();
        }

        delete trades[_tokenAddress][_tokenId][seller];
        emit TradeClosed(_tokenAddress, _tokenId, seller);
    }

    function changePrice(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _newPrice
    ) external {
        address seller = _msgSender();

        if (trades[_tokenAddress][_tokenId][seller].amount == 0) {
            revert ErrNotOpen();
        }

        trades[_tokenAddress][_tokenId][seller].price = _newPrice;
        emit TradePriceChanged(_tokenAddress, _tokenId, seller, _newPrice);
    }

    function executeTrade(
        address _tokenAddress,
        uint256 _tokenId,
        address _seller,
        uint256 _amount
    ) external payable {
        address buyer = _msgSender();

        if (buyer == _seller) {
            revert ErrExecutedBySeller();
        }

        if (_amount == 0) {
            revert ErrInvalidAmount();
        }

        Trade storage trade = trades[_tokenAddress][_tokenId][_seller];
        if (_amount > trade.amount) {
            revert ErrNotEnoughItems();
        }

        if (msg.value != trade.price * _amount) {
            revert ErrIncorrectEtherValue();
        }

        trade.amount -= _amount;
        transferProxy.safeTransferFrom(
            IERC1155Upgradeable(_tokenAddress),
            _seller,
            buyer,
            _tokenId,
            _amount,
            ""
        );
        _paymentProcessing(_tokenAddress, _seller, _tokenId, msg.value);
        emit TradeExecuted(
            _tokenAddress,
            _tokenId,
            _seller,
            buyer,
            _amount,
            trade.price
        );
    }

    function _paymentProcessing(
        address _tokenAddress,
        address _seller,
        uint256 _tokenId,
        uint256 _value
    ) internal {
        uint256 valueWithoutMarketplaceCommission = (_value *
            (10000 - uint256(serviceFee))) / 10000;
        (address royaltyReceiver, uint256 royaltyAmount) = IERC2981Upgradeable(
            _tokenAddress
        ).royaltyInfo(_tokenId, valueWithoutMarketplaceCommission);
        AddressUpgradeable.sendValue(payable(royaltyReceiver), royaltyAmount);
        AddressUpgradeable.sendValue(
            payable(_seller),
            valueWithoutMarketplaceCommission - royaltyAmount
        );
    }

    function setServiceFee(uint16 _newFee) public onlyOwner {
        if (_newFee > 10000) {
            revert ErrInvalidServiceFee();
        }

        serviceFee = _newFee;
        emit ServiceFee(_newFee);
    }

    function withdraw(address _beneficiaryAddress, uint256 _amount)
        public
        onlyOwner
    {
        AddressUpgradeable.sendValue(payable(_beneficiaryAddress), _amount);
        emit WithdrawalCompleted(_beneficiaryAddress, _amount);
    }
}