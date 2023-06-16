// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "IERC20Metadata.sol";

interface IXFETH is IERC20Metadata {
  event Deposit(address indexed dst, uint amountXfETH, uint amountETH);
  event Withdrawal(address indexed src, uint amountETH);
  event FlashMint(address indexed dst, uint amountXfETH);
  event FeeChange(uint newFee);
  event OwnerChange(address newOwner);
  event ArbitrageurChange(address arbitrageur);
  event StatusChange(bool state);

  function owner() external view returns (address _owner);

  function flashMintFee() external view returns (uint _flashMintFee);

  function setStatus(bool _state) external;

  function setOwner(address _newOwner) external;

  function setArbitrageur(address _arbitrageur) external;

  function setFlashMintFee(uint _newFee) external;

  function xfETHToETH(uint _xfETHAmount) external view returns (uint _ETH);

  function ETHToXfETH(uint _ETHAmount) external view returns (uint _xfETH);

  function deposit() external payable returns (uint amountInXfETH);

  function withdraw(uint _liquidity) external returns (uint amountInETH);

  function flashMint(uint _amount) external;
}