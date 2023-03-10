// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title EIP-2981: NFT Royalty Standard
 *
 * @notice A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs)
 *      to enable universal support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * @author Zach Burks, James Morgan, Blaine Malone, James Seibel
 */
interface EIP2981 is IERC165 {
	/**
	 * @dev ERC165 bytes to add to interface array - set in parent contract
	 *      implementing this standard:
	 *      bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
	 *      bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
	 *      _registerInterface(_INTERFACE_ID_ERC2981);
	 *
	 * @notice Called with the sale price to determine how much royalty
	 *      is owed and to whom.
	 * @param _tokenId token ID to calculate royalty info for;
	 *      the NFT asset queried for royalty information
	 * @param _salePrice the price (in any unit, .e.g wei, ERC20 token, et.c.) of the token to be sold;
	 *      the sale price of the NFT asset specified by _tokenId
	 * @return receiver the royalty receiver, an address of who should be sent the royalty payment
	 * @return royaltyAmount royalty amount in the same unit as _salePrice;
	 *      the royalty payment amount for _salePrice
	 */
	function royaltyInfo(
		uint256 _tokenId,
		uint256 _salePrice
	) external view returns (
		address receiver,
		uint256 royaltyAmount
	);
}