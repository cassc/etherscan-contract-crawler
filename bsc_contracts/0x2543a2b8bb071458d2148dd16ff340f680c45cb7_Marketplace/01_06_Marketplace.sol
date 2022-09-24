// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

// Solmate
import { Auth, Authority } from 'solmate/auth/Auth.sol';
import { ERC20 } from 'solmate/tokens/ERC20.sol';
import { ERC721, ERC721TokenReceiver } from 'solmate/tokens/ERC721.sol';
import { ERC1155, ERC1155TokenReceiver } from 'solmate/tokens/ERC1155.sol';
import { SafeTransferLib } from 'solmate/utils/SafeTransferLib.sol';

struct Listing {
	address owner;
	address token;
	uint256 id;
	uint256 amount;
	uint256 price;
}

enum Types {
	Unsupported,
	ERC20,
	ERC721,
	ERC1155
}

contract Marketplace is Auth, ERC721TokenReceiver, ERC1155TokenReceiver {
	ERC20 public currency;
	mapping(address => Types) public allowedTokens;
	mapping(uint256 => Listing) public listings;
	uint256 private listingCount = 0;

	constructor(
		ERC20 _currency,
		address _owner,
		Authority _authority
	) Auth(_owner, _authority) {
		currency = _currency;
	}

	// Marketplace
	function listERC20(
		address token,
		uint256 amount,
		uint256 price
	) public {
		require(allowedTokens[token] == Types.ERC20, 'UNSUPPORTED_TOKEN');

		SafeTransferLib.safeTransferFrom(
			ERC20(token),
			msg.sender,
			address(this),
			amount
		);
		createListing(token, 0, amount, price);
	}

	function listERC721(
		address token,
		uint256 id,
		uint256 price
	) public {
		require(allowedTokens[token] == Types.ERC721, 'UNSUPPORTED_TOKEN');

		ERC721(token).safeTransferFrom(msg.sender, address(this), id);
		createListing(token, id, 1, price);
	}

	function listERC1155(
		address token,
		uint256 id,
		uint256 amount,
		uint256 price
	) public {
		require(allowedTokens[token] == Types.ERC1155, 'UNSUPPORTED_TOKEN');

		ERC1155(token).safeTransferFrom(msg.sender, address(this), id, amount, '');
		createListing(token, id, amount, price);
	}

	function cancelERC20(uint256 id) public {
		Listing storage listing = listings[id];
		require(listing.owner == msg.sender, 'UNAUTHORIZED');
		require(allowedTokens[listing.token] == Types.ERC20, 'WRONG_TOKEN');

		SafeTransferLib.safeTransfer(
			ERC20(listing.token),
			msg.sender,
			listing.amount
		);

		delete listings[id];
	}

	function cancelERC721(uint256 id) public {
		Listing storage listing = listings[id];
		require(listing.owner == msg.sender, 'UNAUTHORIZED');
		require(allowedTokens[listing.token] == Types.ERC721, 'WRONG_TOKEN');

		ERC721(listing.token).safeTransferFrom(
			address(this),
			msg.sender,
			listing.id
		);

		delete listings[id];
	}

	function cancelERC1155(uint256 id) public {
		Listing storage listing = listings[id];
		require(listing.owner == msg.sender, 'UNAUTHORIZED');
		require(allowedTokens[listing.token] == Types.ERC1155, 'WRONG_TOKEN');

		ERC1155(listing.token).safeTransferFrom(
			address(this),
			msg.sender,
			listing.id,
			listing.amount,
			''
		);

		delete listings[id];
	}

	function buyERC20(uint256 id) public {
		Listing storage listing = listings[id];
		require(allowedTokens[listing.token] == Types.ERC20, 'WRONG_TOKEN');

		SafeTransferLib.safeTransferFrom(
			currency,
			msg.sender,
			listing.owner,
			listing.price
		);
		SafeTransferLib.safeTransfer(
			ERC20(listing.token),
			msg.sender,
			listing.amount
		);

		delete listings[id];
	}

	function buyERC721(uint256 id) public {
		Listing storage listing = listings[id];
		require(allowedTokens[listing.token] == Types.ERC721, 'WRONG_TOKEN');

		SafeTransferLib.safeTransferFrom(
			currency,
			msg.sender,
			listing.owner,
			listing.price
		);
		ERC721(listing.token).safeTransferFrom(
			address(this),
			msg.sender,
			listing.id
		);

		delete listings[id];
	}

	function buyERC1155(uint256 id) public {
		Listing storage listing = listings[id];
		require(allowedTokens[listing.token] == Types.ERC1155, 'WRONG_TOKEN');

		SafeTransferLib.safeTransferFrom(
			currency,
			msg.sender,
			listing.owner,
			listing.price
		);
		ERC1155(listing.token).safeTransferFrom(
			address(this),
			msg.sender,
			listing.id,
			listing.amount,
			''
		);

		delete listings[id];
	}

	// Admin
	function allowToken(address token, Types nftType) public requiresAuth {
		allowedTokens[token] = nftType;
	}

	function setCurrency(ERC20 _currency) public requiresAuth {
		currency = _currency;
	}

	// Private
	function createListing(
		address token,
		uint256 id,
		uint256 amount,
		uint256 price
	) public {
		listings[listingCount] = Listing({
			owner: msg.sender,
			token: token,
			id: id,
			amount: amount,
			price: price
		});

		unchecked {
			listingCount++;
		}
	}
}