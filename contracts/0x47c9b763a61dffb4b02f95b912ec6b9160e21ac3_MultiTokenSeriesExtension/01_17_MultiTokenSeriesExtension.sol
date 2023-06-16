// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: stendhal.ai

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/CreatorExtension.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

/// @title MultiTokenSeriesExtension
/// @author ST3NDHAL (https://stendhal.ai)
/// @author dievardump (https://twitter.com/dievardump)
/// @notice Allows users to create Multi Token series with only one transaction on Manifold's contracts
contract MultiTokenSeriesExtension is CreatorExtension, ICreatorExtensionTokenURI, ReentrancyGuard {
	using Strings for uint256;

	error NotAuthorized();
	error InvalidSeries();

	error InvalidParameter();
	error InvalidPayment();

	error InvalidSignature();

	error TooEarly();
	error TooLate();

	error SupplyExceeded();
	error TooManyRequested();

	error InvalidPayees();
	error InvalidPayeesShares();

	error FailedPayment();

	event SeriesCreated(address operator, address creator, uint256 series);

	struct Series {
		address creator;
		bool isCreator721; // if ERC721 or ERC1155
		address signer;
		string prefix;
	}

	struct SeriesIndexData {
		uint128 tokenId;
		uint128 minted;
	}

	struct TokenSeries {
		uint32 seriesId;
		uint32 index;
	}

	struct Payee {
		address account;
		uint96 share;
	}

	struct MintOrder {
		uint32 seriesId; // series id
		uint32 index; // index in the series
		uint32 maxSupply; // how many can be minted all together for this (seriesId, index)
		uint32 orderSupply; // how many can be minted from this order
		uint128 price; // unit price
		uint32 maxPerWallet; // how many per wallet
		uint32 startsAt; // when this order starts
		uint32 endsAt; // when this order ends
		uint32 allowlistUntil; // if allowlistUntil != 0, then msg.sender needs to be included in signature
		Payee[] payees; // accounts receiving shares for the sale
	}

	uint256 private _lastSeriesId;

	mapping(uint256 => Series) public seriesList;
	mapping(address => mapping(uint256 => TokenSeries)) public tokenSeries;
	mapping(address => mapping(uint256 => mapping(uint256 => SeriesIndexData))) public seriesIndexData;

	/// @dev some mint order might be custom. if `orderSupply` != `maxSupply`, the order will have its own counter
	mapping(bytes32 => uint256) private _mintOrderMinted;
	mapping(bytes32 => mapping(address => uint256)) private _mintOrderAccountMinted;

	/// @dev Only allows approved admins to call the specified function
	modifier creatorAdminRequired(address creator) {
		if (!IAdminControl(creator).isAdmin(msg.sender)) {
			revert NotAuthorized();
		}

		_;
	}

	// =============================================================
	//                           Views
	// =============================================================

	function supportsInterface(
		bytes4 interfaceId
	) public view virtual override(CreatorExtension, IERC165) returns (bool) {
		return
			interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
			CreatorExtension.supportsInterface(interfaceId);
	}

	/// @notice returns the amount of tokens already minted for a token in a series
	/// @param creator the collection
	/// @param series the series id
	/// @param index the index to check
	/// @return the total supply
	function totalSupply(address creator, uint256 series, uint256 index) public view returns (uint256) {
		return seriesIndexData[creator][series][index].minted;
	}

	/// @notice returns the amount of tokens already minted for a list of (series, index)
	/// @param creator the collection
	/// @param series the series id
	/// @param indexes the indexes
	/// @return an array of all supply
	function totalSupplyBatch(
		address creator,
		uint256[] calldata series,
		uint256[] calldata indexes
	) external view returns (uint256[] memory) {
		uint256 length = series.length;
		uint256[] memory supplies = new uint256[](length);
		for (uint i; i < length; i++) {
			supplies[i] = totalSupply(creator, series[i], indexes[i]);
		}
		return supplies;
	}

	/// @notice returns the tokenURI for a tokenId
	/// @param creator the collection address
	/// @param tokenId the token id
	function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
		TokenSeries memory data = tokenSeries[creator][tokenId];
		Series memory series = seriesList[data.seriesId];

		return string.concat(series.prefix, "/", uint256(data.index).toString());
	}

	/// @notice get the amount of items minted for a given order
	/// @dev this amount only changes if there the orderSupply != 0 && orderSupply != (series, index).maxSupply
	/// @param orderId the order id
	/// @return the amount minted on this order
	function getMintOrderMinted(bytes32 orderId) external view returns (uint256) {
		return _mintOrderMinted[orderId];
	}

	/// @notice get the amount of items minted by an account for a given order
	/// @dev this amount only changes if there is a restriction on the amount of item a wallet can purchase
	/// @param orderId the order id
	/// @param account the account
	/// @return the amount minted on this order by account
	function getMintOrderAccountMinted(bytes32 orderId, address account) external view returns (uint256) {
		return _mintOrderAccountMinted[orderId][account];
	}

	/// @notice get an order id
	/// @param order the order
	/// @return the order id
	function getOrderId(MintOrder calldata order) external pure returns (bytes32) {
		return _getOrderId(order);
	}

	// =============================================================
	//                     Public Interactions
	// =============================================================

	/// @notice allows anyone to fulfill an order
	/// @param order the order to fulfill
	/// @param amount how many to mint from this ordeer
	/// @param proof the proof that was signed by the series signer
	function purchase(MintOrder calldata order, uint16 amount, bytes calldata proof) external payable nonReentrant {
		if (amount == 0) {
			revert InvalidParameter();
		}

		if (order.startsAt > block.timestamp) {
			revert TooEarly();
		} else if (order.endsAt != 0 && order.endsAt < block.timestamp) {
			revert TooLate();
		}

		if (msg.value != order.price * amount) {
			revert InvalidPayment();
		}

		bytes32 orderId = _getOrderId(order);

		// verify seriesId and signature for order
		bool isAllowlist = order.allowlistUntil != 0 && order.allowlistUntil > block.timestamp;
		_verifySignature(orderId, isAllowlist ? msg.sender : address(0), seriesList[order.seriesId].signer, proof);

		uint256 temp;

		// verify maxPerWallet
		if (order.maxPerWallet != 0) {
			temp = _mintOrderAccountMinted[orderId][msg.sender] + amount;
			if (temp > order.maxPerWallet) {
				revert TooManyRequested();
			}

			_mintOrderAccountMinted[orderId][msg.sender] = temp;
		}

		// verify order.supply
		if (order.orderSupply != 0 && order.maxSupply != order.orderSupply) {
			temp = _mintOrderMinted[orderId] + amount;
			if (temp > order.orderSupply) {
				revert SupplyExceeded();
			}

			_mintOrderMinted[orderId] = temp;
		}

		address creator = seriesList[order.seriesId].creator;

		// verify order.maxSupply
		temp = seriesIndexData[creator][order.seriesId][order.index].minted + amount;
		if (order.maxSupply != 0 && temp > order.maxSupply) {
			revert SupplyExceeded();
		}
		seriesIndexData[creator][order.seriesId][order.index].minted = uint128(temp);

		if (msg.value != 0) {
			_transferPayments(order.payees);
		}

		_mint(msg.sender, amount, order.seriesId, order.index);
	}

	// =============================================================
	//                     Creators Interactions
	// =============================================================

	/// @notice allows a creator's admin to create a new series
	/// @param series the series data
	function createSeries(Series memory series) external creatorAdminRequired(series.creator) returns (uint256) {
		uint256 seriesId = ++_lastSeriesId;
		// if the creator is erc721 or erc1155, better do it one time here than for every mint
		series.isCreator721 = IERC165(series.creator).supportsInterface(0x80ac58cd);
		seriesList[seriesId] = series;

		emit SeriesCreated(msg.sender, series.creator, seriesId);

		return seriesId;
	}

	/// @notice allows a creator's admin to change the series prefix
	/// @param creator the creator contract
	/// @param seriesId the series id
	/// @param prefix the new prefix
	function setSeriesPrefix(
		address creator,
		uint256 seriesId,
		string calldata prefix
	) external creatorAdminRequired(creator) {
		if (seriesList[seriesId].creator != creator) {
			revert InvalidSeries();
		}

		seriesList[seriesId].prefix = prefix;
	}

	/// @notice allows a creator's admin to change the series signer
	/// @dev the series signer is the address that signs the mint orders
	/// @param creator the creator contract
	/// @param seriesId the series id
	/// @param newSigner the new signer
	function setSeriesSigner(
		address creator,
		uint256 seriesId,
		address newSigner
	) external creatorAdminRequired(creator) {
		if (seriesList[seriesId].creator != creator) {
			revert InvalidSeries();
		}

		seriesList[seriesId].signer = newSigner;
	}

	// =============================================================
	//                       	   Internals
	// =============================================================

	/// mint amount tokens to `to`  and associate the tokenIds with (seriesId, index)
	function _mint(address to, uint16 amount, uint32 seriesId, uint32 index) internal {
		Series memory series = seriesList[seriesId];

		uint256[] memory tokenIds;

		if (series.isCreator721) {
			if (amount == 1) {
				tokenIds = new uint256[](1);
				tokenIds[0] = IERC721CreatorCore(series.creator).mintExtension(to);
			} else {
				tokenIds = IERC721CreatorCore(series.creator).mintExtensionBatch(to, amount);
			}

			_associateTokenSeries(series.creator, tokenIds, seriesId, index);
		} else {
			SeriesIndexData memory seriesData = seriesIndexData[series.creator][seriesId][index];

			address[] memory tos = new address[](1);
			tos[0] = to;

			uint256[] memory amounts = new uint256[](1);
			amounts[0] = amount;

			if (seriesData.tokenId == 0) {
				string[] memory uris;
				tokenIds = IERC1155CreatorCore(series.creator).mintExtensionNew(tos, amounts, uris);
				seriesIndexData[series.creator][seriesId][index].tokenId = uint128(tokenIds[0]);

				_associateTokenSeries(series.creator, tokenIds, seriesId, index);
			} else {
				tokenIds = new uint256[](1);
				tokenIds[0] = seriesData.tokenId;

				IERC1155CreatorCore(series.creator).mintExtensionExisting(tos, tokenIds, amounts);
			}
		}
	}

	/// @dev transfer current msg.value to all payees according to their share
	function _transferPayments(Payee[] calldata payees) internal {
		uint256 length = payees.length;
		if (length == 0) {
			revert InvalidPayees();
		}

		uint256 total;
		uint256 value;
		for (uint i; i < length - 1; i++) {
			value = (msg.value * payees[i].share) / 10000;
			_transferValue(payees[i].account, value);
			total += value;
		}

		// total should be less than msg.value, else there is an error in the shares
		if (total >= msg.value) {
			revert InvalidPayeesShares();
		}

		_transferValue(payees[length - 1].account, msg.value - total);
	}

	function _transferValue(address payee, uint256 value) internal {
		(bool success, ) = payee.call{value: value}("");
		if (!success) {
			revert FailedPayment();
		}
	}

	/// @dev verify message has been signed by signer
	function _verifySignature(bytes32 message, address taker, address signer, bytes calldata proof) internal view {
		// if taker is not address(0), the signature must include it to ensure they are in the allowlist
		if (taker != address(0)) {
			message = keccak256(abi.encode(message, taker));
		} else {
			message = keccak256(abi.encode(message));
		}

		// verifies the signature
		if (signer != ECDSA.recover(ECDSA.toEthSignedMessageHash(message), proof)) {
			revert InvalidSignature();
		}
	}

	/// @dev get an orderId from the order content
	function _getOrderId(MintOrder calldata order) internal pure returns (bytes32) {
		return keccak256(abi.encode(order));
	}

	/// @dev associate (seriesId, index) with all tokenIds of creator
	function _associateTokenSeries(address creator, uint256[] memory tokenIds, uint32 seriesId, uint32 index) internal {
		uint256 length = tokenIds.length;
		TokenSeries memory currentTokenSeries = TokenSeries(seriesId, index);
		for (uint i; i < length; ) {
			tokenSeries[creator][tokenIds[i]] = currentTokenSeries;
			unchecked {
				++i;
			}
		}
	}
}