// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./BNVTokenBase.sol";
import "./IBNVToken.sol";
import "./adapters/IBNVAdapter.sol";

/// @title BNV Token Contract 
/// @author Sensible Lab
/// @dev based on a standard ERC721
contract BNVToken is BNVTokenBase, IBNVToken {

    using EnumerableSet for EnumerableSet.AddressSet;

    // Adapter address
    EnumerableSet.AddressSet private _adapters;

    /// @notice Initializes the contract with `baseURI`, use IPFS
    constructor(address[] memory adapterAddress) ERC721("BNV2", "BNV2") {
        for (uint i = 0; i < adapterAddress.length; i++) {
            _adapters.add(adapterAddress[i]);
        }
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(BNVTokenBase) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice disable approve
    function approve(address to, uint256 tokenId) public override(BNVTokenBase) {
        require(isWhiteList(ownerOf(tokenId), to), "Only whitelist is allowed");
        super.approve(to, tokenId);
    }

    /// @notice disable owner to set approve for those operator not in whitelist
    function setApprovalForAll(address operator, bool approved) public override(BNVTokenBase) {
        require(isWhiteList(_msgSender(), operator), "Only whitelist is allowed");
        super.setApprovalForAll(operator, approved);
    }

    /// @notice disable transfer from
    function transferFrom(address from, address to, uint256 tokenId) public virtual override(BNVTokenBase) {
        require(_msgSender() != ownerOf(tokenId), "Use transferWithRoyalty");
        //solhint-disable-next-line max-line-length
        require(getApproved(tokenId) == _msgSender() || isApprovedForAll(ownerOf(tokenId), _msgSender()), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /// @notice safe transfer from only allow for whitelist and us
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override(BNVTokenBase) {
        require(_msgSender() != ownerOf(tokenId), "Use transferWithRoyalty");
        require(getApproved(tokenId) == _msgSender() || isApprovedForAll(ownerOf(tokenId), _msgSender()), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    // VIEW ONLY =======================================

    /// @notice check whether sender is in white list
    function isWhiteList(address owner, address operator) public view override returns (bool) {
        bool isWhitelisted = false;
        for (uint i = 0; i < _adapters.length(); i++) {
            isWhitelisted = IBNVAdapter(_adapters.at(i)).hasPermission(owner, operator);
            if (isWhitelisted) break;
        }
        return isWhitelisted;
    }

    // ADMIN =======================================

    /// @notice get all adapter address
    function _getAllAdapters() external view onlyOwner returns (address[] memory) {
        address[] memory arr = new address[](_adapters.length());
        for (uint i = 0; i < _adapters.length(); i++) {
            arr[i] = _adapters.at(i);
        }
        return arr;
    }

    /// @notice set adapter address
    function _addToAdapters(address newAdapter) external onlyOwner {
        _adapters.add(newAdapter);
    }

    /// @notice remove adapter address
    function _removeFromAdapters(address existingAdapter) external onlyOwner {
        _adapters.remove(existingAdapter);
    }

}