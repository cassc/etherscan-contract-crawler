// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import 'base64-sol/base64.sol';

/*

from Ambition.wtf

  creators of the NFT mechanics:
    - "share-to-mint" (transfer 0riginal to mint a new NFT)
    - "perma-nifties" (untransferrable holograms)


Presenting … … … … Edwone

  Reincarnation of Edworm, with new magical abilities.


Introducing: the "yoink-chain" mechanic.

should Edworm ever get stuck again,
  we can call the "yoink" function
    to free the NFT & bring it home.

from there Edworm may continue the mission
  to visit every wallet on the Ethereum blockchain.


——//——

In an effort to make contracts more accessible to non-developers,
We have left more detailed comments to explain how things work.

This contract consists of these parts:
0. Declaring
	Created the variables to be used
1. Minting
	Functions for creating The Worm and Holograms
2. Transferring
	Override the default transfer functions to create
	"share-to-mint" and "permanent" holograms
3. Displaying
	Functions for getting and assembling the
	on-chain art (SVG) and metadata (JSON)
4. Managing
	Owner functions for creating and updating
	the on-chain art & metadata

*/

contract Edwone is Ownable, ERC721Enumerable {
	using Strings for uint256;

	//
	// 0 — DECLARING
	//

	// need to manually track IDs because we jump from 0 to 273
	// in order to start off where Edworm got stuck
	uint idTracker;

	// store the address of the old Edworm contract
	address public edworm;

	// on-chain SVG & JSON data to store and assemble the NFT art
	// this part is complicated, don't worry about it
	mapping(bytes16 => string) variables;
	mapping(bytes16 => bytes16[]) sequences;
	mapping(bytes16 => Template) public templates;
	bytes16[] public templateKeys; // used for finding the right template for a given ID

	struct Template {
		bytes16 key;
		bytes16 name; // title of the NFT
		bytes16 desc; // description of the NFT (text under image)
		bytes16 graphics; // how to assemble the SVG
		bytes16 metadata; // how to assemble the JSON
		bytes16 imageURI; // encoding of the SVG for URIs
		bytes16 tokenURI; // encoding of the JSON for URIs
		uint boundary; // upper limit of the range of Token IDs
	}

	// called when the contract is deployed
	constructor(address _edworm) ERC721('Edwone', 'WONE') {
		// set the address of the old Edworm contract so that Edwone
		// is aware of where it already went when it was Edworm
		edworm = _edworm;
	}

	//
	// 1 — MINTING
	//

	function resurrect() public onlyOwner {
		// 0. prevent multiple calls, just in case
		require(
			_exists(0) == false,
			'TOO LATE: The resurrection has already happened'
		);
		// 1. mint the new 0riginal
		_safeMint(msg.sender, 0);
		// 2. set ID to 273 to start where Edworm left off
		idTracker = 273;
	}

	// internal mint called by: transferOverride
	function mint(address to) internal {
		// do the mint
		_safeMint(to, idTracker);
		// increment AFTER
		idTracker += 1;
	}

	//
	// 2 — TRANSFERRING
	//

	// the primary transfer function
	// (doesn't require `from` or `tokenId`)
	function propagate(address to) public {
		transferOverride(msg.sender, to, 0);
	}

	// overriding ERC-721 transfer functions

	function transferFrom(
		address from,
		address to,
		uint tokenId
	) public override {
		transferOverride(from, to, tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint tokenId
	) public override {
		transferOverride(from, to, tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint tokenId,
		bytes memory _data
	) public override {
		transferOverride(from, to, tokenId, _data);
	}

	// overriding with the following functions

	function transferOverride(
		address from,
		address to,
		uint tokenId
	) internal {
		transferOverride(from, to, tokenId, '');
	}

	// this function is where the "share-to-mint" magic happens
	// first do the "transfer", then "mint" to the `from` address
	function transferOverride(
		address from,
		address to,
		uint tokenId,
		bytes memory _data
	) internal {
		// do the transfer
		transfer(from, to, tokenId, _data);
		// do NOT mint when transferring from the (contract) owner
		// (we don't want to leave a Hologram in the Worm's address)
		if (from != owner()) {
			mint(from);
		}
	}

	// internal transfer called by: transferOverride
	// this function is where the "perma-nifties" magic happens
	// only allow transferring of the 0riginal, not the Holograms
	function transfer(
		address from,
		address to,
		uint tokenId,
		bytes memory _data
	) internal {
		require(
			// require that the token IS the 0riginal
			tokenId == 0,
			'TOO BAD: only the 0riginal can be transferred'
		);

		require(
			// require that the owner was NOT previously an owner
			isDisciple(to) == false,
			'TOO BAD: you already had the 0riginal'
		);

		require(
			// require standard authorization because we overrode safeTransferFrom
			_isApprovedOrOwner(_msgSender(), tokenId),
			'ERC721: transfer caller is not owner nor approved'
		);

		_safeTransfer(from, to, tokenId, _data);
	}

	// check if the address has any Worm tokens
	// if they do, then they are a disciple
	// prettier-ignore
	function isDisciple(address _address) public view returns (bool) {
		return (
			// if balanceOf Edworm is 1 the address had the old Worm
			IERC721(edworm).balanceOf(_address) == 1
			||
			// if balanceOf Edwone is 1 the address had the new Worm
			balanceOf(_address) == 1
		);
	}

	// returns the 0riginal to the (contract) owner's wallet if it gets stuck
	function yoink() public onlyOwner {
		// get the address where the 0riginal is stuck
		address from = ownerOf(0);
		// do the steal
		_transfer(from, msg.sender, 0);
		// because we're nice, we'll leave a hologram
		mint(from);
	}

	//
	// 3 — DISPLAYING
	//

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

	function getTemplate(uint tokenId) internal view returns (Template memory) {
		for (uint i = 0; i < templateKeys.length; i++) {
			if (tokenId < templates[templateKeys[i]].boundary) {
				return templates[templateKeys[i]];
			}
		}
		return templates[templateKeys[0]];
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

		/*
		This loop does these things:
			1. replace '_token_id' with the actual token id
			2. recursively assemble any nested sequences (start with `$`)
			3. get the modulo of the token id
			4. encode sequence into base64
			5. accumulate the variables
		*/

		for (uint i; i < sequence.length; i++) {
			if (sequence[i] == bytes16('_token_id')) {
				// 1. replace '_token_id' with the actual token id
				acc = join(acc, tokenId.toString());
			} else if (sequence[i][0] == '$') {
				// 2. recursively assemble any nested sequences
				acc = join(acc, assembleSequence(tokenId, sequence[i]));
			} else if (sequence[i][0] == '%') {
				// 3. get the modulo of the token id
				uint modBy = toUint(sequence[i] << 8);
				uint modId = tokenId;
				if (modBy != 0) {
					modId = tokenId % modBy;
				}
				acc = join(acc, modId.toString());
			} else if (sequence[i][0] == '{') {
				// 4. encode sequence into base64

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
				// 5. accumulate the variables
				acc = join(acc, variables[sequence[i]]);
			}
		}
		return acc;
	}

	// utils

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

	function toUint(bytes16 b) public pure returns (uint) {
		uint result;
		for (uint i; i < b.length; i++) {
			// 0 in ASCII is 48 in dec is 0x30 in hex
			// 9 in ASCII is 57 in dec is 0x39 in hex
			if (b[i] >= 0x30 && b[i] <= 0x39) {
				result = result * 10 + (uint8(b[i]) - 48); // bytes and int are not compatible with the operator -.
			}
		}
		return result; // this was missing
	}

	//
	// 4 — MANAGING
	//

	function addVariables(bytes16[] memory keys, string[] memory vals)
		external
		onlyOwner
	{
		for (uint i; i < keys.length; i++) {
			variables[keys[i]] = vals[i];
		}
	}

	function addSequence(bytes16 key, bytes16[] memory vals) external onlyOwner {
		sequences[key] = vals;
	}

	function addTemplate(
		bytes16 _key,
		bytes16 _name,
		bytes16 _desc,
		bytes16 _graphics,
		bytes16 _metadata,
		bytes16 _imageURI,
		bytes16 _tokenURI,
		uint _boundary
	) external onlyOwner {
		Template memory template = Template({
			key: _key,
			name: _name,
			desc: _desc,
			graphics: _graphics,
			metadata: _metadata,
			imageURI: _imageURI,
			tokenURI: _tokenURI,
			boundary: _boundary
		});

		templates[_key] = template;

		templateKeys.push(_key);
	}

	function setTemplates(bytes16[] memory vals) external onlyOwner {
		templateKeys = vals;
	}

	// withdraw balance
	function getPaid() public payable onlyOwner {
		require(payable(_msgSender()).send(address(this).balance));
	}

	// accept ether sent
	receive() external payable {}
}