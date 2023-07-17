// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import "./interfaces/IDeedAuthorizer.sol";
import "./interfaces/IDelegationRegistry.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract DeedAuthWithDelegation is IDeedAuthorizer {
    address private constant DELEGATION_REGISTRY = 0x00000000000076A84feF008CDAbe6409d2FE638B;

    function isAuthedForDeeds(
        address claimant,
        address collection,
        uint256 tokenId,
        uint256
    ) external view returns (bool) {
        require(
            IERC721(collection).ownerOf(tokenId) == claimant ||
            IDelegationRegistry(DELEGATION_REGISTRY).checkDelegateForToken(
                claimant,
                IERC721(collection).ownerOf(tokenId),
                collection,
                tokenId
            )
        );
        return true;
    }
    
    /// @dev No-op
    function deedsMerged(
        address,
        address,
        uint256,
        uint256
    ) external pure returns (bool) {
        return true;
    }

}