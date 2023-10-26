//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {IERC20} from 'oz/token/ERC20/IERC20.sol';

interface IClientTokenStore {
  event Withdraw(address _to, address _token, uint _amount);
  event WithdrawToReceiver(address _receiver, address _token, uint _amount);
  function claimContract() external view returns (address);
  function withdraw(address _token, uint _amount) external;
  function withdrawToReceiver(address _receiver, address _token, uint _amount) external;
  function deposit(address _token, uint _amount) external;
}