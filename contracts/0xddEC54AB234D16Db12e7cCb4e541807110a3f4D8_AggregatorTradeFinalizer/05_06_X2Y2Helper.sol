// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/**
	@title X2Y2 Helper
	@author X2Y2

	This library defines the structs needed to interface with the X2Y2 exchange 
	for fulfilling aggregated orders. Full documentation of X2Y2 structs is left 
	as an exercise of the reader.
*/
library X2Y2Helper {

	/**
		This struct defines an ERC-721 item as a token address and a token ID.

		@param token The address of the ERC-721 item contract.
		@param tokenId The ID of the ERC-721 item.
	*/
	struct Pair721 {
		address token;
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
		address token;
		uint256 tokenId;
		uint256 amount;
	}

	/**
		A helper function to replace particular masked values in the `_src` array.

		@param _src The array to replace elements within.
		@param _replacement The array of potential replacement elements.
		@param _mask A mask of indices correlating to truthy values which indicate 
			which elements in `_src` should be replaced with elements in 
			`_replacement`.
	*/
	function arrayReplace (
		bytes memory _src,
		bytes memory _replacement,
		bytes memory _mask
	) internal pure {
		for (uint256 i = 0; i < _src.length; i++) {
			if (_mask[i] != 0) {
				_src[i] = _replacement[i];
			}
		}
	}

	struct OrderItem {
		uint256 price;
		bytes data;
	}

	struct Order {
		uint256 salt;
		address user;
		uint256 network;
		uint256 intent;
		uint256 delegateType;
		uint256 deadline;
		address currency;
		bytes dataMask;
		OrderItem[] items;
		bytes32 r;
		bytes32 s;
		uint8 v;
		uint8 signVersion;
	}

	enum Operation {
		INVALID,
		COMPLETE_SELL_OFFER,
		COMPLETE_BUY_OFFER,
		CANCEL_OFFER,
		BID,
		COMPLETE_AUCTION,
		REFUND_AUCTION,
		REFUND_AUCTION_STUCK_ITEM
	}

	struct Fee {
		uint256 percentage;
		address to;
	}

	struct SettleDetail {
		Operation op;
		uint256 orderIdx;
		uint256 itemIdx;
		uint256 price;
		bytes32 itemHash;
		address executionDelegate;
		bytes dataReplacement;
		uint256 bidIncentivePct;
		uint256 aucMinIncrementPct;
		uint256 aucIncDurationSecs;
		Fee[] fees;
	}

	struct SettleShared {
		uint256 salt;
		uint256 deadline;
		uint256 amountToEth;
		uint256 amountToWeth;
		address user;
		bool canFail;
	}

	struct RunInput {
		Order[] orders;
		SettleDetail[] details;
		SettleShared shared;
		bytes32 r;
		bytes32 s;
		uint8 v;
	}
}