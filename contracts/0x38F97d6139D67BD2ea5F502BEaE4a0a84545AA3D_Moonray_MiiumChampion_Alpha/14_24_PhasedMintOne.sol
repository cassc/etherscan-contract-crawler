// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// OZ Libraries
import '@openzeppelin/contracts/access/Ownable.sol';

import './PhasedMintBase.sol';

/**
 * @title PhasedMintOne
 * @author @NiftyMike, NFT Culture
 * @dev PhasedMint: An approach to a standard system of controlling mint phases.
 *
 * This is the "One" phase mint flavor of the PhasedMint approach, which is public mint only.
 *
 * Note: No implementation is needed here explicitly, since the base class contains the public
 * mint phase definition.
 */
contract PhasedMintOne is Ownable, PhasedMintBase {
    constructor(uint256 __publicMintPricePerNft) PhasedMintBase(1, __publicMintPricePerNft) {
        // Nothing to do.
    }

    function setMintingState(bool __publicMintingActive, uint256 __publicMintPricePerNft)
        external
        onlyOwner
    {
        _mintControlFlags = _setMintingState(__publicMintingActive, __publicMintPricePerNft);
    }
}