// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// OZ Libraries
import '../basic/BasicPhasedMintOne.sol';
import './ExpandablePhasedMintBase.sol';

/**
 * @title ExpandablePhasedMintOne
 * @author @NiftyMike, NFT Culture
 * @dev PhasedMint: An approach to a standard system of controlling mint phases.
 *
 * This is the "One" phase mint flavor of the PhasedMint approach, which is public mint only.
 *
 * Note: No implementation is needed here explicitly, since the base class contains the public
 * mint phase definition.
 */
abstract contract ExpandablePhasedMintOne is BasicPhasedMintOne, ExpandablePhasedMintBase {
    // Tag Absctract Contract
}