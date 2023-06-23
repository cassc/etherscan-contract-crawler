// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
contract TitanicSub is ERC20, Ownable {
    bool public limited;
    uint256 public maxHoldingAmount;
    address public uniswapV2Pair;

    constructor() ERC20("Titanic Sub", "TITA") {
        _mint(msg.sender, 50000000000 * 10 ** decimals());
    }

    function setRule(bool _limited, address _uniswapV2Pair, uint256 _maxHoldingAmount) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }
        if (limited && to != owner() && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount, "Forbid");
        }
    }
}