// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;

interface ITokenEscrow {
  event ContractReady(address indexed intializer);
  event Deposited(address indexed payee, uint256 weiAmount);
  event Withdrawn(address indexed payee, uint256 weiAmount);
  event TokensDeposited(address indexed payee, address indexed tokenAddress, uint256 weiAmount);
  event TokensWithdrawn(address indexed payee, address indexed tokenAddress, uint256 weiAmount);

  function depositsOf(address payee) external view returns (uint256);
  function depositedTokensCountOf(address payee) external view returns (uint256);
  function depositedTokenAddressByIndexOf(address payee, uint256 index) external view returns (address);
  function tokenDepositsOf(address payee, address tokenAddress) external view returns (uint256);
  function withdraw(address payable payee) external;
  function withdrawTokens(address payable payee, address tokenAddress) external;
  function deposit(address payee) external payable;
  function depositTokens(address payee, address tokenAddress, uint256 amount) external payable;
  function setNftDistributor(address nftDistributor) external;
}