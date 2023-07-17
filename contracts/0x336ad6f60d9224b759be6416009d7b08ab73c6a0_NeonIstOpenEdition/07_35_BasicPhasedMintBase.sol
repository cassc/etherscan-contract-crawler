// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Libraries See: https://github.com/NFTCulture/nftc-open-contracts
import {BooleanPacking} from '@nftculture/nftc-contracts/contracts/utility/BooleanPacking.sol';

// OZ Libraries
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title BasicPhasedMintBase
 * @author @NiftyMike, NFT Culture
 * @dev
 * PhasedMint: An approach to a standard system of controlling mint phases.
 * The 'Basic' flavor only provides on/off controls for each phase, no pricing info or anything else.
 */
abstract contract BasicPhasedMintBase is Ownable {
    using BooleanPacking for uint256;

    // BooleanPacking used on _mintControlFlags
    uint256 internal _mintControlFlags;

    uint256 private immutable PUBLIC_MINT_PHASE;

    modifier isPublicMinting() {
        require(_mintControlFlags.getBoolean(PUBLIC_MINT_PHASE), 'Minting stopped');
        _;
    }

    constructor(uint256 publicMintPhase) {
        PUBLIC_MINT_PHASE = publicMintPhase;
    }

    function _calculateMintingState(bool __publicMintingActive) internal view returns (uint256) {
        uint256 tempControlFlags;

        tempControlFlags = tempControlFlags.setBoolean(PUBLIC_MINT_PHASE, __publicMintingActive);

        // This does not set state, because state is held by the child classes.
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