pragma solidity ^0.8.0;

import "@openzeppelin/token/ERC20/IERC20.sol";

interface IRETH is IERC20 {
  function getExchangeRate() external view returns (uint256);
}