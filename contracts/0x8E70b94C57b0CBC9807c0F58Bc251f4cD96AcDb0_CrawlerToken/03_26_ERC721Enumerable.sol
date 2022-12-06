// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler IERC721Enumerable implementation
/// @author OpenZeppelin, adapted by Studio Avante
/// @notice Simplified IERC721Enumerable implementation for gas saving
/// @dev As tokens cannot be burned and are minted in consecutive order, allTokens_ and _allTokensIndex could be removed
/// Based on: OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.8/contracts/token/ERC721/extensions/IERC721Enumerable.sol
//
pragma solidity ^0.8.16;
import { ERC721, IERC165 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { IERC721Enumerable } from  './IERC721Enumerable.sol';

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
	error OwnerIndexOutOfBounds();
	error GlobalIndexOutOfBounds();

	// Mapping from owner to list of owned token IDs
	mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

	// Mapping from token ID to index of the owner tokens list
	mapping(uint256 => uint256) private _ownedTokensIndex;

	/// @dev Replaces _allTokens and _allTokensIndex, since tokens are sequential and burn proof
	function _totalSupply() public view virtual returns (uint256);

	/// @dev See {IERC165-supportsInterface}.
	function supportsInterface(bytes4 interfaceId) public view virtual override (IERC165, ERC721) returns (bool) {
		return interfaceId == type(IERC721Enumerable).interfaceId || ERC721.supportsInterface(interfaceId);
	}

	/// @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
	function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
		if(index >= ERC721.balanceOf(owner)) revert OwnerIndexOutOfBounds();
		return _ownedTokens[owner][index];
	}

	/// @dev See {IERC721Enumerable-totalSupply}.
	function totalSupply() public view virtual override returns (uint256) {
		return _totalSupply();
	}

	/// @dev See {IERC721Enumerable-tokenByIndex}.
	function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
		if(index >= _totalSupply()) revert GlobalIndexOutOfBounds();
		return index + 1;
	}

	/// @dev See {ERC721-_beforeTokenTransfer}.
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId,
		uint256 batchSize
	) internal virtual override {
		ERC721._beforeTokenTransfer(from, to, tokenId, batchSize);
		if (to != from) {
			if (from != address(0)) {
				uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
				uint256 tokenIndex = _ownedTokensIndex[tokenId];
				// When the token to delete is the last token, the swap operation is unnecessary
				if (tokenIndex != lastTokenIndex) {
					uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
					_ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
					_ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
				}
				// This also deletes the contents at the last position of the array
				delete _ownedTokensIndex[tokenId];
				delete _ownedTokens[from][lastTokenIndex];
			}
			uint256 length = ERC721.balanceOf(to);
			_ownedTokens[to][length] = tokenId;
			_ownedTokensIndex[tokenId] = length;
		}
	}
}