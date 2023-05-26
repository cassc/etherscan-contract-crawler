// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// OZ Libraries
import '@openzeppelin/contracts/access/Ownable.sol';

import './BasicPhasedMintBase.sol';

/**
 * @title BasicPhasedMintThree
 * @author @NiftyMike, NFT Culture
 * @dev 
 * PhasedMint: An approach to a standard system of controlling mint phases.
 * The 'Basic' flavor only provides on/off controls for each phase, no pricing info or anything else.
 *
 * This is the "Three" phase mint flavor of the PhasedMint approach.
 *
 * Note: Since the last phase is always assumed to be the public mint phase, we only
 * need to define the first and second phases here.
 */
abstract contract BasicPhasedMintThree is Ownable, BasicPhasedMintBase {
    using BooleanPacking for uint256;

    uint256 private constant PHASE_ONE = 1;
    uint256 private constant PHASE_TWO = 2;

    modifier isPhaseOne() {
        require(_mintControlFlags.getBoolean(PHASE_ONE), 'Phase one stopped');
        _;
    }

    modifier isPhaseTwo() {
        require(_mintControlFlags.getBoolean(PHASE_TWO), 'Phase two stopped');
        _;
    }

    constructor() BasicPhasedMintBase(3) {}

    function setMintingState(
        bool __phaseOneActive,
        bool __phaseTwoActive,
        bool __publicMintingActive
    ) external onlyOwner {
        uint256 tempControlFlags = _calculateMintingState(__publicMintingActive);

        tempControlFlags = tempControlFlags.setBoolean(PHASE_ONE, __phaseOneActive);

        tempControlFlags = tempControlFlags.setBoolean(PHASE_TWO, __phaseTwoActive);

        _mintControlFlags = tempControlFlags;
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