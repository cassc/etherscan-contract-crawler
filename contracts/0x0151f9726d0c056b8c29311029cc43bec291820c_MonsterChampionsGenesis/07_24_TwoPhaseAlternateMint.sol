// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Libraries See: https://github.com/NFTCulture/nftc-open-contracts
import {BooleanPacking} from "@nftculture/nftc-open-contracts/contracts/utility/BooleanPacking.sol";

// OZ Libraries
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Two Phase Mint, Alternate Implementation
 * @author @NiftyMike, NFT Culture
 * @dev All the code needed to support a Two Phase mint in a standard way.
 *
 * Phase 1 - Presale
 * Phase 2 - Public Mint
 *
 * Phases are independent and can be run concurrently or exclusively.
 */
contract TwoPhaseAlternateMint is Ownable {
    using BooleanPacking for uint256;

    uint256 private constant PRESALE_PHASE = 1;
    uint256 private constant PUBLIC_MINT_PHASE = 2;

    // BooleanPacking used on mintControlFlags
    uint256 private mintControlFlags;

    uint256 public presalePricePerNft;
    uint256 public publicMintPricePerNft;

    modifier isPresale() {
        require(mintControlFlags.getBoolean(PRESALE_PHASE), 'Presale stopped');
        _;
    }

    modifier isPublicMinting() {
        require(mintControlFlags.getBoolean(PUBLIC_MINT_PHASE), 'Minting stopped');
        _;
    }

    constructor(
        uint256 __presalePricePerNft,
        uint256 __publicMintPricePerNft
    ) {
        presalePricePerNft = __presalePricePerNft;
        publicMintPricePerNft = __publicMintPricePerNft;
    }

    function setMintingState(
        bool __presaleActive,
        bool __publicMintingActive,
        uint256 __presalePricePerNft,
        uint256 __publicMintPricePerNft
    ) external onlyOwner {
        uint256 tempControlFlags;

        tempControlFlags = tempControlFlags.setBoolean(
            PRESALE_PHASE,
            __presaleActive
        );
        tempControlFlags = tempControlFlags.setBoolean(
            PUBLIC_MINT_PHASE,
            __publicMintingActive
        );

        mintControlFlags = tempControlFlags;

        if (__presalePricePerNft > 0) {
            presalePricePerNft = __presalePricePerNft;
        }

        if (__publicMintPricePerNft > 0) {
            publicMintPricePerNft = __publicMintPricePerNft;
        }
    }

    function isPresaleActive() external view returns (bool) {
        return mintControlFlags.getBoolean(PRESALE_PHASE);
    }

    function isPublicMintingActive() external view returns (bool) {
        return mintControlFlags.getBoolean(PUBLIC_MINT_PHASE);
    }

    function supportedPhases() external pure returns (uint256) {
        return PUBLIC_MINT_PHASE;
    }
}