// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * New Distribution Scheme ERC721D
 */

interface IERC721D {
    /**
     * Cliamed Distribution Event;
     */

    event ClaimEvent(
        address indexed to,
        uint256[] indexed tokenIds,
        uint8 indexed claimType
    );

    /**
     * Set  Distribution Scheme
     */

    function setDistribution() external;

    /**
     *Uint256 [] tokenIds give the token id holder the allocated bonus
     *Uint8 enumType distinguishes different bonus distribution schemes
     *bytes calldata _ Signature verifies the legitimacy of the collection
     * emit event after claimed
     */

    function claimDistribution(
        uint256[] calldata tokenIds,
        uint8 enumType,
        bytes calldata _signature
    ) external;

    /**
     * Check whether a token ID supports Claim
     * returns supported: is support claim
     */

    function isSupportClaim(uint256 tokenId) external view returns (bool);

    /**
     * Check whether the token id has been claimed
     * returns cliamed : claimed status
     */

    function isClaimedDistribution(uint256 tokenId)
        external
        view
        returns (bool);

    /**
     * Check whether begain claim
     */

    function isBegainClaim() external view returns (bool);
}