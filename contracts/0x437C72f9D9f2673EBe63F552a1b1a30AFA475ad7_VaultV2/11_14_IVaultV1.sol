// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./IVersion.sol";
import "../structs/Fees.sol";
import "../structs/LockMap.sol";

interface IVaultV1 is IVersion {
  function signerVaultFactory() external view returns (address);
  function feeCollector() external view returns (address);

  function partnerOf(address partner) external view returns (uint);

  function fees() external view returns (Fees memory);
  function fees(address vault) external view returns (Fees memory);

  function vaults() external view returns (address[] memory);
  function vaultsLength() external view returns (uint);
  function getVault(uint index) external view returns (address);

  function createVault() external returns (address);

  function vote(address vault) external view returns (bytes memory data, uint quorom, uint accepts, uint rejects, bool voted);
  function castVote(address vault, bool accept) external;

  function addSigner(address vault, address nominee) external;
  function removeSigner(address vault, address nominee) external;

  function lockMapETH(address vault) external view returns (LockMap memory);
  function claimETH(address vault) external;
  function claimETH(address vault, address recipient) external;
  function unlockETH(address vault, uint amount) external;
  function unlockETH(address vault, uint amount, address recipient) external;
  function lockETH(address vault, uint amount, uint until) external payable;
  function lockETHOnPartner(address vault, uint amount, uint until, address partner) external payable;
  function lockETHPermanently(address vault, uint amount) external payable;
  function lockETHPermanentlyOnPartner(address vault, uint amount, address partner) external payable;

  function lockMapToken(address vault, address token) external view returns (LockMap memory);
  function claimToken(address vault, address token) external;
  function claimToken(address vault, address token, address recipient) external;
  function unlockToken(address vault, address token, uint amount) external;
  function unlockToken(address vault, address token, uint amount, address recipient) external;
  function lockToken(address vault, address token, uint amount, uint until) external payable;
  function lockTokenOnPartner(address vault, address token, uint amount, uint until, address partner) external payable;
  function lockTokenPermanently(address vault, address token, uint amount) external payable;
  function lockTokenPermanentlyOnPartner(address vault, address token, uint amount, address partner) external payable;

  function lockMapERC721(address vault, address erc721) external view returns (LockMap memory);
  function claimERC721(address vault, address erc721, uint tokenId) external;
  function claimERC721(address vault, address erc721, uint tokenId, address recipient) external;
  function unlockERC721(address vault, address erc721, uint tokenId) external;
  function unlockERC721(address vault, address erc721, uint tokenId, address recipient) external;
  function lockERC721(address vault, address erc721, uint tokenId, uint until) external payable;
  function lockERC721OnPartner(address vault, address erc721, uint tokenId, uint until, address partner) external payable;
  function lockERC721Permanently(address vault, address erc721, uint tokenId) external payable;
  function lockERC721PermanentlyOnPartner(address vault, address erc721, uint tokenId, address partner) external payable;

  function swapLiquidity(address vault, address token, uint removeLiquidity, address[] calldata swapPath, uint deadline) external payable;
  function swapLiquidityOnPartner(address vault, address token, uint removeLiquidity, address[] calldata swapPath, uint deadline, address partner) external payable;
  function swapLiquidity(address vault, address token, uint removeLiquidity, uint swapAmountOutMin, address[] calldata swapPath, uint deadline) external payable;
  function swapLiquidityOnPartner(address vault, address token, uint removeLiquidity, uint swapAmountOutMin, address[] calldata swapPath, uint deadline, address partner) external payable;
  function swapLiquidity(address vault, address token, uint removeLiquidity, uint removeAmountAMin, uint removeAmountBMin, uint swapAmountOutMin, address[] calldata swapPath, uint addAmountAMin, uint addAmountBMin, uint deadline) external payable;
  function swapLiquidityOnPartner(address vault, address token, uint removeLiquidity, uint removeAmountAMin, uint removeAmountBMin, uint swapAmountOutMin, address[] calldata swapPath, uint addAmountAMin, uint addAmountBMin, uint deadline, address partner) external payable;
}