// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./IOperatorFilter.sol";

abstract contract ERC721AOperatorFilterUpgradeable is
    ERC721AUpgradeable,
    OwnableUpgradeable
{
    IOperatorFilter private operatorFilter_;

    function setOperatorFilter(IOperatorFilter filter) public onlyOwner {
        operatorFilter_ = filter;
    }

    function operatorFilter() public view returns (IOperatorFilter) {
        return operatorFilter_;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721AUpgradeable) {
        if (
            from != address(0) &&
            to != address(0) &&
            !_mayTransfer(msg.sender, startTokenId)
        ) {
            revert("ERC721OperatorFilter: illegal operator");
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
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