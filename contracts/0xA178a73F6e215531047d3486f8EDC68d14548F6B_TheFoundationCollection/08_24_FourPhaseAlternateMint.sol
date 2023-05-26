// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Libraries See: https://github.com/NFTCulture/nftc-open-contracts
import {BooleanPacking} from "@nftculture/nftc-open-contracts/contracts/utility/BooleanPacking.sol";

// OZ Libraries
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Four Phase Mint Alternate Implementation
 * @author @KC, NFT Culture
 * @dev All the code needed to support a Four Phase mint in a standard way.
 *
 * Phase 1 - Presale #1
 * Phase 2 - Presale #2
 * Phase 3 - Presale #3
 * Phase 4 - Public Mint
 *
 * Phases are independent and can be run concurrently or exclusively.
 */
contract FourPhaseAlternateMint is Ownable {
    using BooleanPacking for uint256;

    uint256 private constant PRESALE_PHASE_1 = 1;
    uint256 private constant PRESALE_PHASE_2 = 2;
    uint256 private constant PRESALE_PHASE_3 = 3;
    uint256 private constant PUBLIC_MINT_PHASE = 4;

    // BooleanPacking used on mintControlFlags
    uint256 private mintControlFlags;

    uint256 public presale1PricePerNft;
    uint256 public presale2PricePerNft;
    uint256 public presale3PricePerNft;
    uint256 public publicMintPricePerNft;

    modifier isPresale1() {
        require(mintControlFlags.getBoolean(PRESALE_PHASE_1), 'Presale 1 stopped');
        _;
    }

    modifier isPresale2() {
        require(mintControlFlags.getBoolean(PRESALE_PHASE_2), 'Presale 2 stopped');
        _;
    }

    modifier isPresale3() {
        require(mintControlFlags.getBoolean(PRESALE_PHASE_3), 'Presale 3 stopped');
        _;
    }

    modifier isPublicMinting() {
        require(mintControlFlags.getBoolean(PUBLIC_MINT_PHASE), 'Minting stopped');
        _;
    }

    constructor(
        uint256 __presale1PricePerNft,
        uint256 __presale2PricePerNft,
        uint256 __presale3PricePerNft,
        uint256 __publicMintPricePerNft
    ) {
        presale1PricePerNft = __presale1PricePerNft;
        presale2PricePerNft = __presale2PricePerNft;
        presale3PricePerNft = __presale3PricePerNft;
        publicMintPricePerNft = __publicMintPricePerNft;
    }

    function setMintingState(
        bool __presale1Active,
        bool __presale2Active,
        bool __presale3Active,
        bool __publicMintingActive,
        uint256 __presale1PricePerNft,
        uint256 __presale2PricePerNft,
        uint256 __presale3PricePerNft,
        uint256 __publicMintPricePerNft
    ) external onlyOwner {
        uint256 tempControlFlags;

        tempControlFlags = tempControlFlags.setBoolean(
            PRESALE_PHASE_1,
            __presale1Active
        );
        tempControlFlags = tempControlFlags.setBoolean(
            PRESALE_PHASE_2,
            __presale2Active
        );
        tempControlFlags = tempControlFlags.setBoolean(
            PRESALE_PHASE_3,
            __presale3Active
        );
        tempControlFlags = tempControlFlags.setBoolean(
            PUBLIC_MINT_PHASE,
            __publicMintingActive
        );

        mintControlFlags = tempControlFlags;

        if (__presale1PricePerNft > 0) {
            presale1PricePerNft = __presale1PricePerNft;
        }

        if (__presale2PricePerNft > 0) {
            presale2PricePerNft = __presale2PricePerNft;
        }

        if (__presale3PricePerNft > 0) {
            presale3PricePerNft = __presale3PricePerNft;
        }

        if (__publicMintPricePerNft > 0) {
            publicMintPricePerNft = __publicMintPricePerNft;
        }
    }

    function isPresale1Active() external view returns (bool) {
        return mintControlFlags.getBoolean(PRESALE_PHASE_1);
    }

    function isPresale2Active() external view returns (bool) {
        return mintControlFlags.getBoolean(PRESALE_PHASE_2);
    }

    function isPresale3Active() external view returns (bool) {
        return mintControlFlags.getBoolean(PRESALE_PHASE_3);
    }

    function isPublicMintingActive() external view returns (bool) {
        return mintControlFlags.getBoolean(PUBLIC_MINT_PHASE);
    }

    function supportedPhases() external pure returns (uint256) {
        return PUBLIC_MINT_PHASE;
    }
}