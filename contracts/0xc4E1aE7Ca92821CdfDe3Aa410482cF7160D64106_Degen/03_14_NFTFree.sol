// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;

import '../tokens/ERC721/Reg_ERC721Batch.sol';
import '../utils/IOwnable.sol';
import '../utils/IPausable.sol';
import '../utils/ITradable.sol';
import '../utils/ERC2981Base.sol';

abstract contract NFTFree is Reg_ERC721Batch, IOwnable, IPausable, ITradable, ERC2981Base {
	// Errors 
	error NFT_ARRAY_LENGTH_MISMATCH( uint256 len1, uint256 len2 );
	error NFT_INVALID_QTY();
	error NFT_MAX_BATCH( uint256 qtyRequested, uint256 maxBatch );
	error NFT_MAX_RESERVE( uint256 qtyRequested, uint256 reserveLeft );
	error NFT_MAX_SUPPLY( uint256 qtyRequested, uint256 remainingSupply );

	uint256 private constant SHARE_BASE = 10000;
	uint256 public MAX_SUPPLY;
	uint256 public MAX_BATCH;
	uint256 internal _reserve;

	/**
	* @dev Ensures that `qty_` is higher than 0
	* 
	* @param qty_ : the amount to validate 
	*/
	modifier validateAmount( uint256 qty_ ) {
		if ( qty_ == 0 ) {
			revert NFT_INVALID_QTY();
		}

		_;
	}

	// **************************************
	// *****          INTERNAL          *****
	// **************************************
		/**
		* @dev Internal function to initialize the NFT contract.
		* 
		* @param reserve_       : total amount of reserved tokens for airdrops
		* @param maxBatch_      : maximum quantity of token that can be minted in one transaction
		* @param maxSupply_     : maximum number of tokens that can exist
		* @param royaltyRate_   : portion of the secondary sale that will be paid out to the collection, out of 10,000 total shares
		* @param name_          : name of the token
		* @param symbol_        : symbol representing the token
		* @param baseURI_       : baseURI for the tokens
		*/
		function _initNFTFree (
			uint256 reserve_,
			uint256 maxBatch_,
			uint256 maxSupply_,
			uint256 royaltyRate_,
			string memory name_,
			string memory symbol_,
			string memory baseURI_
		) internal {
			_initERC721Metadata( name_, symbol_, baseURI_ );
			_initIOwnable( _msgSender() );
			_initERC2981Base( _msgSender(), royaltyRate_ );
			MAX_SUPPLY     = maxSupply_;
			MAX_BATCH      = maxBatch_;
			_reserve       = reserve_;
		}

		/**
		* @dev Internal function returning whether `operator_` is allowed to manage tokens on behalf of `tokenOwner_`.
		* 
		* @param tokenOwner_ : address that owns tokens
		* @param operator_   : address that tries to manage tokens
		* 
		* @return bool whether `operator_` is allowed to manage the token
		*/
		function _isApprovedForAll( address tokenOwner_, address operator_ ) internal view virtual override(Reg_ERC721Batch) returns ( bool ) {
			return _isRegisteredProxy( tokenOwner_, operator_ ) ||
						 super._isApprovedForAll( tokenOwner_, operator_ );
		}

		/**
		* @dev Internal function returning whether `addr_` is a contract.
		* Note this function will be inacurate if `addr_` is a contract in deployment.
		* 
		* @param addr_ : address to be verified
		* 
		* @return bool whether `addr_` is a fully deployed contract
		*/
		function _isContract( address addr_ ) internal view returns ( bool ) {
			uint size;
			assembly {
				size := extcodesize( addr_ )
			}
			return size > 0;
		}
	// **************************************

	// **************************************
	// *****           PUBLIC           *****
	// **************************************
		/**
		* @dev Mints `qty_` tokens and transfers them to the caller.
		* 
		* Requirements:
		* 
		* - Sale state must be {SaleState.SALE}.
		* - There must be enough tokens left to mint outside of the reserve.
		* - Caller must send enough ether to pay for `qty_` tokens at public sale price.
		* 
		* @param qty_ : the amount of tokens to be minted
		*/
		function mintPublic( uint256 qty_ ) public validateAmount( qty_ ) isOpen {
			if ( qty_ > MAX_BATCH ) {
				revert NFT_MAX_BATCH( qty_, MAX_BATCH );
			}

			uint256 _remainingSupply_ = MAX_SUPPLY - _reserve - supplyMinted();
			if ( qty_ > _remainingSupply_ ) {
				revert NFT_MAX_SUPPLY( qty_, _remainingSupply_ );
			}

			_mint( _msgSender(), qty_ );
		}
	// **************************************

	// **************************************
	// *****       CONTRACT_OWNER       *****
	// **************************************
		/**
		* @dev See {ITradable-addProxyRegistry}.
		* 
		* @param proxyRegistryAddress_ : the address of the proxy registry to be added
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function addProxyRegistry( address proxyRegistryAddress_ ) external onlyOwner {
			_addProxyRegistry( proxyRegistryAddress_ );
		}

		/**
		* @dev See {ITradable-removeProxyRegistry}.
		* 
		* @param proxyRegistryAddress_ : the address of the proxy registry to be removed
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function removeProxyRegistry( address proxyRegistryAddress_ ) external onlyOwner {
			_removeProxyRegistry( proxyRegistryAddress_ );
		}

		/**
		* @dev Mints `amounts_` tokens and transfers them to `accounts_`.
		* 
		* @param accounts_ : the list of accounts that will receive airdropped tokens
		* @param amounts_  : the amount of tokens each account in `accounts_` will receive
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		* - `accounts_` and `amounts_` must have the same length.
		* - There must be enough tokens left in the reserve.
		*/
		function airdrop( address[] memory accounts_, uint256[] memory amounts_ ) public onlyOwner {
			uint256 _accountsLen_ = accounts_.length;
			uint256 _amountsLen_  = amounts_.length;
			if ( _accountsLen_ != _amountsLen_ ) {
				revert NFT_ARRAY_LENGTH_MISMATCH( _accountsLen_, _amountsLen_ );
			}

			uint256 _totalQty_;
			for ( uint256 i = _amountsLen_; i > 0; i -- ) {
				_totalQty_ += amounts_[ i - 1 ];
			}
			if ( _totalQty_ > _reserve ) {
				revert NFT_MAX_RESERVE( _totalQty_, _reserve );
			}
			unchecked {
				_reserve -= _totalQty_;
			}

			for ( uint256 i; i < _accountsLen_; i ++ ) {
				_mint( accounts_[ i ], amounts_[ i ] );
			}
		}

		/**
		* @dev Updates the baseURI for the tokens.
		* 
		* @param baseURI_ : the new baseURI for the tokens
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function setBaseURI( string memory baseURI_ ) public onlyOwner {
			_setBaseURI( baseURI_ );
		}

		/**
		* @dev Updates the royalty recipient and rate.
		* 
		* @param royaltyRecipient_ : the new recipient of the royalties
		* @param royaltyRate_      : the new royalty rate
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner
		* - `royaltyRate_` cannot be higher than 10,000
		*/
		function setRoyaltyInfo( address royaltyRecipient_, uint256 royaltyRate_ ) external onlyOwner {
			_setRoyaltyInfo( royaltyRecipient_, royaltyRate_ );
		}

		/**
		* @dev See {IPausable-setPauseState}.
		* 
		* @param newState_ : the new sale state
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function setPauseState( uint8 newState_ ) external onlyOwner {
			_setPauseState( newState_ );
		}
	// **************************************

	// **************************************
	// *****            VIEW            *****
	// **************************************
		function supportsInterface( bytes4 interfaceId_ ) public view virtual override(Reg_ERC721Batch, ERC2981Base) returns ( bool ) {
			return ERC2981Base.supportsInterface( interfaceId_ ) ||
						 Reg_ERC721Batch.supportsInterface( interfaceId_ );
		}
	// **************************************
}