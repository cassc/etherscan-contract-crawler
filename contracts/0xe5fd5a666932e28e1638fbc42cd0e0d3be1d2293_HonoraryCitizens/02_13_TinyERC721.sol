// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error TokenDataQueryForNonexistentToken();
error OwnerQueryForNonexistentToken();
error OperatorQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

contract TinyERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    struct TokenData {
        address owner;
        bytes12 aux;
    }

    uint256 private immutable _maxBatchSize;

    mapping(uint256 => TokenData) private _tokens;
    uint256 private _mintCounter;

    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxBatchSize_
    ) {
        _name = name_;
        _symbol = symbol_;
        _maxBatchSize = maxBatchSize_;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _mintCounter;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();

        uint256 total = totalSupply();
        uint256 count;
        address lastOwner;
        for (uint256 i; i < total; ++i) {
            address tokenOwner = _tokens[i].owner;
            if (tokenOwner != address(0)) lastOwner = tokenOwner;
            if (lastOwner == owner) ++count;
        }

        return count;
    }

    function _tokenData(uint256 tokenId) internal view returns (TokenData storage) {
        if (!_exists(tokenId)) revert TokenDataQueryForNonexistentToken();

        TokenData storage token = _tokens[tokenId];
        uint256 currentIndex = tokenId;
        while (token.owner == address(0)) {
            unchecked {
                --currentIndex;
            }
            token = _tokens[currentIndex];
        }

        return token;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();
        return _tokenData(tokenId).owner;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        TokenData memory token = _tokenData(tokenId);
        address owner = token.owner;
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, token);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        TokenData memory token = _tokenData(tokenId);
        if (!_isApprovedOrOwner(_msgSender(), tokenId, token)) revert TransferCallerNotOwnerNorApproved();

        _transfer(from, to, tokenId, token);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        TokenData memory token = _tokenData(tokenId);
        if (!_isApprovedOrOwner(_msgSender(), tokenId, token)) revert TransferCallerNotOwnerNorApproved();

        _safeTransfer(from, to, tokenId, token, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        TokenData memory token,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId, token);

        if (to.isContract() && !_checkOnERC721Received(from, to, tokenId, _data))
            revert TransferToNonERC721ReceiverImplementer();
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _mintCounter;
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId,
        TokenData memory token
    ) internal view virtual returns (bool) {
        address owner = token.owner;
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, "");
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        uint256 startTokenId = _mintCounter;
        _mint(to, quantity);

        if (to.isContract()) {
            unchecked {
                for (uint256 i; i < quantity; ++i) {
                    if (!_checkOnERC721Received(address(0), to, startTokenId + i, _data))
                        revert TransferToNonERC721ReceiverImplementer();
                }
            }
        }
    }

    function _mint(address to, uint256 quantity) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        uint256 startTokenId = _mintCounter;
        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        unchecked {
            for (uint256 i; i < quantity; ++i) {
                if (_maxBatchSize == 0 ? i == 0 : i % _maxBatchSize == 0) {
                    TokenData storage token = _tokens[startTokenId + i];
                    token.owner = to;
                    token.aux = _calculateAux(address(0), to, startTokenId + i, 0);
                }

                emit Transfer(address(0), to, startTokenId + i);
            }
            _mintCounter += quantity;
        }

        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        TokenData memory token
    ) internal virtual {
        if (token.owner != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        _approve(address(0), tokenId, token);

        unchecked {
            uint256 nextTokenId = tokenId + 1;
            if (_exists(nextTokenId)) {
                TokenData storage nextToken = _tokens[nextTokenId];
                if (nextToken.owner == address(0)) {
                    nextToken.owner = token.owner;
                    nextToken.aux = token.aux;
                }
            }
        }

        TokenData storage newToken = _tokens[tokenId];
        newToken.owner = to;
        newToken.aux = _calculateAux(from, to, tokenId, token.aux);

        emit Transfer(from, to, tokenId);

        _afterTokenTransfers(from, to, tokenId, 1);
    }

    function _calculateAux(
        address from,
        address to,
        uint256 tokenId,
        bytes12 current
    ) internal view virtual returns (bytes12) {}

    function _approve(
        address to,
        uint256 tokenId,
        TokenData memory token
    ) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(token.owner, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}