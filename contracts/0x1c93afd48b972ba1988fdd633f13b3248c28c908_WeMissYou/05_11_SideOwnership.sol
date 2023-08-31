// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract SideOwnership {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => mapping(uint256 => bool)) internal _sideOwnerApprovals;
    mapping(uint256 => mapping(address => bool)) internal _sideOwnerships;
    mapping(uint256 => EnumerableSet.AddressSet) internal _sideOwnershipMember;

    function sideOwnersOf(uint256 tokenId) public view virtual returns (address[] memory){
        return _sideOwnershipMember[tokenId].values();
    }

    function hasSideOwnership(address owner, uint256 tokenId) public view returns (bool){
        return _sideOwnerships[tokenId][owner];
    }

    function _addSideOwnership(address account, uint256 tokenId) internal virtual {
        require(account != address(0), "cannot assign side ownership to zero address");
        _sideOwnerships[tokenId][account] = true;
        _sideOwnershipMember[tokenId].add(account);
    }

    function _revokeSideOwnership(address account, uint256 tokenId) internal virtual {
        _sideOwnerships[tokenId][account] = false;
        _sideOwnershipMember[tokenId].remove(account);
    }

    modifier fullOwnership(uint256 tokenId) {
        _checkFullOwnership(tokenId);
        _;
    }

    function _setSideApprovalForToken(address from, uint256 tokenId, bool status) internal virtual {
        _sideOwnerApprovals[from][tokenId] = status;
    }

    function _afterTransfer(address to, uint256 tokenId) internal virtual {
        if(hasSideOwnership(to, tokenId)){
            _revokeSideOwnership(to, tokenId);
        }
    }

    function _checkFullOwnership(uint256 tokenId) internal view virtual {
        for(uint256 i; i < _sideOwnershipMember[tokenId].length(); i ++){
            address member = _sideOwnershipMember[tokenId].at(i);
            if(!_sideOwnerApprovals[member][tokenId]){
                revert("not have full ownership");
            }
        }
    }
}