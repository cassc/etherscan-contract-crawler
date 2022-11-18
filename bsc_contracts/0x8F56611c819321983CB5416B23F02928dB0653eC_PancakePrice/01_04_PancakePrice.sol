// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPancakeRouter {
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract PancakePrice is Ownable {
    IPancakeRouter public pancakeRouter;

    address public immutable WBNB;
    address public immutable USD;

    constructor(IPancakeRouter _pancakeRouteAddress, address _WBNBAddress, address _USDAddress) {
        pancakeRouter = _pancakeRouteAddress;
        WBNB = _WBNBAddress;
        USD = _USDAddress;
    }

    function bnbPrice() public view returns (uint[] memory amounts){
        address[] memory path = new address[](2);
        path[0] = USD;
        path[1] = WBNB;
        amounts = IPancakeRouter(pancakeRouter).getAmountsIn(1 ether, path);
    }

    function tokenPrice(address token) public view returns (uint[] memory amounts){
        address[] memory path = new address[](2);
        path[0] = USD;
        path[1] = token;
        amounts = IPancakeRouter(pancakeRouter).getAmountsIn(1 ether, path);
    }
}