// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Website: https://thexanaxpill.com
// Twitter: https://twitter.com/thexanaxpill
// Telegram: https://t.me/thexanaxpill
contract Xan is Ownable, ERC20 {
    enum TradingPhase {
        Paused,
        Presale,
        OpenMaxBuy,
        Open
    }
    uint256 public maxHoldingAmount;
    TradingPhase public tradingPhase = TradingPhase.Paused;
    IERC721 public constant xanpass = IERC721(0x0D5175ec9f247433E344434f5593Fa247a869e91);

    constructor() ERC20("XAN", "XAN") {
        // 100,000,000,000 XAN
        uint256 _totalSupply = 100_000_000_000 ether;
        _mint(msg.sender, _totalSupply);
        maxHoldingAmount = _totalSupply / 50; // 2%
    }

    function setXan(TradingPhase _phase, uint256 _maxHoldingAmount) external onlyOwner {
        tradingPhase = _phase;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        _validateTransfer(sender, recipient, amount);
        super._transfer(sender, recipient, amount);
    }

    function _validateTransfer(address sender, address recipient, uint256 amount) internal view {
        if (tradingPhase == TradingPhase.Paused) {
            require(sender == owner() || recipient == owner(), "Trading is paused.");
        } else if (tradingPhase == TradingPhase.Presale) {
            require(_whitelistedForPresale(sender, recipient), "Not whitelisted for presale.");
            require(_holdingAmountNotExceeded(sender, recipient, amount), "Max holding amount exceeded.");
        } else if (tradingPhase == TradingPhase.OpenMaxBuy) {
            require(_holdingAmountNotExceeded(sender, recipient, amount), "Max holding amount exceeded.");
        }
    }

    function _holdingAmountNotExceeded(address sender, address recipient, uint256 amount) internal view returns (bool) {
        return sender == owner() || recipient == owner() || super.balanceOf(recipient) + amount <= maxHoldingAmount;
    }

    function _whitelistedForPresale(address from, address to) internal view returns (bool) {
        // always true for owner
        if (from == owner() || to == owner()) {
            return true;
        }
        if (xanpass.balanceOf(from) > 0 || xanpass.balanceOf(to) > 0) {
            return true;
        }
        return false;
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}