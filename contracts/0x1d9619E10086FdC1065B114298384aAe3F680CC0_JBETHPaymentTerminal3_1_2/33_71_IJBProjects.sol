// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {JBProjectMetadata} from './../structs/JBProjectMetadata.sol';
import {IJBTokenUriResolver} from './IJBTokenUriResolver.sol';

interface IJBProjects is IERC721 {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    JBProjectMetadata metadata,
    address caller
  );

  event SetMetadata(uint256 indexed projectId, JBProjectMetadata metadata, address caller);

  event SetTokenUriResolver(IJBTokenUriResolver indexed resolver, address caller);

  function count() external view returns (uint256);

  function metadataContentOf(
    uint256 projectId,
    uint256 domain
  ) external view returns (string memory);

  function tokenUriResolver() external view returns (IJBTokenUriResolver);

  function createFor(
    address owner,
    JBProjectMetadata calldata metadata
  ) external returns (uint256 projectId);

  function setMetadataOf(uint256 projectId, JBProjectMetadata calldata metadata) external;

  function setTokenUriResolver(IJBTokenUriResolver newResolver) external;
}