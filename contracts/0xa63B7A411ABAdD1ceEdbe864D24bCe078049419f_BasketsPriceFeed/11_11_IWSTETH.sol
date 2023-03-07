pragma solidity ^0.8.0;

import "@openzeppelin/token/ERC20/IERC20.sol";

interface IWSTETH is IERC20 {
  function stEthPerToken() external view returns (uint256);
}