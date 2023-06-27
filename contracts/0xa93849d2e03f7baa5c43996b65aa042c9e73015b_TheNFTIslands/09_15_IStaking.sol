//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

interface IStaking {
  function stakeMultipleTokens(uint256[] calldata tokenIds) external;
  function stakeFromNFTContract(uint256 tokenIds) external;
}