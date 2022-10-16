// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/UniswapV2Library.sol";

interface IWETH {
  function deposit() external payable;
  function transfer(address dst, uint wad) external returns (bool);
}

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}

contract Sandwich {
   address owner;
   IWETH public WETH;
   address public constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
   mapping(address => bool) public isAuthorized;

   constructor(address _WETH) public {
     owner = msg.sender;
     isAuthorized[msg.sender] = true;
     WETH = IWETH(_WETH);
   }

   receive() external payable {
     WETH.deposit{value:msg.value}();
   }

   function swap(uint amountIn, uint amountOutMin, address[] memory path) public onlyAuthorized {
     uint[] memory amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
     require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
     IERC20(path[0]).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
     _swap(amounts, path, address(this));
   }

   function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
     for (uint i; i < path.length - 1; i++) {
       (address input, address output) = (path[i], path[i + 1]);
       (address token0,) = UniswapV2Library.sortTokens(input, output);
       uint amountOut = amounts[i + 1];
       (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
       address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
       IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
         amount0Out, amount1Out, to, new bytes(0)
       );
     }
   }

   function withdraw(address token, uint amount) external onlyOwner {
     require(IERC20(token).balanceOf(address(this)) >= amount);
     IERC20(token).transfer(owner, amount);
   }

   function tokenBalance(address token) external view returns (uint balance) {
     balance = IERC20(token).balanceOf(address(this));
   }

   function addAuthority(address user) external onlyOwner {
     require(!isAuthorized[user], "User already authorized");
     isAuthorized[user] = true;
   }

   modifier onlyOwner {
     require(msg.sender == owner, "Not owner");
     _;
   }

   modifier onlyAuthorized {
     require(isAuthorized[msg.sender], "Not authorized to swap");
     _;
   }
}