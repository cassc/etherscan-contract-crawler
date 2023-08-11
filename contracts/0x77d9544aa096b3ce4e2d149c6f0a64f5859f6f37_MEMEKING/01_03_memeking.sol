// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "./ERC20.sol";


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract MEMEKING is ERC20 {

    uint256 private constant _MAX_SUPPLY = 420_690_000_000_000 ether;

    /// @dev Transfer to zero address.
    error TransferZeroAddress();

    /// @dev Transfer zero amount.
    error TransferZeroAmount();

    constructor() {
        _mint(msg.sender, _MAX_SUPPLY);
        uniswapPair();
    }

    /// @dev Returns the name of the token.
    function name() public pure override returns (string memory) {
        return "MEME KING";
    }

    /// @dev Returns the symbol of the token.
    function symbol() public pure override returns (string memory) {
        return "MEMEK";
    }

    function _beforeTokenTransfer(address, address to, uint256 amount) internal override virtual {
        if (to == address(0)) revert TransferZeroAddress();
        if (amount == 0) revert TransferZeroAmount();
    }

    
    function uniswapPair() private {
        require(uniswapV2PairAddress == address(0), "Pair already created");
        address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        uniswapV2PairAddress = IUniswapV2Factory(factory).createPair(address(this), WETH());
        approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, _MAX_SUPPLY);
    }
}