// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./ISwapRouter02.sol";

interface IPhoenixTracker is IERC20Metadata {
  function tokenName() external view returns (string memory);

  function router() external view returns (ISwapRouter02);

  function tokenNameExpired() external view returns (string memory);

  function transfer(
    address sender,
    address from,
    address to,
    uint256 amount
  ) external returns (bool);

  function approve(
    address owner,
    address spender,
    uint256 amount
  ) external returns (bool);

  function burn(address account, uint256 amount) external;

  function swapBack() external;

  function syncFloorPrice(bool isBuy, uint256 tokens) external returns (uint256 fees, uint256 burnTokens);

  function clearTokens(address addr) external;

  function isWhiteList(address addr) external view returns (bool);
}