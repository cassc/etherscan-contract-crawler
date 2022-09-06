// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Context.sol";
import "Strings.sol";
import "Ownable.sol";
import "ERC165.sol";

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, Ownable {
    using Address for address;
    using Strings for uint256;

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Amount of tokens minted
    uint256 public maxSupply;

    // Who should the tokens belong to by default
    address public defaultOwner;

    uint256 public totalSupply = 0;

    /// Base for the token URI.
    string public baseUrl;
    /// Extension of the metadata file.
    /// You can set this to ".json" to have tokenURI() construct an url with
    /// ".json" at the end.
    string internal metadataFileExt = "";
    bool public baseUrlLocked;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        address defaultOwner_,
        string memory baseUrl_
    ) {
        require(maxSupply_ > 0, "maxSupply must be greater than 0");
        require(defaultOwner_ != address(0), "defaultOwner cannot be the zero address");

        name = name_;
        symbol = symbol_;
        maxSupply = maxSupply_;
        defaultOwner = defaultOwner_;
        baseUrl = baseUrl_;
        baseUrlLocked = false;
    }

    function mint(uint256 amount) public onlyOwner {
        uint256 i = totalSupply + 1;
        totalSupply += amount;
        require(totalSupply <= maxSupply, "ERC721: mint amount exceeds maxSupply");
        uint256 end = totalSupply;
        _balances[defaultOwner] += amount;
        for (; i <= end; i++) {
            emit Transfer(address(0), defaultOwner, i);
        }
    }

    /// Changes the base URL for the token metadata.
    function setBaseUrl(string memory _baseUrl) public onlyOwner {
        require(!baseUrlLocked, "Base URL is locked");
        require(bytes(_baseUrl).length > 0, "Base URL cannot be empty");
        baseUrl = _baseUrl;
    }

    /// Blocks the ability to change the metadata base URL in the future.
    /// Only contract owner can do this.
    function lockBaseUrl() public onlyOwner {
        baseUrlLocked = true;
    }

    /// Returns URL to the token metadata JSON file.
    /// The URL is based on the base URL, token ID and the metadata file extension.
    /// Whole token URI is constructed like this: "{baseUrl}{tokenId}{metadataFileExt}"
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireMinted(tokenId);

        return string(abi.encodePacked(baseUrl, tokenId.toString(), metadataFileExt));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);
        return _owners[tokenId] != address(0) ? _owners[tokenId] : defaultOwner;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId > 0 && tokenId <= totalSupply;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
}