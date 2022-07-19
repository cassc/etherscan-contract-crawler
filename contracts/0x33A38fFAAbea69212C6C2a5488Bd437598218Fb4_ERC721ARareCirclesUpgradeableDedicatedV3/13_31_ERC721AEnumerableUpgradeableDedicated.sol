// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "./ERC721AUpgradeableDedicated.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721AEnumerableUpgradeableDedicated is
ERC721AUpgradeableDedicated,
IERC721EnumerableUpgradeable
{
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165Upgradeable, ERC721AUpgradeableDedicated)
    returns (bool)
    {
        return
        interfaceId == _INTERFACE_ID_ERC165 ||
        interfaceId == _INTERFACE_ID_ERC721_ENUMERABLE;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
    {
        require(
            index < ERC721AUpgradeableDedicated.balanceOf(owner),
            "ERC721EnumerableDedicated: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    function tokensOfOwner(address owner)
    public
    view
    virtual
    returns (uint256[] memory)
    {
        uint256 tokenBalance = ERC721AUpgradeableDedicated.balanceOf(owner);
        require(
            tokenBalance > 0,
            "ERC721EnumerableDedicated: owner has no tokens"
        );

        uint256[] memory tokens = new uint256[](tokenBalance);
        for (uint256 i = 0; i < tokenBalance; i++) {
            tokens[i] = _ownedTokens[owner][i];
        }
        return tokens;
    }

    /**
     * @dev See {IERC721EnumerableUpgradeable-totalSupply}.
     */
    function totalSupply()
    public
    view
    virtual
    override(ERC721AUpgradeableDedicated, IERC721EnumerableUpgradeable)
    returns (uint256)
    {
        return ERC721AUpgradeableDedicated.totalSupply();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
    {
        require(
            index < ERC721AEnumerableUpgradeableDedicated.totalSupply(),
            "ERC721EnumerableDedicated: global index out of bounds"
        );
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(startTokenId, quantity);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, startTokenId, quantity);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(startTokenId, quantity);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, startTokenId, quantity);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param startTokenId uint256 start ID of the token to be added to the tokens list of the given address
     * @param quantity uint256 quantity of the tokens to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) private {
        for (uint256 index = 0; index < quantity; index++) {
            uint256 tokenId = startTokenId + index;
            uint256 length = ERC721AUpgradeableDedicated.balanceOf(to);
            _ownedTokens[to][length] = tokenId;
            _ownedTokensIndex[tokenId] = length;
        }
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param startTokenId uint256 start ID of the token to be added to the tokens list
     * @param quantity uint256 quantity of the tokens to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(
        uint256 startTokenId,
        uint256 quantity
    ) private {
        for (uint256 index = 0; index < quantity; index++) {
            uint256 tokenId = startTokenId + index;
            _allTokensIndex[tokenId] = _allTokens.length;
            _allTokens.push(tokenId);
        }
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param startTokenId uint256 start ID of the token to be removed from the tokens list of the given address
     * @param quantity uint256 quantity of the tokens to be removed to the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(
        address from,
        uint256 startTokenId,
        uint256 quantity
    ) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        for (uint256 index = 0; index < quantity; index++) {
            uint256 tokenId = startTokenId + index;

            uint256 lastTokenIndex = ERC721AUpgradeableDedicated.balanceOf(from) - 1;
            uint256 tokenIndex = _ownedTokensIndex[tokenId];

            // When the token to delete is the last token, the swap operation is unnecessary
            if (tokenIndex != lastTokenIndex) {
                uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

                _ownedTokens[from][tokenIndex] = lastTokenId;
                // Move the last token to the slot of the to-delete token
                _ownedTokensIndex[lastTokenId] = tokenIndex;
                // Update the moved token's index
            }

            // This also deletes the contents at the last position of the array
            delete _ownedTokensIndex[tokenId];
            delete _ownedTokens[from][lastTokenIndex];
        }
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param startTokenId uint256 start ID of the token to be removed from the tokens list
     * @param quantity uint256 amount of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(
        uint256 startTokenId,
        uint256 quantity
    ) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        for (uint256 index = 0; index < quantity; index++) {
            uint256 tokenId = startTokenId + index;

            uint256 lastTokenIndex = _allTokens.length - 1;
            uint256 tokenIndex = _allTokensIndex[tokenId];

            // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
            // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
            // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
            uint256 lastTokenId = _allTokens[lastTokenIndex];

            _allTokens[tokenIndex] = lastTokenId;
            // Move the last token to the slot of the to-delete token
            _allTokensIndex[lastTokenId] = tokenIndex;
            // Update the moved token's index

            // This also deletes the contents at the last position of the array
            delete _allTokensIndex[tokenId];
            _allTokens.pop();
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}