// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

import "./RoyaltyInternal.sol";
import "./RoyaltyStorage.sol";
import "./IRoyalty.sol";

/**
 * @title ERC2981 - Royalty
 * @notice Provide standard on-chain EIP-2981 royalty support for ERC721 or ERC1155 tokens, and additional functions for Rarible and Foundation.
 *
 * @custom:type eip-2535-facet
 * @custom:category Finance
 * @custom:provides-interfaces IEIP2981 IRoyalty IRaribleV1 IRaribleV2 IFoundation IEIP2981RoyaltyOverride
 */
contract Royalty is IRoyalty, RoyaltyInternal {
    using RoyaltyStorage for RoyaltyStorage.Layout;

    function defaultRoyalty() external view virtual returns (TokenRoyalty memory) {
        return RoyaltyStorage.layout().defaultRoyalty;
    }

    /**
     * @dev EIP-2981
     */
    function royaltyInfo(uint256 tokenId, uint256 value) external view virtual returns (address, uint256) {
        return _royaltyInfo(tokenId, value);
    }

    /**
     * @dev IEIP2981RoyaltyOverride (Manifold)
     */
    function getTokenRoyaltiesCount() external view virtual override returns (uint256) {
        return _getTokenRoyaltiesCount();
    }

    function getTokenRoyaltyByIndex(uint256 index) external view virtual override returns (TokenRoyaltyConfig memory) {
        return _getTokenRoyaltyByIndex(index);
    }

    /**
     * @dev IFoundation
     */
    function getFees(uint256 tokenId) external view virtual returns (address payable[] memory, uint256[] memory) {
        address payable[] memory receivers = new address payable[](1);
        uint256[] memory bps = new uint256[](1);

        (address receiver, uint256 value) = _royaltyInfo(tokenId, 10000);

        receivers[0] = payable(receiver);
        bps[0] = value;

        return (receivers, bps);
    }

    /**
     * @dev IRaribleV1
     */
    function getFeeRecipients(uint256 tokenId) external view virtual returns (address payable[] memory) {
        address payable[] memory receivers = new address payable[](1);

        (address receiver, ) = _royaltyInfo(tokenId, 10000);
        receivers[0] = payable(receiver);

        return receivers;
    }

    function getFeeBps(uint256 tokenId) external view virtual returns (uint256[] memory) {
        uint256[] memory bps = new uint256[](1);

        (, uint256 value) = _royaltyInfo(tokenId, 10000);

        bps[0] = value;

        return bps;
    }

    /**
     * @dev IRaribleV2
     */
    function getRaribleV2Royalties(uint256 tokenId) external view override returns (IRaribleV2.Part[] memory result) {
        result = new IRaribleV2.Part[](1);

        // Passing 10,000 as value will give us the bps (basis points, out of 10,000) of the royalty.
        (address account, uint256 value) = _royaltyInfo(tokenId, 10000);

        result[0].account = payable(account);
        result[0].value = uint96(value);
    }
}