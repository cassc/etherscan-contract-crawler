// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./daiwo_token.sol";

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IUSDT.sol";

contract DaiwoStorefront is Ownable2Step, Pausable {
    event PriceUpdate(
        uint256 buyPriceNumerator,
        uint256 buyPriceDenominator,
        uint256 sellPriceNumerator,
        uint256 sellPriceDenominator
    );

    event Buy(address indexed from, address indexed to, uint256 tokensBought);

    event Sell(address indexed from, address indexed to, uint256 tokensSold);

    event Withdraw(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount
    );

    uint256 public buyPriceNumerator;
    uint256 public buyPriceDenominator;
    uint256 public sellPriceNumerator;
    uint256 public sellPriceDenominator;

    IERC20 public token;
    IUSDT public USDT;

    constructor(
        address USDTaddress,
        address tokenAddress,
        uint256 _buyPriceNumerator,
        uint256 _buyPriceDenominator,
        uint256 _sellPriceNumerator,
        uint256 _sellPriceDenominator
    ) {
        USDT = IUSDT(USDTaddress);
        token = IERC20(tokenAddress);
        _checkAndSetPrices(
            _buyPriceNumerator,
            _buyPriceDenominator,
            _sellPriceNumerator,
            _sellPriceDenominator
        );
    }

    function setPrices(
        uint256 _buyPriceNumerator,
        uint256 _buyPriceDenominator,
        uint256 _sellPriceNumerator,
        uint256 _sellPriceDenominator
    ) external onlyOwner {
        _checkAndSetPrices(
            _buyPriceNumerator != 0 ? _buyPriceNumerator : buyPriceNumerator,
            _buyPriceDenominator != 0
                ? _buyPriceDenominator
                : buyPriceDenominator,
            _sellPriceNumerator != 0 ? _sellPriceNumerator : sellPriceNumerator,
            _sellPriceDenominator != 0
                ? _sellPriceDenominator
                : sellPriceDenominator
        );
    }

    function _checkAndSetPrices(
        uint256 _buyPriceNumerator,
        uint256 _buyPriceDenominator,
        uint256 _sellPriceNumerator,
        uint256 _sellPriceDenominator
    ) private {
        uint256 ls = _buyPriceNumerator * _sellPriceDenominator;
        uint256 rs = _sellPriceNumerator * _buyPriceDenominator;
        uint256 p = ls * rs;
        require(
            ls >= rs,
            "Buying price should be bigger than or equal to selling price"
        );
        require(p > 0, "Zero parameter");
        buyPriceNumerator = _buyPriceNumerator;
        buyPriceDenominator = _buyPriceDenominator;
        sellPriceNumerator = _sellPriceNumerator;
        sellPriceDenominator = _sellPriceDenominator;
        emit PriceUpdate(
            _buyPriceNumerator,
            _buyPriceDenominator,
            _sellPriceNumerator,
            _sellPriceDenominator
        );
    }

    function buy(uint256 amount) external whenNotPaused {
        USDT.transferFrom(
            msg.sender,
            address(this),
            (amount * buyPriceNumerator) / buyPriceDenominator
        );
        require(token.transfer(msg.sender, amount), "Token transfer failed");
        emit Buy(address(this), msg.sender, amount);
    }

    function sell(uint256 amount) external whenNotPaused {
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Token transfer failed"
        );
        USDT.transfer(
            msg.sender,
            (amount * sellPriceNumerator) / sellPriceDenominator
        );
        emit Sell(msg.sender, address(this), amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawTokens(address _to, uint256 amount) external onlyOwner {
        token.transfer(_to, amount);
        emit Withdraw(address(token), msg.sender, _to, amount);
    }

    function withdrawUSDT(address _to, uint256 amount) external onlyOwner {
        USDT.transfer(_to, amount);
        emit Withdraw(address(USDT), msg.sender, _to, amount);
    }
}