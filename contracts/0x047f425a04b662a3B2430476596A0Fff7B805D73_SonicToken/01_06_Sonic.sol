//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

/**
 * Welcome to Sonic MEME hunter Band!
 * Once upon a time, there was a blue blur with an insatiable appetite for adventure and memes. His name was Sonic, but he wasn't your typical hero. No, Sonic had a degen side that set him apart from the rest. His ultimate goal? Discovering and collecting all the glorious memes coins scattered throughout the universe.
 * Website: https://www.sonic.band
 * Telegram: https://t.me/SONICBAND
 * Launch plan: 
 * - first ~10mins: 
 *    - 20% buy tax & 45% sell tax 
 *    - maxHolding 1% 
 * - Then: 
 *    - remove taxes
 *    - maxHolding 2% for ever
 *    - renonce owernship
 * - burn 95% of liquidity
 * - 🌕
 */
contract SonicToken is Ownable, ERC20 {
    address public uniswapV2Pair;
    uint256 public maxHoldingAmount; 
    uint256 public buyFee = 20; 
    uint256 public sellFee = 45; 
    address constant public feeRecipient = 0x81b548391fe432799b28eF06BAbC94b1CF2e3Db1;

    constructor(uint256 _totalSupply) ERC20("SonicBand", "SONIC") {
        _mint(msg.sender, _totalSupply);
    }

    function setRule(address _uniswapV2Pair, uint256 _maxHoldingAmount, uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        buyFee = _buyFee;
        sellFee = _sellFee;
    }

    function _transfer(address from, address to, uint256 amount) internal override(ERC20)  {
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
        }

        if(from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount, "Forbid");
            uint256 buyFeeAmount = amount * buyFee / 100;
            amount = amount - buyFeeAmount;
            super._transfer(from, feeRecipient, buyFeeAmount);
        }

        if (to == uniswapV2Pair) {
            uint256 sellFeeAmount = amount * sellFee / 100;
            amount = amount - sellFeeAmount;
            super._transfer(from, feeRecipient, sellFeeAmount);
        }

        super._transfer(from, to, amount);    
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}