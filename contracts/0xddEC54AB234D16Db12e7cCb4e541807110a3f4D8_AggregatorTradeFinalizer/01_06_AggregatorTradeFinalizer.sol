// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./lib/LooksRareHelper.sol";
import "./lib/X2Y2Helper.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Aggregated Finalizer
	@author Rostislav Khlebnikov <@catpic5buck>
	@author Tim Clancy <@_Enoch>

	This contract implements delegated order finalization for particular 
	exchanges supported by the multi-market aggregator for GigaMart. In 
	particular, certain exchanges require the orders to be issued from the 
	recipient of the item, like X2Y2 and LooksRare.

	@custom:version 1.0
	@custom:date February 1st, 2023.
*/
contract AggregatorTradeFinalizer {

	/// A constant for the ERC-721 interface ID.
	bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

	/// Track the slot for a supported exchange.
	uint256 private constant _SUPPORTED_EXCHANGES_SLOT = 4;
	
	/// Record the address of LooksRare's exchange.
	address private constant _LOOKSRARE_ADDRESS =
		0x59728544B08AB483533076417FbBB2fD0B17CE3a;
	
	/// Record the address of X2Y2's exchange.
	address private constant _X2Y2_ADDRESS =
		0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3;

	/**
		A function to initialize storage for this aggregated trade finalizer.
	*/
	function initialize () external {
		assembly {
			mstore(0x00, _LOOKSRARE_ADDRESS)
			mstore(0x20, _SUPPORTED_EXCHANGES_SLOT)
			let lr_key := keccak256(0x00, 0x40)
			mstore(0x00, _X2Y2_ADDRESS)
			let x2y2_key := keccak256(0x00, 0x40)
			sstore(lr_key, add(sload(lr_key), 1))
			sstore(x2y2_key, add(sload(x2y2_key), 1))
		}
	}

	/**
		Match a LooksRare ask, fulfilled using ETH, via this finalizer to transfer 
		the purchased item to the buyer.

		@param _ask The LooksRare ask order being fulfilled.
	*/
	function matchAskWithTakerBidUsingETHAndWETH (
		LooksRareHelper.TakerOrder calldata,
		LooksRareHelper.MakerOrder calldata _ask
	) external payable {
		if (IERC165(_ask.collection).supportsInterface(INTERFACE_ID_ERC721)) {
			IERC721(_ask.collection).safeTransferFrom(
				address(this),
				msg.sender,
				_ask.tokenId
			);
		} else {
			IERC1155(_ask.collection).safeTransferFrom(
				address(this),
				msg.sender,
				_ask.tokenId,
				_ask.amount,
				""
			);
		}
	}

	/**
		Match a LooksRare ask via this finalizer to transfer the purchased item to 
		the buyer.

		@param _ask The LooksRare ask order being fulfilled.
	*/
	function matchAskWithTakerBid (
		LooksRareHelper.TakerOrder calldata,
		LooksRareHelper.MakerOrder calldata _ask
	) external payable {
		if (IERC165(_ask.collection).supportsInterface(INTERFACE_ID_ERC721)) {
			IERC721(_ask.collection).safeTransferFrom(
				address(this),
				msg.sender,
				_ask.tokenId
			);
		} else {
			IERC1155(_ask.collection).safeTransferFrom(
				address(this),
				msg.sender,
				_ask.tokenId,
				_ask.amount,
				""
			);
		}
	}

	/**
		Finalize an X2Y2 purchase.

		@param _input The X2Y2 order input struct.
	*/
	function run (
		X2Y2Helper.RunInput calldata _input
	) external payable {
		for (uint256 i; i < _input.details.length; ) {
			bytes memory data = _input.orders[_input.details[i].orderIdx]
				.items[_input.details[i].itemIdx].data;

			// Replace any data masked within the order.
			{
				if (
					_input.orders[_input.details[i].orderIdx].dataMask.length > 0 
					&& _input.details[i].dataReplacement.length > 0
				) {
					X2Y2Helper.arrayReplace(
						data,
						_input.details[i].dataReplacement,
						_input.orders[_input.details[i].orderIdx].dataMask
					);
				}
			}

			/*
				Divide the data length on the amount of structs in the original bytes 
				array to get a bytes length for a single struct.
			*/
			uint256 pairSize;
			assembly {
				pairSize := div(

					/*
						Load the length of the entire bytes array and escape 64 bytes of 
						offset and length.
					*/
					sub(mload(data), 0x40), 
					
					// Load the length of the Pair structs encoded into the bytes array.
					mload(add(data, 0x40))
				)
			}

			// ERC-721 items transferred by X2Y2 have a data length of two words.
			if (pairSize == 64) {
				X2Y2Helper.Pair721[] memory pairs = abi.decode(
					data,
					(X2Y2Helper.Pair721[])
				);
				for (uint256 j; j < pairs.length; ) {
					IERC721(pairs[j].token).safeTransferFrom(
						address(this),
						msg.sender,
						pairs[j].tokenId
					);

					unchecked {
						++j;
					}
				}

			// If the length is three words, the item is an ERC-1155.
			} else if (pairSize == 96) {
				X2Y2Helper.Pair1155[] memory pairs = abi.decode(
					data,
					(X2Y2Helper.Pair1155[])
				);
				for (uint256 j; j < pairs.length; ) {
					IERC1155(pairs[j].token).safeTransferFrom(
						address(this),
						msg.sender,
						pairs[j].tokenId, pairs[j].amount,
						""
					);

					unchecked {
						++j;
					}
				}
			}

			unchecked {
				++i;
			}
		}
	}
}