// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IVault } from './IVault.sol';
import { IERC20 } from '../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IDex {
  function isPaused() external view returns (bool);
  function rateValues() external view returns (uint256, uint256);
  function ownCoin() external view returns (IERC20);
  function stableCoin() external view returns (IERC20);
  function vaultContract() external view returns (IVault);

  function deposit(uint256 maxAmountToSell, uint256 amountToBuy) external;
  function withdraw(uint256 maxAmountToSell, uint256 amountToBuy) external returns (bool);
  function cancelBooking() external;

  function _setPause(bool pause) external;
  function _changeOwner(address newOwner) external;
  function _setStableCoin(address tokenAddress) external;
  function _setOwnCoin(address tokenAddress) external;
  function _setVaultContract(address vaultAddress) external;
  function _removeOperator(address operator) external;
  function _setPriceRate(uint256 stable, uint256 own) external;
  function _completeBooking(address recepient, uint256 amountToBuy) external;
}