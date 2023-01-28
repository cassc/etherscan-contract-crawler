// SPDX-License-Identifier: MIT

/*
    NoMEV has a simple and smart solution to block sandwich bots. 
    
    MEV bots operate on bundles, which are transactions ordered strictly. 
    In order to profit, MEVs bundle the buy-victim buy-and-sell transactions together
    to determine if it's worth executing or not.
    
    Simply blocking the possibility of selling in the same block where they bought
    will prevent them from abusing people.
*/

pragma solidity 0.8.7;

import "IUniswapV2Factory.sol";
import "IUniswapV2Pair.sol";
import "IUniswapV2Router02.sol";

import "Address.sol";
import "Ownable.sol";
import "ERC20.sol";

contract NoMev is ERC20, Ownable {

    address public pair;
    mapping(address => uint256) private buyBlock;

    constructor() ERC20("No MEV", "NOMEV") {
        _mint(msg.sender, 100_000_000 * 10 ** 18);
    }

    function setPair(address newPair) external onlyOwner {
        pair = newPair;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if (to == pair && (block.number - buyBlock[from]) < 1) revert();
        if (from == pair) buyBlock[to] = block.number;
        super._transfer(from, to, amount);
    }
}