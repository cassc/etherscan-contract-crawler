// SPDX-License-Identifier: MIT
//
// EIP-721: Non-Fungible Token Standard
// https://eips.ethereum.org/EIPS/eip-721
//
// Derived from OpenZeppelin Contracts (token/ERC721/extensions/ERC721Enumerable.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/...
// ...contracts/token/ERC721/extensions/ERC721Enumerable.sol
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//      OpenERC165
//           |
//      OpenERC721
//           |
//  OpenERC721Enumerable —— IERC721Enumerable
//
pragma solidity 0.8.9;

import "OpenNFTs/contracts/OpenERC/OpenERC721.sol";
import "OpenNFTs/contracts/interfaces/IERC721Enumerable.sol";

abstract contract OpenERC721Enumerable is IERC721Enumerable, OpenERC721 {
    // Array of all tokens ID
    uint256[] private _allTokens;

    // Mapping from owner to list of token IDs owned
    // mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to owned index
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Mapping from token ID to all index
    mapping(uint256 => uint256) private _allTokensIndex;

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        override (IERC721Enumerable)
        returns (uint256)
    {
        require(index < OpenERC721.balanceOf(owner), "Invalid index!");
        return _ownedTokens[owner][index];
    }

    function totalSupply() external view override (IERC721Enumerable) returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index)
        external
        view
        override (IERC721Enumerable)
        returns (uint256)
    {
        require(index < _allTokens.length, "Invalid index!");
        return _allTokens[index];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (OpenERC721)
        returns (bool)
    {
        return interfaceId == 0x780e9d63 || super.supportsInterface(interfaceId);
    }

    function _mint(address to, string memory tokenURI, uint256 tokenID)
        internal
        virtual
        override (OpenERC721)
    {
        _addOwnedToken(to, tokenID);

        _allTokensIndex[tokenID] = _allTokens.length;
        _allTokens.push(tokenID);

        super._mint(to, tokenURI, tokenID);
    }

    function _burn(uint256 tokenID) internal virtual override (OpenERC721) {
        address from = ownerOf(tokenID);

        _removeOwnedToken(from, tokenID);

        uint256 allBurnIndex = _allTokensIndex[tokenID];
        uint256 allLastIndex = _allTokens.length - 1;
        uint256 allLastTokenId = _allTokens[allLastIndex];

        _allTokensIndex[allLastTokenId] = allBurnIndex;
        delete _allTokensIndex[tokenID];

        _allTokens[allBurnIndex] = allLastTokenId;
        _allTokens.pop();

        super._burn(tokenID);
    }

    function _transferFromBefore(address from, address to, uint256 tokenID)
        internal
        virtual
        override (OpenERC721)
    {
        _removeOwnedToken(from, tokenID);
        _addOwnedToken(to, tokenID);

        super._transferFromBefore(from, to, tokenID);
    }

    function _addOwnedToken(address owner, uint256 tokenID) private {
        _ownedTokensIndex[tokenID] = _ownedTokens[owner].length;
        _ownedTokens[owner].push(tokenID);
    }

    function _removeOwnedToken(address owner, uint256 tokenID) private {
        uint256 burnIndex = _ownedTokensIndex[tokenID];
        uint256 lastIndex = OpenERC721.balanceOf(owner) - 1;

        if (burnIndex != lastIndex) {
            uint256 lastTokenId = _ownedTokens[owner][lastIndex];
            _ownedTokens[owner][burnIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = burnIndex;
        }

        delete _ownedTokensIndex[tokenID];
        _ownedTokens[owner].pop();
    }
}