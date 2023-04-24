// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FuckIt is ERC20, Ownable {

    bool public limited = true;
    uint256 public maxHoldingAmount = 690000 ether;
    uint256 public minHoldingAmount = 69000 ether;
    address public uniswapV2Pair;

    constructor() ERC20("FUCKIT", "FUCKIT") {
        _mint(msg.sender, 69000000 ether);
    }

    function setLimited(bool _limited) external onlyOwner {
        limited = _limited;
    }

    function setPair(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
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

        if (limited && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid");
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

}