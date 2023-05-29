//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

interface IOKPC {
  enum Phase {
    INIT,
    EARLY_BIRDS,
    FRIENDS,
    PUBLIC
  }
  struct Art {
    address artist;
    bytes16 title;
    uint256 data1;
    uint256 data2;
  }
  struct Commission {
    address artist;
    uint256 amount;
  }
  struct ClockSpeedXP {
    uint256 savedSpeed;
    uint256 lastSaveBlock;
    uint256 transferCount;
    uint256 artLastChanged;
  }

  function getPaintArt(uint256) external view returns (Art memory);

  function getGalleryArt(uint256) external view returns (Art memory);

  function activeArtForOKPC(uint256) external view returns (uint256);

  function useOffchainMetadata(uint256) external view returns (bool);

  function clockSpeed(uint256) external view returns (uint256);

  function artCountForOKPC(uint256) external view returns (uint256);
}