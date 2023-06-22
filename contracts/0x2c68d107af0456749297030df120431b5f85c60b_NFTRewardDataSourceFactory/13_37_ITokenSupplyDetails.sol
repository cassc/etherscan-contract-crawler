// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IToken721UriResolver.sol';

interface ITokenSupplyDetails {
  /**
    @notice Should return the total number of tokens in this contract. For ERC721 this would be the number of unique token ids. For ERC1155 this would be the number of unique token ids and their individual supply. For ERC20 this would be total supply of the token.
   */
  function totalSupply() external view returns (uint256);

  /**
    @notice For ERC1155 this would be the supply of a particular token for the given id. For ERC721 this would be 0 or 1 depending on whether or not the given token has been minted.
   */
  function tokenSupply(uint256) external view returns (uint256);

  /**
    @notice Total holder balance regardless of token id within the contract.
   */
  function totalOwnerBalance(address) external view returns (uint256);

  /**
    @notice For ERC1155 this would be the token count held by the address in the given token id. For ERC721 this would be 0 or 1 depending on ownership of the specified token id by the address. For ERC20 this would be the token balance of the address.
   */
  function ownerTokenBalance(address, uint256) external view returns (uint256);
}