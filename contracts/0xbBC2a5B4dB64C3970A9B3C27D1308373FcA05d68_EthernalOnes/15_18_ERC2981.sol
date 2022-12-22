// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

import "../interfaces/IERC2981.sol";

abstract contract ERC2981 is IERC2981 {
	// Errors
  /**
  * @dev Thrown when the desired royalty rate is higher than 10,000
  * 
  * @param royaltyRate : the desired royalty rate
  * @param royaltyBase : the maximum royalty rate
  */
	error IERC2981_INVALID_ROYALTIES( uint256 royaltyRate, uint256 royaltyBase );

	// Royalty rate is stored out of 10,000 instead of a percentage to allow for
	// up to two digits below the unit such as 2.5% or 1.25%.
	uint private constant ROYALTY_BASE = 10000;

	// Represents the percentage of royalties on each sale on secondary markets.
	// Set to 0 to have no royalties.
	uint256 private _royaltyRate;

	// Address of the recipient of the royalties.
	address private _royaltyRecipient;

	/**
	* @notice Called with the sale price to determine how much royalty is owed and to whom.
	* 
	* Note: This function should be overriden to revert on a query for non existent token.
	* 
  * @param tokenId_   : identifier of the NFT being referenced
  * @param salePrice_ : the sale price of the token sold
  * 
  * @return address : the address receiving the royalties
  * @return uint256 : the royalty payment amount
	*/
	function royaltyInfo( uint256 tokenId_, uint256 salePrice_ ) public view virtual override returns ( address, uint256 ) {
		if ( salePrice_ == 0 || _royaltyRate == 0 ) {
			return ( _royaltyRecipient, 0 );
		}
		uint256 _royaltyAmount_ = _royaltyRate * salePrice_ / ROYALTY_BASE;
		return ( _royaltyRecipient, _royaltyAmount_ );
	}

	/**
	* @dev Sets the royalty rate to `royaltyRate_` and the royalty recipient to `royaltyRecipient_`.
	* 
	* @param royaltyRecipient_ : the address that will receive royalty payments
	* @param royaltyRate_      : the percentage of the sale price that will be taken off as royalties, expressed in Basis Points (100 BP = 1%)
	* 
	* Requirements: 
	* 
	* - `royaltyRate_` cannot be higher than `10,000`;
	*/
	function _setRoyaltyInfo( address royaltyRecipient_, uint256 royaltyRate_ ) internal virtual {
		if ( royaltyRate_ > ROYALTY_BASE ) {
			revert IERC2981_INVALID_ROYALTIES( royaltyRate_, ROYALTY_BASE );
		}
		_royaltyRate      = royaltyRate_;
		_royaltyRecipient = royaltyRecipient_;
	}
}