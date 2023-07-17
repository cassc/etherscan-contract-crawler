// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// OZ Libraries
import '@openzeppelin/contracts/access/Ownable.sol';

import './BasicPhasedMintBase.sol';

/**
 * @title BasicPhasedMintOne
 * @author @NiftyMike, NFT Culture
 * @dev
 * PhasedMint: An approach to a standard system of controlling mint phases.
 * The 'Basic' flavor only provides on/off controls for each phase, no pricing info or anything else.
 *
 * This is the "One" phase mint flavor of the PhasedMint approach, which is public mint only.
 *
 * Note: No implementation is needed here explicitly, since the base class contains the public
 * mint phase definition.
 */
contract BasicPhasedMintOne is Ownable, BasicPhasedMintBase {
    constructor() BasicPhasedMintBase(1) {
        // Nothing to do.
    }

    function setMintingState(bool __publicMintingActive) external onlyOwner {
        _mintControlFlags = _calculateMintingState(__publicMintingActive);
    }
}