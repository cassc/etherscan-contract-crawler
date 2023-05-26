// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import 'base64-sol/base64.sol';

contract WormXBrink is Ownable, ERC721 {
	using Counters for Counters.Counter;
	using Strings for uint256;
	Counters.Counter private _tokenIdTracker;

	string graphics;
	address[] public signedBy;

	//
	constructor() ERC721('WormXBrink', 'WxB') {
		//
		graphics = "<svg xmlns='http://www.w3.org/2000/svg' stroke-linecap='round' stroke-linejoin='round' viewBox='0 0 720 720'><style>@keyframes blink{0%,97%,to{opacity:1}97.01%,99.99%{opacity:0}}</style><defs><filter id='glow' width='1.4' height='1.4' x='-.2' y='-.2'><feOffset in='SourceGraphic' result='offOut'/><feGaussianBlur in='offOut' result='blurOut' stdDeviation='25'/><feBlend in='SourceGraphic' in2='blurOut'/></filter></defs><path d='M0 0h720v720H0z'/><g fill='none'><g><path stroke='#f27fa5' stroke-width='33' d='M399.8 235.2c47.7-65.8 133.5-83.3 181.6-14.5 40.6 58.1 13.2 124.7-15.7 156.7-54 59.8-120.2 104.5-187.8 207.9-44-97.9-184-133.8-234.3-212.6C96.8 299.3 121 200.4 194.2 181c57-15.2 91.8 4.8 139.7 57.8 22.6 19.6 16.2-33 6.9-56.1' filter='url(#glow)'/><g stroke='#000' stroke-width='3.5'><path d='M396.2 223.4a25.2 25.2 0 0012.8 16M429.2 189.2a36.4 36.4 0 0012 20M472.5 169.2a32.4 32.4 0 007.6 21.6M527.8 169.4a20.4 20.4 0 00-3 21.4M581.4 204c-8 0-14 6.5-17.7 13.5M610.5 264a18.4 18.4 0 00-21.3 2.7M606.3 324.5c-5.3-5.4-11-7.2-19.5-5.6M576.5 381.2A24.7 24.7 0 00558 368M543.7 417.3c-1.7-5-10.6-12.5-18.9-14M510.5 449.7a28 28 0 00-16-15.7M478.9 479.5c-2-6.6-7.8-12-14.4-15M448.2 510.4A24.1 24.1 0 00434 497M417.8 543.7a38.5 38.5 0 00-14.3-14.4M338.5 545a39.7 39.7 0 0015.1-15.2M305 513.8c7.3-5.5 11-13.2 13.2-16.5M263.4 485.7c4.8-3.8 10.2-9 13.1-16.6M218.4 455.7a28.7 28.7 0 0015.9-16M181.6 428.3a36 36 0 0015.6-14.6M144.9 393.5c9 0 14.4-8 18.1-13.8M117.8 339.8c7 4 15 4.3 22.4-.5M108.5 280.6c2.2 4.3 13.9 11.4 22.5 9.3M122.8 231.4c1.9 6.4 8 13 16.7 14.5M148.8 196.4a30.9 30.9 0 0012.2 16.9M193.5 169.4c-.7 6.2-.6 16 6.7 22.8M246.1 167.3c-4.4 5.3-7.4 12.6-2.4 21.1M288.7 182.4c-4.7 3.5-9.5 9.3-8.6 20.6M322.2 211.7a22.6 22.6 0 00-12.2 17.7'/></g><g stroke='#000' stroke-width='3.5'><g><path d='M335.8 186.3l2.5-.9M348.4 183l2.5-.8'/></g><g style='animation:blink 7.3s linear infinite normal'><path d='M348.4 183.3c.5 2.4 3 3 2.5-1.2-.5-3.9-3.4-3.1-2.5 1.2zM335.9 186.5c.5 2.4 2.9 3 2.4-1.2-.4-3.9-3.4-3.1-2.4 1.2z'/></g><path d='M342.6 194.9c2.3 12.2 13.1 8.8 8.7-1.7'/></g></g><g stroke-width='3.5'><path stroke='#f1c025' d='M567.6 0v180.6s1-.5 1.4-.1c11.2 10.8 15.3 2 11.5.1-7-2.3-13.4-1.4-9.5-.4 22.9-.6 8.9-22.7-2.3-1.6a47 47 0 01-24.7 27.6'/><path stroke='#68c39e' d='M367.4 0v217.5a9 9 0 002.4 5.2c4.3 5.3 9.8 1 5.1-3-4.8-3-10.4-2.4-7-2 25.1.2 5.3-21-.6 1-10.6 7.7-25.2 9.3-36.3-7.2'/><path stroke='#38c2d6' d='M170.5 0v170.9s-.9 2.7-1.3 3c-6.5 7-11.5 3.6-11.7 1.7-.7-3.5 6-5.3 13.4-4.4-20.9 2.2-11.8-19.2-.3-.1-8.1 16.4 13.7 35.5 22.3 29.4'/></g></g></svg>";
	}

	//
	// managing
	//

	// withdraw balance
	function getPaid() public payable onlyOwner {
		require(payable(_msgSender()).send(address(this).balance));
	}

	function airDrop(address[] calldata _to) external onlyOwner {
		for (uint i = 0; i < _to.length; i++) {
			// increment BEFORE because starts at 1
			_tokenIdTracker.increment();
			//
			_safeMint(_to[i], _tokenIdTracker.current());
		}
	}

	function addSignature() public {
		signedBy.push(msg.sender);
	}
	function getSignatures() public view returns (address[] memory) {
		return signedBy;
	}
	
	//
	// displaying
	//

	function getGraphics() public view returns (string memory) {
		return graphics;
	}

	function getMetadata(uint _tokenId) public view returns (string memory) {
		string memory image = Base64.encode(bytes(getGraphics()));

		return string(abi.encodePacked(
			'{',
				'"name": "', 'The Worm x Bryan Brinkman #', _tokenId.toString(), '",',
				'"description": "', 'A limited edition Bryan Brinkman artwork. Gifted to each of the first 100 wallets that received and shared The Worm on its journey across the blockchain. 100% on-chain. ', _tokenId.toString(), '/100', '",',
				'"image": "data:image/svg+xml;base64,', image, '",',
				'"external_url": "https://theworm.wtf"',
			'}'
		));
	}

	function tokenURI(uint _tokenId) public view override returns (string memory) {
		return string(
			abi.encodePacked(
				'data:application/json;base64,',
				Base64.encode(
					bytes(
						getMetadata(_tokenId)
					)
				)
			)
		);
	}

	// accept ether sent
	receive() external payable {}
}

