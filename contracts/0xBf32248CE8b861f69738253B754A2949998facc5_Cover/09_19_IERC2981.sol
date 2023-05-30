// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// import "./IERC165.sol";

/**
* @dev Interface for the NFT Royalty Standard
*/
interface IERC2981 /* is IERC165 */ {
  /**
  * ERC165 bytes to add to interface array - set in parent contract implementing this standard
  *
  * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
  * bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  * _registerInterface(_INTERFACE_ID_ERC2981);
  * 
  * @notice Called with the sale price to determine how much royalty is owed and to whom.
  */
  function royaltyInfo(
    uint256 tokenId_,
    uint256 salePrice_
  ) external view returns (address receiver, uint256 royaltyAmount);
}