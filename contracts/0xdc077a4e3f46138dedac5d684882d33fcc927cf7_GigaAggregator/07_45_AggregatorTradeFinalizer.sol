// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../test/looksrare/LooksRareExchange.sol";
import "../test/x2y2/X2Y2Exchange.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Aggregated Finalizer
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>
	
	This contract implements delegated order finalization for particular 
	exchanges supported by the multi-market aggregator for GigaMart. In 
	particular, certain exchanges require the orders to be issued from the 
	recipient of the item, like X2Y2 and LooksRare.

	@custom:version 1.0
	@custom:date Januart 24th, 2023.
*/
contract AggregatorTradeFinalizer {

	/// A constant for the ERC-721 interface ID.
	bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

	/// Track the slot for a supported exchange.
	uint256 private constant _SUPPORTED_EXCHANGES_SLOT = 4;

	/// Record the address of X2Y2's exchange.
	address private constant _X2Y2_ADDRESS =
		0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3;

	/// Record the address of LooksRare's exchange.
	address private constant _LOOKSRARE_ADDRESS =
		0x59728544B08AB483533076417FbBB2fD0B17CE3a;

	/**
		This struct defines an ERC-721 item as a token address and a token ID.

		@param token The address of the ERC-721 item contract.
		@param tokenId The ID of the ERC-721 item.
	*/
	struct Pair721 {
		IERC721 token;
		uint256 tokenId;
	}

	/**
		This struct defines an ERC-1155 item as a token address, token ID, and 
		amount.

		@param token The address of the ERC-1155 item contract.
		@param tokenId The ID of the ERC-1155 item.
		@param amount The amount of the ERC-1155 item to transfer.
	*/
	struct Pair1155 {
		IERC1155 token;
		uint256 tokenId;
		uint256 amount;
	}

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
		A helper function to replace particular masked values in the `_src` array
	*/
	function _arrayReplace (
		bytes memory _src,
		bytes memory _replacement,
		bytes memory _mask
	) internal pure virtual {
		for (uint256 i = 0; i < _src.length; i++) {
			if (_mask[i] != 0) {
				_src[i] = _replacement[i];
			}
		}
	}

		function run(Market.RunInput calldata input) external payable{
				for ( uint256 i; i < input.details.length;) {
						bytes memory data = input.orders[input.details[i].orderIdx].items[input.details[i].itemIdx].data;
						{
								if (input.orders[input.details[i].orderIdx].dataMask.length > 0 && input.details[i].dataReplacement.length > 0) {
										_arrayReplace(data, input.details[i].dataReplacement, input.orders[input.details[i].orderIdx].dataMask);
								}
						}
						if (data.length == 128){
								Pair721[] memory pairs = abi.decode(data, (Pair721[]));
								for (uint256 j; j < pairs.length;) {
										pairs[j].token.safeTransferFrom(address(this), msg.sender, pairs[j].tokenId);
										unchecked {
												++j;
										}
								}
						} else {
								Pair1155[] memory pairs = abi.decode(data, (Pair1155[]));
								for (uint256 j; j < pairs.length;) {
										pairs[j].token.safeTransferFrom(address(this), msg.sender, pairs[j].tokenId, pairs[j].amount, "");
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

		function matchAskWithTakerBidUsingETHAndWETH(
				OrderTypes.TakerOrder calldata,
				OrderTypes.MakerOrder calldata makerAsk
		) external payable {
				if (IERC165(makerAsk.collection).supportsInterface(INTERFACE_ID_ERC721)) {
						IERC721(makerAsk.collection).safeTransferFrom(address(this), msg.sender, makerAsk.tokenId);
				} else {
						IERC1155(makerAsk.collection).safeTransferFrom(address(this), msg.sender, makerAsk.tokenId, makerAsk.amount, "");
				}
		}

		function matchAskWithTakerBid(
				OrderTypes.TakerOrder calldata,
				OrderTypes.MakerOrder calldata makerAsk
		) external payable {
				if (IERC165(makerAsk.collection).supportsInterface(INTERFACE_ID_ERC721)) {
						IERC721(makerAsk.collection).safeTransferFrom(address(this), msg.sender, makerAsk.tokenId);
				} else {
						IERC1155(makerAsk.collection).safeTransferFrom(address(this), msg.sender, makerAsk.tokenId, makerAsk.amount, "");
				}
		}
}