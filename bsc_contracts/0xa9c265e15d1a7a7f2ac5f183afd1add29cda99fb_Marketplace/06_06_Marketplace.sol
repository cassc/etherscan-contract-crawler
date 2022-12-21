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
	uint32 public constant MAX_FEE = 1000;
	uint32 public constant FEE_PRECISION = 1e4;

	ERC20 public currency;
	mapping(address => Types) public allowedTokens;
	mapping(uint256 => Listing) public listings;
	uint256 private listingCount = 0;

	uint256 public fee;
	address public beneficiary;

	event ItemListed(
		address indexed token,
		uint256 indexed id,
		uint256 indexed listingId,
		address owner,
		uint256 amount,
		uint256 price
	);
	event ItemCancelled(uint256 indexed id);
	event ItemBought(uint256 indexed id);

	event AllowToken(address indexed token, Types nftType);
	event SetCurrency(ERC20 currency);
	event SetFee(uint256 fee);

	constructor(
		ERC20 _currency,
		address _owner,
		Authority _authority,
		address _beneficiary,
		uint256 _fee
	) Auth(_owner, _authority) {
		currency = _currency;
		beneficiary = _beneficiary;
		fee = _fee;

		emit SetFee(fee);
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
		emit ItemCancelled(id);
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
		emit ItemCancelled(id);
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
		emit ItemCancelled(id);
	}

	function buyERC20(uint256 id) public {
		Listing storage listing = listings[id];
		require(allowedTokens[listing.token] == Types.ERC20, 'WRONG_TOKEN');

		transferFee(listing.price);
		transferProfits(listing);

		SafeTransferLib.safeTransfer(
			ERC20(listing.token),
			msg.sender,
			listing.amount
		);

		delete listings[id];
		emit ItemBought(id);
	}

	function buyERC721(uint256 id) public {
		Listing storage listing = listings[id];
		require(allowedTokens[listing.token] == Types.ERC721, 'WRONG_TOKEN');

		transferFee(listing.price);
		transferProfits(listing);

		ERC721(listing.token).safeTransferFrom(
			address(this),
			msg.sender,
			listing.id
		);

		delete listings[id];
		emit ItemBought(id);
	}

	function buyERC1155(uint256 id) public {
		Listing storage listing = listings[id];
		require(allowedTokens[listing.token] == Types.ERC1155, 'WRONG_TOKEN');

		transferFee(listing.price);
		transferProfits(listing);

		ERC1155(listing.token).safeTransferFrom(
			address(this),
			msg.sender,
			listing.id,
			listing.amount,
			''
		);

		delete listings[id];
		emit ItemBought(id);
	}

	// Admin
	function allowToken(address token, Types nftType) public requiresAuth {
		allowedTokens[token] = nftType;
		emit AllowToken(token, nftType);
	}

	function setCurrency(ERC20 _currency) public requiresAuth {
		currency = _currency;
		emit SetCurrency(currency);
	}

	function setFee(uint256 _fee) public requiresAuth {
		require(_fee <= MAX_FEE, 'FEE_TOO_HIGH');

		fee = _fee;
		emit SetFee(fee);
	}

	// Private
	function createListing(
		address token,
		uint256 id,
		uint256 amount,
		uint256 price
	) public {
		emit ItemListed(token, id, listingCount, msg.sender, amount, price);
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

	function transferFee(uint256 price) private {
		SafeTransferLib.safeTransferFrom(
			currency,
			msg.sender,
			beneficiary,
			(price * fee) / FEE_PRECISION
		);
	}

	function transferProfits(Listing storage listing) private {
		SafeTransferLib.safeTransferFrom(
			currency,
			msg.sender,
			listing.owner,
			listing.price
		);
	}
}