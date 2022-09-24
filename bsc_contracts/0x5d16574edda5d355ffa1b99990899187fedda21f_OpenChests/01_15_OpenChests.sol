// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

// Chainlink
import { VRFCoordinatorV2Interface } from 'chainlink/interfaces/VRFCoordinatorV2Interface.sol';
import { VRFConsumerBaseV2 } from 'chainlink/VRFConsumerBaseV2.sol';

// Solmate
import { Auth, Authority } from 'solmate/auth/Auth.sol';
import { ERC721 } from 'solmate/tokens/ERC721.sol';
import { LibString } from 'solmate/utils/LibString.sol';

// Custom
import { Probabilities, ProbabilitiesLib } from './lib/ProbabilitiesLib.sol';
import { Characters, Rarities } from './Characters.sol';
import { MintableBEP20 } from './lib/MintableBEP20.sol';
import { IOpenChests } from './interfaces/IOpenChests.sol';

// Libraries
using ProbabilitiesLib for Probabilities;

enum Settings {
	EvolvingStone,
	Powder,
	Olymp,
	CharacterRarity,
	Character
}

struct ChestConfigs {
	uint8 chest;
	Settings name;
	Probabilities probabilities;
}

struct Chest {
	uint8 id;
}

struct MintConfig {
	Characters characters;
	MintableBEP20 olymp;
	MintableBEP20 powder;
	MintableBEP20 stones;
}

struct ChainlinkConfig {
	VRFCoordinatorV2Interface coordinator;
	uint32 callbackGasLimit;
	uint16 requestConfirmations;
	bytes32 keyHash;
	uint64 subscriptionId;
}

contract OpenChests is IOpenChests, ERC721, VRFConsumerBaseV2, Auth {
	event ChestClaimed(uint256 indexed id, uint256 random);

	// Configs
	ChainlinkConfig chainlinkConfig;
	MintConfig public mintConfig;

	// Open chests
	/// @dev start at 1 in case the requestId is not found
	uint256 chestsIndex = 1;
	mapping(uint256 => uint256) chests;
	mapping(uint256 => uint256) requestIds;

	// Chest config
	mapping(uint256 => mapping(Settings => Probabilities)) public probabilities;

	// ERC721 config
	string private baseUri;

	constructor(
		string memory _name,
		string memory _symbol,
		address _owner,
		Authority _authority,
		ChainlinkConfig memory _chainlinkConfig,
		MintConfig memory _mintConfig,
		ChestConfigs[] memory _configs,
		string memory _baseUri
	)
		ERC721(_name, _symbol)
		Auth(_owner, _authority)
		VRFConsumerBaseV2(address(_chainlinkConfig.coordinator))
	{
		chainlinkConfig = _chainlinkConfig;
		mintConfig = _mintConfig;
		baseUri = _baseUri;
		setConfigs(_configs);
	}

	function setConfigs(ChestConfigs[] memory _configs) private {
		uint256 length = _configs.length;
		for (uint256 i = 0; i < length; ) {
			ChestConfigs memory config = _configs[i];
			probabilities[config.chest][config.name] = config.probabilities;
			unchecked {
				++i;
			}
		}
	}

	function mint(address to, uint256 chestId) external requiresAuth {
		// Mint an open chest
		uint256 id = chestsIndex++;
		_mint(to, id);

		// Request random number
		uint256 requestId = chainlinkConfig.coordinator.requestRandomWords(
			chainlinkConfig.keyHash,
			chainlinkConfig.subscriptionId,
			chainlinkConfig.requestConfirmations,
			chainlinkConfig.callbackGasLimit,
			1
		);

		// Set state
		requestIds[requestId] = id;
		chests[id] = chestId;
	}

	function open(uint256 id, uint256 random) private {
		// Emit chest claimed
		emit ChestClaimed(id, random);

		// Metadata
		address owner = ownerOf(id);
		uint256 chestId = chests[id];

		// Burn the chest
		_burn(id);

		// Get large random number
		uint16 result;

		// Get evolving stones to mint
		(result, random) = getProbability(chestId, Settings.EvolvingStone, random);
		if (result > 0) {
			mintConfig.stones.mint(owner, result);
		}

		// Get powder to mint
		(result, random) = getProbability(chestId, Settings.Powder, random);
		if (result > 0) {
			mintConfig.powder.mint(owner, result);
		}

		// Get OLYMP to mint
		(result, random) = getProbability(chestId, Settings.Olymp, random);
		if (result > 0) {
			mintConfig.olymp.mint(owner, result);
		}

		// Get rarity of the character to mint
		(result, random) = getProbability(
			chestId,
			Settings.CharacterRarity,
			random
		);

		// If the rarity is invalid, it means no character should be minted
		if (result > uint16(type(Rarities).max)) {
			return;
		}

		// Keep rarity to set on the character
		Rarities rarity = Rarities(result);

		// Mint character
		(result, random) = getProbability(chestId, Settings.Character, random);
		mintConfig.characters.mint(owner, result, rarity);
	}

	function getProbability(
		uint256 id,
		Settings name,
		uint256 random
	) internal view returns (uint16, uint256) {
		Probabilities storage prob = probabilities[id][name];
		return (prob.getRandomUint(random), random / prob.sum);
	}

	// ERC721
	function tokenURI(uint256 id)
		public
		view
		virtual
		override
		returns (string memory)
	{
		return string.concat(baseUri, LibString.toString(chests[id]), '.json');
	}

	// Chainlink
	function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
		internal
		override
	{
		uint256 id = requestIds[requestId];
		require(id > 0, 'CHEST_NOT_FOUND');
		open(id, randomWords[0]);
	}
}