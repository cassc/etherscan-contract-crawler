// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.9;

interface IGhostMinter {
  struct Distribution {
    address recipient;
    uint256 amount;
  }

  struct NftIncomeDistribution {
    Distribution RefRewards;
    Distribution Liquidity;
    Distribution Donation;
    Distribution Profit;
  }

  function mintNft(bytes32 slug, uint256 tokenId, address recipient, uint256 amount) external;

  function mintNft(bytes32 slug, uint256 tokenId, address recipient, uint256 amount, address referrer) external;

  function mintOneRandomNft(bytes32 slug, address recipient) external returns(uint256);

  function addReferal(bytes32 slug, address referrer) external;

  function isERC1155(bytes32 slug) external returns(bool);
  
  function isERC721(bytes32 slug) external returns(bool);

  function getNftIncomeDistribution(
    bytes32 slug,
    uint256 tokenId,
    address referrer,
    bytes32 referrerTokenSlug,
    uint256 referrerTokenId
  ) external view returns (NftIncomeDistribution memory nftIncomeDistribution);
}