// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IPosters {
  error NotPosterMinter();

  /**
   * @dev Emitted when a poster is minted.
   * @param to The address of the poster owner.
   * @param id The token id of the poster.
   * @param amount The amount of posters minted.
   */
  event PosterMinted(address indexed to, uint256 indexed id, uint256 amount);

  /**
   * @dev Emitted when the base uri is set.
   * @param baseUri The base uri of the poster.
   */
  event BaseUriSet(string baseUri);

  function mint(address _to, uint256 _id, uint256 _amount) external;

  function setBaseUri(string calldata _baseUri) external;

  function uri(uint256 _id) external view returns (string memory);
}