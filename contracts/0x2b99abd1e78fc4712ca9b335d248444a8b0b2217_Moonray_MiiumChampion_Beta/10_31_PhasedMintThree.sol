// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// OZ Libraries
import '@openzeppelin/contracts/access/Ownable.sol';

import './PhasedMintBase.sol';

/**
 * @title PhasedMintThree
 * @author @NiftyMike, NFT Culture
 * @dev PhasedMint: An approach to a standard system of controlling mint phases.
 *
 * This is the "Three" phase mint flavor of the PhasedMint approach.
 *
 * Note: Since the last phase is always assumed to be the public mint phase, we only
 * need to define the first and second phases here.
 */
contract PhasedMintThree is Ownable, PhasedMintBase {
    using BooleanPacking for uint256;

    uint256 private constant PHASE_ONE = 1;
    uint256 private constant PHASE_TWO = 2;

    uint256 public phaseOnePricePerNft;
    uint256 public phaseTwoPricePerNft;

    modifier isPhaseOne() {
        require(_mintControlFlags.getBoolean(PHASE_ONE), 'Phase one stopped');
        _;
    }

    modifier isPhaseTwo() {
        require(_mintControlFlags.getBoolean(PHASE_TWO), 'Phase two stopped');
        _;
    }

    constructor(
        uint256 __phaseOnePricePerNft,
        uint256 __phaseTwoPricePerNft,
        uint256 __publicMintPricePerNft
    ) PhasedMintBase(3, __publicMintPricePerNft) {
        phaseOnePricePerNft = __phaseOnePricePerNft;
        phaseTwoPricePerNft = __phaseTwoPricePerNft;
    }

    function setMintingState(
        bool __phaseOneActive,
        bool __phaseTwoActive,
        bool __publicMintingActive,
        uint256 __phaseOnePricePerNft,
        uint256 __phaseTwoPricePerNft,
        uint256 __publicMintPricePerNft
    ) external onlyOwner {
        uint256 tempControlFlags = _setMintingState(__publicMintingActive, __publicMintPricePerNft);

        tempControlFlags = tempControlFlags.setBoolean(PHASE_ONE, __phaseOneActive);

        tempControlFlags = tempControlFlags.setBoolean(PHASE_TWO, __phaseTwoActive);

        _mintControlFlags = tempControlFlags;

        if (__phaseOnePricePerNft > 0) {
            phaseOnePricePerNft = __phaseOnePricePerNft;
        }

        if (__phaseTwoPricePerNft > 0) {
            phaseTwoPricePerNft = __phaseTwoPricePerNft;
        }
    }

    function isPhaseOneActive() external view returns (bool) {
        return _isPhaseOneActive();
    }

    function _isPhaseOneActive() internal view returns (bool) {
        return _mintControlFlags.getBoolean(PHASE_ONE);
    }

    function isPhaseTwoActive() external view returns (bool) {
        return _isPhaseTwoActive();
    }

    function _isPhaseTwoActive() internal view returns (bool) {
        return _mintControlFlags.getBoolean(PHASE_TWO);
    }
}