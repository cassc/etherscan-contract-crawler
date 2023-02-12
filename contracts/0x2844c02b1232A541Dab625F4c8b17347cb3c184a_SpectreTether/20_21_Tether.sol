// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC4973} from './ERC4973.sol';
import {BitMaps} from '@openzeppelin/contracts/utils/structs/BitMaps.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {SignatureChecker} from '@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

struct Link {
  uint64 tokenIndex;
  uint192 expiration;
  address holder;
}

interface ITether is IERC4973 {
  event Tether(address holder, address operator, uint256 tokenId);
  event Untether(address holder, address operator);

  function refresh(uint256 tokenId, uint256 validityPeriod_) external;

  function isActive (uint256 tokenId) external view returns (bool);

  function exists(address active, address passive) external view returns (bool);

  function tokenId(address active, address passive) external view returns (uint256);

  function links(uint256 tokenId) external view returns (Link memory);
}