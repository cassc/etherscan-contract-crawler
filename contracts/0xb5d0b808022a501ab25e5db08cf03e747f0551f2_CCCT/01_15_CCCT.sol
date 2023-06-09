// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { ERC721FairDistribution } from './ERC721FairDistribution.sol';

/**
 * @title CCCT
 * @notice The Chunky Cow Club Tour ERC721 NFT contract.
 */
contract CCCT is
  ERC721FairDistribution
{
  constructor(
    uint256 maxSupply,
    uint256 mintPrice,
    uint256 maxPurchaseSize,
    uint256 presaleStart,
    uint256 presaleEnd
  )
    ERC721FairDistribution(
        'Chunky Cow Club Tour',
        'CCCT',
        maxSupply,
        mintPrice,
        maxPurchaseSize,
        presaleStart,
        presaleEnd
    )
  {
    // Mint founder cows.
    for (uint256 i = 0; i < 10; i++) {
      _safeMint(0x799e5b7fde4b8be33c7E7fCb2fc82ed1331bE024, i);
    }
    for (uint256 i = 10; i < 20; i++) {
      _safeMint(0x59bF8061367Dfba43A6359848c581214E0DfeF16, i);
    }
    for (uint256 i = 20; i < 30; i++) {
      _safeMint(0xdEf4Ed6e5Aa0Aea70503C91F12587a06dDc1e60F, i);
    }
    for (uint256 i = 30; i < 40; i++) {
      _safeMint(0x22f06A62F6D48c9f883d8fd1a6D5345893b6288a, i);
    }

    // Mint community/partnership cows.
    for (uint256 i = 40; i < 50; i++) {
      _safeMint(0xdC222325B0fBE26FF047A2aa373851CaDcC9DEBd, i);
    }
  }
}