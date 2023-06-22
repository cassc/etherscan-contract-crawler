// SPDX-License-Identifier: MIT
//
// EIP-721: Non-Fungible Token Standard
// https://eips.ethereum.org/EIPS/eip-721
//
// Derived from OpenZeppelin Contracts (token/ERC721/ERC721.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC721/ERC721.sol
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//  OpenERC165
//       |
//  OpenERC721 —— IERC721
//
pragma solidity 0.8.9;

import "OpenNFTs/contracts/OpenERC/OpenERC165.sol";
import "OpenNFTs/contracts/interfaces/IERC721.sol";
import "OpenNFTs/contracts/interfaces/IERC721TokenReceiver.sol";

abstract contract OpenERC721 is IERC721, OpenERC165 {
    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    modifier onlyTokenOwnerOrApproved(uint256 tokenID) {
        require(_isOwnerOrApproved(msg.sender, tokenID), "Not token owner nor approved");
        _;
    }

    modifier existsToken(uint256 tokenID) {
        require(_owners[tokenID] != address(0), "Invalid token ID");
        _;
    }

    function transferFrom(address from, address to, uint256 tokenID)
        external
        payable
        override (IERC721)
    {
        _transferFrom(from, to, tokenID);
    }

    function safeTransferFrom(address from, address to, uint256 tokenID, bytes memory data)
        external
        payable
        override (IERC721)
    {
        _safeTransferFrom(from, to, tokenID, data);
    }

    function approve(address spender, uint256 tokenID) public override (IERC721) {
        require(_isOwnerOrOperator(msg.sender, tokenID), "Not token owner nor operator");

        _tokenApprovals[tokenID] = spender;
        emit Approval(ownerOf(tokenID), spender, tokenID);
    }

    function setApprovalForAll(address operator, bool approved) public override (IERC721) {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenID)
        public
        payable
        override (IERC721)
    {
        _safeTransferFrom(from, to, tokenID, "");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (OpenERC165)
        returns (bool)
    {
        return interfaceId == 0x80ac58cd // = type(IERC721).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override (IERC721) returns (uint256) {
        require(owner != address(0), "Invalid zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenID)
        public
        view
        override (IERC721)
        existsToken(tokenID)
        returns (address)
    {
        return _owners[tokenID];
    }

    function getApproved(uint256 tokenID)
        public
        view
        override (IERC721)
        existsToken(tokenID)
        returns (address)
    {
        return _tokenApprovals[tokenID];
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override (IERC721)
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function _mint(address to, string memory, uint256 tokenID) internal virtual {
        require(to != address(0), "Mint to zero address");
        require(_owners[tokenID] == address(0), "Token already minted");

        _balances[to] += 1;
        _owners[tokenID] = to;

        emit Transfer(address(0), to, tokenID);
        require(_isERC721Receiver(address(0), to, tokenID, ""), "Not ERC721Received");
    }

    function _burn(uint256 tokenID) internal virtual {
        address owner = ownerOf(tokenID);
        require(owner != address(0), "Invalid token ID");

        assert(_balances[owner] > 0);

        _balances[owner] -= 1;
        delete _tokenApprovals[tokenID];
        delete _owners[tokenID];

        emit Transfer(owner, address(0), tokenID);
    }

    function _transferFromBefore(address from, address to, uint256 tokenID) internal virtual {}

    function _isOwnerOrOperator(address spender, uint256 tokenID)
        internal
        view
        virtual
        returns (bool ownerOrOperator)
    {
        address tokenOwner = ownerOf(tokenID);
        ownerOrOperator = (tokenOwner == spender || isApprovedForAll(tokenOwner, spender));
    }

    function _safeTransferFrom(address from, address to, uint256 tokenID, bytes memory data)
        private
    {
        _transferFrom(from, to, tokenID);

        require(_isERC721Receiver(from, to, tokenID, data), "Not ERC721Receiver");
    }

    function _transferFrom(address from, address to, uint256 tokenID)
        private
        onlyTokenOwnerOrApproved(tokenID)
    {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        require(from == ownerOf(tokenID), "From not owner");

        _transferFromBefore(from, to, tokenID);

        delete _tokenApprovals[tokenID];

        if (from != to) {
            _balances[from] -= 1;
            _balances[to] += 1;
            _owners[tokenID] = to;
        }

        emit Transfer(from, to, tokenID);
    }

    function _isERC721Receiver(address from, address to, uint256 tokenID, bytes memory data)
        private
        returns (bool)
    {
        return to.code.length == 0
            || IERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenID, data)
                == IERC721TokenReceiver.onERC721Received.selector;
    }

    function _isOwnerOrApproved(address spender, uint256 tokenID)
        private
        view
        returns (bool ownerOrApproved)
    {
        ownerOrApproved =
            (_isOwnerOrOperator(spender, tokenID) || (getApproved(tokenID) == spender));
    }
}