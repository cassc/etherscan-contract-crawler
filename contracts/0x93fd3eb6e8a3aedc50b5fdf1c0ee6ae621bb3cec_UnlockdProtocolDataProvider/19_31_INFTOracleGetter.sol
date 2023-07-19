// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/************
@title INFTOracleGetter interface
@notice Interface for getting NFT price oracle.*/
interface INFTOracleGetter {
  /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
  /***********
    @dev returns the asset price in ETH
    @param assetContract the underlying NFT asset
    @param tokenId the underlying NFT token Id
  */
  function getNFTPrice(address assetContract, uint256 tokenId) external view returns (uint256);
}