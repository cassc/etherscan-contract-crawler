// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Burnable.sol";

abstract contract ERC1155Enumerable is ERC1155Burnable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    mapping(address => mapping(uint256 => uint256)) private _ownedTokensIndex;

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    mapping(address => uint256) private _itemBalances;

    function getTokenIdList(address owner) public view virtual returns (uint256[] memory) {
        uint256 b = itemBalanceOf(owner);
        uint256[] memory idList = new uint256[](b);
        for (uint256 i = 0; i < b; i++) {
            idList[i] = _ownedTokens[owner][i];
        }
        return idList;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < itemBalanceOf(owner), "ERC1155Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalItemSupply() public view virtual returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(index < totalItemSupply(), "ERC1155Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            if (id == 0 || amount == 0) {
                continue;
            }

            if (from == address(0)) {
                if (_allTokensIndex[id] == 0 && (_allTokens.length == 0 || _allTokens[0] != id)) {
                    _addTokenToAllTokensEnumeration(id);
                }
            } else if (from != to) {
                if (balanceOf(from, id) == amount) {
                    _removeTokenFromOwnerEnumeration(from, id);
                    _itemBalances[from] -= 1;
                }
            }
            if (to == address(0)) {
            } else if (to != from) {
                if (balanceOf(to, id) == 0) {
                    _addTokenToOwnerEnumeration(to, id);
                    _itemBalances[to] += 1;
                }
            }
        }
    }

    function itemBalanceOf(address account) public view returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _itemBalances[account];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = itemBalanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[to][tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = itemBalanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[from][tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[from][lastTokenId] = tokenIndex;
        }

        delete _ownedTokensIndex[from][tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
}