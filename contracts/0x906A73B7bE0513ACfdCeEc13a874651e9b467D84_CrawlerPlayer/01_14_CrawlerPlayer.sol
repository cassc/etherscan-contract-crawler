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
/// @title Endless Crawler Player Profile and Stash Manager
/// @author Studio Avante
/// @notice Creates and maintain Player profile and stash
/// @dev Serves CrawlerToken.sol, depends on ICrawlerToken (chambers tokens)
//
pragma solidity ^0.8.16;
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ERC165Checker } from '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import { ICrawlerToken } from './ICrawlerToken.sol';
import { ICrawlerQuery } from './ICrawlerQuery.sol';
import { Crawl } from './Crawl.sol';

contract CrawlerPlayer is Ownable {

	ICrawlerQuery public _query;

	struct Profile {
		address pfpContract;
		uint256 pfpId;
		uint8 classId;
		uint8 style;
		uint16 value1;
		uint16 value2;
		uint16 value3;
		uint16 value4;
		uint16 value5;
		bool hidden;
		string name;
	}

	struct Stash {
		uint128 coins;
		uint128 worth;
		uint32[8] gems;
	}

	mapping(address => Profile) private _profiles;
	mapping(address => Stash) private _stash;

	event CreatedProfile(address indexed player);
	event UpdatedProfile(address indexed player);

	event Give(address indexed to, Crawl.Gem indexed gem, uint16 indexed coins, uint16 worth);
	event Take(address indexed from, Crawl.Gem indexed gem, uint16 indexed coins, uint16 worth);

	/// @dev modifier to test profile existence, reverts if it does not
	modifier ifExists(address player) {
		require(_profiles[player].style != 0, 'Profile not found');
		require(!_profiles[player].hidden || msg.sender == player, 'Profile unavailable');
		_;
	}

	//---------------
	// Admin
	//

	/// @notice Admin function
	function setQueryContract(address queryContract_) public onlyOwner {
		_query = ICrawlerQuery(queryContract_);
	}

	//---------------
	// Public
	//

	/// @notice Check if a player has a public profile
	/// @param player The Player wallet address
	/// @return result True if the Player has a public profile, False if not, or profile is not public
	function playerHasProfile(address player) public view returns (bool) {
		return (_profiles[player].style != 0 && (!_profiles[player].hidden || msg.sender == player));
	}

	/// @notice Returns a Player public profile
	/// @param player The Player wallet address
	/// @return result Profile struct
	/// PFP and Class id will return empty if player does not own
	/// reverts if Player has no profile or profile is not public
	function getPlayerProfile(address player) public view ifExists(player) returns (Profile memory result) {
		result = _profiles[player];
		// Check PFP ownership
		if(!_query.isOwner(result.pfpContract, result.pfpId, player)) {
			result.pfpContract = address(0);
			result.pfpId = 0;
		}
		// Check class ownership
		if(result.classId != 0 && !_query.isOwner(address(_query.getCardsContract()), result.classId, player)) {
			result.classId = 0;
		}
		// Get class from owned cards
		if(result.classId == 0) {
			uint256[] memory cards = _query.getOwnedCards(player, 1);
			for(uint8 i = 0 ; i < cards.length ; ++i) {
				if(cards[i] > 0) {
					result.classId = i + 1;
					break;
				}
			}
		}
	}

	/// @notice Returns a Player Stash
	/// @param player The Player wallet address
	/// @return result Stash struct, reverts if Player has no profile or profile is not public
	function getPlayerStash(address player) public view ifExists(player) returns (Stash memory) {
		return _stash[player];
	}

	/// @notice Creates a public profile and stash for the sender wallet, reverts if Player already have a profile
	/// @param name Display name
	/// @param pfpContract The PFP contract address, or address(0) if no PFP
	/// @param pfpId The PFP token id, ownership will be validated by getPlayerProfile()
	/// @param classId Class token id to be used, from CardsMinter, ownership will be validated by getPlayerProfile()
	/// @param style The PFP style, reverts if 0
	/// @param value1 Reserved for styling and customization
	/// @param value2 Reserved for styling and customization
	/// @param value3 Reserved for styling and customization
	/// @param value4 Reserved for styling and customization
	/// @param value5 Reserved for styling and customization
	function createProfile(
		string calldata name,
		address pfpContract,
		uint256 pfpId,
		uint8 classId,
		uint8 style,
		uint16 value1,
		uint16 value2,
		uint16 value3,
		uint16 value4,
		uint16 value5)
	public {
		// create new profile
		require(_profiles[msg.sender].style == 0, 'Your profile already exists');
		_updateProfile(name, pfpContract, pfpId, classId, style, value1, value2, value3, value4, value5, false);

		// Create stash from player's Crawler tokens
		ICrawlerToken chambers = _query.getChambersContract();
		Stash memory stash;
		for(uint256 i = 0 ; i < chambers.balanceOf(msg.sender) ; ++i) {
			uint256 tokenId = chambers.tokenOfOwnerByIndex(msg.sender, i);
			Crawl.Hoard memory hoard = chambers.tokenIdToHoard(tokenId);
			stash.gems[uint8(hoard.gemType)]++;
			stash.coins += hoard.coins;
			stash.worth += hoard.worth;
		}

		_stash[msg.sender] = stash;

		emit CreatedProfile(msg.sender);
	}

	/// @notice Updates a public profile for the sender wallet, reverts if Player does not have a profile
	/// @param name Display name
	/// @param pfpContract The PFP contract address, or address(0) if no PFP
	/// @param pfpId The PFP token id, ownership will be validated by getPlayerProfile()
	/// @param classId Class token id to be used, from CardsMinter, ownership will be validated by getPlayerProfile()
	/// @param style The PFP style, reverts if 0
	/// @param value1 Reserved for styling and customization
	/// @param value2 Reserved for styling and customization
	/// @param value3 Reserved for styling and customization
	/// @param value4 Reserved for styling and customization
	/// @param value5 Reserved for styling and customization
	function updateProfile(
		string calldata name,
		address pfpContract,
		uint256 pfpId,
		uint8 classId,
		uint8 style,
		uint16 value1,
		uint16 value2,
		uint16 value3,
		uint16 value4,
		uint16 value5)
	public ifExists(msg.sender) {
		_updateProfile(name, pfpContract, pfpId, classId, style, value1, value2, value3, value4, value5, _profiles[msg.sender].hidden);
		emit UpdatedProfile(msg.sender);
	}

	/// @dev internal profile updater
	function _updateProfile(
		string calldata name,
		address pfpContract,
		uint256 pfpId,
		uint8 classId,
		uint8 style,
		uint16 value1,
		uint16 value2,
		uint16 value3,
		uint16 value4,
		uint16 value5,
		bool hidden
	)
	internal {
		require(style != 0, 'Invalid style');
		_profiles[msg.sender] = Profile(
			pfpContract,
			pfpId,
			classId,
			style,
			value1,
			value2,
			value3,
			value4,
			value5,
			hidden,
			name
		);
	}

	/// @notice Updates the profile visibility for the sender wallet, reverts if Player does not have a profile
	/// @param hidden True to hide, profile will be kept private, False if profile is public
	function hideProfile(bool hidden) public ifExists(msg.sender) {
		_profiles[msg.sender].hidden = hidden;
	}

	//---------------
	// Crawler only
	//

	/// @notice Transfer a Chamber's Hoard to another wallet, works only if called by CrawlerToken contract
	function transferChamberHoard(address from, address to, Crawl.Hoard memory hoard) public {
		if(address(_query) != address(0) && msg.sender == address(_query.getChambersContract())) {
			// Take from
			emit Take(from, hoard.gemType, hoard.coins, hoard.worth);
			if(_profiles[from].style != 0) {
				Stash storage stash = _stash[from];
				stash.gems[uint8(hoard.gemType)] = safe_sub32(stash.gems[uint8(hoard.gemType)], 1);
				stash.coins = safe_sub128(stash.coins, hoard.coins);
				stash.worth = safe_sub128(stash.worth, hoard.worth);
			}
			// Give to
			emit Give(to, hoard.gemType, hoard.coins, hoard.worth);
			if(_profiles[to].style != 0) {
				Stash storage stash = _stash[to];
				stash.gems[uint8(hoard.gemType)] = safe_add32(stash.gems[uint8(hoard.gemType)], 1);
				stash.coins = safe_add128(stash.coins, hoard.coins);
				stash.worth = safe_add128(stash.worth, hoard.worth);
			}
		}
	}

	/// @dev overflows should not happen, but just to be safe and avoid reverting transfers...
	function safe_add128(uint128 a, uint128 b) internal pure returns (uint128) {
		unchecked {
			uint128 c = a + b;
			if (c < a) return type(uint128).max;
			return c;
		}
	}
	function safe_add32(uint32 a, uint32 b) internal pure returns (uint32) {
		unchecked {
			uint32 c = a + b;
			if (c < a) return type(uint32).max;
			return c;
		}
	}
	function safe_sub128(uint128 a, uint128 b) internal pure returns (uint128) {
		if (b > a) return 0;
		return a - b;
	}
	function safe_sub32(uint32 a, uint32 b) internal pure returns (uint32) {
		if (b > a) return 0;
		return a - b;
	}

}