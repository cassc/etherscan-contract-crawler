// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

contract BoxJsonParser {

	function generateTokenUriPart1(uint256 _tokenId, string memory _series, string memory _name, string memory _theme) public pure returns(string memory) {
		return string(
			abi.encodePacked(
				bytes('data:application/json;utf8,{"name":"'),
				_getName(_name, _tokenId),
				bytes('","description":"'),
				"NFTBoxes are a curated monthly box of NFTs on the newest gold standard of NFT technology."
			)
		);
	}

	function generateTokenUriPart2(uint256 _boxId, uint256 _tokenId, uint256 _max, string memory _series, string memory _hash, string memory _theme) public pure returns(string memory) {
		return string(
			abi.encodePacked(
				bytes('","attributes":['),
				_traitBoxId(_boxId),
				_traitBoxSeries(_series),
				_traitBoxTheme(_theme),
				_traitBoxEdition(_tokenId, _max),
				bytes(',"image":"'),
				_getImageCache(_hash),bytes('"}')
			)
		);
	}

	function _traitBoxId(uint256 _boxId) internal pure returns(string memory) {
		return string(abi.encodePacked(bytes('{"trait_type": "box id","value":"'), _uint2str(_boxId), bytes('"},')));
	}

	function _traitBoxSeries(string memory _series) internal pure returns(string memory) {
		return string(abi.encodePacked(bytes('{"trait_type": "box series","value":"'), _series, bytes('"},')));
	}

	function _traitBoxTheme(string memory _theme) internal pure returns(string memory) {
		return string(abi.encodePacked(bytes('{"trait_type": "box theme","value":"'), _theme, bytes('"},')));
	}

	function _traitBoxEdition(uint256 _tokenId, uint256 _maxEdition) internal pure returns(string memory) {
		return string(abi.encodePacked(bytes('{"trait_type": "box edition","value":"'), _uint2str(_tokenId), bytes(' of '), _uint2str(_maxEdition), bytes('"}]')));
	}

	function _getName(string memory _name, uint256 _tokenId) internal pure returns(string memory) {
		return string(abi.encodePacked(_name, " #", _uint2str(_tokenId)));
	}

	function _getImageCache(string memory _hash) internal pure returns(string memory) {
		return string(abi.encodePacked("https://ipfs.io/ipfs/", _hash));
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