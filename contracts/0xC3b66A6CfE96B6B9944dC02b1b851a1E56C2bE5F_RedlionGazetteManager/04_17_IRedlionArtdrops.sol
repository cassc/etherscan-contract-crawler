// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

interface IRedlionArtdrops is IERC721Upgradeable {
  /*///////////////////////////////////////////////////////////////
                          EVENTS
  ///////////////////////////////////////////////////////////////*/

  event ArtdropLaunched(uint indexed issue);

  /*///////////////////////////////////////////////////////////////
                         FUNCTIONS
  ///////////////////////////////////////////////////////////////*/

  function mint(address _to, uint _tokenId) external;

  function isClaimed(uint _tokenId) external view returns (bool);

  function launchArtdrop(uint _issueId, string calldata _uri) external;
}