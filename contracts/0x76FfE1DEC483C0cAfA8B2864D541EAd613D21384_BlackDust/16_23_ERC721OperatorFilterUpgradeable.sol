// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "./IOperatorFilter.sol";

abstract contract ERC721OperatorFilterUpgradeable is
    ERC721Upgradeable,
    OwnableUpgradeable
{
    IOperatorFilter private operatorFilter_;

    function setOperatorFilter(IOperatorFilter filter) public onlyOwner {
        operatorFilter_ = filter;
    }

    function operatorFilter() public view returns (IOperatorFilter) {
        return operatorFilter_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable) {
        if (
            from != address(0) &&
            to != address(0) &&
            !_mayTransfer(msg.sender, tokenId)
        ) {
            revert("ERC721OperatorFilter: illegal operator");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _mayTransfer(address operator, uint256 tokenId)
        private
        view
        returns (bool)
    {
        IOperatorFilter filter = operatorFilter_;
        if (address(filter) == address(0)) return true;
        if (operator == ownerOf(tokenId)) return true;
        return filter.mayTransfer(msg.sender);
    }
}