// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IERC721Custom.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ERC721Custom is Context, ERC165, IERC721Custom {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;

    mapping(uint256 => address) internal _owners;
    mapping(uint256 => address) internal _tokenApprovals;
    mapping(address => mapping(address => bool)) internal _operatorApprovals;
    mapping(address => uint256) internal _balances;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert QueryForZeroAddress();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();
        return _owners[tokenId];
    }

    function name() external view virtual returns (string memory) {
        return _name;
    }

    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view virtual returns (string memory) {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (!(_msgSender() == owner || isApprovedForAll(owner, _msgSender()))) revert CallerNotOwnerNorApproved();

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert CallerNotOwnerNorApproved();

        _transfer(from, to, tokenId);
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
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert CallerNotOwnerNorApproved();

        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data)) revert TransferToNonERC721ReceiverImplementer();
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, _data)) revert TransferToNonERC721ReceiverImplementer();
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (_exists(tokenId)) revert MintForPreExistentToken();

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (ownerOf(tokenId) != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _beforeApprove(ownerOf(tokenId), to, tokenId);
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        if (owner == operator) revert ApproveToCaller();
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721ReceiverImplementer();
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _beforeApprove(
        address owner,
        address to,
        uint256 tokenId
    ) internal virtual {}
}