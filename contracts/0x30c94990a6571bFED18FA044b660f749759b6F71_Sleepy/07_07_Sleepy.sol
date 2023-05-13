// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//   ____  _                           _
//  / ___|| | ___  ___ _ __  _   _    | | ___   ___   __ _ _ __  _ __
//  \___ \| |/ _ \/ _ \ '_ \| | | |_  | |/ _ \ / _ \ / _` | '_ \| '_ \
//   ___) | |  __/  __/ |_) | |_| | |_| | (_) |  __/| (_| | |_) | |_) |
//  |____/|_|\___|\___| .__/ \__, |\___/ \___/ \___(_)__,_| .__/| .__/
//                    |_|    |___/                        |_|   |_|
// Visit https://sleepyjoe.app
// Join our telegram https://t.me/+n3tejharUCRjNTY0
// Join our discord https://discord.gg/XKdUt3bnV4

contract Sleepy is Ownable, ERC20, ERC20Burnable {
    uint256 public maxTradeAmount;
    address public uniswapV2Pair;
    address public sleepyJoeBank;

    constructor(
        address teamWallet,
        address marketingWallet,
        address cexWallet
    ) ERC20("Sleepy", "SLEEPY") {
        // 1 token for every dollar of U.S. federal debt
        uint256 totalSupply = 32_000_000_000_000 * 10 ** 18;
        // 4.20% of total supply is allocated to the team
        _mint(teamWallet, (totalSupply * 420) / 10000);
        // 4.20% of total supply is allocated for marketing
        _mint(marketingWallet, (totalSupply * 420) / 10000);
        // 4.20% of total supply is allocated for the CEX listing
        _mint(cexWallet, (totalSupply * 420) / 10000);
        // 87.4% of total supply is allocated for the liquidity pool
        _mint(msg.sender, (totalSupply * 8740) / 10000);
    }

    /// @notice Sets the trading rule for the token
    /// @param _sleepyJoeBank The address of the sleepyJoeBank contract
    /// @param _uniswapV2Pair The address of the Uniswap V2 pair
    /// @param _maxTradeAmount The maximum amount of tokens that can be traded at once
    function setRule(
        address _sleepyJoeBank,
        address _uniswapV2Pair,
        uint256 _maxTradeAmount
    ) external onlyOwner {
        sleepyJoeBank = _sleepyJoeBank;
        uniswapV2Pair = _uniswapV2Pair;
        maxTradeAmount = _maxTradeAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (uniswapV2Pair == address(0)) {
            require(
                from == owner() || to == owner() || from == address(0),
                "trading is not started"
            );
            return;
        }
        if (
            maxTradeAmount > 0 && (to == uniswapV2Pair || from == uniswapV2Pair)
        ) {
            require(amount <= maxTradeAmount, "Forbid");
        }
    }

    /// @notice Allows the sleepyJoeBank to mint new tokens
    /// @param recipient The address to receive the stimulus
    /// @param stimulusAmount The amount of stimulus to mint
    function payStimulus(address recipient, uint256 stimulusAmount) external {
        require(msg.sender == sleepyJoeBank, "no permission");
        _mint(recipient, stimulusAmount);
    }
}