// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import 'base64-sol/base64.sol';


/*

Presenting … … … … The Mark I Mech Suit, piloted by Edwone

  A contract wrapper that imbues Edwone with new scientific abilities.


Introducing: the “Public Yoink” mechanic.

Should Edwone ever get stuck again,
  Anyone can call the "yoink" function
    to free the NFT and have it visit a wallet of their choosing.

from there Edwone may continue the mission
  to visit every wallet on the Ethereum blockchain.


——//——

With special thanks to Worm Disciples:
- outerpockets.eth for the mech suit idea, prototype, and code review
- markegli.eth for code review
- meuleman.eth for evangelism

*/

contract Mechworm is Ownable, ERC721, ERC721Holder {
	using Strings for uint256;

	constructor(address _edwone) ERC721('Mechworm', 'MECH') {
		edwone = _edwone;
	}

	//
	// VARIABLES
	//

	// address of the Edwone contract
	address public edwone;
	// timestamp of the last time the mechworm was transferred
	uint256 public lastVisitTimestamp;
	// time before the mechworm can be yoinked by anyone
	uint256 public maxVisitDuration = 7 days;

	// on-chain SVG & JSON data to store & assemble art
	mapping(bytes16 => string) variables;
	mapping(bytes16 => bytes16[]) sequences;
	Template public template;

	struct Template {
		bytes16 name; // title of the NFT
		bytes16 desc; // description of the NFT (text under image)
		bytes16 graphics; // how to assemble the SVG
		bytes16 metadata; // how to assemble the JSON
		bytes16 imageURI; // encoding of the SVG for URIs
		bytes16 tokenURI; // encoding of the JSON for URIs
	}

	//
	// TRANSFERS
	//

	function transferFrom(
		address from,
		address to,
		uint tokenId
	) public override {
		require(
			_isApprovedOrOwner(_msgSender(), tokenId),
			'ERC721: transfer caller is not owner nor approved'
		);

		lastVisitTimestamp = block.timestamp;
		_flashEject(from);
		_transfer(from, to, tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint tokenId
	) public override {
		safeTransferFrom(from, to, tokenId, '');
	}

	function safeTransferFrom(
		address from,
		address to,
		uint tokenId,
		bytes memory _data
	) public override {
		require(
			_isApprovedOrOwner(_msgSender(), tokenId),
			'ERC721: transfer caller is not owner nor approved'
		);

		lastVisitTimestamp = block.timestamp;
		_flashEject(from);
		_safeTransfer(from, to, tokenId, _data);
	}

	// wrapping in a try catch to prevent reverts
	function _flashEject(address target) internal {
		try this.flashEject(target) {} catch {}
	}

	// transfers Edwone to the address AND immediately yoinks
	// (this is what patches the yoink vulnerability)
	function flashEject(address target) external {
		require(
			_msgSender() == address(this),
			'MECH: eject must be called from within the contract'
		);

		// DON'T mint holograms for the owner OR disciples
		if (target != owner() && !IEdwone(edwone).isDisciple(target)) {
			IEdwone(edwone).propagate(target);
			IEdwone(edwone).yoink();
		}
	}

	// now anyone can yoink the mechworm!
	function yoink() public {
		// if not the owner, do these checks
		if (_msgSender() != owner()) {
			// check time passed since last visit
			require(
				block.timestamp - lastVisitTimestamp >= maxVisitDuration,
				'MECH: not enough time has passed since last visit'
			);

			// ensure sender is not a disciple
			require(
				!IEdwone(edwone).isDisciple(_msgSender()),
				'MECH: yoink caller cannot be a disciple'
			);

			// ensure mechworm is not held by owner
			require(
				ownerOf(0) != owner(), 
				'MECH: cannot yoink from owner'
			);
		}

		lastVisitTimestamp = block.timestamp;
		// we still want to leave a hologram for yoinks
		_flashEject(ownerOf(0));
		_transfer(ownerOf(0), _msgSender(), 0);
	}

	// now anyone can yoink the mechworm TO someone else!
	function yoinkTo(address target) public {
		if (_msgSender() != owner()) {
			// check time passed since last visit
			require(
				block.timestamp - lastVisitTimestamp >= maxVisitDuration,
				'MECH: not enough time has passed since last visit'
			);

			// ensure target is not a disciple
			require(
				!IEdwone(edwone).isDisciple(target),
				'MECH: yoinkTo target cannot be a disciple'
			);

			// ensure mechworm is not held by owner
			require(
				ownerOf(0) != owner(), 
				'MECH: cannot yoink from owner'
			);
		}

		lastVisitTimestamp = block.timestamp;
		// we still want to leave a hologram for yoinks
		_flashEject(ownerOf(0));
		_transfer(ownerOf(0), target, 0);
	}

	function propagate(address to) public {
		safeTransferFrom(_msgSender(), to, 0);
	}

	//
	// VISUAL
	//

	// for a tokenId, return the SVG raw text
	function getGraphics(uint tokenId) public view returns (string memory) {
		return assembleSequence(tokenId, template.graphics);
	}

	// for a tokenId, return the JSON raw text
	function getMetadata(uint tokenId) public view returns (string memory) {
		return assembleSequence(tokenId, template.metadata);
	}

	// for a tokenId, return the SVG base64 encoded for data URI
	function imageURI(uint tokenId) public view returns (string memory) {
		return assembleSequence(tokenId, template.imageURI);
	}

	// for a tokenId, return the JSON base64 encoded for data URI
	function tokenURI(uint tokenId) public view override returns (string memory) {
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

		/*
		This loop does these things:
			1. replace '_token_id' with the actual token id
			2. recursively assemble any nested sequences (start with `$`)
			3. encode sequence into base64
			4. accumulate the variables
		*/

		for (uint i; i < sequence.length; i++) {
			// 1: replace '_token_id' with the actual token id
			if (sequence[i] == bytes16('_token_id')) {
				acc = join(acc, tokenId.toString());
			}
			// 2: recursively assemble any nested sequences
			else if (sequence[i][0] == '$') {
				acc = join(acc, assembleSequence(tokenId, sequence[i]));
			}
			// 3: encode sequence into base64
			else if (sequence[i][0] == '{') {
				string memory ecc;
				uint numEncode;
				// 3.1: figure out how many variables are to be encoded
				for (uint j = i + 1; j < sequence.length; j++) {
					if (sequence[j][0] == '}' && sequence[j][1] == sequence[i][1]) {
						break;
					} else {
						numEncode++;
					}
				}
				// 3.2: create a new build sequence
				bytes16[] memory encodeSequence = new bytes16[](numEncode);
				// 3.3: populate the new build sequence
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
				// 3.4: encode & assemble the new build sequence
				ecc = assembleSequence(tokenId, encodeSequence);
				// 3.5: join the encoded string to the accumulated string
				acc = join(acc, encodeBase64(ecc));
			}
			// 4: accumulate the variables
			else {
				acc = join(acc, variables[sequence[i]]);
			}
		}
		return acc;
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
	// OWNER
	//

	// put Edwone into the mech suit
	function insertWormIntoMech() external onlyOwner {
		// 1. ensure the Mechworm contract is the holder of the Edwone token
		require(
			address(this) == IERC721(edwone).ownerOf(0),
			'MECH: must be ownerOf Edwone token'
		);

		// 2. ensure that the Mechworm contract is the owner of the Edwone contract
		require(
			address(this) == Ownable(edwone).owner(),
			'MECH: must be owner of Edwone contract'
		);

		// 3. if mech suit has been minted, transfer to owner
		if (_exists(0)) {
			_transfer(ownerOf(0), owner(), 0);
		}
		// otherwise, mint it to the owner
		else {
			_mint(owner(), 0);
		}
	}

	// remove Edwone from the mech suit
	function ejectWormFromMech() external onlyOwner {
		// 1. transfer the Edwone token to the owner
		IERC721(edwone).transferFrom(address(this), owner(), 0);
		
		// 2. transfer ownership of the Edwone contract to the owner
		Ownable(edwone).transferOwnership(owner());
		
		// 3. return the mech suit to the owner
		_transfer(ownerOf(0), owner(), 0);
	}

	// set how long the mech suit can visit before it can be yoinked
	function setMaxVisitDuration(uint256 _maxVisitDuration) external onlyOwner {
		maxVisitDuration = _maxVisitDuration;
	}

	// on-chain stuff

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
		bytes16 _name,
		bytes16 _desc,
		bytes16 _graphics,
		bytes16 _metadata,
		bytes16 _imageURI,
		bytes16 _tokenURI
	) external onlyOwner {
		template = Template({
			name: _name,
			desc: _desc,
			graphics: _graphics,
			metadata: _metadata,
			imageURI: _imageURI,
			tokenURI: _tokenURI
		});
	}

	// withdraw balance
	function getPaid() external payable onlyOwner {
		require(payable(_msgSender()).send(address(this).balance));
	}

	// accept ether sent
	receive() external payable {}
}

interface IEdwone {
	function isDisciple(address _address) external view returns (bool);

	function yoink() external;

	function propagate(address to) external;
}