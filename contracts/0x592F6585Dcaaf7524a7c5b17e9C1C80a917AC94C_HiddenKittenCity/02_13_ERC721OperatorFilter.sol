// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

import "./IOperatorFilter.sol";

abstract contract ERC721OperatorFilter is ERC721A, Ownable {
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
        uint256 tokenId,
        uint256 quantity
    ) internal virtual override(ERC721A) {
        if (
            from != address(0) &&
            to != address(0) &&
            !_mayTransfer(msg.sender, tokenId)
        ) {
            revert("ERC721OperatorFilter: illegal operator");
        }
        super._beforeTokenTransfers(from, to, tokenId, quantity);
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