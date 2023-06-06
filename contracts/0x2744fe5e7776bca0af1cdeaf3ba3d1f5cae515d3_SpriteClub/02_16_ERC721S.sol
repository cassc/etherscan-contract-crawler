// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';


contract ERC721S is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Minting happens in order from 0 onwwards
    uint256 internal currentTokenIndex = 0;

    // Total token limit
    uint256 public immutable collectionSize;

    // Minting limit per transaction
    uint256 public immutable transactionMintLimit;

    // Minting limit per address
    uint256 public immutable addressMintLimit;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_, uint256 transactionMintLimit_, uint256 addressMintLimit_, uint256 collectionSize_) {
        _name = name_;
        _symbol = symbol_;
        transactionMintLimit = transactionMintLimit_;
        addressMintLimit = addressMintLimit_;
        collectionSize = collectionSize_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function totalSupply() public view override returns (uint256) {
        return currentTokenIndex;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < currentTokenIndex;
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721S: owner query for nonexistent token");
        return owner;
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        require(index < currentTokenIndex, "ERC721S: index out of bounds");
        return index;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), 'ERC721S: balance query for the zero address');
        return _balances[owner];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        require(index < balanceOf(owner), "ERC721S: index out of bounds");
        uint256 tokenIndex = 0;
        for (uint256 tokenId = 0; tokenId < currentTokenIndex; tokenId++) {
            if (_owners[tokenId] == owner) {
                if (tokenIndex == index) {
                    return tokenId;
                }
                tokenIndex++;
            }
        }
        revert('ERC721S: unable to get token of owner by index');
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721S: URI query for nonexistent token');
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = _owners[tokenId];
        require(to != owner, "ERC721S: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721S: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721S: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), 'ERC721S: approved query for nonexistent token');
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721S: query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            'ERC721S: transfer to non ERC721Receiver implementer'
        );
    }

    function _mint(address to, uint256 quantity, bool shouldIgnoreLimits) internal {
        require(to != address(0), 'ERC721S: mint to the zero address');
        if (!shouldIgnoreLimits) {
            require(quantity > 0 && quantity <= transactionMintLimit, 'ERC721S: invalid quantity');
            require(_balances[to] + quantity <= addressMintLimit, "ERC721S: adress mint limit reached");
        }
        uint256 startTokenId = currentTokenIndex;
        uint256 nextCurrentTokenIndex = currentTokenIndex + quantity;
        require(nextCurrentTokenIndex <= collectionSize, 'ERC721S: quantity out of bounds');
        _beforeTokenTransfers(address(0), to, startTokenId, quantity);
        _balances[to] += quantity;
        for (; startTokenId < nextCurrentTokenIndex; startTokenId++) {
            _owners[startTokenId] = to;
            emit Transfer(address(0), to, startTokenId);
        }
        currentTokenIndex = nextCurrentTokenIndex;
    }

    function _transfer(address from, address to, uint256 tokenId) private {
        require(_owners[tokenId] == from, "ERC721S: transfer of token that is not own");
        require(to != address(0), "ERC721S: oww, dont do that! I almost got burnt!");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721S: caller is not owner nor approved");

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert('ERC721S: transfer to non ERC721Receiver implementer');
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}
}