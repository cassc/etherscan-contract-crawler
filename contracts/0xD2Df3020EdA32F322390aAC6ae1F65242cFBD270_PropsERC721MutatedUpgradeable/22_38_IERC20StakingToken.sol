// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IERC20StakingToken {
  function issueTokens(address _to, uint256 _amount) external;
  function getSignatureVerifier() external view returns (address);
  function claimPoints(address from, uint256 tokenId) external;
  function resetClaimTimer(address from, uint256 tokenId) external;
  function bridgeUnstake(address from, uint256[] calldata id) external;
}