// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./IOperatorFilter.sol";

abstract contract ERC721OperatorFilter is ERC721, Ownable {
    IOperatorFilter private operatorFilter_;
    mapping(address => bool) private groupFilter;

    function setOperatorFilter(IOperatorFilter filter) public onlyOwner {
        operatorFilter_ = filter;
    }

    function setGroupFilter(address filter) public onlyOwner {
        groupFilter[filter] = true;
    }

    function removeGroupFilter(address filter) public onlyOwner {
        groupFilter[filter] = false;
    }

    function getGroupFilter(address filter) public view returns (bool) {
        return !!groupFilter[filter];
    }

    function operatorFilter() public view returns (IOperatorFilter) {
        return operatorFilter_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        if (groupFilter[from]) revert("ERC721OperatorFilter: illegal operator");
        if (groupFilter[to]) revert("ERC721OperatorFilter: illegal operator");
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