// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "../interface/IERC721.sol";
import {NFTUtils} from "./NFTUtils.sol";
import {SupplyPosition} from "../DataStructure/Storage.sol";
import {supplyPositionStorage} from "../DataStructure/Global.sol";
import {ERC721AddressZeroIsNotAValidOwner, ERC721ApprovalToCurrentOwner, ERC721CallerIsNotOwnerNorApproved, ERC721CallerIsNotOwnerNorApprovedForAll} from "../DataStructure/ERC721Errors.sol";

/// @title ERC721 Diamond Facet
/// @notice implements basic ERC721 for usage as a diamond facet
/// @dev based on OpenZeppelin's implementation
///     this is a minimalist implementation, notably missing are the
///     tokenURI, _baseURI, _beforeTokenTransfer and _afterTokenTransfer methods
/// @author Kairos protocol
abstract contract DiamondERC721 is IERC721, NFTUtils {
    using Address for address;

    error Unauthorized();

    // constructor equivalent is in the Initializer contract

    /// @dev don't use this method for inclusion in the facet function selectors
    ///     prefer the LibDiamond implementation for this method
    ///     it is included here for IERC721-compliance
    /* solhint-disable-next-line no-empty-blocks */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {}

    function balanceOf(address owner) public view virtual returns (uint256) {
        SupplyPosition storage sp = supplyPositionStorage();

        if (owner == address(0)) {
            revert ERC721AddressZeroIsNotAValidOwner();
        }
        return sp.balance[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _ownerOf(tokenId);
    }

    function name() public view virtual returns (string memory) {
        SupplyPosition storage sp = supplyPositionStorage();

        return sp.name;
    }

    function symbol() public view virtual returns (string memory) {
        SupplyPosition storage sp = supplyPositionStorage();

        return sp.symbol;
    }

    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        if (to == owner) {
            revert ERC721ApprovalToCurrentOwner();
        }
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert ERC721CallerIsNotOwnerNorApprovedForAll();
        }

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        return _getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _isApprovedForAll(owner, operator);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert ERC721CallerIsNotOwnerNorApproved();
        }

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert ERC721CallerIsNotOwnerNorApproved();
        }
        _safeTransfer(from, to, tokenId, data);
    }
}