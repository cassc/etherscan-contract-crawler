// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import 'base64-sol/base64.sol';

/*

from Ambition.wtf
	"learning how to create magical experiences"


Presenting … … … … The Worm Vigils
	A contract for creating the light needed to resurrect The Worm.


Every great magic trick consists of three parts or acts:

1 — "THE PLEDGE"

	The magician shows you something ordinary: a worm.
	You can inspects it to see if it is indeed normal.
		But of course… it probably isn't. 

2 — "THE TURN"

	The magician takes the worm and makes it disappear. 
	Now you're looking for the secret…
		But you won't find it, unless you read the code.
	
	But you wouldn't clap yet.
		Because making something disappear isn't enough;
			you have to bring it back. 
		
	That's why every magic trick has a third act,
		the hardest part,
			the part we call…

3 — "THE PRESTIGE"


——//——

In an effort to make contracts more accessible to non-developers,
We have left more detailed comments to explain how things work.

This contract consists of these parts:
0. Declaring
	Created the variables to be used
1. Minting
	Functions for creating the NFTs
2. Displaying
	Functions for getting and assembling the
	on-chain art (SVG) and metadata (JSON)
3. Managing
	Owner functions for creating and updating
	the on-chain art & metadata

*/

contract WormVigils is Ownable, ERC721Enumerable {
	using Counters for Counters.Counter;
	using Strings for uint256;
	Counters.Counter private _tokenIdTracker;

	//
	// 0 — DECLARING
	//

	// store the addresses of the Worm contracts
	// (they don't needs to be public which lowers gas)
	address edworm;
	address edwone;

	// current vigil number
	uint64 public vigil;

	// track the number of candles lit per vigil
	mapping(uint64 => uint) public vigilCandles;
	// track the candle specific data (discipleId, level, vigil)
	mapping(uint => uint) candleDna;

	// on-chain SVG & JSON data to store and assemble the NFT art
	// this part is complicated, don't worry about it
	mapping(bytes16 => string) variables;
	mapping(bytes16 => bytes16[]) sequences;
	// uint128 templateId is a mashup of:
	//   uint56 vigil
	//   uint8 isDisciple
	//   uint64 level
	mapping(uint128 => Template) templates;

	struct Template {
		bytes16 name; // title of the NFT
		bytes16 desc; // description of the NFT (text under image)
		bytes16 graphics; // how to assemble the SVG
		bytes16 metadata; // how to assemble the JSON
		bytes16 imageURI; // encoding of the SVG for URIs
		bytes16 tokenURI; // encoding of the JSON for URIs
	}

	// uint256 lumenLevel is a mashup of:
	//   uint64 lumen
	//   uint192 price
	uint[] lumenLevels;

	constructor(address _edworm, address _edwone) ERC721('WormVigils', 'LUMEN') {
		// store the addresses of the Worm contracts so that
		// we can know if a disciple minted a token
		edworm = _edworm;
		edwone = _edwone;

		// when minting a candle, if a donation is included
		// these are the Ether increments that will
		// increase the level of light for an NFT
		lumenLevels = [
			encodeLumenLevel(12, 1 ether),
			encodeLumenLevel(6, 0.1 ether),
			encodeLumenLevel(3, 0.01 ether),
			encodeLumenLevel(1, 0 ether)
		];
	}

	//
	// 1 — MINTING
	//

	function mintCandle() public payable {
		mintCandleWithPrestige(0);
	}

	function mintCandleWithPrestige(uint64 prestige) public payable {
		// 1. get the disicple ID from Worm contracts

		uint discipleId;

		if (IERC721(edworm).balanceOf(msg.sender) > 0) {
			discipleId = IERC721Enumerable(edworm).tokenOfOwnerByIndex(msg.sender, 0);
		} else if (IERC721(edwone).balanceOf(msg.sender) > 0) {
			discipleId = IERC721Enumerable(edwone).tokenOfOwnerByIndex(msg.sender, 0);
		}

		// 2. get level & lumen by comparing msg.value to the lumenLevels

		uint64 level;
		uint64 lumen;

		for (uint i; i < lumenLevels.length; i++) {
			(uint64 _lumen, uint192 _price) = decodeLumenLevel(lumenLevels[i]);

			if (msg.value >= _price) {
				level = uint64(lumenLevels.length - 1 - i);
				lumen = _lumen;
				break;
			}
			// If level is not found, lumen & level will be 0
		}

		// ಠ_ಠ
		if (prestige > lumenLevels.length) {
			level = prestige;
		}

		// 3. put it all together into one uint256

		uint256 dna = uint256(discipleId);
		dna |= uint(level) << 128;
		dna |= uint(vigil) << 192;

		// 4. store candle data
		uint newTokenId = _tokenIdTracker.current();

		candleDna[newTokenId] = dna;

		// 5. increment the candles in this vigil
		vigilCandles[vigil] += 1;

		// 6. do the mint
		_safeMint(msg.sender, newTokenId);

		// increment AFTER because starts at 0
		_tokenIdTracker.increment();
	}

	//
	// 2 — DISPLAYING
	//

	function getTemplate(uint _tokenId) internal view returns (Template memory) {
		// 1. get candle dna

		(uint128 _discipleId, uint64 _level, uint64 _vigil) = getCandleData(
			_tokenId
		);
		uint8 _isDisciple;
		if (_discipleId > 0) {
			_isDisciple = 1;
		}

		// 2. extract level & vigil

		uint128 templateId = uint128(_vigil);
		templateId |= uint128(_isDisciple) << 56;
		templateId |= uint128(_level) << 64;

		// 3. get template from the mapping

		Template memory maybeTemplate = templates[templateId];

		// it might not exist, so confirm it does first
		if (maybeTemplate.name != bytes16(0)) {
			return maybeTemplate;
		}

		// if not, this is the fallback template
		templateId = uint128(_vigil);
		templateId |= uint128(_isDisciple) << 56;

		maybeTemplate = templates[templateId];

		return maybeTemplate;
	}

	// for a tokenId, return the SVG raw text
	function getGraphics(uint tokenId) public view returns (string memory) {
		Template memory template = getTemplate(tokenId);

		return assembleSequence(tokenId, template.graphics);
	}

	// for a tokenId, return the JSON raw text
	function getMetadata(uint tokenId) public view returns (string memory) {
		Template memory template = getTemplate(tokenId);

		return assembleSequence(tokenId, template.metadata);
	}

	// for a tokenId, return the SVG base64 encoded for data URI
	function imageURI(uint tokenId) public view returns (string memory) {
		Template memory template = getTemplate(tokenId);

		return assembleSequence(tokenId, template.imageURI);
	}

	// for a tokenId, return the JSON base64 encoded for data URI
	function tokenURI(uint tokenId) public view override returns (string memory) {
		Template memory template = getTemplate(tokenId);

		return assembleSequence(tokenId, template.tokenURI);
	}

	function assembleSequence(uint tokenId, bytes16 _sequence)
		internal
		view
		returns (string memory)
	{
		bytes16[] memory sequence = sequences[_sequence];

		return assembleSequence(tokenId, sequence);
	}

	function assembleSequence(uint tokenId, bytes16[] memory sequence)
		internal
		view
		returns (string memory)
	{
		string memory acc;

		(uint128 _discipleId, uint64 _level, uint64 _vigil) = getCandleData(
			tokenId
		);

		/*
		This loop does these things:
			1. replace '_token_id' with the actual token id
			2. replace '_disciple_id' with the actual disciple id
			3. replace '_level' with the actual level
			4. replace '_vigil' with the actual vigil id
			5. recursively assemble any nested sequences (start with `$`)
			6. encode sequence into base64
			7. accumulate the variables
		*/

		for (uint i; i < sequence.length; i++) {
			if (sequence[i] == bytes16('_token_id')) {
				// 1. replace '_token_id' with the actual token id
				acc = join(acc, tokenId.toString());
			} else if (sequence[i] == bytes16('_disciple_id')) {
				// 2. replace '_disciple_id' with the actual disciple id
				acc = join(acc, uint(_discipleId).toString());
			} else if (sequence[i] == bytes16('_level')) {
				// 3. replace '_level' with the actual level
				acc = join(acc, uint(_level).toString());
			} else if (sequence[i] == bytes16('_vigil')) {
				// 4. replace '_vigil' with the actual vigil id
				acc = join(acc, uint(_vigil).toString());
			} else if (sequence[i][0] == '$') {
				// 5. recursively assemble any nested sequences
				acc = join(acc, assembleSequence(tokenId, sequence[i]));
			} else if (sequence[i][0] == '{') {
				// 6. encode sequence into base64

				string memory ecc;
				uint numEncode;
				// step 1: figure out how many variables are to be encoded
				for (uint j = i + 1; j < sequence.length; j++) {
					if (sequence[j][0] == '}' && sequence[j][1] == sequence[i][1]) {
						break;
					} else {
						numEncode++;
					}
				}
				// step 2: create a new build sequence
				bytes16[] memory encodeSequence = new bytes16[](numEncode);
				// step 3: populate the new build sequence
				uint k;
				for (uint j = i + 1; j < sequence.length; j++) {
					if (k < numEncode) {
						encodeSequence[k] = sequence[j];
						k++;
						i++; // CRITICAL: this increments the MAIN loop to prevent duplicates
					} else {
						break;
					}
				}
				// step 4: encode & assemble the new build sequence
				ecc = assembleSequence(tokenId, encodeSequence);
				// step 5: join the encoded string to the accumulated string
				acc = join(acc, encodeBase64(ecc));
			} else {
				// 7. accumulate the variables
				acc = join(acc, variables[sequence[i]]);
			}
		}
		return acc;
	}

	// utils

	function getCandleData(uint _tokenId)
		public
		view
		returns (
			uint128 _discipleId,
			uint64 _level,
			uint64 _vigil
		)
	{
		uint dna = candleDna[_tokenId];

		_discipleId = uint128(dna);
		_level = uint64(dna >> 128);
		_vigil = uint64(dna >> 192);
	}

	function encodeLumenLevel(uint64 _lumen, uint192 _price)
		internal
		pure
		returns (uint256 _lumenLevel)
	{
		_lumenLevel = uint(_lumen);
		_lumenLevel |= uint(_price) << 64;
	}

	function decodeLumenLevel(uint256 _lumenLevel)
		internal
		pure
		returns (uint64 _lumen, uint192 _price)
	{
		_lumen = uint64(_lumenLevel);
		_price = uint192(_lumenLevel >> 64);
	}

	function join(string memory _a, string memory _b)
		internal
		pure
		returns (string memory)
	{
		return string(abi.encodePacked(bytes(_a), bytes(_b)));
	}

	function encodeBase64(string memory _str)
		internal
		pure
		returns (string memory)
	{
		return string(abi.encodePacked(Base64.encode(bytes(_str))));
	}

	//
	// 3 — MANAGING
	//

	function setVigil(uint64 _vigil) external onlyOwner {
		vigil = _vigil;
	}

	// MUST be ordered in descending lumens/price
	function setLevels(uint64[] memory _lumens, uint128[] memory _prices)
		external
		onlyOwner
	{
		uint[] memory _lumenLevels = new uint[](_lumens.length);

		for (uint i = 0; i < _lumens.length; i++) {
			_lumenLevels[i] = encodeLumenLevel(_lumens[i], _prices[i]);
		}

		lumenLevels = _lumenLevels;
	}

	function addVariables(bytes16[] memory keys, string[] memory vals)
		external
		onlyOwner
	{
		for (uint i; i < keys.length; i++) {
			variables[keys[i]] = vals[i];
		}
	}

	function addSequences(bytes16[] memory keys, bytes16[][] memory vals)
		external
		onlyOwner
	{
		for (uint i; i < keys.length; i++) {
			sequences[keys[i]] = vals[i];
		}
	}

	function addTemplate(
		uint56 _vigil,
		uint8 _isDisciple,
		uint64 _level,
		bytes16 _name,
		bytes16 _desc,
		bytes16 _graphics,
		bytes16 _metadata,
		bytes16 _imageURI,
		bytes16 _tokenURI
	) external onlyOwner {
		Template memory template = Template({
			name: _name,
			desc: _desc,
			graphics: _graphics,
			metadata: _metadata,
			imageURI: _imageURI,
			tokenURI: _tokenURI
		});

		uint128 templateId = uint128(_vigil);
		templateId |= uint128(_isDisciple) << 56;
		templateId |= uint128(_level) << 64;

		templates[templateId] = template;
	}

	// withdraw balance
	function getPaid() public payable onlyOwner {
		require(payable(_msgSender()).send(address(this).balance));
	}

	// accept ether sent
	receive() external payable {}
}