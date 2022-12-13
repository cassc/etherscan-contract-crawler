// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC721LazyMint.sol";
import "../libraries/MintERC721Lib.sol";
import "./ERC721Upgradeable.sol";

/**
 * @title ERC721LazyMint
 * ERC721LazyMint - This contract manages the lazy mint for ERC721.
 */
abstract contract ERC721LazyMint is IERC721LazyMint, ERC721Upgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;

    function isMinted(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return
            interfaceId == MintERC721Lib._INTERFACE_ID_LAZY_MINT ||
            super.supportsInterface(interfaceId);
    }

    function _lazyMint(MintERC721Lib.MintERC721Data memory mintERC721Data)
        internal
    {
        bytes32 mintERC721Hash = MintERC721Lib.hash(mintERC721Data);
        (bool isMintValid, string memory mintErrorMessage) = MintERC721Lib
            .validate(mintERC721Data);
        require(isMintValid, mintErrorMessage);
        _mint(mintERC721Data.to, mintERC721Data.tokenId);
        emit Minted(mintERC721Hash);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_burned(tokenId), "token already burned");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _holderTokens[to].add(tokenId);
        _tokenOwners.set(tokenId, to);
        address minter = address(uint160(tokenId >> 96));
        if (minter != to) {
            emit Transfer(address(0), minter, tokenId);
            emit Transfer(minter, to, tokenId);
        } else {
            emit Transfer(address(0), to, tokenId);
        }
        _afterTokenTransfer(address(0), to, tokenId);
    }

    uint256[50] private __gap;
}