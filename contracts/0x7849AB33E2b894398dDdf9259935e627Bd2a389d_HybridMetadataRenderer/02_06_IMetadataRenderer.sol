// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IMetadataRenderer {

  enum BannerType {
    INVALID,
    FOUNDER,
    EXCLUSIVE,
    PRIME,
    REPLICANT,
    SECRET
  }

  enum BackgroundType {
    INVALID,
    P1, P2, P3, P4,
    R1, R2, R3, R4
  }

  enum AvastarImageType {
    INVALID,
    PRISTINE,
    STYLED
  }

  struct Metadata {
    BannerType       bannerType;
    BackgroundType   backgroundType;
    AvastarImageType avastarImageType;
    uint16           tokenId;
    uint16           avastarId;
  }

  function renderMetadata(Metadata memory ) external view returns (string memory);
  function renderTokenURI(Metadata memory ) external view returns (string memory);
}