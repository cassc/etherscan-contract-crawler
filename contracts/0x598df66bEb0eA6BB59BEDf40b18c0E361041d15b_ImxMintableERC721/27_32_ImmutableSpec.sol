// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Immutable X Mintable Specification
 *
 * @notice Interfaces supporting IMX integration:
 *      - ImmutableMintableERC20: @imtbl/imx-contracts/contracts/IMintable.sol
 *      - ImmutableMintableERC721: @imtbl/imx-contracts/contracts/IMintable.sol
 *
 * @dev See https://docs.x.immutable.com/docs/minting-assets-1
 * @dev See https://docs.x.immutable.com/docs/partner-nft-minting-setup
 *
 * @author Basil Gorin
 */

/**
 * @dev IMX Mintable interface, enables Layer 2 minting in IMX,
 *      see https://docs.x.immutable.com/docs/minting-assets-1
 *
 * @dev See @imtbl/imx-contracts/contracts/IMintable.sol
 */
interface ImmutableMintableERC20 {
	/**
	 * @dev Mints ERC20 tokens
	 *
	 * @param to address to mint tokens to
	 * @param amount amount of tokens to mint
	 * @param mintingBlob [optional] data structure supplied
	 */
	function mintFor(address to, uint256 amount, bytes calldata mintingBlob) external;
}

/**
 * @dev IMX Mintable interface, enables Layer 2 minting in IMX,
 *      see https://docs.x.immutable.com/docs/minting-assets-1
 *      see https://docs.x.immutable.com/docs/asset-minting
 *
 * @dev See @imtbl/imx-contracts/contracts/IMintable.sol
 */
interface ImmutableMintableERC721 {
	/**
	 * @dev Mints an NFT
	 *
	 * @param to address to mint NFT to
	 * @param quantity rudimentary (ERC20 amount of tokens to mint) equal to one,
	 *      implementation MUST revert if it not equal to one
	 * @param mintingBlob blob containing the ID of the NFT and its metadata as
	 *      `{tokenId}:{metadata}` string, where `tokenId` is encoded as decimal string,
	 *      and metadata can be anything, but most likely is also encoded as decimal string
	 */
	function mintFor(address to, uint256 quantity, bytes calldata mintingBlob) external;
}