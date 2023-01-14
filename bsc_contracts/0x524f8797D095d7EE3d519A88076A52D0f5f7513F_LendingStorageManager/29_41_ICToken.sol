// SPDX-License-Identifier: AGPL-3.0-only
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

pragma solidity ^0.8.9;

interface ICompoundToken is IERC20 {
  function mint(uint256) external returns (uint256);

  function borrow(uint256) external returns (uint256);

  function borrowBalanceCurrent(address account) external returns (uint256);

  function repayBorrow(uint256) external returns (uint256);

  function exchangeRateCurrent() external returns (uint256);

  function supplyRatePerBlock() external returns (uint256);

  function redeem(uint256) external returns (uint256);

  function redeemUnderlying(uint256) external returns (uint256);

  function balanceOfUnderlying(address owner) external returns (uint256);

  function getAccountSnapshot(address account)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  function underlying() external view returns (address);

  function getOwner() external view returns (address);

  function exchangeRateStored() external view returns (uint256);
}

interface IComptroller {
  function getAllMarkets() external view returns (address[] memory);
}