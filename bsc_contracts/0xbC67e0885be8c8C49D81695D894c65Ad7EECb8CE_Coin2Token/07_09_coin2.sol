// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../public/ipancakerouter.sol";
import "../public/ipancakefactory.sol";

// import "hardhat/console.sol";

contract Coin2Token is ERC20, Ownable {
    using Address for address;

    uint256 public _totalTaxIfBuying = 1;
    uint256 public _totalTaxIfSelling = 1;
    uint256 public _buyFeeAmount;
    uint256 public _sellFeeAmount;

    bool public swap = true;
    bool private swaping = false;

    address public tokenOwner;
    address public pancakePair;
    address public receiveBuyFeeWallet =
        0x9AA2370d4b87C1980297fB2c4Bba563C16050CF5;
    address public receiveSellFeeWallet =
        0x000000000000000000000000000000000000dEaD;
    IERC20 public usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IPancakeRouter01 public PancakeRouter01 =
        IPancakeRouter01(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    mapping(address => bool) public isMarketPair;

    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        IERC20 _usdt,
        IPancakeRouter01 _PancakeRouter01
    ) ERC20(name_, symbol_) {
        if (totalSupply_ > 0) {
            super._mint(owner_, totalSupply_);
            tokenOwner = owner_;
        }
        PancakeRouter01 = _PancakeRouter01;
        pancakePair = IPancakeFactory(PancakeRouter01.factory()).createPair(
            address(this),
            address(usdt)
        );
        isMarketPair[pancakePair] = true;
        usdt = _usdt;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(
            sender != address(0),
            "ERC20: transfer sender the zero address"
        );
        require(
            recipient != address(0),
            "ERC20: transfer recipient the zero address"
        );
        if (amount == 0) {
            super._transfer(sender, recipient, 0);
            return;
        }
        bool freeOfCharge = sender == address(this) ||
            sender == owner() ||
            sender == receiveBuyFeeWallet ||
            tokenOwner == sender ||
            sender == receiveSellFeeWallet ||
            recipient == address(this) ||
            recipient == owner() ||
            tokenOwner == recipient ||
            recipient == receiveBuyFeeWallet ||
            recipient == receiveSellFeeWallet;
        if (!freeOfCharge) {
            bool isSwap = sender == pancakePair || recipient == pancakePair;
            require(!isSwap || swap, "swap not open");
            uint256 feeAmount = 0;
            if (isMarketPair[sender]) {
                feeAmount = (amount * _totalTaxIfBuying) / 100;
                super._transfer(sender, address(this), feeAmount);
                _buyFeeAmount = _buyFeeAmount + feeAmount;
            } else if (isMarketPair[recipient]) {
                feeAmount = (amount * _totalTaxIfSelling) / 100;
                super._transfer(sender, address(this), feeAmount);
                _sellFeeAmount = _sellFeeAmount + feeAmount;
            }
            amount = amount - feeAmount;
            uint256 currentBalance = balanceOf(address(this));
            if (currentBalance > 0 && !swaping && sender != pancakePair) {
                swaping = true;
                if (_buyFeeAmount > 0) {
                    _swapTokensForUsdt(_buyFeeAmount, receiveBuyFeeWallet);
                }
                if (_sellFeeAmount > 0) {
                    // _burn(sender, _sellFeeAmount);
                    _swapTokensForUsdt(_sellFeeAmount, receiveBuyFeeWallet);
                }
                _buyFeeAmount = 0;
                _sellFeeAmount = 0;
                swaping = false;
            }
        }
        super._transfer(sender, recipient, amount);
    }

    function _swapTokensForUsdt(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(usdt);
        _approve(address(this), address(PancakeRouter01), tokenAmount);
        PancakeRouter01.swapExactTokensForTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }
}