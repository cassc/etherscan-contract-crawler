// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;

import '../EthereumContracts/contracts/NFT/NFTFree.sol';
import '../EthereumContracts/contracts/interfaces/IERC721.sol';

abstract contract CCVault {
	function balanceOf( address tokenOwner ) public virtual view returns ( uint256 key ) {}
}

contract Degen is NFTFree {
	error NFT_FORBIDDEN( address account );
	error NFT_ALLOCATION_CONSUMED( address account );
	error NFT_MAX_ALLOCATION( address account, uint256 allocated );

	uint8   public constant PRIVATE_SALE      = 2;
	uint8   public constant PARTNER_SALE      = 3;

	uint256 public constant MINTS_PER_KEY     = 3;
	uint256 public constant MINTS_PER_PARTNER = 1;

	mapping( address => uint256 ) public privateMints;
	mapping( address => uint256 ) public partnerMints;

	CCVault private _vault;
	IERC721 private _tab;
	IERC721 private _fmc;

	constructor () {
		_initNFTFree (
			300,
			5,
			4000,
			1250,
			"GMers",
			"GMER",
			"https://collectorsclub.io/api/gmers/metadata?tokenId="
		);
	}

	/**
	* Ensures the contract state is PRIVATE_SALE or PARTNER_SALE
	*/
	modifier isPrivateOrPartnerSale {
		uint8 _currentState_ = getPauseState();
		if ( _currentState_ != PRIVATE_SALE && _currentState_ != PARTNER_SALE ) {
			revert IPausable_INCORRECT_STATE( _currentState_ );
		}

		_;
	}

	/**
	* Ensures the contract state is PARTNER_SALE
	*/
	modifier isPartnerSale {
		uint8 _currentState_ = getPauseState();
		if ( _currentState_ != PARTNER_SALE ) {
			revert IPausable_INCORRECT_STATE( _currentState_ );
		}

		_;
	}

	// **************************************
	// *****          INTERNAL          *****
	// **************************************
		/**
		* @dev Internal function returning whether `operator_` is allowed to manage tokens on behalf of `tokenOwner_`.
		* 
		* @param tokenOwner_ : address that owns tokens
		* @param operator_   : address that tries to manage tokens
		* 
		* @return bool whether `operator_` is allowed to manage the token
		*/
		function _isApprovedForAll( address tokenOwner_, address operator_ ) internal view virtual override(NFTFree) returns ( bool ) {
			return operator_ == address( _vault ) ||
						 super._isApprovedForAll( tokenOwner_, operator_ );
		}
	// **************************************

	// **************************************
	// *****           PUBLIC           *****
	// **************************************
		/**
		* Mints a single token during the PARTNER_SALE period.
		* 
		* Requirements:
		* - Contract state must be PARTNER_SALE
		* - Caller must own one of the PARTNER NFTs
		* - Caller must not have minted through this function before
		*/
		function mintPartner() public isPartnerSale {
			address _account_ = _msgSender();
			if ( partnerMints[ _account_ ] == MINTS_PER_PARTNER ) {
				revert NFT_ALLOCATION_CONSUMED( _account_ );
			}

			uint256 _remainingSupply_ = MAX_SUPPLY - _reserve - supplyMinted();
			if ( _remainingSupply_ < MINTS_PER_PARTNER ) {
				revert NFT_MAX_SUPPLY( MINTS_PER_PARTNER, _remainingSupply_ );
			}

			uint256 _allocated_;
			uint256 _tabOwned_ = _tab.balanceOf( _account_ );
			if ( _tabOwned_ > 0 ) {
				_allocated_ = MINTS_PER_PARTNER;
			}
			else {
				uint256 _fmcOwned_ = _fmc.balanceOf( _account_ );
				if ( _fmcOwned_ > 0 ) {
					_allocated_ = MINTS_PER_PARTNER;
				}
			}
			if ( _allocated_ < MINTS_PER_PARTNER ) {
				revert NFT_FORBIDDEN( _account_ );
			}

			unchecked {
				partnerMints[ _account_ ] = MINTS_PER_PARTNER;
			}

			_mint( _account_, MINTS_PER_PARTNER );
		}

		/**
		* Mints tokens for key stakers.
		* 
		* @param qty_ ~ type = uint256 : the number of tokens to mint 
		* 
		* Requirements:
		* - `qty_` must be greater than 0
		* - Contract state must be PARTNER_SALE or PRIVATE_SALE
		* - Caller must have enough keys staked (one key staked = 3 tokens)
		* - Caller must have enough remaining tokens allocated to mint `qty_` tokens
		*/
		function mintPrivate( uint256 qty_ ) public validateAmount( qty_ ) isPrivateOrPartnerSale {
			address _account_ = _msgSender();
			if ( privateMints[ _account_ ] == MINTS_PER_KEY ) {
				revert NFT_ALLOCATION_CONSUMED( _account_ );
			}

			uint256 _remainingSupply_ = MAX_SUPPLY - _reserve - supplyMinted();
			if ( _remainingSupply_ < qty_ ) {
				revert NFT_MAX_SUPPLY( qty_, _remainingSupply_ );
			}

			uint256 _keys_ = _vault.balanceOf( _account_ );
			uint256 _allocated_ = _keys_ * MINTS_PER_KEY;
			uint256 _claimed_ = privateMints[ _account_ ];
			if ( qty_ > _allocated_ - _claimed_ ) {
				revert NFT_MAX_ALLOCATION( _account_, _allocated_ );
			}

			unchecked {
				privateMints[ _account_ ] = _claimed_ + qty_;
			}

			_mint( _account_, qty_ );
		}
	// **************************************

	// **************************************
	// *****       CONTRACT OWNER       *****
	// **************************************
		/**
		* @dev Sets the vault contract address.
		*/
		function setVault( address vault_ ) public onlyOwner {
			_vault = CCVault( vault_ );
		}

		/**
		* @dev Sets the FMC contract address.
		*/
		function setFmc( address fmc_ ) public onlyOwner {
			_fmc = IERC721( fmc_ );
		}

		/**
		* @dev Sets the TAB contract address.
		*/
		function setTab( address tab_ ) public onlyOwner {
			_tab = IERC721( tab_ );
		}
	// **************************************
}