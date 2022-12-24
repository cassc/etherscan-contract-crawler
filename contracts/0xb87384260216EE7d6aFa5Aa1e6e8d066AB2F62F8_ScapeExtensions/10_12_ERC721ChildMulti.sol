// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)
// Modified by Akuti (Scapes.Studio)

pragma solidity ^0.8.16;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC165, IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC721Child} from "./IERC721Child.sol";

interface IERC721WithMergeBalance is IERC721 {
    function balanceOfMerges(address account)
        external
        view
        returns (uint256 balance);
}

/**
 * @title ERC721ChildMulti
 * @author akuti.eth | scapes.eth
 * @notice Child collection that is attached to a parent ERC721 contract.
 * @dev Modification based on ERC721, including the Metadata and custom Child
 *      extension which supports multiple sub-collections. This one is modified for Scapes
 *      and allows 10 child collections following normal Scapes + one collection following merges.
 *      Transfers and approvals are disabled as token ownership is managed by the parent.
 */
contract ERC721ChildMulti is
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Child,
    Ownable2Step
{
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Parent NFT
    IERC721WithMergeBalance internal _parent;
    address internal _parentAddress;

    string[] internal _baseURIs;
    string internal _mergeBaseURI;

    uint256 internal constant FIRST_TOKEN_ID = 1;
    uint256 internal constant LAST_TOKEN_ID = 10_000;
    uint256 internal constant MAX_CHILD_COLLECTIONS = 10;
    // Token ids larger than this value will be for merges
    uint256 internal constant MAX_NORMAL_TOKEN_ID =
        LAST_TOKEN_ID * MAX_CHILD_COLLECTIONS;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address parent_
    ) {
        _name = name_;
        _symbol = symbol_;
        _parent = IERC721WithMergeBalance(parent_);
        _parentAddress = parent_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Child).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 totalBalance = _parent.balanceOf(owner);
        try _parent.balanceOfMerges(owner) returns (uint256 mergeBalance) {
            return
                ((totalBalance - mergeBalance) * _nrCollections()) +
                mergeBalance;
        } catch {
            return totalBalance * _nrCollections();
        }
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if (!_exists(tokenId)) revert ERC721Child__NonExistentToken();
        return _parent.ownerOf(_parentTokenId(tokenId));
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev The address of the parent collection.
     */
    function parent() public view virtual override returns (address) {
        return _parentAddress;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert ERC721Child__NonExistentToken();
        string memory baseURI;
        if (tokenId <= MAX_NORMAL_TOKEN_ID) {
            baseURI = _baseURIs[(tokenId - 1) / 10_000]; // -1 since the tokenId is counting from 1
        } else baseURI = _mergeBaseURI;
        return string.concat(baseURI, _parentTokenId(tokenId).toString());
    }

    /**
     * @dev The number of normal child collections (max 10).
     */
    function _nrCollections() internal view returns (uint256) {
        return _baseURIs.length;
    }

    /**
     * @dev Get the parent token id the child token id maps to.
     */
    function _parentTokenId(uint256 tokenId)
        internal
        view
        virtual
        returns (uint256)
    {
        if (tokenId > MAX_NORMAL_TOKEN_ID) return tokenId;
        uint256 collectionIdx = (tokenId - 1) / LAST_TOKEN_ID;
        if (collectionIdx < _nrCollections())
            return ((tokenId - 1) % LAST_TOKEN_ID) + 1; // extra -+ 1 since the tokenId is counting from 1
        revert ERC721Child__NonExistentToken();
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address, uint256) public virtual override {
        revert ERC721Child__ApprovalNotSupported();
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256)
        public
        view
        virtual
        override
        returns (address)
    {
        return address(0);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address, bool) public virtual override {
        revert ERC721Child__ApprovalNotSupported();
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address, address)
        public
        view
        virtual
        override
        returns (bool)
    {
        return false;
    }

    /**
     * @dev Initialize token ownership, used when adding more child collections
     * after the parent contract minted.
     * @param baseURI The URI for the token metadata of the child collection.
     * @param tokenOwners The list of token owners of the parent collection.
     * The xth position the list will be the xth token ID of the parent contract.
     *
     * Emits a {Transfer} event from ZeroAddress to current owner per token.
     */
    function _init_using_tokenOwners(
        string memory baseURI,
        address[] memory tokenOwners
    ) internal virtual {
        _baseURIs.push(baseURI);
        uint256 baseURIIndex = _baseURIs.length - 1;
        uint256 length = tokenOwners.length;

        unchecked {
            for (uint256 i = 0; i < length; ) {
                emit Transfer(
                    address(0),
                    tokenOwners[i],
                    (LAST_TOKEN_ID * baseURIIndex) + FIRST_TOKEN_ID + i
                );
                i++;
            }
        }
    }

    /**
     * @dev See {IERC721Child-update}.
     */
    function update(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        if (msg.sender != _parentAddress) revert ERC721Child__InvalidCaller();
        if (tokenId > MAX_NORMAL_TOKEN_ID) {
            emit Transfer(from, to, tokenId);
            return;
        }

        uint256 length = _baseURIs.length;
        unchecked {
            for (uint256 i = 0; i < length; ) {
                uint256 childTokenId = tokenId + (LAST_TOKEN_ID * i);
                emit Transfer(from, to, childTokenId);
                i++;
            }
        }
    }

    /**
     * @notice Manually update a token ownership.
     * @dev Manually update token ownership by emitting a transfer event.
     * @param from sender of token
     * @param childTokenId child token id to update
     */
    function manualUpdate(address from, uint256 childTokenId)
        public
        virtual
        onlyOwner
    {
        emit Transfer(from, ownerOf(childTokenId), childTokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public virtual override {
        revert ERC721Child__TransferNotSupported();
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256
    ) public virtual override {
        revert ERC721Child__TransferNotSupported();
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override {
        revert ERC721Child__TransferNotSupported();
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens are managed by the parent contract.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        uint256 parentTokenId = _parentTokenId(tokenId);
        try _parent.ownerOf(parentTokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }
}