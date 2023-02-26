// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IDex } from './IDex.sol';
import { IWETHToken } from './IToken.sol';
import { Vault } from './Vault.sol';
import { IERC20 } from '../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IVault {
  function stableCoin() external view returns (IERC20);
  function ownCoin() external view returns (IERC20);
  function wETHCoin() external view returns (IWETHToken);
  function ownDexContract() external view returns (IDex);
  function maxBookingTime() external view returns (uint);

  function getBookedBalance() external view returns (uint256);
  function getAvailableAmount() external view returns (uint256);
  function getBookingAmount(address user) external view returns (uint256);

  function _setStableCoin(address tokenAddress) external;
  function _setOwnCoin(address tokenAddress) external;
  function _setWETHCoin(address tokenAddress) external;
  function _setOwnDexContract(address dexContract) external;
  function _changeOwner(address newOwner) external;
  function _addOperator(address operator) external;
  function _removeOperator(address operator) external;
  function _sendEth(address payable target, uint amount) external;
  function _sendToken(address target, uint amount, IERC20 token) external;
  function _setAllowance(IERC20 token, address spender, uint amount) external;
  function _moveSessionsToFinal(Vault.Session[] calldata sessions) external;
  function _completeSessions(Vault.Session[] calldata sessions) external;
  function _makeBooking(address user, uint256 amount) external;
  function _completeBookings() external;
  function _cancelBooking(address user) external;
  function _setMaxBookingTime(uint time) external;
  function _proxySwap(
    address proxyAddress,
    bytes calldata proxyData,
    address tokenToBuy,
    address payable target
  ) external;
  function _createSession(
    uint256 sessionId,
    uint256 transferedAmount
  ) external;
  function _startSession(
    uint256 sessionId,
    address proxyAddress,
    bytes calldata proxyData,
    address tokenToBuy,
    address payable target
  ) external;
}