// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from"@openzeppelin/contracts/access/Ownable.sol";

contract PraiseToken is ERC20, Ownable {
    address private uniswapV2Pair;
    uint public constant MAX_WALLET = (21000000000000 * 10 ** 18) / 100;

    constructor() ERC20("Praise Token", "$PRAISE") {
        _mint(msg.sender, 21000000000000 * 10 ** decimals());
    }

    /// @notice This method sets the uniswap pair address. Once set trading will commence.
    /// @param _uniswapV2Pair The pair address to set.
    function initializeLp(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal virtual override {
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "!trading");
            return;
        }

        if (from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= MAX_WALLET, "> max amt");
        }
    }
}