// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Base} from  "../base/Base.sol";
import {IApproval} from "../interfaces/IApproval.sol";
import {LibTokenOwnership} from "../libraries/LibTokenOwnership.sol";
import {IOperatorFilter} from "../interfaces/IOperatorFilter.sol";

contract ApprovalFacet is Base, IApproval {
    modifier canOperate(address _operator) {
        if(!mayOperate(_operator)) revert IOperatorFilter.IllegalOperator();
        _;
    }
    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external isTransferable tokenLocked(_tokenId) canOperate(_approved) {
        if (_approved == address(0)) revert InvalidApprovalZeroAddress();
        address owner = LibTokenOwnership.ownerOf(_tokenId);
        if (owner != msg.sender && !s.nftStorage.operators[msg.sender][_approved] && s.nftStorage.tokenOperators[_tokenId] != msg.sender)
            revert CallerNotOwnerOrApprovedOperator();

        s.nftStorage.tokenOwners[_tokenId] = owner;
        s.nftStorage.tokenOperators[_tokenId] = _approved;

        emit Approval(msg.sender, _approved, _tokenId);
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external isTransferable canOperate(_operator) {
        s.nftStorage.operators[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view tokenLocked(_tokenId) returns (address) {
        return LibTokenOwnership.ownerOf(_tokenId);
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        if(!mayOperate(_operator)) return false;
        return s.nftStorage.operators[_owner][_operator];
    }



    function mayOperate(address _operator) private view returns (bool) {
        IOperatorFilter filter = IOperatorFilter(s.operatorFilter);
        if (address(filter) == address(0)) return true;
        return filter.mayTransfer(_operator);
    }
}