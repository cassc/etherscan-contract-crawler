// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract ERC721B is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;

    enum TOKEN_TYPE {
        SILVER,
        ROSE,
        GOLD
    }

    struct Token {
        address owner;
        uint16 typeIndex;
        TOKEN_TYPE tokenType;
    }

    Token[] public tokens;
    string private _name;
    string private _symbol;

    mapping(uint => address) internal _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_ ){
        _name = name_;
        _symbol = symbol_;
    }

    //public
    function balanceOf(address owner) public view virtual override returns (uint) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        uint count;
        for( uint i; i < tokens.length; ++i ){
          if( owner == tokens[i].owner )
            ++count;
        }
        return count;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function ownerOf(uint tokenId) public view override returns (address) {
        return tokens[tokenId].owner;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view virtual returns (uint) {
        return tokens.length;
    }


    function approve(address to, uint tokenId) external override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function setApprovalForAll(address operator, bool approved) external override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint tokenId) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }


    //internal
    function _approve(address to, uint tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _beforeTokenTransfer( address from, address to) internal virtual;

    function _checkOnERC721Received(address from, address to, uint tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _exists(uint tokenId) internal view returns (bool) {
        return tokenId < tokens.length && tokens[tokenId].owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint tokenId) internal virtual;

    function _next() internal view virtual returns(uint){
        return tokens.length;
    }

    function _safeMint(address to, uint tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _safeTransfer(address from, address to, uint tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _transfer(address from, address to, uint tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        tokens[tokenId].owner = to;

        emit Transfer(from, to, tokenId);
    }
}