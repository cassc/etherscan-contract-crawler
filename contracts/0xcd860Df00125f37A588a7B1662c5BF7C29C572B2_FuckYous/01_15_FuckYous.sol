// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import 'base64-sol/base64.sol';

// An fuck you, to you and you and you.

contract FuckYous is Ownable, ERC721Enumerable {
	using Counters for Counters.Counter;
	using Strings for uint256;
	Counters.Counter private _tokenIdTracker;

	// Truth:
	string public constant R = 'Fuck you and you and you. I hate your friends and they hate too.';

	// sales shit
	bool public fuckStart; // sale started (default false)
	uint public fuckPrice = 0.02 ether; // price per NFT
	uint public fuckTotal = 9669; // max number in total
	// 10K - 319 CryptoJunks.wtf owners - 12 Hexis.wtf owners 
	uint public fuckLimit = 50; // max mints per transaction

	//
	constructor() ERC721('FuckYous', "FU") {
		//
	}

	//
	// managing
	//

	// withdraw balance
	function getPaid() public payable onlyOwner {
		require(payable(_msgSender()).send(address(this).balance));
	}

	function setStart(bool start) external onlyOwner { fuckStart = start; }
	function setPrice(uint price) external onlyOwner { fuckPrice = price; }
	function setTotal(uint total) external onlyOwner { fuckTotal = total; }
	function setLimit(uint limit) external onlyOwner { fuckLimit = limit; }

	//
	// main
	//

	function getFucked(uint _timesFucked) public payable {
		require(
			// ensure minting is only possible once sale has started
			fuckStart == true,
			'TOO EARLY: the fucking has not started.'
		);

		require(
			// ensure mintting is less than the limit constrained by gas
			_timesFucked <= fuckLimit,
			'TOO MUCH: you cannot fuck this much.'
		);

		require(
			// ensure the price was paid in full
			msg.value >= _timesFucked * fuckPrice,
			'TOO POOR: send moar ether.'
		);

		require(
			// ensure there are enough fucks left
			_tokenIdTracker.current() + _timesFucked < fuckTotal,
			'TOO MANY: not enough fucks to give.'
		);

    mint(msg.sender, _timesFucked);
	}

	// devMints - for CryptoJunks.wtf & Hexis.wtf
	function giveAFuck(address _to, uint _howManyFucks) external onlyOwner {
		mint(_to, _howManyFucks);
	}
	
	function giveManyFucks(address[] calldata _to) external onlyOwner {
		for (uint i = 0; i < _to.length; i++) {
			mint(_to[i]);
		}
	}

	// internal - mint loop
	function mint(address _to, uint _fucks) internal {
    for (uint i = 0; i < _fucks; i++) {            
      mint(_to);
    }
	}
	// internal - mint once
	function mint(address _to) internal {
		uint newTokenId = _tokenIdTracker.current();
		_safeMint(_to, newTokenId);
		// increment AFTER because starts at 0
		_tokenIdTracker.increment();
	}

	//
	// displaying
	//

	// future stuff for onchain stuff

	address public graphicsAddress;
	address public metadataAddress;
	FuckYousGraphics graphics;
	FuckYousMetadata metadata;

	function setGraphics(address _address) external onlyOwner {
		// set the adress
		graphicsAddress = _address;
		// set the contract 
		graphics = FuckYousGraphics(_address);
	}

	function getGraphics(uint tokenId)
		public
		view
		returns (string memory)
	{
		return graphics.getGraphics(tokenId);
	}

	function setMetadata(address _address) external onlyOwner {
		// set the adress
		metadataAddress = _address;
		// set the contract
		metadata = FuckYousMetadata(_address);
	}

	function getMetadata(uint tokenId)
		public
		view
		returns (string memory)
	{
		return metadata.getMetadata(tokenId);
	}

	function tokenURI(uint256 _tokenId)
		public
		view
		override
		returns (string memory)
	{
		return getMetadata(_tokenId);
	}

	// accept ether sent
	receive() external payable {}
}

contract FuckYousGraphics {

	string public name = "FuckYousGraphics";

  function getGraphics(uint)
		public
		pure
		returns (string memory)
	{
		return getGraphics();
	}
	
	function getGraphics()
		public
		pure
		returns (string memory)
	{
		return "ipfs://QmXbgNxtqB3r8YNjzxN5kmL3fykoAMhGVpcL7n7gvtdb2v";
	}
}

contract FuckYousMetadata {
	using Strings for uint256;

	string public name = "FuckYousMetadata";

	function getMetadata(uint256 _tokenId)
		public
		pure
		returns (string memory)
	{
		string memory desc = "Unite around the one thing we can all agree on - FUCK YOU! Get one or give one at https://fuckyous.wtf";
		string memory image = "ipfs://QmXbgNxtqB3r8YNjzxN5kmL3fykoAMhGVpcL7n7gvtdb2v";

		return string(abi.encodePacked(
			'data:application/json;base64,',
			Base64.encode(
				bytes(abi.encodePacked(
					'{',
						'"name": "Fuck Yous #', _tokenId.toString(), '",',
						'"description": "', desc, '",',
						'"image": "', image, '",',
						'"external_url": "https://fuckyous.wtf"',
					'}'
				))
			)
		));
	}
}