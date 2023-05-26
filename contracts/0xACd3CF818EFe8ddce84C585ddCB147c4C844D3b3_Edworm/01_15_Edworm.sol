// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import 'base64-sol/base64.sol';

// In memory of my sweet cat Edwin. I told him he could live forever and now he can.

contract Edworm is Ownable, ERC721Enumerable {
	using Counters for Counters.Counter;
	using Strings for uint256;
	Counters.Counter private _tokenIdTracker;

	// Truth:
	string public constant R = 'Healing the world with comedy. Making a literal difference metaphorically.';

	// can the worm be released
	bool public hasItBegun = false;

	// the true cost is priceless
	uint public priceToRelease = 6.0 ether;

	// art & meta stuff
	mapping(bytes8 => string) meta;
	mapping(bytes8 => string) svg;
	bytes8[] svg0rig;
	bytes8[] svgHolo;

	//
	constructor() ERC721('Edworm', 'WORM') {
		//
		svg[
			'head'
		] = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 346 346' stroke-linecap='round' stroke-linejoin='round'>";
		svg[
			'font'
		] = "<style type='text/css'>@font-face { font-family: 'COMPUTER Robot'; font-weight: normal; src: url(data:application/font-woff2;charset=utf-8;base64,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) format('woff2'); }</style>";
		svg[
			'defs'
		] = "<defs><linearGradient id='_overlay' x1='0' x2='0' y1='0' y2='1'><stop offset='57%' stop-color='#080702'/><stop offset='71%' stop-color='#080702' stop-opacity='.75'/><stop offset='93%' stop-color='#080702' stop-opacity='0'/></linearGradient><linearGradient id='_text' x1='0' x2='0' y1='0' y2='1'><stop offset='30%' stop-color='#adff2f'/><stop offset='45%' stop-color='#adff2f'/><stop offset='77%' stop-color='#fff'/></linearGradient><clipPath id='_box'><path d='M0 0h346v346H0z'/></clipPath></defs>";
		svg[
			'back'
		] = "<g id='back' clip-path='url(#_box)'><path id='bg' fill='#080702' d='M0 0h346v346H0z'/><path id='lines' fill='none' stroke='#adff2f' stroke-width='6' d='M138 346V64M54.75 346L138 64M-22 335L138 64M-102 335L138 64M221.25 346L138 64M304.5 346L138 64M378 335L138 64M458 335L138 64M538 335L138 64M0 318h346M0 278h346M0 248.75l346 .13M346 226.74l-346-.16M346 209.3H0'/><path id='overlay' fill='url(#_overlay)' d='M0 0h346v346H0z'/></g>";
		svg[
			'text_a'
		] = "<g id='text' font-family='COMPUTER Robot' fill='url(#_text)'><text x='21.27' y='88.31' font-size='112'>T</text><text x='62.22' y='86.88' font-size='80'>HE</text><text x='22.05' y='138.22' font-size='80'>WOR</text><text x='149.27' y='139.68' font-size='112'>M</text><text x='24.22' y='162.16' fill='#ec008c' font-size='32'>#";
		svg[
			'text_b'
		] = "</text></g>";
		svg[
			'worm'
		] = "<g id='worm'><path fill='none' stroke='#ec008c' stroke-width='48' d='M65 247c6.25 30.96 49.37 33.85 59.7 4l10.06-29.09c11.46-33.11 58.26-33.2 69.83-.12l10.58 30.24c11.94 34.1 61.15 27.41 64.83-8.53.51-5 2.5-4.5-.86-151.5'/><path fill='none' stroke='#231f20' stroke-width='3.25' d='M276.92 104.27s-.32 3.57 2.92 3.57c3.25 0 2.92-3.9 2.92-3.9'/><path fill='#231f20' d='M271.59 97.16c1.33 0 2.42-1.1 2.43-2.43 0-1.34-1.1-2.43-2.43-2.44a2.46 2.46 0 00-2.44 2.43 2.48 2.48 0 002.44 2.44zm15.87-.25h.01a2.43 2.43 0 10-2.44-2.44 2.48 2.48 0 002.44 2.44z'/></g>";
		svg[
			'holo'
		] = "<g id='holo'><path fill='#080702' stroke='#adff2f' stroke-linecap='butt' stroke-width='3.3' d='M41.47 251.75c11.09 54.92 87.59 60.05 105.9 7.1l10.07-29.09c4.02-11.62 20.44-11.65 24.5-.04l10.58 30.23c20.48 58.54 105.04 47.69 111.35-14 .53-5.1 2.69-4.6-.73-154.5a24.01 24.01 0 00-48 1.1c3.3 144.1 1.49 143.6.99 148.5 0 0 0 0 0 0-1.05 10.2-14.92 12.72-18.3 3.05l-10.58-30.24c-19.09-54.54-96.28-54.4-115.17.2L102 243.17c-2.33 6.74-12.07 6.09-13.48-.9a24.01 24.01 0 00-47.06 9.49z'/><path fill='none' stroke='#adff2f' stroke-width='3.25' d='M276.92 104.27s-.32 3.57 2.92 3.57c3.25 0 2.92-3.9 2.92-3.9'/><path fill='#adff2f' d='M271.59 97.16c1.33 0 2.42-1.1 2.43-2.43 0-1.34-1.1-2.43-2.43-2.44a2.46 2.46 0 00-2.44 2.43 2.48 2.48 0 002.44 2.44zm15.87-.25h.01a2.43 2.43 0 10-2.44-2.44 2.48 2.48 0 002.44 2.44z'/></g>";
		svg[
			'tail'
		] = "</svg>";

		svg0rig = [
			//
			bytes8('head'),
			bytes8('font'),
			bytes8('defs'),
			bytes8('back'),
			bytes8('text_a'),
			bytes8('token_id'),
			bytes8('text_b'),
			bytes8('worm'),
			bytes8('tail')
		];

		svgHolo = [
			//
			bytes8('head'),
			bytes8('font'),
			bytes8('defs'),
			bytes8('back'),
			bytes8('text_a'),
			bytes8('token_id'),
			bytes8('text_b'),
			bytes8('holo'),
			bytes8('tail')
		];

		meta[
			'desc0rig'
		] = "The Worm is building a cult as he travels through the Ethereum blockchain. Help him on his journey by passing him along.";
		meta[
			'descHolo'
		] = "I've left this beautiful Hologram of myself as a memento of our special time together. Joining my cult was the best decision you ever made. You can never leave. Best Wishes. - The Worm.";
		meta['ext_url'] = "https://theworm.wtf/#";
	}

	//
	// managing
	//

	// withdraw balance
	function getPaid() public payable onlyOwner {
		require(payable(_msgSender()).send(address(this).balance));
	}

	function setPrice(uint256 price) external onlyOwner {
		priceToRelease = price;
	}

	function setBegun(bool yes) external onlyOwner {
		hasItBegun = yes;
	}

	function setArt(bytes8 key, string memory value) external onlyOwner {
		svg[key] = value;
	}

	function setLayers(bool isWorm, bytes8[] memory values) external onlyOwner {
		if (isWorm) {
			svg0rig = values;
		} else {
			svgHolo = values;
		}
	}

	function setMeta(bytes8 key, string memory value) external onlyOwner {
		meta[key] = value;
	}
	
	//
	// main
	//

	// don't release the worm
	function release() public payable {
		uint newTokenId = _tokenIdTracker.current();

		require(
			// ensure minting is only possible once it has begun
			hasItBegun == true,
			'TOO EARLY: it has not begun yet.'
		);

		require(
			// ensure only the 0riginal is ever minted
			newTokenId == 0,
			'TOO LATE: the 0riginal can only be minted once.'
		);

		require(
			// ensure the price was paid in full
			msg.value >= priceToRelease,
			'TOO POOR: send moar ether.'
		);

		mint(msg.sender);
	}

	//
	// transferring
	//

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public override {
		transferOverride(from, to, tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public override {
		transferOverride(from, to, tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) public override {
		transferOverride(from, to, tokenId, _data);
	}

	function transferOverride(
		address from,
		address to,
		uint256 tokenId
	) internal {
		transferOverride(from, to, tokenId, '');
	}

	function transferOverride(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal {
		//
		transfer(from, to, tokenId, _data);
		//
		mint(from);
	}

	// THIS is the main transfer function
	function propagate(address to) public {
		// enforce requirements
		transferOverride(msg.sender, to, 0);
	}

	// internal transfer
	function transfer(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal {
		require(
			// require that the address isnt zero (not necessary) but
			// it's not about the gas, it's about sending a message
			to != address(0),
			'TOO BAD: cant burn me.'
		);

		require(
			// require that the token is the 0riginal
			tokenId == 0,
			'TOO BAD: only the 0riginal can be transferred.'
		);

		require(
			// require that the owner wasnt previously an owner
			balanceOf(to) == 0,
			'TOO BAD: you already had the 0riginal.'
		);

		require(
			// require because we overrode safeTransferFrom
			_isApprovedOrOwner(_msgSender(), tokenId),
			'ERC721: transfer caller is not owner nor approved'
		);

		_safeTransfer(from, to, tokenId, _data);
	}

	// internal mint a copy
	function mint(address to) internal {
		// do the mint
		uint newTokenId = _tokenIdTracker.current();
		_safeMint(to, newTokenId);

		// increment AFTER because starts at 0
		_tokenIdTracker.increment();
	}

	//
	// displaying
	//

	function getArt(uint256 _tokenId) public view returns (string memory) {
		string memory acc;
		bytes8[] memory layers;

		if (_tokenId == 0) {
			layers = svg0rig;
		} else {
			layers = svgHolo;
		}

		for (uint i = 0; i < layers.length; i++) {
			if (layers[i] == bytes8('token_id')) {
				acc = join(acc, _tokenId.toString());
			} else {
				acc = join(acc, svg[layers[i]]);
			}
		}

		return acc;
	}

	function join(string memory _a, string memory _b)
		internal
		pure
		returns (string memory result)
	{
		result = string(abi.encodePacked(bytes(_a), bytes(_b)));
	}

	function getMeta(uint256 _tokenId) public view returns (string memory) {
		string memory name;
		string memory desc;

		string memory image = Base64.encode(bytes(getArt(_tokenId)));

		if (_tokenId == 0) {
			name = 'The Worm';
			desc = meta['desc0rig'];
		} else {
			name = join('The Worm Hologram #', _tokenId.toString());
			desc = meta['descHolo'];
		}

		return string(abi.encodePacked(
			'data:application/json;base64,',
			Base64.encode(
				bytes(abi.encodePacked(
					'{',
						'"name": "', name, '",',
						'"description": "', desc, '",',
						'"image": "data:image/svg+xml;base64,', image, '",',
						'"external_url": "', meta['ext_url'], _tokenId.toString(), '"',
					'}'
				))
			)
		));
	}

	function tokenURI(uint256 _tokenId)
		public
		view
		override
		returns (string memory)
	{
		return getMeta(_tokenId);
	}

	// accept ether sent
	receive() external payable {}
}