// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract StaticNFT is IERC721 {
    using Strings for uint256;

    string public name;
    string public symbol;
    string public baseURI;

    error TransferNotAllowed();
    error InvalidOwner();
    error NonExistentToken();

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function getBalance(address) internal view virtual returns (uint256);

    function getOwner(uint256) internal view virtual returns (address);

    function balanceOf(address owner) external view override returns (uint256) {
        if (owner == address(0)) revert InvalidOwner();
        return getBalance(owner);
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        address owner = getOwner(tokenId);
        if (owner == address(0)) revert NonExistentToken();
        return owner;
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override {
        revert TransferNotAllowed();
    }

    function safeTransferFrom(
        address,
        address,
        uint256
    ) external pure override {
        revert TransferNotAllowed();
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external pure override {
        revert TransferNotAllowed();
    }

    function approve(address, uint256) external pure override {
        revert TransferNotAllowed();
    }

    function setApprovalForAll(address, bool) external pure override {
        revert TransferNotAllowed();
    }

    function getApproved(uint256) external pure override returns (address) {
        return address(0);
    }

    function isApprovedForAll(address, address)
        external
        pure
        override
        returns (bool)
    {
        return false;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        returns (string memory)
    {
        if (getOwner(tokenId) == address(0)) revert NonExistentToken();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata;
    }
}