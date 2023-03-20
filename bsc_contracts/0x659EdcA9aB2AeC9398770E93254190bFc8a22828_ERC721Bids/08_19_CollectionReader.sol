// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

library CollectionReader {
    function collectionOwner(address collectionAddress)
        internal
        view
        returns (address owner)
    {
        try Ownable(collectionAddress).owner() returns (address _owner) {
            owner = _owner;
        } catch {}
    }

    function tokenOwner(address erc721Address, uint256 tokenId)
        internal
        view
        returns (address owner)
    {
        IERC721 _erc721 = IERC721(erc721Address);
        try _erc721.ownerOf(tokenId) returns (address _owner) {
            owner = _owner;
        } catch {}
    }

    /**
     * @dev check if this contract has approved to transfer this erc721 token
     */
    function isTokenApproved(address erc721Address, uint256 tokenId)
        internal
        view
        returns (bool isApproved)
    {
        IERC721 _erc721 = IERC721(erc721Address);
        try _erc721.getApproved(tokenId) returns (address tokenOperator) {
            if (tokenOperator == address(this)) {
                isApproved = true;
            }
        } catch {}
    }

    /**
     * @dev check if this contract has approved to all of this owner's erc721 tokens
     */
    function isAllTokenApproved(
        address erc721Address,
        address owner,
        address operator
    ) internal view returns (bool isApproved) {
        IERC721 _erc721 = IERC721(erc721Address);

        try _erc721.isApprovedForAll(owner, operator) returns (
            bool _isApproved
        ) {
            isApproved = _isApproved;
        } catch {}
    }
}