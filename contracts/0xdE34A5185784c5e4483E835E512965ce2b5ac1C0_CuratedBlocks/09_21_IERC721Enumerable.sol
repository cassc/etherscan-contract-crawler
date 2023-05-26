// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// import "./IERC721.sol";

/**
* @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
* @dev See https://eips.ethereum.org/EIPS/eip-721
* Note: the ERC-165 identifier for this interface is 0x780e9d63.
*/
interface IERC721Enumerable /* is IERC721 */ {
  /**
  * @notice Enumerate valid NFTs
  * @dev Throws if `index_` >= {totalSupply()}.
  */
  function tokenByIndex(uint256 index_) external view returns (uint256);
  /**
  * @notice Enumerate NFTs assigned to an owner
  * @dev Throws if `index_` >= {balanceOf(owner_)} or if `owner_` is the zero address, representing invalid NFTs.
  */
  function tokenOfOwnerByIndex(address owner_, uint256 index_) external view returns (uint256);
  /**
  * @notice Count NFTs tracked by this contract
  */
  function totalSupply() external view returns (uint256);
}