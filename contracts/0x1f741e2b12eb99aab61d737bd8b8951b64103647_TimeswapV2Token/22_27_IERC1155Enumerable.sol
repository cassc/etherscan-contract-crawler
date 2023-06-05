// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title ERC-1155 Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
interface IERC1155Enumerable is IERC1155 {
  /// @dev Returns the total amount of ids with positive supply stored by the contract.
  function totalIds() external view returns (uint256);

  /// @dev Returns the total supply of a token given its id.
  /// @param id The index of the queried token.
  function totalSupply(uint256 id) external view returns (uint256);

  /// @dev Returns a token ID owned by `owner` at a given `index` of its token list.
  /// Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  /// @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
  /// Use along with {totalSupply} to enumerate all tokens.
  function tokenByIndex(uint256 index) external view returns (uint256);
}