// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ImmutableSpec.sol";
import "./RoyalERC721.sol";
import "@imtbl/imx-contracts/contracts/utils/Minting.sol";

/**
 * @title Immutable Mintable ERC721
 *
 * @notice Generic contract compatible with IMX (ImmutableMintableERC721) to be reused
 *      to deploy any ERC721 asset on IMX (ex.: IlluvitarERC721, AccessoryERC721, D1skERC721)
 *
 * @notice Contract can be redeployed in full,
 *      or a proxy can be used pointing to already deployed implementation
 *
 * @author Yuri Fernandes
 */
contract ImxMintableERC721 is RoyalERC721, ImmutableMintableERC721 {
	/**
	 * @dev "Constructor replacement" for upgradeable, must be execute immediately after deployment
	 *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
	 *
	 * @param _name token name (ERC721Metadata)
	 * @param _symbol token symbol (ERC721Metadata)
	 */
	function postConstruct(string memory _name, string memory _symbol) public virtual initializer {
		// execute all parent initializers in cascade
		super._postConstruct(_name, _symbol, msg.sender);
	}

	/**
	 * @inheritdoc ImmutableMintableERC721
	 *
	 * @dev Restricted access function to mint the token  and assign
	 *      the metadata packed into the IMX `mintingBlob` bytes array
	 *
	 * @dev Creates new token with the token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *
	 * @dev Requires executor to have ROLE_TOKEN_CREATOR permission
	 *
	 * @param _to an address to mint token to
	 * @param _quantity rudimentary (ERC20 amount of tokens to mint) equal to one,
	 *      implementation MUST revert if it not equal to one
	 * @param _mintingBlob blob containing the ID of the NFT and its metadata as
	 *      `{tokenId}:{metadata}` string, where `tokenId` is encoded as decimal string,
	 *      and metadata can be anything, but most likely is also encoded as decimal string
	 */
	function mintFor(address _to, uint256 _quantity, bytes calldata _mintingBlob) public virtual override {
		// ensure quantity is equal to one (rudimentary ERC20 amount of tokens to mint)
		require(_quantity == 1, "quantity must be equal to one");

		// parse the `_mintingBlob` and extract the tokenId and metadata from it
		(uint256 _tokenId,) = Minting.split(_mintingBlob);

		// delegate to `mint`
		mint(_to, _tokenId);
	}

}