// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;

import '../EthereumContracts/contracts/NFT/NFTBaseC.sol';
import '../EthereumContracts/contracts/utils/IWhitelistable_ECDSA.sol';

contract BBCLUB is NFTBaseC, IWhitelistable_ECDSA {
	uint8 public constant PRIVATE_SALE = 2;
	uint8 public constant PRE_SALE     = 3;
	uint8 public constant CLAIM        = 4;

	constructor(
		uint256 reserve_,
		uint256 maxBatch_,
		uint256 maxSupply_
	) {
		_initNFTBaseC(
			reserve_,
			maxBatch_,
			maxSupply_,
			30000000000000000,
			500,
			"Bush Baby Club",
			"BUSH",
			"https://api.bushbabyclub.io/metadata?tokenId="
		);
	}

	modifier isPrivateOrPreSale {
		uint8 _currentState_ = getPauseState();
		if ( _currentState_ != PRIVATE_SALE && _currentState_ != PRE_SALE ) {
			revert IPausable_INCORRECT_STATE( _currentState_ );
		}

		_;
	}

	modifier isPreSale {
		uint8 _currentState_ = getPauseState();
		if ( _currentState_ != PRE_SALE ) {
			revert IPausable_INCORRECT_STATE( _currentState_ );
		}

		_;
	}

	// **************************************
	// *****           PUBLIC           *****
	// **************************************
		function claim( uint256 alloted_, Proof memory proof_, uint256 qty_ ) public validateAmount( qty_ ) isNotClosed isWhitelisted( _msgSender(), CLAIM, alloted_, proof_, qty_ ) {
			address _account_ = _msgSender();
			if ( _reserve < qty_ ) {
				revert NFT_MAX_RESERVE( qty_, _reserve );
			}
			unchecked {
				_reserve -= qty_;
			}
			_consumeWhitelist( _account_, CLAIM, qty_ );
			_mint( _account_, qty_ );
		}

		function mintPreSale( uint256 alloted_, Proof memory proof_, uint256 qty_ ) public payable validateAmount( qty_ ) isPreSale isWhitelisted( _msgSender(), PRE_SALE, alloted_, proof_, qty_ ) {
			uint256 _remainingSupply_ = MAX_SUPPLY - _reserve - supplyMinted();
			if ( qty_ > _remainingSupply_ ) {
				revert NFT_MAX_SUPPLY( qty_, _remainingSupply_ );
			}

			uint256 _expected_ = qty_ * SALE_PRICE;
			if ( _expected_ != msg.value ) {
				revert NFT_INCORRECT_PRICE( msg.value, _expected_ );
			}

			address _account_ = _msgSender();
			_consumeWhitelist( _account_, PRE_SALE, qty_ );
			_mint( _account_, qty_ );
		}

		function mintPrivateSale( uint256 alloted_, Proof memory proof_, uint256 qty_ ) public payable validateAmount( qty_ ) isPrivateOrPreSale isWhitelisted( _msgSender(), PRIVATE_SALE, alloted_, proof_, qty_ ) {
			uint256 _remainingSupply_ = MAX_SUPPLY - _reserve - supplyMinted();
			if ( qty_ > _remainingSupply_ ) {
				revert NFT_MAX_SUPPLY( qty_, _remainingSupply_ );
			}

			uint256 _expected_ = qty_ * SALE_PRICE;
			if ( _expected_ != msg.value ) {
				revert NFT_INCORRECT_PRICE( msg.value, _expected_ );
			}

			address _account_ = _msgSender();
			_consumeWhitelist( _account_, PRIVATE_SALE, qty_ );
			_mint( _account_, qty_ );
		}
	// **************************************

	// **************************************
	// *****       CONTRACT_OWNER       *****
	// **************************************
		function setWhitelist( address adminSigner_ ) public onlyOwner {
			_setWhitelist( adminSigner_ );
		}
	// **************************************
}