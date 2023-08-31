//SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * This is a generic factory contract that can be used to mint tokens. The configuration
 * for minting is specified by an _optionId, which can be used to delineate various
 * ways of minting.
 *
 * https://docs.opensea.io/docs/2-custom-item-sale-contract
 */
interface IFactoryERC721PayWithEther {

  function withdraw(address _address, uint256 _amount) external;
  
  function redeem(uint256 tokenId) external;

  function batchRedeem(uint256[] memory tokenIds) external;

  function _mint() external payable;

  function _transfer(address[] memory tos, uint256[] memory tokenIds) external;
}