pragma solidity >=0.6.0 <0.8.0;

import { IERC20 } from "oz410/token/ERC20/IERC20.sol";

abstract contract IyVault is IERC20 {
  function pricePerShare() external view virtual returns (uint256);

  function getPricePerFullShare() external view virtual returns (uint256);

  function totalAssets() external view virtual returns (uint256);

  function deposit(uint256 _amount) external virtual returns (uint256);

  function withdraw(uint256 maxShares) external virtual returns (uint256);

  function want() external virtual returns (address);

  function decimals() external view virtual returns (uint8);
}