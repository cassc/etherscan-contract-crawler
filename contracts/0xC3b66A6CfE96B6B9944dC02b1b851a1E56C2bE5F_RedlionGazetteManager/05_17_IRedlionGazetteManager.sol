// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './IRedlionGazette.sol';
import './IRedlionLegendaryGazette.sol';

interface IRedlionGazetteManager {
  event IssueDelivered(
    uint indexed issue,
    uint tokenId,
    address indexed receiver
  );

  event IssueMinted(uint indexed issue, uint tokenId, address indexed minter);

  event IssueClaimed(
    uint indexed issue,
    uint tokenId,
    address indexed claimant
  );

  event ArtdropClaimed(
    uint indexed issue,
    uint tokenId,
    address indexed claimant
  );
  
  struct DeliveryState {
    uint delivered;
    uint received;
    uint total;
  }

  function getRLG() external view returns (IRedlionGazette);

  function getRLLG() external view returns (IRedlionLegendaryGazette);
}