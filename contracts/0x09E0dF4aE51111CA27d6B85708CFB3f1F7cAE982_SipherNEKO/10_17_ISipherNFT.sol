// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';


interface ISipherNFT is IERC721Enumerable {
  /**
   * @dev Call only by the Genesis Minter to roll the start index
   */
  function rollStartIndex() external;

  /**
   * @dev Call to mint new genesis tokens, only by Genesis Minter
   *  Can mint up to MAX_GENESIS_SUPPLY tokens
   * @param amount amount of genesis tokens to mint
   * @param to recipient of genesis tokens
   */
  function mintGenesis(uint256 amount, address to, uint256 unitPrice) external;

  /**
   * @dev Call to mint a fork of a tokenId, only by Fork Minter
   *  need to wait for all genesis to be minted before minting forks
   *  allow to mint multile forks for a tokenId
   * @param tokenId id of token to mint a fork
   */
  function mintFork(uint256 tokenId) external;

  /**
   * @dev Return the original of a fork token
   * @param forkId fork id to get its original token id
   */
  function originals(uint256 forkId)
    external
    view
    returns (uint256 originalId);

  /**
   * @dev Return the current genesis minter address
   */
  function genesisMinter() external view returns (address);

  /**
   * @dev Return the current fork minter address
   */
  function forkMinter() external view returns (address);

  /**
   * @dev Return the randomized start index, 0 if has not rolled yet
   */
  function randomizedStartIndex() external view returns (uint256);

  /**
   * @dev Return the current genesis token id, default 0, the first token has id of 1
   */
  function currentId() external view returns (uint256);

  /**
   * @dev Return the base Sipher URI for tokens
   */
  function baseSipherURI() external view returns (string memory);

  /**
   * @dev Return the store front URI
   */
  function contractURI() external view returns (string memory);


}