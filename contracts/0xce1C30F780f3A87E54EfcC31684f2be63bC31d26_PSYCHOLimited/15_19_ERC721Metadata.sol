// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "../ERC721.sol";
import "../../interface/metadata/IERC721Metadata.sol";
import "../../library/Encode.sol";

contract ERC721Metadata is ERC721, IERC721Metadata {
	string private _name;
	string private _symbol;

	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
	}

	function name()
		public
		view
		virtual
		override(IERC721Metadata)
		returns (string memory)
	{
		return _name;
	}

	function symbol()
		public
		view
		virtual
		override(IERC721Metadata)
		returns (string memory)
	{
		return _symbol;
	}

	function tokenURI(
		uint256 _tokenId
	) public view virtual override(IERC721Metadata) returns (string memory) {
		bytes memory data;
		if (_customTokenURI(_tokenId).length == 0) {
			if (_extendedTokenURI(_tokenId).length == 0) {
				data = abi.encodePacked("{", _baseTokenURI(_tokenId), "}");
			} else {
				data = abi.encodePacked(
					"{",
					_baseTokenURI(_tokenId),
					",",
					_extendedTokenURI(_tokenId),
					"}"
				);
			}
		} else {
			data = abi.encodePacked(
				"{",
				_baseTokenURI(_tokenId),
				",",
				_customTokenURI(_tokenId),
				"}"
			);
		}
		if (ownerOf(_tokenId) == address(0)) {
			return "INVALID_ID";
		} else {
			return
				string(
					abi.encodePacked(
						"data:application/json;base64,",
						Encode.toBase64(data)
					)
				);
		}
	}

	function _baseTokenURI(
		uint256 _tokenId
	) internal view virtual returns (bytes memory) {
		return
			abi.encodePacked(
				'"name":"',
				name(),
				" #",
				Encode.toString(_tokenId),
				'"'
			);
	}

	function _extendedTokenURI(
		uint256 _tokenId
	) internal view virtual returns (bytes memory) {}

	function _customTokenURI(
		uint256 _tokenId
	) internal view virtual returns (bytes memory) {}
}