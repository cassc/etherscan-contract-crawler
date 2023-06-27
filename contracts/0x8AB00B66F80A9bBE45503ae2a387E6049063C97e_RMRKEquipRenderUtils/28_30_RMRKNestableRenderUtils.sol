// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "../nestable/IERC6059.sol";
import "../library/RMRKErrors.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/**
 * @title RMRKNestableRenderUtils
 * @author RMRK team
 * @notice Smart contract of the RMRK Nestable render utils module.
 */
contract RMRKNestableRenderUtils {
    /**
     * @notice Used to retrieve the given child's index in its parent's child tokens array.
     * @param parentAddress Address of the parent token's collection smart contract
     * @param parentId ID of the parent token
     * @param childAddress Address of the child token's colection smart contract
     * @param childId ID of the child token
     * @return The index of the child token in the parent token's child tokens array
     */
    function getChildIndex(
        address parentAddress,
        uint256 parentId,
        address childAddress,
        uint256 childId
    ) public view returns (uint256) {
        IERC6059.Child[] memory children = IERC6059(parentAddress).childrenOf(
            parentId
        );
        (parentId);
        uint256 len = children.length;
        for (uint256 i; i < len; ) {
            if (
                children[i].tokenId == childId &&
                children[i].contractAddress == childAddress
            ) return i;
            unchecked {
                ++i;
            }
        }
        revert RMRKChildNotFoundInParent();
    }

    /**
     * @notice Used to retrieve the given child's index in its parent's pending child tokens array.
     * @param parentAddress Address of the parent token's collection smart contract
     * @param parentId ID of the parent token
     * @param childAddress Address of the child token's colection smart contract
     * @param childId ID of the child token
     * @return The index of the child token in the parent token's pending child tokens array
     */
    function getPendingChildIndex(
        address parentAddress,
        uint256 parentId,
        address childAddress,
        uint256 childId
    ) public view returns (uint256) {
        IERC6059.Child[] memory children = IERC6059(parentAddress)
            .pendingChildrenOf(parentId);
        (parentId);
        uint256 len = children.length;
        for (uint256 i; i < len; ) {
            if (
                children[i].tokenId == childId &&
                children[i].contractAddress == childAddress
            ) return i;
            unchecked {
                ++i;
            }
        }
        revert RMRKChildNotFoundInParent();
    }

    /**
     * @notice Used to retrieve the contract address and ID of the parent token of the specified child token.
     * @dev Reverts if child token is not owned by an NFT.
     * @param childAddress Address of the child token's collection smart contract
     * @param childId ID of the child token
     * @return parentAddress Address of the parent token's collection smart contract
     * @return parentId ID of the parent token
     */
    function getParent(
        address childAddress,
        uint256 childId
    ) public view returns (address parentAddress, uint256 parentId) {
        bool isNFT;
        (parentAddress, parentId, isNFT) = IERC6059(childAddress).directOwnerOf(
            childId
        );
        if (!isNFT) revert RMRKParentIsNotNFT();
    }

    /**
     * @notice Used to retrieve the immediate owner of the given token, and whether it is on the parent's active or pending children list.
     * @dev If the immediate owner is not an NFT, the function returns false for both `inParentsActiveChildren` and `inParentsPendingChildren`.
     * @param collection Address of the token's collection smart contract
     * @param tokenId ID of the token
     * @return directOwner Address of the given token's owner
     * @return ownerId The ID of the parent token. Should be `0` if the owner is an externally owned account
     * @return isNFT The boolean value signifying whether the owner is an NFT or not
     * @return inParentsActiveChildren A boolean value signifying whether the token is in the parent's active children list
     * @return inParentsPendingChildren A boolean value signifying whether the token is in the parent's pending children list
     */
    function directOwnerOfWithParentsPerspective(
        address collection,
        uint256 tokenId
    )
        public
        view
        returns (
            address directOwner,
            uint256 ownerId,
            bool isNFT,
            bool inParentsActiveChildren,
            bool inParentsPendingChildren
        )
    {
        (directOwner, ownerId, isNFT) = IERC6059(collection).directOwnerOf(
            tokenId
        );
        if (!isNFT) {
            inParentsActiveChildren = false;
            inParentsPendingChildren = false;
        } else {
            IERC6059.Child[] memory activeChildren = IERC6059(directOwner)
                .childrenOf(ownerId);
            IERC6059.Child[] memory pendingChildren = IERC6059(directOwner)
                .pendingChildrenOf(ownerId);

            uint256 len = activeChildren.length;
            for (uint256 i; i < len; ) {
                if (
                    activeChildren[i].tokenId == tokenId &&
                    activeChildren[i].contractAddress == collection
                ) {
                    inParentsActiveChildren = true;
                    break;
                }
                unchecked {
                    ++i;
                }
            }
            if (!inParentsActiveChildren) {
                // Cannot be on both lists
                len = pendingChildren.length;
                for (uint256 i; i < len; ) {
                    if (
                        pendingChildren[i].tokenId == tokenId &&
                        pendingChildren[i].contractAddress == collection
                    ) {
                        inParentsPendingChildren = true;
                        break;
                    }
                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    /**
     * @notice Used to identify if the given token is rejected or abandoned. That is, it's parent is an NFT but this token is neither on the parent's active nor pending children list.
     * @dev Returns false if the immediate owner is not an NFT.
     * @param collection Address of the token's collection smart contract
     * @param tokenId ID of the token
     * @return isRejectedOrAbandoned Whether the token is rejected or abandoned
     */
    function isTokenRejectedOrAbandoned(
        address collection,
        uint256 tokenId
    ) public view returns (bool isRejectedOrAbandoned) {
        (
            ,
            ,
            bool parentIsNft,
            bool inParentsActiveChildren,
            bool inParentsPendingChildren
        ) = directOwnerOfWithParentsPerspective(collection, tokenId);
        return
            parentIsNft &&
            !inParentsActiveChildren &&
            !inParentsPendingChildren;
    }

    /**
     * @notice Check if the child is owned by the expected parent.
     * @dev Reverts if child token is not owned by an NFT.
     * @dev Reverts if child token is not owned by the expected parent.
     * @param childAddress Address of the child contract
     * @param childId ID of the child token
     * @param expectedParent Address of the expected parent contract
     * @param expectedParentId ID of the expected parent token
     */
    function checkExpectedParent(
        address childAddress,
        uint256 childId,
        address expectedParent,
        uint256 expectedParentId
    ) public view {
        address parentAddress;
        uint256 parentId;
        (parentAddress, parentId) = getParent(childAddress, childId);
        if (parentAddress != expectedParent || expectedParentId != parentId)
            revert RMRKUnexpectedParent();
    }

    /**
     * @notice Used to validate whether the specified child token is owned by a given parent token.
     * @param parentAddress Address of the parent token's collection smart contract
     * @param childAddress Address of the child token's collection smart contract
     * @param parentId ID of the parent token
     * @param childId ID of the child token
     * @return A boolean value indicating whether the child token is owned by the parent token or not
     */
    function validateChildOf(
        address parentAddress,
        address childAddress,
        uint256 parentId,
        uint256 childId
    ) public view returns (bool) {
        if (
            !IERC165(childAddress).supportsInterface(type(IERC6059).interfaceId)
        ) {
            return false;
        }

        (address directOwner, uint256 ownerId, ) = IERC6059(childAddress)
            .directOwnerOf(childId);

        return (directOwner == parentAddress && ownerId == parentId);
    }

    /**
     * @notice Used to validate whether the specified child token is owned by a given parent token.
     * @param parentAddress Address of the parent token's collection smart contract
     * @param childAddresses An array of the child token's collection smart contract addresses
     * @param parentId ID of the parent token
     * @param childIds An array of child token IDs to verify
     * @return A boolean value indicating whether all of the child tokens are owned by the parent token or not
     * @return An array of boolean values indicating whether each of the child tokens are owned by the parent token or
     *  not
     */
    function validateChildrenOf(
        address parentAddress,
        address[] memory childAddresses,
        uint256 parentId,
        uint256[] memory childIds
    ) public view returns (bool, bool[] memory) {
        if (childAddresses.length != childIds.length) {
            revert RMRKMismachedArrayLength();
        }

        address directOwner;
        uint256 ownerId;
        bool[] memory validityOfChildren = new bool[](childAddresses.length);
        bool isValid = true;

        for (uint256 i; i < childAddresses.length; ) {
            validityOfChildren[i] = validateChildOf(
                parentAddress,
                childAddresses[i],
                parentId,
                childIds[i]
            );

            if (isValid && !validityOfChildren[i]) {
                isValid = false;
            }

            delete directOwner;
            delete ownerId;

            unchecked {
                ++i;
            }
        }

        return (isValid, validityOfChildren);
    }
}