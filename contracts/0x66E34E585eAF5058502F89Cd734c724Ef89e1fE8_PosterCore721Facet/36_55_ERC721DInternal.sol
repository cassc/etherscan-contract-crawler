// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "solady/src/utils/LibString.sol";

import {ERC721DStorage, ERC721DTokenData, ERC721DAddressData} from "./ERC721DStorage.sol";

contract ERC721DInternal is ContextUpgradeable {
    using AddressUpgradeable for address;
    using LibString for uint256;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    function _name() internal view virtual returns (string memory) {
        return ERC721DStorage.layout()._name;
    }

    function _symbol() internal view virtual returns (string memory) {
        return ERC721DStorage.layout()._symbol;
    }
    
    function _setName(string memory newName) internal {
        ERC721DStorage.layout()._name = newName;
    }
    
    function _setSymbol(string memory newSymbol) internal {
        ERC721DStorage.layout()._symbol = newSymbol;
    }
    
    function _setAddressExtraData(address owner, uint64 extraData) internal {
        ERC721DAddressData storage addressData = ERC721DStorage.layout()._addressData[owner];
        addressData.extraData = extraData;
    }
    
    function _getAddressExtraData(address owner) internal view returns (uint64) {
        return ERC721DStorage.layout()._addressData[owner].extraData;
    }
    
    function _setTokenExtraData(uint tokenId, uint96 extraData) internal {
        ERC721DTokenData storage tokenData = ERC721DStorage.layout()._tokenData[tokenId];
        tokenData.extraData = extraData;
    }
    
    function _getTokenExtraData(uint tokenId) internal view returns (uint96) {
        return ERC721DStorage.layout()._tokenData[tokenId].extraData;
    }
    
    function _numberMinted(address owner) internal view returns (uint256) {
        return ERC721DStorage.layout()._addressData[owner].numberMinted;
    }
    
    function _numberBurned(address owner) internal view returns (uint256) {
        return ERC721DStorage.layout()._addressData[owner].numberBurned;
    }
    
    function _balanceOf(address owner) internal view virtual returns (uint256) {
        return ERC721DStorage.layout()._addressData[owner].balance;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return ERC721DStorage.layout()._tokenData[tokenId].owner;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            ERC721DAddressData storage addressData = ERC721DStorage.layout()._addressData[to];
            addressData.balance += 1;
            addressData.numberMinted += 1;
            
            ERC721DTokenData storage tokenData = ERC721DStorage.layout()._tokenData[tokenId];
            tokenData.owner = to;
        }

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }
    
    function _burn(uint256 tokenId) internal virtual {
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = _ownerOf(tokenId);

        delete ERC721DStorage.layout()._tokenApprovals[tokenId];

        unchecked {
            ERC721DAddressData storage addressData = ERC721DStorage.layout()._addressData[owner];
            addressData.balance -= 1;
            addressData.numberBurned += 1;
            
            delete ERC721DStorage.layout()._tokenData[tokenId];
        }

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(_ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(_ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        delete ERC721DStorage.layout()._tokenApprovals[tokenId];
        
        unchecked {
            ERC721DAddressData storage fromAddressData = ERC721DStorage.layout()._addressData[from];
            fromAddressData.balance -= 1;
            
            ERC721DAddressData storage toAddressData = ERC721DStorage.layout()._addressData[to];
            toAddressData.balance += 1;
            
            ERC721DTokenData storage tokenData = ERC721DStorage.layout()._tokenData[tokenId];
            tokenData.owner = to;
        }

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }
    
    function _isApprovedForAll(address owner, address operator) internal view virtual returns (bool) {
        return ERC721DStorage.layout()._operatorApprovals[owner][operator];
    }
    
    function _getApproved(uint256 tokenId) internal view virtual returns (address) {
        _requireMinted(tokenId);

        return ERC721DStorage.layout()._tokenApprovals[tokenId];
    }
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = _ownerOf(tokenId);
        return (spender == owner || _isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        ERC721DStorage.layout()._tokenApprovals[tokenId] = to;
        emit Approval(_ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        ERC721DStorage.layout()._operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /* firstTokenId */,
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                ERC721DStorage.layout()._addressData[from].balance -= uint64(batchSize);
            }
            if (to != address(0)) {
                ERC721DStorage.layout()._addressData[to].balance += uint64(batchSize);
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}
}