/*

# Agreement

This Collaboration  Agreement (the “Agreement”) states the terms
and conditions that govern the contractual agreement between
Bryan Brinkman having his principal wallet address at
0x1e8E749b2B578E181Ca01962e9448006772b24a2 (the “Artist”),
and Ambition ÖU (the “Dev Team”) who agrees to be bound by
this Agreement.

The Artist and the Dev Team  (individually, each a “Party”
and collectively, the “Parties”) covenant and agree as follows:

## Services

The Artist agrees that he has provided a unique digital artwork
(the “Art”) that is represented by 100 individual non-fungible
tokens (“NFT”). Parties agree that Artist has provided the Art
and Dev Team has provided Smart Contract development (the
“Development”) at no charge. The Dev Team agrees to pay all costs
associated with deploying the Smart Contract. The Dev Team agrees
to manage information and assets associated with the Art on 
third-party marketplaces (ex. OpenSea), for example collection
images and descriptive text.

## Compensation

The Dev Team shall compensate to the Artist a royalty of 5.0%
on all secondary sales to the extent that royalties can be
collected from third-party marketplaces that facilitate
secondary sales, (ex. OpenSea). The Dev Team shall retain
a 5.0% royalty on all secondary sales. The Dev Team agrees
to make calendar-year quarterly payments of royalties to the
Artist until automated royalties become available.

## Intellectual Property Rights in Work Product

The Parties acknowledge and agree that the Art and NFT are
provided under CC0 1.0 Universal (CC0 1.0) (Public Domain Dedication).

*/