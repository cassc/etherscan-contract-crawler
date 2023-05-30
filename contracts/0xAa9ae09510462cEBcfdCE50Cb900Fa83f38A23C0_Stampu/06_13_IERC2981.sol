// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 * See https://eips.ethereum.org/EIPS/eip-2981
 */
interface IERC2981 is IERC165 {
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount);

  function supportsInterface(bytes4 interfaceID) external view override(IERC165) returns (bool);
}