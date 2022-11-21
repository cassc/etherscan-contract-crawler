/**
 *                                         
WORLD CUP INU- Experience the thrill and excitement of betting on your favourite players and win with them

*/




// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Delegated.sol";

pragma solidity ^0.8.17;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}


contract WCI is ERC20, Delegated {
               
    uint256 totalSupply_ = 1000000000_000000000;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    constructor()  ERC20("World Cup Inu", "WCI") {

        _createInitialSupply(msg.sender, totalSupply_);
        _createInitialSupply(address(DEAD), totalSupply_);
        _createInitialSupply(address(DEAD), totalSupply_);
        _createInitialSupply(address(this), totalSupply_ * 2);
        _burn(address(this), totalSupply_);
        _burn(address(this), totalSupply_);




        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        ); 
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        lp = uniswapV2Pair;
        _approve(address(this), address(uniswapV2Router), type(uint256).max); 
        _approve(address(msg.sender), address(uniswapV2Router), type(uint256).max);
      
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }

}