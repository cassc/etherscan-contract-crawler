// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract Reveal is ERC721 {
	uint256 private id = 0;
	mapping(uint256 => uint256) private _seed;
	mapping(uint256 => uint256) private _parentId;
	mapping(uint256 => uint256) private _generation;
	mapping(uint256 => uint256) private _childNum;

	constructor() ERC721("Reveal", "RVL") {
		_mint(_msgSender(), id);
	}

	//-------------------------------------------

	function _transfer(
		address from,
		address to,
		uint256 tokenId
	) internal override(ERC721) {
		uint256 childNum = _childNum[tokenId];

		if (from != to && from != address(0) && childNum < 3) {
			uint256 childTokenId = ++id;
			_parentId[childTokenId] = tokenId;
			_childNum[tokenId] = childNum + 1;
			_generation[childTokenId] = _generation[tokenId] + 1;
			uint256 parentSeed = _seed[tokenId];

			if (childNum == 0 && parentSeed != 0) {
				//The eldest son inherits a seed from his ancestors
				_seed[childTokenId] = parentSeed;
			} else {
				_seed[childTokenId] = _rand(tokenId, childNum);
			}

			_mint(ownerOf(tokenId), childTokenId);
			tokenId = childTokenId;
		}

		super._transfer(from, to, tokenId);
	}

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "nonexistent token");

		uint256 childNum = _childNum[tokenId];
		string memory svg;
		string memory t;
		{
			uint256 s = 30;
			uint256 p = 50;
			string memory k;

			if (tokenId == 0) {
				t = "\u004e\u006f\u0020\u0063\u006f\u006c\u006f\u0072\u0020\u0062\u0075\u0067";
			} else if (tokenId == 10) {
				k = '<path d="M95.5,58.4c-0.9,3.9-1.8,7.8-4,11.2c-1.7,2.8-3.8,5.2-6,7.6c-4,4.5-8.4,8.9-10.3,14.8c0,0,0,0,0,0c2-6.4,6.9-11,11.2-15.9c2-2.2,3.9-4.6,5.4-7.1C93.8,65.8,94.7,62.1,95.5,58.4C95.5,58.4,95.5,58.4,95.5,58.4L95.5,58.4z" stroke="#000" stroke-width="0.05"/><circle class="d" cx="50" cy="50" r="30"/>';
				t = "\u0044\u0075\u0073\u0074\u0020\u006f\u006e\u0020\u0070\u0069\u0063\u0074\u0075\u0072\u0065\u0020\u0062\u0075\u0067";
			} else if (tokenId == 20) {
				p = 999999;
				t = "\u004e\u006f\u0020\u0070\u0069\u0063\u0074\u0075\u0072\u0065\u0020\u0062\u0075\u0067";
			} else if (tokenId == 40) {
				p = 80;
				t = "\u0050\u0069\u0063\u0074\u0075\u0072\u0065\u0020\u0073\u0068\u0069\u0066\u0074\u0065\u0064\u0020\u0062\u0075\u0067";
			} else if (tokenId == 80) {
				k = '<circle class="d" cx="50" cy="50" r="30" style="animation:f 0.1s linear infinite;"/><style>@keyframes f{49%{opacity:1;}50%{opacity:0;}}</style>';
				t = "\u0050\u0069\u0063\u0074\u0075\u0072\u0065\u0020\u0066\u006c\u0061\u0073\u0068\u0069\u006e\u0067\u0020\u0062\u0075\u0067";
			} else if (tokenId == 160) {
				k = '<defs><g id="p"><polygon points="25,0 0,25 0,100 100,100 100,0"/><polygon class="t" points="25,0 25,25 0,25"/></g></defs><use href="#p" class="d" transform="rotate(270)"/>';
				t = "\u004e\u006f\u0074\u0020\u0070\u0065\u0065\u006c\u0069\u006e\u0067\u0020\u0062\u0075\u0067";
			} else if (tokenId == 320) {
				k = '<circle class="a" cx="25" cy="35" r="30"/><circle class="d" cx="50" cy="50" r="30"/>';
				t = "\u0050\u0069\u0063\u0074\u0075\u0072\u0065\u0020\u006f\u0076\u0065\u0072\u006c\u0061\u0070\u0070\u0065\u0064\u0020\u0062\u0075\u0067";
			} else if (tokenId == 640) {
				s = 52;
				t = "\u0050\u0069\u0063\u0074\u0075\u0072\u0065\u0020\u0073\u0069\u007a\u0065\u0020\u0062\u0075\u0067";
			} else {
				if (_getChance(_rand(tokenId, childNum))) {
					t = "\u0055\u006e\u0075\u0073\u0075\u0061\u006c\u0020\u0070\u0069\u0063\u0074\u0075\u0072\u0065";
				} else {
					t = "\u0042\u006f\u0072\u0065\u0064\u0020\u0070\u0069\u0063\u0074\u0075\u0072\u0065";
				}
			}

			svg = Base64.encode(
				abi.encodePacked(
					'<?xml version="1.0" encoding="utf-8"?><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 100 100"><style>svg{background-color:hsl(0,0%,97%);}use{transform-origin:50%;}.t{fill:rgb(0,0,0,0.1);}',
					(childNum == 0) ? string(abi.encodePacked(".a{fill:", this.getColorStr(tokenId, 0), "}")) : "",
					(childNum <= 1) ? string(abi.encodePacked(".b{fill:", this.getColorStr(tokenId, 1), "}")) : "",
					(childNum == 1 || childNum == 2)
						? string(abi.encodePacked(".c{fill:", this.getColorStr(tokenId, 2), "}"))
						: "",
					(childNum == 3) ? string(abi.encodePacked(".d{fill:", this.getColorStr(tokenId, 3), "}")) : "",
					"</style>",
					(childNum < 3)
						? '<defs><g id="p"><polygon points="25,0 0,25 0,100 100,100 100,0"/><polygon class="t" points="25,0 25,25 0,25"/></g></defs>'
						: (bytes(k).length != 0)
						? k
						: string(
							abi.encodePacked(
								'<circle class="d" cx="',
								Strings.toString(p),
								'" cy="50" r="',
								Strings.toString(s),
								'"/>'
							)
						),
					(childNum == 1 || childNum == 2) ? '<use href="#p" class="c" transform="rotate(180)"/>' : "",
					(childNum <= 1) ? '<use href="#p" class="b" transform="rotate(90)"/>' : "",
					(childNum == 0) ? '<use href="#p" class="a"/>' : "",
					"</svg>"
				)
			);
		}

		bytes memory json = abi.encodePacked(
			'{"name":"',
			string(
				abi.encodePacked(
					(childNum == 3) ? "NO" : Strings.toString(3 - childNum),
					(childNum == 2) ? " MORE REVEAL #" : " MORE REVEALS #"
				)
			),
			Strings.toString(tokenId),
			'","description":"Reveal is the most exciting event on NFT.","created_by":"bouze","image":"data:image/svg+xml;base64,',
			svg,
			'","attributes":[{"trait_type": "Reveal count","value":"',
			string(abi.encodePacked(Strings.toString(childNum), ' / 3"},')),
			(childNum < 3)
				? ""
				: string(
					abi.encodePacked(
						'{"trait_type":"Type","value":"',
						t,
						'"},{"trait_type":"Saturation","value":"',
						_getSaturation(_rand(tokenId, 3), tokenId, 3),
						'"},'
					)
				),
			'{"trait_type":"Generation","value":"GEN ',
			Strings.toString(_generation[tokenId]),
			'"},{"trait_type":"Parent","value":"',
			(tokenId == 0) ? "None" : string(abi.encodePacked("#", Strings.toString(_parentId[tokenId]))),
			'"}]}'
		);

		return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
	}

	//-------------------------------------------

	function getColorStr(uint256 tokenId, uint256 index) public view returns (string memory str) {
		if (tokenId != 0 && index == 0) {
			//The first color inherits a seed of the ancestor
			str = _getColorStr(_seed[tokenId], tokenId, index);
		} else {
			str = _getColorStr(_rand(tokenId, index), tokenId, index);
		}
	}

	function getGeneration(uint256 tokenId) public view returns (uint256) {
		return _generation[tokenId];
	}

	function getParentTokenId(uint256 tokenId) public view returns (uint256) {
		return _parentId[tokenId];
	}

	function getChildNum(uint256 tokenId) public view returns (uint256) {
		return _childNum[tokenId];
	}

	function totalSupply() public view returns (uint256) {
		return id + 1;
	}

	//-------------------------------------------

	function _getColorStr(
		uint256 seed,
		uint256 tokenId,
		uint256 index
	) private pure returns (string memory) {
		bool chance = _getChance(seed);
		uint256 hue = _rand(seed, 0) % 360;
		uint256 minLum = (index != 3) ? 85 : (chance) ? 50 : 70;
		uint256 maxLum = (index != 3) ? 95 : (chance) ? 90 : 90;
		uint256 lum = (_rand(seed, 2) % (maxLum - minLum)) + minLum;
		if (tokenId == 0 && index == 3) {
			hue = 0;
			lum = 0;
		}
		return
			string(
				abi.encodePacked(
					"hsl(",
					Strings.toString(hue),
					",",
					_getSaturation(seed, tokenId, index),
					"%,",
					Strings.toString(lum),
					"%);"
				)
			);
	}

	function _getSaturation(
		uint256 seed,
		uint256 tokenId,
		uint256 index
	) private pure returns (string memory) {
		bool chance = (index != 3) ? true : _getChance(seed);
		uint256 minSat = (chance) ? 80 : 0;
		uint256 maxSat = (chance) ? 85 : 30;
		uint256 sat = (_rand(seed, 1) % (maxSat - minSat)) + minSat;
		if (tokenId == 0 && index == 3) sat = 0;
		return Strings.toString(sat);
	}

	function _getChance(uint256 seed) private pure returns (bool) {
		return (_rand(seed, 0) % 100) < 15;
	}

	function _rand(uint256 seed0, uint256 seed1) private pure returns (uint256) {
		return
			uint256(
				//Root seed of random numbers
				keccak256(abi.encodePacked(seed0, seed1, "4e070562db0e5c1defea16b7230de01f640b7e4729b49fce"))
			);
	}
}