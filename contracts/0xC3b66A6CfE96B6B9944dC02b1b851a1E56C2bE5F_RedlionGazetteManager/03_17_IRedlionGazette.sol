// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

interface IRedlionGazette is IERC721Upgradeable {
  event MintedIssue(address user, uint issue, uint tokenId);

  event IssueLaunched(uint256 indexed issue, uint256 saleSize);

  struct Issue {
    uint totalSupply;
    uint saleSize; // quantity of issues to sell
    uint timestamp;
    string uri;
    uint issue;
    bool openEdition;
  }

  function mint(
    address _to,
    uint256 _issue,
    uint256 _amount,
    bool claim
  ) external returns (uint[] memory);

  function launchIssue(
    uint _issue,
    uint _saleSize,
    string memory _uri
  ) external;

  function isIssueLaunched(uint256 _issue) external view returns (bool);

  function tokenToIssue(uint _tokenId) external view returns (uint);

  function timeToIssue(uint256 _timestamp) external view returns (Issue memory);

  function issueList() external view returns (uint[] memory);
}