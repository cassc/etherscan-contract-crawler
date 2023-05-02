// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "Strings.sol";

contract nftBoxJsonParser {
	function generateTokenUriPart1(
		uint256 _editionNumber,
		string memory _description,
		string memory _animationUrl,
		string memory _image,
		string memory _name) public pure returns(string memory) {
		return string(
			abi.encodePacked(
				bytes('data:application/json;utf8,{"name":"'),
				_getName(_name, _editionNumber),
				bytes('","description":"'),
				_description,
				_getURLs(_image, _animationUrl)
			)
		);
	}

	function generateTokenUriPart2(
		string memory _artistName,
		uint256 _edition,
		uint256 _maxEdition,
		string memory _series,
		string memory _file,
		string memory _theme,
		string memory _boxName) public pure returns(string memory) {
		return string(
			abi.encodePacked(
				bytes('","attributes":['),
				_traitArtistName(_artistName),
				_traitEditionNumber(_edition, _maxEdition),
				_traitFileType(_file),
				_traitBoxName(_boxName),
				_traitBoxTheme(_theme),
				_traitSeries(_series),
				bytes('}')
			)
		);
	}

	function _getURLs(string memory _image, string memory _animation) internal pure returns(string memory) {
				return string(
			abi.encodePacked(
				bytes('","animation_url":'),
				bytes('"https://ipfs.io/ipfs/'), _animation,
				bytes('","image":'),
				bytes('"https://ipfs.io/ipfs/'), _image
			)
		);
	}
	
	function _getName(string memory _name, uint256 _tokenId) internal pure returns(string memory) {
		return string(abi.encodePacked(_name, " #", _uint2str(_tokenId)));
	}

	function _generateDescription(string memory _artist, string memory _artistAddress, string memory _sigHash, string memory _sigMsg, string memory _note) internal pure returns(string memory) {
		return string(abi.encodePacked(
			bytes('NFTBoxes are a curated monthly box of NFTs on the newest gold standard of NFT technology.\\n\\nArtist: '),
			_artist,
			bytes('\\n\\nSignature Address: '),
			_artistAddress,
			bytes('\\n\\nSignature Hash: '),
			_sigHash,
			_generateDescription2(_sigMsg, _note)
		));
	}

	function _generateDescription2(string memory _sigMsg, string memory _note) internal pure returns(string memory) {
		return string(abi.encodePacked(
			bytes('\\n\\nSignature Message: '),
			_sigMsg,
			bytes('\\n\\nArtist Note: '),
			_note
		));
	}

	function _traitArtistName(string memory _artistName) internal pure returns(string memory) {
		return string(abi.encodePacked(bytes('{"trait_type": "artist name","value":"'), _artistName, bytes('"},')));
	}

	function _traitEditionNumber(uint256 _editionNumber, uint256 _maxSize) internal pure returns(string memory) {
		return string(abi.encodePacked(bytes('{"trait_type": "edition number","value":"'), _uint2str(_editionNumber), bytes(' of '),_uint2str(_maxSize), bytes('"},')));
	}

	function _traitFileType(string memory _fileType) internal pure returns(string memory) {
		return string(abi.encodePacked(bytes('{"trait_type": "file type","value":"'), _fileType, bytes('"},')));
	}

	function _traitBoxName(string memory _boxName) internal pure returns(string memory) {
		return string(abi.encodePacked(bytes('{"trait_type": "box name","value":"'), _boxName, bytes('"},')));
	}

	function _traitBoxTheme(string memory _theme) internal pure returns(string memory) {
		return string(abi.encodePacked(bytes('{"trait_type": "box theme","value":"'), _theme, bytes('"},')));
	}

	function _traitSeries(string memory _theme) internal pure returns(string memory) {
		return string(abi.encodePacked(bytes('{"trait_type": "box theme","value":"'), _theme, bytes('"}]')));
	}

	function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint j = _i;
		uint len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint k = len;
		while (_i != 0) {
			k = k-1;
			uint8 temp = (48 + uint8(_i - _i / 10 * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}
}

// {
//    "image":"https://ipfs.infura.io/ipfsQmToccy4x6DR7nDH7ZzgdYB2Qtv4MPjeoBJ3Himk8FSkNC",
//    "description":"NFTBoxes are a curated monthly box of NFTs on the newest gold standard of NFT technology.\\n\\nArtist: Giant Swan\\n\\nSignature Address: 0xd656f8d9Cb8fA5Aeb8b1576161d0488EE2c9C926\\n\\nSignature Hash: 0x62df3f5bcfbf173315b5608f5ee6a90698b83ff92f78e2c95840f2039d418fce0c8020e1575251c68eb35bd6df926d90be0e8a4afedb9b8022f3d5eb768e81011c\\n\\nSignature Message: Giant Swan \"Rot\" 5/21 \\n0x70732c08Fb6dbb06A64BF619c816c22aED12267a\\n\\nArtist Note: This Rot of ours is weightless, Its casts no shadow in this reflection. It lingers and holds these hands further up, It lingers and feeds the roots of this body. This rot of mine is weighted, It casts its tendrils at my reflection.",
//    "animation_url":"https://ipfs.infura.io/ipfsQmanC93UYkRQ5HuTqxuqqUiUJkb4VuCz2RGjuwNXYdYFGm",
//    "name":"Rot #1",
//    "attributes":[
//       {
//          "trait_type":"artist name",
//          "value":"Giant Swan"
//       },
//       {
//          "trait_type":"edition number",
//          "value":"1 of 153"
//       },
//       {
//          "trait_type":"file type",
//          "value":".MP4"
//       },
//       {
//          "trait_type":"box name",
//          "value":"May 2021"
//       },
//       {
//          "trait_type":"theme",
//          "value":"Reflective"
//       },
//       {
//          "trait_type":"series",
//          "value":"Main"
//       }
//    ]
// }