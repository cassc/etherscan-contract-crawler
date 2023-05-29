//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import {IOKPC} from './IOKPC.sol';
import {IOKPCParts} from './IOKPCParts.sol';

interface IOKPCMetadata {
  error InvalidTokenID();
  error NotEnoughPixelData();

  struct Parts {
    IOKPCParts.Vector headband;
    IOKPCParts.Vector rightSpeaker;
    IOKPCParts.Vector leftSpeaker;
    IOKPCParts.Color color;
    string word;
  }

  function tokenURI(uint256 tokenId) external view returns (string memory);

  function renderArt(bytes memory art, uint256 colorIndex)
    external
    view
    returns (string memory);

  function getParts(uint256 tokenId) external view returns (Parts memory);

  function drawArt(bytes memory artData) external pure returns (string memory);
}