// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Pulk is Ownable, ERC20 {
    bool public limited;
    uint256 public minHoldingAmount;
    uint256 public maxHoldingAmount;
    address public uniswapV2Pair;
    mapping(address => bool) public blacklisted;

    constructor() ERC20("Pulk", "PULK") {
        _mint(msg.sender, 420_690_000_000_000 * 10 ** decimals());

        limited = true;
        // User must buy at least 0.2% of supply during limit.
        minHoldingAmount = totalSupply() / 500;
        // User must buy at most 0.6% of supply during limit.
        maxHoldingAmount = (totalSupply() * 3) / 500;
    }

    // Blacklists wallets suspected to be bots by the team.
    // Useless after renouncing the contract.
    function blacklist(address account) external onlyOwner {
        blacklisted[account] = true;
    }

    // Sets the liquidity pool address and opens trading.
    // Cannot be called again once pool is set. Trading can no longer stop.
    function setPool(address uniswapV2Pair_) external onlyOwner {
        require(uniswapV2Pair == address(0), "Pool is already set.");
        uniswapV2Pair = uniswapV2Pair_;
    }

    // Removes the buy limits.
    function removeLimits() external onlyOwner {
        limited = false;
        minHoldingAmount = 0;
        maxHoldingAmount = 0;
    }

    // Makes sure user holding amount is within limits.
    // Useless after removing the limits.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklisted[to] && !blacklisted[from], "Blacklisted.");

        if (uniswapV2Pair == address(0)) {
            require(
                from == owner() || to == owner(),
                "Trading has not started yet."
            );
            return;
        }

        if (limited && from == uniswapV2Pair) {
            require(
                balanceOf(to) + amount <= maxHoldingAmount &&
                    balanceOf(to) + amount >= minHoldingAmount,
                "Transaction not within limits."
            );
        }
    }
}