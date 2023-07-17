/*
We are cooking the $SAUCE
https://t.me/araboileth
https://twitter.com/araboilcoin
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract Oil is ERC20, Ownable {
    address public uniswapV2Pair;

    constructor() ERC20("Arab Oil", "OIL") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _mint(_msgSender(), 1000000000 * 10**18);
    }

    /// BURN THE OIL
    function burn(uint256 amount) public virtual {
        require(
            balanceOf(_msgSender()) >= amount,
            "ERC20: burn amount exceeds oil balance"
        );
        _burn(_msgSender(), amount);
    }

     function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        bool success = true;
        (success, ) = payable(owner()).call{value: contractBalance}("");
        require(success, "Transfer failed");
    }
}