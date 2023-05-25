pragma solidity >=0.7.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0



import "./IERC721TokenOwner.sol";

interface IRelicEquippable is IERC721TokenOwner {
  
  /**
   * @dev Removes relic from token
   * 
   * Should only be able to remove if:
   *   - Owns tokenId
   */
  function removeRelic(address relicAddress, uint256 relicTokenId) external;

  /**
   * @dev Returns the relics for a specific token.
   * 
   * Should:
   *   - only return relic IF token owner OWNS relic.
   * 
   * NOTE: assumes limited number of relics (so function does not run out of gas)
   *   - could make enumerable so would avoid problem...
   */
  function getRelics(uint256 tokenId) external view returns (address[] memory, uint256[] memory);




}