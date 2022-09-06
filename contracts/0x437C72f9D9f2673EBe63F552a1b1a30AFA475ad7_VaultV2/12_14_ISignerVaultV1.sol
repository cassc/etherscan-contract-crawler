// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./lightweight/IERC721Receiver.sol";
import "./IVersion.sol";
import "../structs/LockMap.sol";

interface ISignerVaultV1 is IVersion, IERC721Receiver {
  event VoteOperationExecuted(bytes data, bool success, string revertReason);

  function initializeImplementation(address signerVaultFactory_, address signer_) external;

  function signerVaultFactory() external view returns (address);
  function signers() external view returns (address[] memory);
  function signer(address candidate) external view returns (bool);

  function vote(address voter) external view returns (bytes memory data, uint quorom, uint accepts, uint rejects, bool voted);
  function castVote(bool accept) external;
  function castVote(bool accept, address voter) external;

  function addSigner(address nominee) external;
  function addSigner(address nominee, address voter) external;
  function removeSigner(address nominee) external;
  function removeSigner(address nominee, address voter) external;

  function lockMapETH() external view returns (LockMap memory);
  function claimETH() external;
  function claimETH(address recipient) external;
  function unlockETH(uint amount) external;
  function unlockETH(uint amount, address recipient) external;
  function unlockETH(uint amount, address recipient, address voter) external;
  function lockETH(uint amount, uint until) external payable;
  function lockETHPermanently(uint amount) external payable;

  function lockMapToken(address token) external view returns (LockMap memory);
  function claimToken(address token) external;
  function claimToken(address token, address recipient) external;
  function unlockToken(address token, uint amount) external;
  function unlockToken(address token, uint amount, address recipient) external;
  function unlockToken(address token, uint amount, address recipient, address voter) external;
  function lockToken(address token, uint amount, uint until) external payable;
  function lockTokenPermanently(address token, uint amount) external payable;

  function lockMapERC721(address erc721) external view returns (LockMap memory);
  function claimERC721(address erc721, uint tokenId) external;
  function claimERC721(address erc721, uint tokenId, address recipient) external;
  function unlockERC721(address erc721, uint tokenId) external;
  function unlockERC721(address erc721, uint tokenId, address recipient) external;
  function unlockERC721(address erc721, uint tokenId, address recipient, address voter) external;
  function lockERC721(address erc721, uint tokenId, uint until) external payable;
  function lockERC721Permanently(address erc721, uint tokenId) external payable;

  function swapLiquidity(address token, uint removeLiquidity, address[] calldata swapPath, uint deadline) external payable;
  function swapLiquidity(address token, uint removeLiquidity, uint swapAmountOutMin, address[] calldata swapPath, uint deadline) external payable;
  function swapLiquidity(address token, uint removeLiquidity, uint removeAmountAMin, uint removeAmountBMin, uint swapAmountOutMin, address[] calldata swapPath, uint addAmountAMin, uint addAmountBMin, uint deadline) external payable;
}