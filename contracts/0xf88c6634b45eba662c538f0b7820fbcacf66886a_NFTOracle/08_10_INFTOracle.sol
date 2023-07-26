// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/************
@title INFTOracle interface
@notice Interface for NFT price oracle.*/
interface INFTOracle {
  /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
  /**
  @dev returns the NFT price for a given NFT
  @param _collection the NFT collection
  @param _tokenId the NFT token Id
   */
  function getNFTPrice(address _collection, uint256 _tokenId) external view returns (uint256);

  /**
  @dev returns the NFT price for a given array of NFTs
  @param _collections the array of NFT collections
  @param _tokenIds the array NFT token Id
   */
  function getMultipleNFTPrices(address[] calldata _collections, uint256[] calldata _tokenIds)
    external
    view
    returns (uint256[] memory);

  /**
  @dev sets the price for a given NFT 
  @param _collection the NFT collection
  @param _tokenId the NFT token Id
  @param _price the price to set to the token
  */
  function setNFTPrice(
    address _collection,
    uint256 _tokenId,
    uint256 _price
  ) external;

  /**
  @dev sets the price for a given NFT 
  @param _collections the array of NFT collections
  @param _tokenIds the array of  NFT token Ids
  @param _prices the array of prices to set to the given tokens
   */
  function setMultipleNFTPrices(
    address[] calldata _collections,
    uint256[] calldata _tokenIds,
    uint256[] calldata _prices
  ) external;

  /**
  @dev sets the pause status of the NFT oracle
  @param _nftContract the of NFT collection
  @param val the value to set the pausing status (true for paused, false for unpaused)
   */
  function setPause(address _nftContract, bool val) external;
}