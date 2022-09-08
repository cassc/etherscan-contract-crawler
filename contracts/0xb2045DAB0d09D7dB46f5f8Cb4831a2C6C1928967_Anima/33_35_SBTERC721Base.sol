//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";
import { EnumerableMap } from "@solidstate/contracts/utils/EnumerableMap.sol";
import { EnumerableSet } from "@solidstate/contracts/utils/EnumerableSet.sol";
import { IERC721 } from "@solidstate/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@solidstate/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC721Base } from "@solidstate/contracts/token/ERC721/base/IERC721Base.sol";
import { ERC721BaseStorage } from "@solidstate/contracts/token/ERC721/base/ERC721BaseStorage.sol";
import { ERC721BaseInternal } from "@solidstate/contracts/token/ERC721/base/ERC721BaseInternal.sol";
import { AnimaErrors } from "./AnimaErrors.sol";

/**
 * @title Base ERC721 implementation, excluding optional extensions
 */
abstract contract SBTERC721Base is IERC721Base, ERC721BaseInternal {
    using AddressUtils for address;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC721
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * @inheritdoc IERC721
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _ownerOf(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        return _getApproved(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function isApprovedForAll(address, address) public pure returns (bool) {
        return false;
    }

    /**
     * @inheritdoc IERC721
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable {
        _handleTransferMessageValue(from, to, tokenId, msg.value);
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner or approved");
        _transfer(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable {
        _handleTransferMessageValue(from, to, tokenId, msg.value);
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @inheritdoc IERC721
     */
    function approve(address operator, uint256 tokenId) public payable {
        _handleApproveMessageValue(operator, tokenId, msg.value);
        address owner = ownerOf(tokenId);
        require(operator != owner, "ERC721: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(operator, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address, bool) public pure {
        revert AnimaErrors.NotAllowed();
    }
}