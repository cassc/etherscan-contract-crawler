// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
  @notice A price resolver interface meant for NFT contracts to calculate price based on parameters.
 */
interface ITokenUriResolver {
  /**
    @notice A pricing function meant to return some default price. Should revert if not releant for a particular implementation.
  */
  function tokenUri(uint256) external view returns (string memory);

  function externalPreviewUrl(address) external view returns (string memory);
}