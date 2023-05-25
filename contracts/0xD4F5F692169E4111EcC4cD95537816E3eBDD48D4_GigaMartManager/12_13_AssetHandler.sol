// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
	SafeERC20,
	IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {
	IERC721
} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {
	IERC1155
} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {
	Registry
} from "./Registry.sol";

import { 
	IAssetHandler,
	NonAuthorized,
	Transfer,
	AssetType,
	Item,
	ItemType,
	ERC20Payment
} from "../interfaces/IGigaMartManager.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Asset Handler
	@author Tim Clancy <@_Enoch>
	@author Rostislav Khlebnikov <@catpic5buck>

	Asset Handler is a logic component of GigaMart Manager contract, which 
	executes ERC20, ERC721 and ERC1155 token transfers. User must approve 
	this contract with their tokens to participate in trading.
*/
contract AssetHandler is Registry, IAssetHandler {
	using SafeERC20 for IERC20;

	/**
		Private helper function, which calls ERC20 contract transfer function.

		@param _token Address of the token.
		@param _from Address, from which tokens are being transferred.
		@param _to Address, to which  tokens are being transferred.
		@param _amount Amount of the tokens.
	*/
	function _transferERC20(
		address _token,
		address _from,
		address _to,
		uint256 _amount
	) private {
		IERC20(_token).safeTransferFrom(
			_from,
			_to,
			_amount
		);
	}

	/**
		Private helper function, which calls ERC721 contract transfer function.

		@param _collection Address of the collection, token belongs to.
		@param _from Address, from which token is being transferred.
		@param _to Address, to which  token is being transferred.
		@param _id id of the tokens.
	*/
	function _transferERC721(
		address _collection,
		address _from,
		address _to,
		uint256 _id
	) private {
		IERC721(_collection).safeTransferFrom(
			_from,
			_to,
			_id,
			""
		);
	}

	/**
		Private helper function, which calls ERC1155 contract transfer function.

		@param _collection Address of the collection, token belongs to.
		@param _from Address, from which token is being transferred.
		@param _to Address, to which  token is being transferred.
		@param _id Id of the tokens.
		@param _amount Amount of the token.
	*/
	function _transferERC1155(
		address _collection,
		address _from,
		address _to,
		uint256 _id,
		uint256 _amount
	) private {
		IERC1155(_collection).safeTransferFrom(
			_from,
			_to,
			_id,
			_amount,
			""
		);
	}

	/**
		Execute restricted ERC721 or ERC1155 transfer. Reverts if caller is
		not authorized to call this function.

		@param _item Item to transfer.
		
		@custom:throws NonAuthorized.
	*/
	function transferItem(
		Item calldata _item
	) public {
		if (!authorizedCallers[msg.sender]) {
			revert NonAuthorized(msg.sender);
		}
		if ( _item.itemType == ItemType.ERC721) {
			_transferERC721(
				_item.collection,
				_item.from,
				_item.to, 
				_item.id
			);
		}
		if (_item.itemType == ItemType.ERC1155) {
			_transferERC1155(
				_item.collection,
				_item.from,
				_item.to, 
				_item.id,
				_item.amount
			);
		}
	}

	/**
		Executes restricted ERC20 transfer. Reverts if caller is
		not authorized to call this function.

		@param _token Address of the token.
		@param _from Address, from which tokens are being transferred.
		@param _to Address, to which tokens are being transferrec.
		@param _amount Amount of tokens.

		@custom:throws NonAuthorized.
	*/
	function transferERC20 (
		address _token,
		address _from,
		address _to,
		uint256 _amount
	) external {
		if (!authorizedCallers[msg.sender]) {
			revert NonAuthorized(msg.sender);
		}
		_transferERC20(
			_token,
			_from,
			_to,
			_amount
		);
	}

	/**
		Executes multiple restricted ERC20 transfers. Reverts if caller is
		not authorized to call this function.

		@param _payments Array of helper structs, which contains information
		about ERC20 token transfers.

		@custom:throws NonAuthorized.
	*/
	function transferPayments (
		ERC20Payment[] calldata _payments
	) external {
		if (!authorizedCallers[msg.sender]) {
			revert NonAuthorized(msg.sender);
		}
		for (uint256 i; i < _payments.length; ) {
			_transferERC20(
				_payments[i].token,
				_payments[i].from,
				_payments[i].to,
				_payments[i].amount
			);
			unchecked {
				++i;
			}
		}
	}

	/**
		Execute multiple transfers from msg.sender to supplied
		recipients addresses.

		@param _transfers Items to transfer.
	*/
	function transferMultipleItems (
		Transfer[] calldata _transfers
	) external {
		for (uint256 i; i < _transfers.length; ) {
			if ( _transfers[i].assetType == AssetType.ERC20) {
				_transferERC20(
					_transfers[i].collection,
					msg.sender,
					_transfers[i].to, 
					_transfers[i].amount
				);
			}
			if ( _transfers[i].assetType == AssetType.ERC721) {
				_transferERC721(
					_transfers[i].collection,
					msg.sender,
					_transfers[i].to, 
					_transfers[i].id
				);
			}
			if (_transfers[i].assetType == AssetType.ERC1155) {
				_transferERC1155(
					_transfers[i].collection,
					msg.sender,
					_transfers[i].to, 
					_transfers[i].id,
					_transfers[i].amount
				);
			}
			unchecked {
				++i;
			}
		}
	}
}