// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @notice Allows the middleware contract to try the original interface if the new one has not yet been deployed.
 * @dev TODO remove this once the 2.4.0 upgrade is complete on mainnet.
 */
interface INFTMarket230 {
  function getTokenCreator(address nftContract, uint256 tokenId) external view returns (address payable creator);
}