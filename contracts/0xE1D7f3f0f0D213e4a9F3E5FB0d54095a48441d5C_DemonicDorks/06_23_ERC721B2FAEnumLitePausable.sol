// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.14;
/***
 *************************************************************************
 * ERC721B2FA - Ultra Low Gas - 2 Factor Authentication                  *
 * @author: @ghooost0x2a                                                 *
 *************************************************************************
 * ERC721B2FA is a modified version of EnumerableLite, by @squuebo_nft   *
 * and the LockRegistry/Guardian contracts by @OwlOfMoistness            *
 *************************************************************************
 *     :::::::              ::::::::      :::                            *
 *    :+:   :+: :+:    :+: :+:    :+:   :+: :+:                          *
 *    +:+  :+:+  +:+  +:+        +:+   +:+   +:+                         *
 *    +#+ + +:+   +#++:+       +#+    +#++:++#++:                        *
 *    +#+#  +#+  +#+  +#+    +#+      +#+     +#+                        *
 *    #+#   #+# #+#    #+#  #+#       #+#     #+#                        *
 *     #######             ########## ###     ###                        *
 *************************************************************************/

import "./ERC721BLockRegistry.sol";
import "./IBatch.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

abstract contract ERC721B2FAEnumLitePausable is
    ERC721BLockRegistry,
    Pausable,
    IBatch,
    IERC721Enumerable
{
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _offset
    ) ERC721BLockRegistry(_name, _symbol, _offset) {}

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyDelegates
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyDelegates {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyDelegates {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyDelegates {
        _resetTokenRoyalty(tokenId);
    }

    function isOwnerOf(address account, uint256[] calldata tokenIds)
        external
        view
        override
        returns (bool)
    {
        for (uint256 i; i < tokenIds.length; ++i) {
            if (_owners[tokenIds[i]] != account) return false;
        }

        return true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721B)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256 tokenId)
    {
        uint256 count;
        for (uint256 i; i < _owners.length; ++i) {
            if (owner == _owners[i]) {
                if (count == index) return i;
                else ++count;
            }
        }

        require(false, "ERC721Enumerable: owner index out of bounds");
    }

    function tokenByIndex(uint256 index)
        external
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return index;
    }

    function totalSupply()
        public
        view
        override(ERC721B, IERC721Enumerable)
        returns (uint256)
    {
        return _owners.length - _offset;
    }

    // Modified to call ERC721BLockRegistry's safeTransferFrom (to account for 2FA)
    function transferBatch(
        address from,
        address to,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external override {
        for (uint256 i; i < tokenIds.length; ++i) {
            ERC721BLockRegistry.safeTransferFrom(from, to, tokenIds[i], data);
        }
    }

    function walletOfOwner(address account)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 quantity = balanceOf(account);
        uint256[] memory wallet = new uint256[](quantity);
        for (uint256 i; i < quantity; ++i) {
            wallet[i] = tokenOfOwnerByIndex(account, i);
        }
        return wallet;
    }
}