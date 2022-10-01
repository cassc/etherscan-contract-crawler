// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Libraries See: https://github.com/NFTCulture/nftc-open-contracts
import {BooleanPacking} from '@nftculture/nftc-open-contracts/contracts/utility/BooleanPacking.sol';

// OZ Libraries
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title PhasedMintBase
 * @author @NiftyMike, NFT Culture
 * @dev PhasedMint: An approach to a standard system of controlling mint phases.
 */
abstract contract PhasedMintBase is Ownable {
    using BooleanPacking for uint256;

    // BooleanPacking used on _mintControlFlags
    uint256 internal _mintControlFlags;

    uint256 private immutable PUBLIC_MINT_PHASE;

    uint256 public publicMintPricePerNft;

    modifier isPublicMinting() {
        require(_mintControlFlags.getBoolean(PUBLIC_MINT_PHASE), 'Minting stopped');
        _;
    }

    constructor(uint256 publicMintPhase, uint256 __publicMintPricePerNft) {
        PUBLIC_MINT_PHASE = publicMintPhase;

        publicMintPricePerNft = __publicMintPricePerNft;
    }

    function _setMintingState(bool __publicMintingActive, uint256 __publicMintPricePerNft)
        internal
        returns (uint256)
    {
        uint256 tempControlFlags;

        tempControlFlags = tempControlFlags.setBoolean(PUBLIC_MINT_PHASE, __publicMintingActive);

        if (__publicMintPricePerNft > 0) {
            publicMintPricePerNft = __publicMintPricePerNft;
        }

        return tempControlFlags;
    }

    function isPublicMintingActive() external view returns (bool) {
        return _isPublicMintingActive();
    }

    function _isPublicMintingActive() internal view returns (bool) {
        return _mintControlFlags.getBoolean(PUBLIC_MINT_PHASE);
    }

    function supportedPhases() external view returns (uint256) {
        return PUBLIC_MINT_PHASE;
    }
}