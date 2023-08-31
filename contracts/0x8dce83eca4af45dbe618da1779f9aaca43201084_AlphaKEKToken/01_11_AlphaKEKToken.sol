// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// @custom:website App: https://alphakek.ai/
// @custom:website Telegram: https://t.me/alphakek 
// @custom:website Twitter: https://twitter.com/alphakek_ai
// @notice AlphaKEKToken is a main token of AlphaKEK platform.

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract AlphaKEKToken is ERC20, Ownable, ReentrancyGuard {
    using Address for address payable;

    IUniswapV2Router02 public immutable _router;
    address public immutable _weth9;
    address public immutable _pair;

    address public _treasury;
    bool public _trading;
    uint8 public _tax = 40;

    error ZeroAddress();

    event TreasuryChanged(address newTreasury);
    event TaxChanged(uint8 newValue);

    constructor(
        address treasury_,
        address router_,
        address mintTo_
    ) ERC20("AlphaKEK.AI", "AIKEK") Ownable() {
        _mint(mintTo_, 256e6 * 10 ** decimals());
        _treasury = treasury_;
        _router = IUniswapV2Router02(router_);
        _weth9 = _router.WETH();
        _pair = IUniswapV2Factory(_router.factory()).createPair(
            address(this),
            _weth9
        );
    }

    function enableTrading() external onlyOwner {
        _trading = true;
    }

    function disableTrading() external onlyOwner {
        _trading = false;
    }

    function setTreasuryAddress(address newTreasury_) external onlyOwner {
        if (newTreasury_ == address(0)) {
            revert ZeroAddress();
        }
        _treasury = newTreasury_;
        emit TreasuryChanged(newTreasury_);
    }

    function setTax(uint8 newTax_) external onlyOwner {
        _tax = newTax_;
        emit TaxChanged(newTax_);
    }

    function _transfer(
        address sender_,
        address recipient_,
        uint256 amount_
    ) internal virtual override {
        address pair = _pair;
        if (sender_ == address(this) || !_trading) {
            super._transfer(sender_, recipient_, amount_);
        } else if (sender_ != pair && recipient_ != pair) {
            super._transfer(sender_, recipient_, amount_);
        } else {
            uint fee = (amount_ * _tax) / 1000;
            uint amt = amount_ - fee;

            super._transfer(sender_, address(this), fee);

            if (sender_ != pair) {
                _distributeFee();
            }

            super._transfer(sender_, recipient_, amt);
        }
    }

    function _distributeFee() internal nonReentrant {
        uint amount = balanceOf(address(this));
        if (amount >= 0) {
            _swapTokensForETH(amount);
        }
    }

    function _swapTokensForETH(uint256 amount_) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _weth9;
        _approve(address(this), address(_router), amount_);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount_,
            0,
            path,
            _treasury,
            block.timestamp
        );
    }
}