// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./BaseERC721.sol";
import "./EnumerableBitMaps.sol";


abstract contract ERC721M is BaseERC721 {
    using BitMaps for BitMaps.BitMap;
    using EnumerableBitMaps for BitMaps.BitMap;

    struct Ownership {
        address owner;
        uint64 startedAt;
    }

    struct Holdings {
        BitMaps.BitMap tokens;
    }

    uint256 private immutable _size; // the maximum number of token IDs (fixed at construction)
    mapping(uint256 => Ownership) private _owners; // token ID => owner mapping
    mapping(address => Holdings) private _holdings; // per-user bitmap of owned token IDs

    constructor(
        string memory name,
        string memory symbol,
        uint256 size_
    ) BaseERC721(name, symbol) {
        _size = size_;
    }

    function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _holdings[owner].tokens.countSet(_size);
    }

    function ownerOf(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
    {
        address owner = _owners[tokenId].owner;
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function _exists(uint256 tokenId)
    internal
    view
    virtual
    override
    returns (bool)
    {
        return _owners[tokenId].owner != address(0);
    }

    function _anyExists(uint256 fromTokenId, uint256 quantity)
    internal
    view
    virtual
    override
    returns (bool)
    {
        for (uint256 i = 0; i < quantity; i++) {
            if (_owners[fromTokenId + i].owner != address(0)) {
                return true;
            }
        }
        return false;
    }

    function _doMint(address to, uint256 tokenId) internal virtual override {
        require(tokenId < _size, "token ID out of range");
        _owners[tokenId].owner = to;
        _owners[tokenId].startedAt = uint64(block.timestamp);

        _holdings[to].tokens.set(tokenId);
    }

    function _doMultiMint(
        address to,
        uint256 fromTokenId,
        uint256 quantity
    ) internal virtual override {
        require(fromTokenId + quantity <= _size, "token ID out of range");
        for (uint256 i = 0; i < quantity; i++) {
            _owners[fromTokenId + i].owner = to;
            _owners[fromTokenId + i].startedAt = uint64(block.timestamp);
        }
        _holdings[to].tokens.setMulti(fromTokenId, quantity);
    }

    function _doBurn(address owner, uint256 tokenId) internal virtual override {
        _owners[tokenId].owner = address(0);
        _owners[tokenId].startedAt = 0;
        _holdings[owner].tokens.unset(tokenId);
    }

    function _doTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        _holdings[from].tokens.unset(tokenId);
        _holdings[to].tokens.set(tokenId);

        _owners[tokenId].owner = to;
        _owners[tokenId].startedAt = uint64(block.timestamp);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    returns (uint256)
    {
        (bool wasFound, uint256 position) = _holdings[owner].tokens.indexOfNth(
            index + 1,
            _size
        );
        require(wasFound, "ERC721Enumerable: owner index out of bounds");
        return position;
    }
}