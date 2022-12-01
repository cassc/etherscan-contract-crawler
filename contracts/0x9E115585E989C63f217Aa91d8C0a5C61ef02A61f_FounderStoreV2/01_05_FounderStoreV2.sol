// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Founder Cards Store (v.2)
/// @author Studio Avante
/// @notice Contains token info for Founder Cards (ids 1, 2, 3, 4)
/// @dev Serves CardsMinter.sol, will be upgraded to a generic store eventually
pragma solidity ^0.8.16;
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Base64 } from '@openzeppelin/contracts/utils/Base64.sol';
import { ICardsStore } from './ICardsStore.sol';

contract FounderStoreV2 is ICardsStore, Ownable {

	uint8 constant TYPE_CLASS = 1;

	struct Card {
		uint256 price;
		uint128 supply;
		uint8 cardType;
		string name;
		string edition;
		string description;
		string imageData;
	}
	
	mapping(uint256 => Card) private _cards;

	/// @notice Emitted when a new card is created
	/// @param id Token id
	/// @param name The name of the card
	event Created(uint256 indexed id, string indexed name);

	constructor() {
		_createCard(1, Card(
			1_000_000_000_000_000_000, // 1 eth
			16,
			TYPE_CLASS,
			'Champion',
			'Founder',
			'The keeper of this card is a Crawler Champion. Grants all native cards!',
			'<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" viewBox="0 -0.5 16 16"><path stroke="#1a1a1a" d="M2 0h12M1 1h2m10 0h2M1 2h1m1 0h10m1 0h1M1 3h1m1 0h2m2 0h2m1 0h3m1 0h1M1 4h1m1 0h1m1 0h2m1 0h1m1 0h3m1 0h1M1 5h1m1 0h1m1 0h4m1 0h3m1 0h1M1 6h1m1 0h1m1 0h4m2 0h2m1 0h1M1 7h1m1 0h1m1 0h4m1 0h1m1 0h1m1 0h1M1 8h1m1 0h1m1 0h2m1 0h1m1 0h1m1 0h1m1 0h1M1 9h1m1 0h2m2 0h2m1 0h1m1 0h1m1 0h1M1 10h1m1 0h10m1 0h1M1 11h2m1 0h3m1 0h1m1 0h2m1 0h2M2 12h2m1 0h6m1 0h2M3 13h2m1 0h4m1 0h2m-9 1h2m4 0h2m-7 1h6"/><path stroke="#ffbfa6" d="M3 1h10M2 2h1m10 0h1M2 3h1m10 0h1M2 4h1m10 0h1M2 5h1m10 0h1M2 6h1m10 0h1M2 7h1m10 0h1M2 8h1m10 0h1M2 9h1m10 0h1M2 10h1m10 0h1M3 11h1m8 0h1m-9 1h1m6 0h1m-7 1h1m4 0h1m-5 1h4"/><path stroke="#f2e9c3" d="M5 3h2m2 0h1M4 4h1m2 0h1m1 0h1M4 5h1m4 0h1M4 6h1m4 0h2M4 7h1m4 0h1m1 0h1M4 8h1m2 0h1m1 0h1m1 0h1M5 9h2m2 0h1m1 0h1"/><path stroke="#784f40" d="M7 11h1m1 0h1"/></svg>'
		));
		_createCard(2, Card(
			80_000_000_000_000_000, // 0.08 eth
			256,
			TYPE_CLASS,
			'Hero',
			'Founder',
			'The keeper of this card is a Crawler Hero. Grants all native cards!',
			'<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" viewBox="0 -0.5 16 16"><path stroke="#1a1a1a" d="M2 0h12M1 1h2m10 0h2M1 2h1m1 0h10m1 0h1M1 3h1m1 0h1m1 0h2m1 0h5m1 0h1M1 4h1m1 0h1m1 0h2m1 0h5m1 0h1M1 5h1m1 0h1m1 0h2m1 0h5m1 0h1M1 6h1m1 0h1m4 0h2m2 0h1m1 0h1M1 7h1m1 0h1m1 0h2m1 0h1m1 0h3m1 0h1M1 8h1m1 0h1m1 0h2m1 0h1m1 0h3m1 0h1M1 9h1m1 0h1m1 0h2m1 0h1m1 0h1m1 0h1m1 0h1M1 10h1m1 0h10m1 0h1M1 11h2m1 0h3m1 0h1m1 0h2m1 0h2M2 12h2m1 0h6m1 0h2M3 13h2m1 0h4m1 0h2m-9 1h2m4 0h2m-7 1h6"/><path stroke="#ffbfa6" d="M3 1h10M2 2h1m10 0h1M2 3h1m10 0h1M2 4h1m10 0h1M2 5h1m10 0h1M2 6h1m10 0h1M2 7h1m10 0h1M2 8h1m10 0h1M2 9h1m10 0h1M2 10h1m10 0h1M3 11h1m8 0h1m-9 1h1m6 0h1m-7 1h1m4 0h1m-5 1h4"/><path stroke="#f2e9c3" d="M4 3h1m2 0h1M4 4h1m2 0h1M4 5h1m2 0h1M4 6h4m2 0h2M4 7h1m2 0h1m1 0h1M4 8h1m2 0h1m1 0h1M4 9h1m2 0h1m1 0h1m1 0h1"/><path stroke="#784f40" d="M7 11h1m1 0h1"/></svg>'
		));
		_createCard(3, Card(
			20_000_000_000_000_000, // 0.02 eth
			1000,
			TYPE_CLASS,
			'Crawler',
			'1st',
			'The keeper of this card is an Original Crawler.',
			'<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" viewBox="0 -0.5 16 16"><path stroke="#1a1a1a" d="M2 0h12M1 1h2m10 0h2M1 2h1m1 0h10m1 0h1M1 3h1m1 0h2m2 0h6m1 0h1M1 4h1m1 0h1m1 0h2m1 0h5m1 0h1M1 5h1m1 0h1m1 0h8m1 0h1M1 6h1m1 0h1m1 0h5m2 0h1m1 0h1M1 7h1m1 0h1m1 0h4m1 0h3m1 0h1M1 8h1m1 0h1m1 0h2m1 0h1m1 0h3m1 0h1M1 9h1m1 0h2m2 0h2m1 0h1m1 0h1m1 0h1M1 10h1m1 0h10m1 0h1M1 11h2m1 0h3m1 0h1m1 0h2m1 0h2M2 12h2m1 0h6m1 0h2M3 13h2m1 0h4m1 0h2m-9 1h2m4 0h2m-7 1h6"/><path stroke="#ffbfa6" d="M3 1h10M2 2h1m10 0h1M2 3h1m10 0h1M2 4h1m10 0h1M2 5h1m10 0h1M2 6h1m10 0h1M2 7h1m10 0h1M2 8h1m10 0h1M2 9h1m10 0h1M2 10h1m10 0h1M3 11h1m8 0h1m-9 1h1m6 0h1m-7 1h1m4 0h1m-5 1h4"/><path stroke="#f2e9c3" d="M5 3h2M4 4h1m2 0h1M4 5h1M4 6h1m5 0h2M4 7h1m4 0h1M4 8h1m2 0h1m1 0h1M5 9h2m2 0h1m1 0h1"/><path stroke="#784f40" d="M7 11h1m1 0h1"/></svg>'
		));
		_createCard(4, Card(
			0, // Free
			0, // Not released yet
			TYPE_CLASS,
			'Adventurer',
			'Limited',
			'The keeper of this card is a Loot Adventurer. Claimable soon with Loot (for Adventurers).',
			'<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" viewBox="0 -0.5 16 16"><path stroke="#1a1a1a" d="M2 0h12M1 1h2m10 0h2M1 2h1m1 0h10m1 0h1M1 3h1m1 0h2m2 0h4m1 0h1m1 0h1M1 4h1m1 0h1m1 0h2m1 0h3m1 0h1m1 0h1M1 5h1m1 0h1m1 0h2m1 0h3m1 0h1m1 0h1M1 6h1m1 0h1m4 0h2m2 0h1m1 0h1M1 7h1m1 0h1m1 0h2m1 0h1m1 0h1m1 0h1m1 0h1M1 8h1m1 0h1m1 0h2m1 0h1m1 0h1m1 0h1m1 0h1M1 9h1m1 0h1m1 0h2m1 0h2m1 0h2m1 0h1M1 10h1m1 0h10m1 0h1M1 11h2m1 0h3m1 0h1m1 0h2m1 0h2M2 12h2m1 0h6m1 0h2M3 13h2m1 0h4m1 0h2m-9 1h2m4 0h2m-7 1h6"/><path stroke="#ffbfa6" d="M3 1h10M2 2h1m10 0h1M2 3h1m10 0h1M2 4h1m10 0h1M2 5h1m10 0h1M2 6h1m10 0h1M2 7h1m10 0h1M2 8h1m10 0h1M2 9h1m10 0h1M2 10h1m10 0h1M3 11h1m8 0h1m-9 1h1m6 0h1m-7 1h1m4 0h1m-5 1h4"/><path stroke="#f2e9c3" d="M5 3h2m4 0h1M4 4h1m2 0h1m3 0h1M4 5h1m2 0h1m3 0h1M4 6h4m2 0h2M4 7h1m2 0h1m1 0h1m1 0h1M4 8h1m2 0h1m1 0h1m1 0h1M4 9h1m2 0h1m2 0h1"/><path stroke="#784f40" d="M7 11h1m1 0h1"/></svg>'
		));
	}

	function _createCard(uint256 id, Card memory card) internal {
		_cards[id] = card;
		emit Created(id, _cards[id].name);
	}

	//---------------
	// Public
	//

	/// @notice Returns the Store version
	/// @return version This contract version (1)
	function getVersion() public pure override returns (uint8) {
		return 2;
	}

	/// @notice Check if a Token exists
	/// @param id Token id
	/// @return bool True if it exists, False if not
	function exists(uint256 id) public pure override returns (bool) {
		return (id >= 1 && id <= 4);
	}

	/// @notice Returns a Token stored info
	/// @param id Token id
	/// @return card FounderStoreV2.Card structure
	function getCard(uint256 id) public view returns (Card memory) {
		require(exists(id), 'Card does not exist');
		return _cards[id];
	}

	/// @notice Returns the number of Cards maintained by this contract
	/// @return number 2
	function getCardCount() public pure override returns (uint256) {
		return 4;
	}

	/// @notice Returns the total amount of Cards available for purchase
	/// @param id Token id
	/// @return number
	function getCardSupply(uint256 id) public view override returns (uint256) {
		require(exists(id), 'Card does not exist');
		return _cards[id].supply;
	}

	/// @notice Returns the price of a Card
	/// @param id Token id
	/// @return price The Card price, in WEI
	function getCardPrice(uint256 id) public view override returns (uint256) {
		require(exists(id), 'Card does not exist');
		return _cards[id].price;
	}

	/// @notice Run all the required tests to purchase a Card, reverting the transaction if not allowed to purchase
	/// @param id Token id
	/// @param currentSupply The total amount of minted Tokens, from all accounts
	/// @param balance The amount of tokens the purchaser owns
	/// @param value Transaction value sent, in WEI
	function beforeMint(uint256 id, uint256 currentSupply, uint256 balance, uint256 value) public view override {
		require(exists(id), 'Card does not exist');
		Card storage card = _cards[id];
		require(currentSupply < card.supply, 'Sold out');
		require(balance == 0, 'One per wallet');
		require(value >= card.price, 'Bad value');
	}

	/// @notice Returns a token metadata, compliant with ERC1155Metadata_URI
	/// @param id Token id
	/// @return metadata Token metadata, as json string base64 encoded
	function uri(uint256 id) public view override returns (string memory) {
		require(exists(id), 'Card does not exist');
		Card storage card = _cards[id];
		bytes memory json = abi.encodePacked(
			'{'
				'"name":"', card.name, '",'
				'"description":"', card.description, '",'
				'"external_url":"https://endlesscrawler.io",'
				'"background_color":"7D381F",'
				'"attributes":['
					'{"trait_type":"Type","value":"Class"},'
					'{"trait_type":"Class","value":"', card.name, '"},'
					'{"trait_type":"Edition","value":"', card.edition, '"}'
				'],'
				'"image":"data:image/svg+xml;base64,', Base64.encode(bytes(card.imageData)), '"'
			'}'
		);
		return string(abi.encodePacked('data:application/json;base64,', Base64.encode(json)));
	}
}