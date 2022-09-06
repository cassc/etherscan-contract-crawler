// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

/************
@title INFTOracle interface
@notice Interface for the NFT price oracle.*/
interface INFTOracle {

  /***********
    @dev returns the nft asset price in wei
     */
  function getAssetPrice(address asset) external view returns (uint256);

  /***********
    @dev returns the addresses of the assets
  */
  function getAddressList() external view returns(address[] memory);
}