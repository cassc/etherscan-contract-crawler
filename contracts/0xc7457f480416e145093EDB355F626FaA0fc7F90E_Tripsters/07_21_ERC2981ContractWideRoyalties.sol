// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./ERC2981Base.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981ContractWideRoyalties is ERC2981Base {
	RoyaltyInfo private _royalties;

	/// @dev Sets token royalties
	/// @param _recipient recipient of the royalties
	/// @param _value percentage (using 2 decimals - 10000 = 100, 0 = 0)
	function _setRoyalties(
		address _recipient,
		uint256 _value
	)
		internal
	{
		// unneeded since the derived contract has a lower _value limit
		// require(_value <= 10000, "ERC2981Royalties: Too high");
		_royalties = RoyaltyInfo(_recipient, uint24(_value));
	}

	/// @inheritdoc	IERC2981Royalties
	function royaltyInfo(
		uint256,
		uint256 _value
	)
		external
		view
		override
		returns (address receiver, uint256 royaltyAmount)
	{
		RoyaltyInfo memory royalties = _royalties;
		receiver = royalties.recipient;
		royaltyAmount = (_value * royalties.amount) / 10000;
	}
}