// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '../basic/BasicPhasedMintThree.sol';
import './ExpandablePhasedMintBase.sol';

/**
 * @title ExpandablePhasedMintThree
 * @author @NiftyMike, NFT Culture
 * @dev
 * PhasedMint: An approach to a standard system of controlling mint phases.
 * Expandable: An approach to ERC721 contracts that allows multiple subtypes of tokens.
 *
 * This is the "Three" phase mint flavor of the PhasedMint approach.
 *
 * Note: Since the last phase is always assumed to be the public mint phase, we only
 * need to define the first and second phases here.
 */
abstract contract ExpandablePhasedMintThree is BasicPhasedMintThree, ExpandablePhasedMintBase {
    /**
     * Expandable collection requires flavorId to be passed in to retrieve pricing.
     */
    function getPhaseOnePricePerNft(uint256 flavorId) external view virtual returns (uint256);

    /**
     * Expandable collection requires flavorId to be passed in to retrieve pricing.
     */
    function getPhaseTwoPricePerNft(uint256 flavorId) external view virtual returns (uint256);
}