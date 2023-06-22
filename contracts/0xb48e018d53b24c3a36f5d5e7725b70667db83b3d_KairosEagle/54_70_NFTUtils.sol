// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {supplyPositionStorage} from "../DataStructure/Global.sol";
import {SupplyPosition} from "../DataStructure/Storage.sol";
import {ERC721ApproveToCaller, ERC721InvalidTokenId, ERC721TokenAlreadyMinted, ERC721MintToTheZeroAddress, ERC721TransferFromIncorrectOwner, ERC721TransferToNonERC721ReceiverImplementer, ERC721TransferToTheZeroAddress} from "../DataStructure/ERC721Errors.sol";

/// @notice internal logic for DiamondERC721 adapted fo usage with diamond storage
abstract contract NFTUtils {
    using Address for address;

    function emitTransfer(address from, address to, uint256 tokenId) internal virtual;

    function emitApproval(address owner, address approved, uint256 tokenId) internal virtual;

    function emitApprovalForAll(address owner, address operator, bool approved) internal virtual;

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721TransferToNonERC721ReceiverImplementer();
                } else {
                    /* solhint-disable-next-line no-inline-assembly */
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert ERC721TransferToNonERC721ReceiverImplementer();
        }
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory data) internal {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, data)) {
            revert ERC721TransferToNonERC721ReceiverImplementer();
        }
    }

    function _mint(address to, uint256 tokenId) internal {
        SupplyPosition storage sp = supplyPositionStorage();

        if (to == address(0)) {
            revert ERC721MintToTheZeroAddress();
        }
        if (_exists(tokenId)) {
            revert ERC721TokenAlreadyMinted();
        }

        sp.balance[to] += 1;
        sp.owner[tokenId] = to;

        emitTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        SupplyPosition storage sp = supplyPositionStorage();

        address owner = _ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        sp.balance[owner] -= 1;
        delete sp.owner[tokenId];

        emitTransfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        SupplyPosition storage sp = supplyPositionStorage();

        if (_ownerOf(tokenId) != from) {
            revert ERC721TransferFromIncorrectOwner();
        }
        if (to == address(0)) {
            revert ERC721TransferToTheZeroAddress();
        }

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        sp.balance[from] -= 1;
        sp.balance[to] += 1;
        sp.owner[tokenId] = to;

        emitTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        SupplyPosition storage sp = supplyPositionStorage();

        sp.tokenApproval[tokenId] = to;
        emitApproval(_ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        SupplyPosition storage sp = supplyPositionStorage();

        if (owner == operator) {
            revert ERC721ApproveToCaller();
        }
        sp.operatorApproval[owner][operator] = approved;
        emitApprovalForAll(owner, operator, approved);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        SupplyPosition storage sp = supplyPositionStorage();

        return sp.owner[tokenId] != address(0);
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        SupplyPosition storage sp = supplyPositionStorage();

        address owner = sp.owner[tokenId];
        if (owner == address(0)) {
            revert ERC721InvalidTokenId();
        }
        return owner;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = _ownerOf(tokenId);
        return (spender == owner || _isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    function _getApproved(uint256 tokenId) internal view returns (address) {
        if (!_exists(tokenId)) {
            revert ERC721InvalidTokenId();
        }

        return supplyPositionStorage().tokenApproval[tokenId];
    }

    function _isApprovedForAll(address owner, address operator) internal view returns (bool) {
        return supplyPositionStorage().operatorApproval[owner][operator];
    }
}