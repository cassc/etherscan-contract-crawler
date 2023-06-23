// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IEligibilityFilter} from "./IEligibilityFilter.sol";
import {IERC721Ownership} from "../interfaces/IERC721Ownership.sol";
import {Owned} from "solmate/auth/Owned.sol";

struct Collab {
    IEligibilityFilter eligibilityFilter;
    IERC721Ownership collection;
}

contract CollabEligibility is Owned {
    IEligibilityFilter defaultFilter;
    IERC721Ownership primaryCollection;
    mapping(uint256 => Collab) public collabs;

    constructor(IEligibilityFilter defaultFilter_, IERC721Ownership primaryCollection_)
        Owned(msg.sender)
    {
        defaultFilter = defaultFilter_;
        primaryCollection = primaryCollection_;
    }

    function registerCollab(
        uint256 collabId,
        IEligibilityFilter eligibilityFilter,
        IERC721Ownership collection
    ) external onlyOwner {
        collabs[collabId] = Collab(eligibilityFilter, collection);
    }

    function eligibilityCriteria(uint256 collabId) external view returns (string memory) {
        IEligibilityFilter eligibilityFilter = getEligibilityFilter(collabId);
        return eligibilityFilter.eligibilityCriteria();
    }

    function tokenIsEligible(uint256 collabId, uint256 tokenId) external view returns (bool) {
        IEligibilityFilter eligibilityFilter = getEligibilityFilter(collabId);

        return eligibilityFilter.tokenIsEligible(tokenId);
    }

    function tokensAreEligible(uint256 collabId, uint256[] calldata tokenIds)
        external
        view
        returns (bool[] memory)
    {
        IEligibilityFilter eligibilityFilter = getEligibilityFilter(collabId);
        uint256 count = tokenIds.length;
        bool[] memory result = new bool[](count);

        for (uint256 i; i < count;) {
            uint256 tokenId = tokenIds[i];
            if (eligibilityFilter.tokenIsEligible(tokenId)) {
                result[i] = true;
            }
            unchecked {
                ++i;
            }
        }

        return result;
    }

    function ownerIsEligible(uint256 collabId, address owner) external view returns (bool) {
        if (primaryCollection.balanceOf(owner) == 0) {
            return false;
        }
        IERC721Ownership collection = collabs[collabId].collection;
        if (address(collection) == address(0)) {
            return true;
        }

        return collection.balanceOf(owner) > 0;
    }

    function getEligibilityFilter(uint256 collabId) private view returns (IEligibilityFilter) {
        IEligibilityFilter eligibilityFilter = collabs[collabId].eligibilityFilter;
        if (address(eligibilityFilter) == address(0)) {
            eligibilityFilter = defaultFilter;
        }

        return eligibilityFilter;
    }
}